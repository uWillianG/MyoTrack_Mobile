import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:myotrack/core/db/local_database.dart';
import 'package:myotrack/core/providers.dart';
import 'package:myotrack/core/theme.dart';
import 'package:myotrack/features/home/account_sheet.dart';
import 'package:myotrack/features/reviews/review_controller.dart';

/// A folha da conta é onde o app conta o que deu errado longe da tela.
///
/// O aviso de escrita recusada é a única coisa que separa "o servidor não aceitou seu treino"
/// de o registro simplesmente sumir. Estes testes fixam que ele aparece, que diz o suficiente
/// para a pessoa refazer o registro, e que só some quando ela dispensa.
///
/// Aqui o `discardedWritesProvider` **não** é substituído: ele lê o banco em memória de
/// verdade. Um valor fixo no lugar dele deixaria o teste do "dispensar" sempre verde — o
/// `invalidate` recarregaria o mesmo fixture e a tela pareceria certa mesmo que o `clear`
/// nunca tivesse tocado no banco.
void main() {
  setUpAll(() => initializeDateFormatting('pt_BR'));

  late LocalDatabase db;

  setUp(() => db = LocalDatabase.forTesting(NativeDatabase.memory()));
  tearDown(() => db.close());

  /// Arquiva uma escrita recusada, como a fila faria ao levar um 4xx.
  Future<void> recusar(String endpoint, String payload) async {
    await db.enqueue(endpoint, payload);
    await db.discardPending(
      (await db.pending()).single,
      'Peso fora da faixa válida.',
    );
  }

  Future<void> pump(WidgetTester tester) async {
    tester.view.physicalSize = const Size(360, 1200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          localDatabaseProvider.overrideWithValue(db),
          pendingWritesProvider.overrideWith((ref) => Stream.value(0)),
          reviewableKindsProvider.overrideWith((ref) async => const []),
        ],
        child: MaterialApp(
          theme: AppTheme.light(),
          home: const Scaffold(body: AccountSheet()),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('sem nada recusado, o aviso não existe', (tester) async {
    await pump(tester);

    // Um cartão vermelho permanente ensinaria a ignorar a cor justamente quando ela importa.
    expect(find.textContaining('recusado'), findsNothing);
    expect(find.text('Progresso'), findsOne);
  });

  testWidgets('o aviso diz o que se perdeu, não o endpoint', (tester) async {
    await recusar(
      '/api/measurements',
      '{"date":"2026-07-28","weightKg":82.4}',
    );
    await pump(tester);

    expect(
      find.text('Um registro foi recusado pelo servidor e não subiu.'),
      findsOne,
    );
    // O que a pessoa precisa para refazer o registro: qual foi e de que dia.
    expect(find.text('Pesagem de 82,4 kg (28/07)'), findsOne);
    expect(find.text('Peso fora da faixa válida.'), findsOne);
    expect(find.textContaining('Registre de novo'), findsOne);
  });

  testWidgets('duas recusas viram duas linhas, não um número', (tester) async {
    await recusar('/api/measurements', '{"date":"2026-07-28","weightKg":82.4}');
    await recusar('/api/sessions', '{"date":"2026-07-29","sets":[{"a":1}]}');
    await pump(tester);

    expect(
      find.text('2 registros foram recusados pelo servidor e não subiram.'),
      findsOne,
    );
    // "2 registros falharam" não permite refazer nenhum dos dois.
    expect(find.text('Pesagem de 82,4 kg (28/07)'), findsOne);
    expect(find.text('Treino com 1 série (29/07)'), findsOne);
  });

  testWidgets('dispensar apaga e o aviso não volta', (tester) async {
    await recusar('/api/sessions', '{"date":"2026-07-28","sets":[{"a":1}]}');
    await pump(tester);
    expect(find.text('Treino com 1 série (28/07)'), findsOne);

    await tester.tap(find.text('Entendi, dispensar'));
    await tester.pumpAndSettle();

    expect(find.textContaining('recusado'), findsNothing);
    // E some do banco: o payload existia só para poder ser mostrado esta vez.
    expect(await db.discarded(), isEmpty);
  });
}
