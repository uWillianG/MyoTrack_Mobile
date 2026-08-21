import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

part 'local_database.g.dart';

/// Escritas que ainda não chegaram ao servidor.
///
/// Uma linha por requisição, com o corpo já serializado. Guardar o JSON pronto — e não os
/// campos separados — deixa a fila indiferente ao que está sendo enviado: série, medida ou
/// o que vier depois.
class PendingWrites extends Table {
  IntColumn get id => integer().autoIncrement()();

  /// Caminho relativo, ex.: `/api/sessions`.
  TextColumn get endpoint => text()();

  TextColumn get payload => text()();

  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  IntColumn get attempts => integer().withDefault(const Constant(0))();

  /// Motivo da última falha — só para diagnóstico; não decide nada.
  TextColumn get lastError => text().nullable()();
}

/// Escritas que o servidor recusou e que não vão subir nunca.
///
/// **Esta tabela existe porque o descarte era silencioso.** Quando o servidor responde 4xx a
/// uma escrita da fila, mantê-la lá travaria todas as seguintes — o usuário perderia tudo que
/// registrasse depois, sem perceber. Então ela é descartada; mas apagar a linha e seguir
/// significava que um treino inteiro sumia sem deixar rastro, e o `lastError` que acabara de ser
/// gravado ia junto. Aqui a escrita recusada é **movida**, não deletada: o app pode dizer o que
/// não subiu, quando, e por quê.
///
/// O [payload] vem junto de propósito. Sem ele o aviso seria "um registro falhou"; com ele dá
/// para dizer "a pesagem de 82,4 kg do dia 28/07" — que é a diferença entre um alerta que a
/// pessoa ignora e um que ela consegue agir em cima, refazendo o registro à mão.
class DiscardedWrites extends Table {
  IntColumn get id => integer().autoIncrement()();

  TextColumn get endpoint => text()();

  TextColumn get payload => text()();

  /// A recusa do servidor, como ela chegou.
  TextColumn get error => text()();

  /// Quando o servidor recusou — e não quando o usuário registrou. As duas datas podem estar a
  /// dias de distância se a escrita passou uma viagem inteira na fila, e o que a pessoa precisa
  /// para se localizar é a data do registro, que está no [payload].
  DateTimeColumn get discardedAt =>
      dateTime().withDefault(currentDateAndTime)();
}

/// Conquistas que o usuário já viu comemoradas.
///
/// **Só o "já vi", e não a conquista.** Se alguém ganhou algo é derivado dos agregados do
/// servidor a cada abertura — guardar isso aqui criaria uma segunda verdade livre para
/// divergir da primeira. O que o servidor não tem como saber é se a pessoa já foi avisada, e
/// isso é estado de aparelho: quem instala num celular novo reveria a comemoração de um
/// recorde de três meses atrás.
class SeenAchievements extends Table {
  /// O id do catálogo, ex.: `quatro-semanas`.
  TextColumn get id => text()();

  DateTimeColumn get seenAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}

@DriftDatabase(tables: [PendingWrites, SeenAchievements, DiscardedWrites])
class LocalDatabase extends _$LocalDatabase {
  LocalDatabase() : super(_open());

  /// Construtor para teste: recebe um banco em memória.
  LocalDatabase.forTesting(super.executor);

  @override
  int get schemaVersion => 4;

  /// v2 acrescentou [SeenAchievements], v3 [DiscardedWrites], e v4 **apaga** a tabela do
  /// catálogo de exercícios, que existia só para a tela de registro manual sair do ar.
  ///
  /// Fora essa, `onUpgrade` cria a tabela nova e não toca em mais nada: a fila de escrita pode
  /// ter séries de um treino que ainda não subiu, e uma migração que recriasse o banco perderia
  /// justamente o dado que ninguém tem de volta. Derrubar o catálogo é seguro pelo motivo
  /// oposto — era cache de uma lista que o servidor devolve inteira, e ninguém mais a lê.
  ///
  /// A tabela é nomeada por string porque a classe que a descrevia não existe mais neste
  /// arquivo; quem migra de uma versão antiga ainda tem a tabela no disco.
  ///
  /// Os `if` são independentes e não têm `else` de propósito: quem pula da v1 direto para a v4
  /// — instalou, ficou meses sem atualizar — precisa das três passagens de uma vez.
  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) => m.createAll(),
    onUpgrade: (m, from, to) async {
      if (from < 2) {
        await m.createTable(seenAchievements);
      }
      if (from < 3) {
        await m.createTable(discardedWrites);
      }
      if (from < 4) {
        await customStatement('DROP TABLE IF EXISTS cached_exercises');
      }
    },
  );

  // --- Fila de escrita ---

  Future<int> enqueue(String endpoint, String payload) => into(
    pendingWrites,
  ).insert(PendingWritesCompanion.insert(endpoint: endpoint, payload: payload));

  /// Em ordem de criação: uma medida registrada antes deve chegar antes.
  Future<List<PendingWrite>> pending() =>
      (select(pendingWrites)..orderBy([(t) => OrderingTerm.asc(t.id)])).get();

  Future<int> countPending() async => (await pendingWrites.count().getSingle());

  Future<void> removePending(int id) =>
      (delete(pendingWrites)..where((t) => t.id.equals(id))).go();

  /// Incrementa a contagem de tentativas e guarda o erro.
  Future<void> recordAttempt(int id, String error) => customUpdate(
    'UPDATE pending_writes SET attempts = attempts + 1, last_error = ? WHERE id = ?',
    variables: [Variable<String>(error), Variable<int>(id)],
    updates: {pendingWrites},
  );

  /// Observa quantas escritas estão pendentes — a UI mostra o aviso de "não sincronizado".
  Stream<int> watchPendingCount() => pendingWrites.count().watchSingle();

  // --- Escritas recusadas ---

  /// Tira [write] da fila e a arquiva como recusada, com o motivo.
  ///
  /// Numa transação porque as duas metades não podem se separar: gravar o descarte sem remover
  /// da fila faria a mesma escrita ser recusada de novo a cada sincronização, e remover sem
  /// gravar é exatamente o sumiço silencioso que esta tabela veio resolver.
  Future<void> discardPending(PendingWrite write, String error) {
    return transaction(() async {
      await into(discardedWrites).insert(
        DiscardedWritesCompanion.insert(
          endpoint: write.endpoint,
          payload: write.payload,
          error: error,
        ),
      );
      await removePending(write.id);
    });
  }

  /// As recusadas, mais recentes primeiro — é a ordem em que a UI as lista.
  Future<List<DiscardedWrite>> discarded() => (select(
    discardedWrites,
  )..orderBy([(t) => OrderingTerm.desc(t.id)])).get();

  /// Some com o aviso depois que o usuário o leu.
  ///
  /// Apaga de verdade: o payload de uma escrita recusada é dado pessoal guardado sem prazo, e
  /// o único motivo de ele existir era poder ser mostrado. Lido o aviso, o motivo acabou.
  Future<void> clearDiscarded() => delete(discardedWrites).go();

  // --- Conquistas já comemoradas ---

  Future<Set<String>> seenAchievementIds() async {
    final rows = await select(seenAchievements).get();
    return {for (final row in rows) row.id};
  }

  /// Marca [ids] como vistas.
  ///
  /// `insertOrIgnore`, e não update: o que interessa é **quando foi a primeira vez**, e
  /// sobrescrever a data a cada visita à tela apagaria justamente essa informação.
  Future<void> markAchievementsSeen(Iterable<String> ids) async {
    if (ids.isEmpty) {
      return;
    }
    await batch((batch) {
      batch.insertAll(seenAchievements, [
        for (final id in ids) SeenAchievementsCompanion.insert(id: id),
      ], mode: InsertMode.insertOrIgnore);
    });
  }

  // --- Fim de sessão ---

  /// Apaga deste aparelho tudo que pertence a quem estava logado.
  ///
  /// **Existe porque sair da conta não apagava nada, e isso vazava dado de uma pessoa para
  /// outra.** A fila de escrita guarda o corpo cru de séries e pesagens, e a sincronização a
  /// reenvia com *o token que estiver valendo na hora* — o treino de quem saiu subiria para a
  /// conta de quem entrasse depois no mesmo aparelho, sem erro nenhum no caminho. Na exclusão
  /// de conta o buraco é ainda mais direto: a tela promete que "não há cópia de segurança"
  /// enquanto o celular ficava com uma.
  ///
  /// **Apaga tudo o que há**, sem exceção: desde que o catálogo de exercícios saiu do banco,
  /// não sobrou aqui nenhuma tabela que não seja do titular da sessão.
  Future<void> wipe() async {
    await batch((batch) {
      batch.deleteWhere(pendingWrites, (_) => const Constant(true));
      batch.deleteWhere(discardedWrites, (_) => const Constant(true));
      batch.deleteWhere(seenAchievements, (_) => const Constant(true));
    });
  }
}

QueryExecutor _open() {
  return LazyDatabase(() async {
    final dir = await getApplicationDocumentsDirectory();
    final file = File(p.join(dir.path, 'myotrack.sqlite'));
    return NativeDatabase.createInBackground(file);
  });
}
