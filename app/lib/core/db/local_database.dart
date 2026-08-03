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

/// Catálogo de exercícios espelhado localmente.
///
/// Sem ele não dá para registrar treino offline: o usuário precisa escolher o exercício, e a
/// lista vem do servidor. O catálogo é igual para todos e muda raramente, então cabe inteiro
/// no aparelho.
class CachedExercises extends Table {
  IntColumn get id => integer()();
  TextColumn get name => text()();
  TextColumn get muscleGroup => text()();
  TextColumn get equipment => text()();
  BoolColumn get isCompound => boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {id};
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

@DriftDatabase(tables: [PendingWrites, CachedExercises, SeenAchievements])
class LocalDatabase extends _$LocalDatabase {
  LocalDatabase() : super(_open());

  /// Construtor para teste: recebe um banco em memória.
  LocalDatabase.forTesting(super.executor);

  @override
  int get schemaVersion => 2;

  /// A v2 só acrescenta [SeenAchievements].
  ///
  /// `onUpgrade` cria a tabela nova e não toca em mais nada: a fila de escrita pode ter
  /// séries de um treino que ainda não subiu, e uma migração que recriasse o banco perderia
  /// justamente o dado que ninguém tem de volta.
  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) => m.createAll(),
    onUpgrade: (m, from, to) async {
      if (from < 2) {
        await m.createTable(seenAchievements);
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

  // --- Catálogo ---

  Future<void> replaceExercises(List<CachedExercisesCompanion> items) async {
    await batch((batch) {
      // O catálogo é substituído inteiro: exercício removido no servidor não pode
      // continuar selecionável aqui.
      batch.deleteWhere(cachedExercises, (_) => const Constant(true));
      batch.insertAll(cachedExercises, items);
    });
  }

  Future<List<CachedExercise>> exercises() => (select(
    cachedExercises,
  )..orderBy([(t) => OrderingTerm.asc(t.name)])).get();

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
}

QueryExecutor _open() {
  return LazyDatabase(() async {
    final dir = await getApplicationDocumentsDirectory();
    final file = File(p.join(dir.path, 'myotrack.sqlite'));
    return NativeDatabase.createInBackground(file);
  });
}
