import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:myotrack/core/db/local_database.dart';

/// A subida de v1 para v2 é o único caminho deste banco que roda na máquina de alguém que já
/// usava o app — e é o único que pode destruir dado que ninguém tem de volta: a fila de
/// escrita guarda séries registradas sem rede, na academia, que ainda não subiram.
///
/// Um teste que só abre o banco do zero não passa por aqui: ele cai no `onCreate`.
void main() {
  late Directory dir;
  late File file;

  setUp(() async {
    dir = await Directory.systemTemp.createTemp('myotrack-migration');
    file = File('${dir.path}/myotrack.sqlite');
  });

  tearDown(() => dir.delete(recursive: true));

  /// Escreve um banco exatamente como a v1 o deixava, com uma escrita pendente dentro.
  Future<void> seedV1() async {
    final db = NativeDatabase(file);
    await db.ensureOpen(_NoopUser());
    await db.runCustom('''
      CREATE TABLE pending_writes (
        id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
        endpoint TEXT NOT NULL,
        payload TEXT NOT NULL,
        created_at INTEGER NOT NULL DEFAULT (strftime('%s', CURRENT_TIMESTAMP)),
        attempts INTEGER NOT NULL DEFAULT 0,
        last_error TEXT NULL
      )''', const []);
    await db.runCustom('''
      CREATE TABLE cached_exercises (
        id INTEGER NOT NULL,
        name TEXT NOT NULL,
        muscle_group TEXT NOT NULL,
        equipment TEXT NOT NULL,
        is_compound INTEGER NOT NULL DEFAULT 0,
        PRIMARY KEY (id)
      )''', const []);
    await db.runCustom(
      "INSERT INTO pending_writes (endpoint, payload) VALUES ('/api/sessions', '{}')",
      const [],
    );
    await db.runCustom('PRAGMA user_version = 1', const []);
    await db.close();
  }

  test('a subida para v2 cria a tabela nova e preserva a fila', () async {
    await seedV1();

    final db = LocalDatabase.forTesting(NativeDatabase(file));
    addTearDown(db.close);

    // O que a migração acrescenta.
    await db.markAchievementsSeen(const ['quatro-semanas']);
    expect(await db.seenAchievementIds(), {'quatro-semanas'});

    // O que ela não pode ter tocado: a série registrada na academia, sem rede.
    expect(await db.countPending(), 1);
    final pending = await db.pending();
    expect(pending.single.endpoint, '/api/sessions');
  });

  test('marcar duas vezes não duplica nem reescreve a primeira vez', () async {
    final db = LocalDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);

    await db.markAchievementsSeen(const ['primeiro-treino']);
    await db.markAchievementsSeen(const ['primeiro-treino', 'semana-cheia']);

    expect(await db.seenAchievementIds(), {'primeiro-treino', 'semana-cheia'});
  });

  test('marcar nada não toca no banco', () async {
    final db = LocalDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);

    await db.markAchievementsSeen(const []);

    expect(await db.seenAchievementIds(), isEmpty);
  });
}

/// O `ensureOpen` do drift pede um `QueryExecutorUser` para decidir migração. Aqui a
/// abertura é crua — o objetivo é escrever o esquema da v1 à mão —, então ele não faz nada.
class _NoopUser extends QueryExecutorUser {
  @override
  int get schemaVersion => 1;

  @override
  Future<void> beforeOpen(
    QueryExecutor executor,
    OpeningDetails details,
  ) async {}
}
