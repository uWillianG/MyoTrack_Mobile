import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:myotrack/core/jobs/generation_controller.dart';
import 'package:myotrack/core/jobs/job_status.dart';
import 'package:myotrack/core/theme.dart';
import 'package:myotrack/features/home/today_controller.dart';
import 'package:myotrack/features/meals/data/meal_models.dart';
import 'package:myotrack/features/meals/data/meal_repository.dart';
import 'package:myotrack/features/meals/manual_meal_controller.dart';
import 'package:myotrack/features/meals/manual_meal_page.dart';
import 'package:myotrack/features/meals/meal_analysis_controller.dart';

import '../home/home_test_harness.dart';

/// Registrar uma refeição **sem foto**, pelos três caminhos.
///
/// O que estes testes protegem é a decisão que sustenta a tela: **os três caminhos desembocam
/// numa lista só**. Digitar, deixar a IA estimar e escolher no catálogo produzem o mesmo item,
/// entram no mesmo rascunho e saem num único `POST`. Se algum deles ganhasse a própria lista, a
/// pergunta "o que acontece com o que eu digitei antes?" ficaria sem resposta — e o sintoma
/// seria o pior possível: uma refeição salva pela metade, sem erro nenhum no caminho.
///
/// O segundo grupo é sobre **quem manda no número**. Item do catálogo tem os macros
/// recalculados no servidor a partir da tabela; deixar a tela digitá-los faria o vínculo virar
/// enfeite e "150 g de arroz" poder valer zero caloria.
class _MockMealRepository extends Mock implements MealRepository {}

void main() {
  const smallPhone = Size(360, 900);

  final hoje = DateTime(2026, 8, 27, 15, 40);

  const arroz = FoodItem(
    id: 1,
    name: 'Arroz branco cozido',
    kcalPer100g: 128,
    proteinPer100g: 2.5,
    carbsPer100g: 28.1,
    fatPer100g: 0.2,
    source: 'TACO',
  );

  setUpAll(() {
    registerFallbackValue(const MealManualRequest(items: []));
  });

  late _MockMealRepository repository;

  setUp(() {
    repository = _MockMealRepository();
    when(
      () => repository.foods(
        query: any(named: 'query'),
        limit: any(named: 'limit'),
      ),
    ).thenAnswer((_) async => const [arroz]);
    when(
      () => repository.createManual(any()),
    ).thenAnswer((_) async => const MealAnalysis(id: 'nova', source: 'Manual'));
  });

  Future<ProviderContainer> pump(
    WidgetTester tester, {
    DateTime? day,
    List<Override> extra = const [],
  }) async {
    tester.view.physicalSize = smallPhone;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final container = ProviderContainer(
      overrides: [
        ...homeOverrides(),
        nowProvider.overrideWithValue(() => hoje),
        mealRepositoryProvider.overrideWithValue(repository),
        ...extra,
      ],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          theme: AppTheme.dark(),
          home: ManualMealPage(day: day ?? hoje),
        ),
      ),
    );
    await tester.pumpAndSettle();
    return container;
  }

  /// Preenche a folha de item digitado e confirma.
  Future<void> digitarItem(
    WidgetTester tester, {
    String descricao = 'Ovo frito',
    String gramas = '100',
    String kcal = '240',
    String proteina = '15.6',
    String carbo = '1.2',
    String gordura = '18.6',
  }) async {
    await tester.tap(find.text('Digitar'));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.widgetWithText(TextFormField, 'O que é'),
      descricao,
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Quantidade'),
      gramas,
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Proteína'),
      proteina,
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Carboidrato'),
      carbo,
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Gordura'),
      gordura,
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Calorias'),
      kcal,
    );

    await tester.tap(find.text('Adicionar à refeição'));
    await tester.pumpAndSettle();
  }

  group('a tela vazia', () {
    testWidgets('não oferece salvar o que não existe', (tester) async {
      await pump(tester);

      // Sem itens não há número, e nem toda manchete precisa de um: o assunto é o trabalho, e
      // parado o trabalho é um convite.
      expect(find.text('Salvar refeição'), findsNothing);
      expect(find.textContaining('Sem foto desta vez'), findsOne);
      expect(find.text('Nenhum item ainda.'), findsOne);
    });

    testWidgets('o caminho principal fica aberto, e não atrás de uma porta', (
      tester,
    ) async {
      await pump(tester);

      // A IA por texto é o caminho que o produto quer que as pessoas usem; guardá-la ao lado
      // das outras duas a teria demovido a uma opção entre três.
      expect(find.text('Descreva a refeição'), findsOne);
      expect(find.text('Estimar com IA'), findsOne);
      // As outras duas entram no pé da lista, que é onde "mais um item" se procura.
      expect(find.text('Catálogo'), findsOne);
      expect(find.text('Digitar'), findsOne);
    });

    testWidgets('o título diz em que dia a refeição vai cair', (tester) async {
      // A tela grava no dia que o diário estava mostrando, e não necessariamente hoje. Sem
      // dizê-lo, quem abriu o diário em ontem procuraria a refeição no dia errado.
      await pump(tester, day: hoje.subtract(const Duration(days: 1)));

      expect(find.text('Refeição de ontem'), findsOne);
    });
  });

  group('os três caminhos', () {
    testWidgets('digitar à mão soma no herói', (tester) async {
      await pump(tester);
      await digitarItem(tester);

      expect(find.text('240'), findsOne);
      expect(find.text('Salvar refeição'), findsOne);
      expect(find.text('1 de 20'), findsOne);
    });

    testWidgets('a estimativa da IA cai na mesma lista', (tester) async {
      final estimativa = _FakeEstimate();
      await pump(
        tester,
        extra: [manualMealEstimateProvider.overrideWith(() => estimativa)],
      );

      await tester.enterText(
        find.byType(TextField).first,
        '2 ovos fritos e um pão francês',
      );
      await tester.tap(find.text('Estimar com IA'));
      await tester.pumpAndSettle();

      expect(estimativa.pedido, '2 ovos fritos e um pão francês');
      expect(find.text('Ovo frito'), findsOne);
      expect(find.text('Pão francês'), findsOne);
      expect(find.text('2 de 20'), findsOne);
    });

    testWidgets('o catálogo entra na mesma lista, e acrescenta', (
      tester,
    ) async {
      // **Acrescenta, e não substitui.** É o que permite descrever metade da refeição para a
      // IA e depois somar o cafezinho pelo catálogo — e é a prova de que a lista é uma só.
      await pump(tester);
      await digitarItem(tester);

      await tester.tap(find.text('Catálogo'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Arroz branco cozido'));
      await tester.pumpAndSettle();

      await tester.enterText(
        find.widgetWithText(TextFormField, 'Quantidade'),
        '150',
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Adicionar à refeição'));
      await tester.pumpAndSettle();

      expect(find.text('2 de 20'), findsOne);
      // 240 do ovo + 192 do arroz (128 kcal/100 g × 150 g).
      expect(find.text('432'), findsOne);
    });

    testWidgets('a busca abre com o catálogo já à vista', (tester) async {
      // O `q` em branco devolve o começo da lista justamente para isto: uma folha que abre
      // vazia esperando a primeira tecla parece um catálogo vazio.
      await pump(tester);

      await tester.tap(find.text('Catálogo'));
      await tester.pumpAndSettle();

      expect(find.text('Arroz branco cozido'), findsOne);
      verify(
        () => repository.foods(
          query: '',
          limit: any(named: 'limit'),
        ),
      ).called(1);
    });
  });

  group('quem manda no número', () {
    testWidgets('item do catálogo mostra os macros da tabela, não campos', (
      tester,
    ) async {
      await pump(tester);

      await tester.tap(find.text('Catálogo'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Arroz branco cozido'));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Quantidade'),
        '150',
      );
      await tester.pumpAndSettle();

      // Campos editáveis que o servidor vai sobrescrever seriam mentira de interface: ele
      // recalcula o item com vínculo e descarta o que fosse digitado.
      expect(find.widgetWithText(TextFormField, 'Calorias'), findsNothing);
      expect(find.text('192 kcal'), findsOne);
      expect(find.textContaining('Calculado pela tabela'), findsOne);
    });

    testWidgets('o cliente não manda total nenhum ao salvar', (tester) async {
      final container = await pump(tester);
      await digitarItem(tester);
      await tester.tap(find.text('Salvar refeição'));
      await tester.pumpAndSettle();

      final request =
          verify(() => repository.createManual(captureAny())).captured.single
              as MealManualRequest;

      // É o total que o diário soma; mandá-lo pronto permitiria gravar um dia de calorias que
      // não corresponde a nada do que estava na tela.
      expect(request.toJson().containsKey('totalKcal'), isFalse);
      expect(request.items.single.description, 'Ovo frito');
      expect(request.items.single.kcal, 240);
      // Hoje não manda hora: o relógio que ordena o dia é o do servidor.
      expect(request.createdAt, isNull);
      // E o rascunho não sobrevive ao salvamento — reabrir a tela começaria com a refeição
      // que já foi gravada.
      expect(container.read(manualMealDraftProvider), isEmpty);
    });

    testWidgets('num dia passado, a data é do diário e a hora é a de agora', (
      tester,
    ) async {
      // A hora não é a de quem comeu — ninguém sabe qual foi. O que a lista do diário precisa
      // é de ordem: duas refeições lançadas com minutos de diferença têm de sair nessa ordem,
      // e uma hora fixa faria almoço e jantar de ontem empilharem no mesmo instante.
      await pump(tester, day: DateTime(2026, 8, 25));
      await digitarItem(tester);
      await tester.tap(find.text('Salvar refeição'));
      await tester.pumpAndSettle();

      final request =
          verify(() => repository.createManual(captureAny())).captured.single
              as MealManualRequest;

      expect(
        request.createdAt,
        DateTime(2026, 8, 25, 15, 40).toIso8601String(),
      );
    });
  });

  group('o que a tela recusa antes de mandar', () {
    testWidgets('item sem descrição: o servidor o descartaria em silêncio', (
      tester,
    ) async {
      await pump(tester);
      await tester.tap(find.text('Digitar'));
      await tester.pumpAndSettle();

      await tester.enterText(
        find.widgetWithText(TextFormField, 'Quantidade'),
        '100',
      );
      await tester.tap(find.text('Adicionar à refeição'));
      await tester.pumpAndSettle();

      expect(find.text('Diga o que é este item.'), findsOne);
    });

    testWidgets('porção acima do teto do servidor', (tester) async {
      // O servidor prende a porção a 2 kg em silêncio. Recusar antes evita a pessoa digitar
      // 3000 g e receber 2000 de volta sem entender por quê.
      await pump(tester);
      await tester.tap(find.text('Digitar'));
      await tester.pumpAndSettle();

      await tester.enterText(
        find.widgetWithText(TextFormField, 'O que é'),
        'Arroz',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Quantidade'),
        '3000',
      );
      await tester.tap(find.text('Adicionar à refeição'));
      await tester.pumpAndSettle();

      expect(find.textContaining('No máximo'), findsOne);
    });

    testWidgets('caloria em branco é deixada para o servidor calcular', (
      tester,
    ) async {
      // A reconciliação por Atwater é do servidor, e repeti-la aqui criaria duas versões dela
      // livres para divergir. A tela só avisa que dá para deixar em branco.
      await pump(tester);
      await digitarItem(tester, kcal: '');

      await tester.tap(find.text('Salvar refeição'));
      await tester.pumpAndSettle();

      final request =
          verify(() => repository.createManual(captureAny())).captured.single
              as MealManualRequest;

      // Zero é o que o servidor lê como "derive dos macros" — 15,6 P + 1,2 C + 18,6 G.
      expect(request.items.single.kcal, 0);
      expect(request.items.single.proteinG, 15.6);
    });
  });

  group('o rascunho', () {
    testWidgets('um item pode ser removido da lista', (tester) async {
      await pump(tester);
      await digitarItem(tester);

      await tester.tap(find.byTooltip('Remover Ovo frito'));
      await tester.pumpAndSettle();

      expect(find.text('Nenhum item ainda.'), findsOne);
      expect(find.text('Salvar refeição'), findsNothing);
    });

    testWidgets('tocar num item o reabre para corrigir', (tester) async {
      await pump(tester);
      await digitarItem(tester);

      await tester.tap(find.text('Ovo frito'));
      await tester.pumpAndSettle();

      expect(find.text('Corrigir item'), findsOne);
    });
  });

  group('a estimativa que não deu certo', () {
    test('resposta ilegível vira erro em vez de sucesso vazio', () {
      // Engolir em silêncio faria o job terminar "com sucesso" sem nenhum item ter aparecido
      // na lista, e não há tela que explique isso.
      final container = ProviderContainer(
        overrides: [mealRepositoryProvider.overrideWithValue(repository)],
      );
      addTearDown(container.dispose);

      final controller = container.read(manualMealEstimateProvider.notifier);

      expect(
        () => controller.onResult(
          const JobStatus(
            id: 'j',
            type: 'MealPhoto',
            state: JobState.completed,
            resultJson: 'isto não é json',
          ),
        ),
        throwsA(anything),
      );
    });

    test('o resultJson do job é o produto, e vai para o rascunho', () {
      // É a exceção que o gancho `onResult` existe para servir: esta estimativa não persiste
      // nada, então o `resultJson` é tudo o que existe dela.
      final container = ProviderContainer(
        overrides: [mealRepositoryProvider.overrideWithValue(repository)],
      );
      addTearDown(container.dispose);

      container
          .read(manualMealEstimateProvider.notifier)
          .onResult(
            const JobStatus(
              id: 'j',
              type: 'MealPhoto',
              state: JobState.completed,
              resultJson:
                  '{"items":[{"description":"Ovo frito","quantityG":100,'
                  '"kcal":240,"proteinG":15.6,"carbsG":1.2,"fatG":18.6}],'
                  '"totalKcal":240}',
            ),
          );

      final draft = container.read(manualMealDraftProvider);
      expect(draft.single.description, 'Ovo frito');
      expect(draft.single.kcal, 240);
    });
  });
}

/// A estimativa por IA sem rede nem fila: guarda a frase e devolve os itens que o teste espera.
///
/// Sobrescreve o [ManualMealEstimate.estimate] inteiro porque o que a tela precisa provar é o
/// que ela faz com o resultado — o caminho do job em si é do [JobGenerationController], que já
/// tem testes, e a leitura do `resultJson` é testada à parte, sem widget nenhum.
class _FakeEstimate extends ManualMealEstimate {
  String? pedido;

  @override
  GenerationState build() => GenerationState.idle;

  @override
  Future<void> estimate(String text) async {
    pedido = text;
    ref.read(manualMealDraftProvider.notifier).addAll(const [
      MealAnalysisItem(
        description: 'Ovo frito',
        quantityG: 100,
        kcal: 240,
        proteinG: 15.6,
        carbsG: 1.2,
        fatG: 18.6,
      ),
      MealAnalysisItem(
        description: 'Pão francês',
        quantityG: 50,
        kcal: 150,
        proteinG: 4,
        carbsG: 29.3,
        fatG: 1.6,
      ),
    ]);
  }
}
