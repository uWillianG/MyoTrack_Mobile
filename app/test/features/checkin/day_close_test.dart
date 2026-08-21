import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:myotrack/core/sync/sync_queue.dart';
import 'package:myotrack/core/theme.dart';
import 'package:myotrack/features/checkin/day_close_page.dart';
import 'package:myotrack/features/logging/data/logging_models.dart';
import 'package:myotrack/features/logging/data/logging_repository.dart';
import 'package:myotrack/features/logging/logging_controller.dart';

import '../home/home_test_harness.dart';

class _MockLoggingRepository extends Mock implements LoggingRepository {}

/// O fechamento do dia faz uma coisa que sai do aparelho — a pesagem — e três que só
/// ajustam a tela. Estes testes fixam justamente essa divisão: a sequência das perguntas, o
/// POST da medida, e o que o resumo pode ou não afirmar.
void main() {
  const smallPhone = Size(360, 800);

  setUpAll(() {
    registerFallbackValue(const MeasurementRequest(date: '2026-07-30'));
  });

  late _MockLoggingRepository repository;

  setUp(() {
    repository = _MockLoggingRepository();
    when(
      () => repository.logMeasurement(any()),
    ).thenAnswer((_) async => WriteOutcome.sent);
  });

  Future<void> pump(
    WidgetTester tester, {
    Brightness brightness = Brightness.light,
  }) async {
    tester.view.physicalSize = smallPhone;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          ...homeOverrides(),
          loggingRepositoryProvider.overrideWithValue(repository),
        ],
        child: MaterialApp(
          theme: brightness == Brightness.light
              ? AppTheme.light()
              : AppTheme.dark(),
          home: const DayClosePage(),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  /// Responde as três perguntas na ordem em que a tela as faz.
  Future<void> answerAll(WidgetTester tester) async {
    await tester.tap(find.text('Puxado'));
    await tester.pumpAndSettle();
    // O peso da última pesagem vem do harness: 82,45 kg, exibido como "82,5 kg".
    await tester.tap(find.text('Igual à última pesagem'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Baixa'));
    await tester.pumpAndSettle();
  }

  testWidgets('as três perguntas vêm em ordem e terminam no resumo', (
    tester,
  ) async {
    await pump(tester);

    expect(find.text('Como foi o dia?'), findsOne);
    await tester.tap(find.text('Puxado'));
    await tester.pumpAndSettle();

    expect(find.text('Seu peso de hoje'), findsOne);
    await tester.tap(find.text('Não pesei hoje'));
    await tester.pumpAndSettle();

    expect(find.text('Como está sua energia?'), findsOne);
    await tester.tap(find.text('Média'));
    await tester.pumpAndSettle();

    expect(find.text('Dia fechado'), findsOne);
  });

  testWidgets('a pesagem vai para /api/measurements', (tester) async {
    // É a única resposta do fechamento com destino no servidor. Se ela deixar de subir, o
    // check-in vira um formulário que não guarda nada.
    await pump(tester);
    await answerAll(tester);

    final captured =
        verify(() => repository.logMeasurement(captureAny())).captured.single
            as MeasurementRequest;
    expect(captured.weightKg, closeTo(82.45, 0.001));
  });

  testWidgets('"não pesei hoje" não registra medida nenhuma', (tester) async {
    // Gravar a pesagem de ontem com a data de hoje inventaria um ponto na curva de peso.
    await pump(tester);

    await tester.tap(find.text('Puxado'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Não pesei hoje'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Baixa'));
    await tester.pumpAndSettle();

    verifyNever(() => repository.logMeasurement(any()));
    expect(find.text('Dia fechado'), findsOne);
  });

  testWidgets('o peso digitado no diálogo não derruba a tela', (tester) async {
    // Regressão: o `TextEditingController` era descartado logo depois do `await
    // showDialog(...)`, e o diálogo ainda estava saindo de cena. O `TextField`
    // reconstruía contra um controller morto, a exceção abortava a reconstrução no meio, e
    // o que o usuário via era a tela vermelha de `'_dependents.isEmpty': is not true` —
    // que não menciona campo de texto nenhum.
    await pump(tester);

    await tester.tap(find.text('Puxado'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Outro valor'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), '83,1');
    await tester.tap(find.widgetWithText(FilledButton, 'Salvar'));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('Como está sua energia?'), findsOne);

    final captured =
        verify(() => repository.logMeasurement(captureAny())).captured.single
            as MeasurementRequest;
    expect(captured.weightKg, closeTo(83.1, 0.001));
  });

  testWidgets('peso inválido explica em vez de fechar o diálogo', (
    tester,
  ) async {
    // O "Salvar" devolvia direto o resultado de `parseWeightKg`, então um valor recusado
    // fechava o diálogo com null — exatamente o que "Cancelar" faz. Quem digitasse "8o" em
    // vez de "80" via a tela avançar sem ter registrado nada e sem nenhuma pista do motivo.
    await pump(tester);

    await tester.tap(find.text('Puxado'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Outro valor'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), '8o');
    await tester.tap(find.widgetWithText(FilledButton, 'Salvar'));
    await tester.pumpAndSettle();

    expect(find.text('Digite um peso entre 1 e 500 kg. Ex.: 82,4'), findsOne);
    // O diálogo continua aberto — é isso que o "Cancelar" acidental fazia diferente.
    expect(find.byType(AlertDialog), findsOne);
    verifyNever(() => repository.logMeasurement(any()));

    // Corrigido, o erro sai de cena e o valor sobe.
    await tester.enterText(find.byType(TextField), '80');
    await tester.pumpAndSettle();
    expect(
      find.text('Digite um peso entre 1 e 500 kg. Ex.: 82,4'),
      findsNothing,
    );

    await tester.tap(find.widgetWithText(FilledButton, 'Salvar'));
    await tester.pumpAndSettle();

    expect(find.text('Como está sua energia?'), findsOne);
    final captured =
        verify(() => repository.logMeasurement(captureAny())).captured.single
            as MeasurementRequest;
    expect(captured.weightKg, closeTo(80, 0.001));
  });

  testWidgets('600 kg é recusado no aparelho, sem ida ao servidor', (
    tester,
  ) async {
    // A mesma faixa que o servidor valida. Barrar aqui evita a ida e volta só para receber
    // "Peso fora da faixa válida" de volta — e, com a fila de escrita no caminho, evita que
    // o registro fique pendente para ser recusado depois, longe da tela.
    await pump(tester);

    await tester.tap(find.text('Puxado'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Outro valor'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), '600');
    await tester.tap(find.widgetWithText(FilledButton, 'Salvar'));
    await tester.pumpAndSettle();

    expect(find.text('Digite um peso entre 1 e 500 kg. Ex.: 82,4'), findsOne);
    verifyNever(() => repository.logMeasurement(any()));
  });

  testWidgets('a pesagem termina mesmo depois de a pergunta sair da tela', (
    tester,
  ) async {
    // A tela avança sem esperar o POST, então a escrita volta quando o passo do peso já
    // não existe. Com o `WidgetRef` daquele passo, o `invalidate` do dashboard lançava e o
    // aviso de "guardado no aparelho" nunca aparecia — quem se pesou sem rede não ficava
    // sabendo que o número tinha ficado na fila.
    when(() => repository.logMeasurement(any())).thenAnswer((_) async {
      await Future<void>.delayed(const Duration(seconds: 2));
      return WriteOutcome.queued;
    });

    await pump(tester);

    await tester.tap(find.text('Puxado'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Igual à última pesagem'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 3));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(
      find.text('Peso guardado no aparelho. Sobe quando houver rede.'),
      findsOne,
    );
  });

  for (final brightness in Brightness.values) {
    testWidgets('o resumo cabe na tela e não promete ajuste (${brightness.name})', (
      tester,
    ) async {
      await pump(tester, brightness: brightness);
      await answerAll(tester);

      expect(tester.takeException(), isNull);
      // Consumo do dia contra a meta: 1.476 de 2.100 kcal, 110 g de 172 g de proteína. A
      // unidade fica de fora da diferença — está no número logo acima, no mesmo tijolo.
      expect(find.text('−624 vs meta'), findsOne);
      expect(find.text('−62 vs meta'), findsOne);
      // O que o plano já diz sobre amanhã — e não um ajuste que o servidor não fez.
      expect(find.text('Amanhã'), findsOne);
      expect(find.textContaining('Treino B · Peito e tríceps'), findsOne);
      expect(find.text('Você marcou: dia puxado · energia baixa.'), findsOne);
    });
  }
}
