import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:myotrack/core/theme.dart';
import 'package:myotrack/features/diary/diary_controller.dart';
import 'package:myotrack/features/home/today_controller.dart';
import 'package:myotrack/features/home/today_page.dart';
import 'package:myotrack/features/profile/onboarding_controller.dart';
import 'package:myotrack/features/reviews/review_controller.dart';

import 'home_test_harness.dart';

/// A Hoje é um mosaico com um bloco promovido a herói, e quem promove é a hora. O que estes
/// testes fixam é a regra da promoção e as duas invariantes que a sustentam: o assunto que
/// virou herói **sai** do mosaico, e chamada que falhou nunca vira "não existe".
void main() {
  const smallPhone = Size(360, 800);

  // Uma terça-feira, para os testes que não são sobre a hora. 15h cai na faixa do dia.
  final tarde = DateTime(2026, 8, 4, 15);

  Future<void> pump(
    WidgetTester tester,
    List<Override> overrides, {
    Brightness brightness = Brightness.light,
    DateTime? now,
  }) async {
    tester.view.physicalSize = smallPhone;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          nowProvider.overrideWithValue(() => now ?? tarde),
          ...overrides,
        ],
        child: MaterialApp.router(
          theme: brightness == Brightness.light
              ? AppTheme.light()
              : AppTheme.dark(),
          routerConfig: GoRouter(
            routes: [
              GoRoute(
                path: '/',
                builder: (_, _) => const Scaffold(body: TodayView()),
              ),
            ],
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  group('pickHero', () {
    // A função é pura justamente para esta tabela existir: as onze da noite e as seis da
    // manhã são estados que ninguém conferiria à mão.
    HeroKind pick(
      int hour, {
      bool workoutPending = true,
      bool hasWorkoutPlan = true,
      bool hasDiet = true,
    }) => pickHero(
      hour: hour,
      workoutPending: workoutPending,
      hasWorkoutPlan: hasWorkoutPlan,
      hasDiet: hasDiet,
    );

    test('de manhã, o treino que falta vem primeiro', () {
      expect(pick(6), HeroKind.workout);
      expect(pick(11), HeroKind.workout);
    });

    test('de manhã, com o treino feito, sobra a nutrição', () {
      expect(pick(8, workoutPending: false), HeroKind.nutrition);
    });

    test('durante o dia, as calorias ganham do treino', () {
      // É a pergunta que traz a pessoa ao app na fila do restaurante.
      expect(pick(12), HeroKind.nutrition);
      expect(pick(19), HeroKind.nutrition);
    });

    test('à noite, fechar o dia', () {
      expect(pick(20), HeroKind.closeDay);
      expect(pick(23), HeroKind.closeDay);
      expect(pick(3), HeroKind.closeDay);
    });

    test('sem dieta, o treino assume em qualquer hora do dia', () {
      expect(pick(15, hasDiet: false), HeroKind.workout);
    });

    test('sem plano nem dieta, a tela vira o caminho para montá-los', () {
      expect(
        pick(15, hasWorkoutPlan: false, hasDiet: false),
        HeroKind.onboarding,
      );
      // E a hora não muda isso: quem não tem plano não tem o que fechar à noite.
      expect(
        pick(22, hasWorkoutPlan: false, hasDiet: false),
        HeroKind.onboarding,
      );
    });

    test('faltando só a dieta, a tela continua servindo o treino', () {
      // O passo que falta vira um ladrilho; o app não para de funcionar por causa dele.
      expect(pick(15, hasDiet: false), HeroKind.workout);
    });
  });

  for (final brightness in Brightness.values) {
    testWidgets('à tarde o herói é a nutrição (${brightness.name})', (
      tester,
    ) async {
      await pump(tester, homeOverrides(), brightness: brightness);

      expect(tester.takeException(), isNull);
      // 2.100 de meta menos 1.476 consumidas: o número grande é o que ainda cabe, não o que
      // já foi comido.
      expect(find.text('624'), findsOne);
      expect(find.text('kcal restam'), findsOne);
      expect(find.text('1.476 de 2.100 kcal'), findsOne);
      expect(find.text('Fotografar refeição'), findsOne);

      // A proteína saiu de dentro do herói e virou ladrilho: como frase ali ela empurrava o
      // bloco para metade da tela sem ganhar o destaque que um número tem.
      expect(find.text('Proteína'), findsOne);
      expect(find.text('62 g'), findsOne);
      expect(find.textContaining('faltam de 172 g'), findsOne);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('o assunto promovido a herói sai do mosaico', (tester) async {
    // Repetir o bloco nos dois lugares é a duplicação que faz a tela parecer cheia sem dizer
    // nada a mais.
    await pump(tester, homeOverrides());

    // O herói é a nutrição: o rótulo aparece uma vez só, no bloco grande.
    expect(find.text('Nutrição'), findsOne);
    // E o treino, que não é o herói, está no mosaico.
    expect(find.text('Treino'), findsOne);
    expect(find.text('55 min'), findsOne);
  });

  testWidgets('de manhã o herói é o treino, e a nutrição vira ladrilho', (
    tester,
  ) async {
    await pump(tester, homeOverrides(), now: DateTime(2026, 8, 4, 7));

    expect(find.text('Treino de hoje'), findsOne);
    expect(find.text('Começar treino'), findsOne);
    // A nutrição desceu para o mosaico, com o mesmo número.
    expect(find.text('624'), findsOne);
    expect(find.text('kcal restam'), findsOne);
  });

  testWidgets('à noite o herói é fechar o dia, com o resumo do dia', (
    tester,
  ) async {
    await pump(tester, homeOverrides(), now: DateTime(2026, 8, 4, 21));

    expect(find.text('Como foi hoje?'), findsOne);
    expect(find.text('Responder'), findsOne);
    expect(find.textContaining('1.476 kcal'), findsOne);
  });

  testWidgets('o convite de fechar o dia não existe de manhã', (tester) async {
    // Às nove da manhã ele pede algo que ainda não aconteceu.
    await pump(tester, homeOverrides(), now: DateTime(2026, 8, 4, 9));

    expect(find.textContaining('Fechar o dia'), findsNothing);
  });

  testWidgets('sem plano nem dieta, a tela vira os primeiros passos', (
    tester,
  ) async {
    await pump(
      tester,
      homeOverrides(day: diaryDay(withTargets: false), hasNextWorkout: false),
    );

    expect(find.text('Vamos montar\nseu plano.'), findsOne);
    expect(find.text('Gere sua dieta'), findsOne);
    // Perfil existe no fixture, e passo cumprido perde a seta.
    expect(find.byIcon(Icons.check), findsOne);
  });

  testWidgets('faltando só a dieta, ela vira um ladrilho', (tester) async {
    await pump(tester, homeOverrides(day: diaryDay(withTargets: false)));

    expect(find.text('Vamos montar\nseu plano.'), findsNothing);
    // O herói passa a ser o treino, e a dieta que falta ocupa um ladrilho.
    expect(find.text('Treino de hoje'), findsOne);
    expect(find.text('Dieta'), findsOne);
  });

  testWidgets('chamada que falha não anuncia primeiros passos', (tester) async {
    // Sem rede as consultas voltam nulas, e a tela diria a quem treina no app há meses que o
    // perfil e o plano dele não existem. Erro é "não sei".
    await pump(tester, [
      ...homeOverrides(),
      diaryDayProvider.overrideWith((ref) async => throw Exception('sem rede')),
      userProfileProvider.overrideWith(
        (ref) async => throw Exception('sem rede'),
      ),
      nextWorkoutProvider.overrideWith(
        (ref) async => throw Exception('sem rede'),
      ),
    ]);

    expect(find.textContaining('Não foi possível carregar seu dia'), findsOne);
    expect(find.text('Complete seu perfil'), findsNothing);
  });

  testWidgets('o peso e a semana andam juntos, e levam ao progresso', (
    tester,
  ) async {
    await pump(tester, homeOverrides());

    expect(find.text('Semana'), findsOne);
    expect(find.text('3/4'), findsOne);
    expect(find.text('Peso'), findsOne);
    // Sinal explícito: quem emagrece e quem ganha massa querem sinais opostos.
    expect(find.textContaining('−0,3 kg'), findsOne);
  });

  testWidgets('a sequência de semanas aparece a partir de duas', (
    tester,
  ) async {
    // É o número que rende plano Pro por constância, e vivia só na tela de conquistas — o
    // mecanismo de recompensa do produto estava invisível para quem não fosse procurá-lo.
    await pump(tester, homeOverrides());

    expect(find.text('Sequência'), findsOne);
    expect(find.text('8'), findsOne);
    expect(find.text('semanas seguidas'), findsOne);
  });

  testWidgets('com uma semana só, a sequência não vira conquista', (
    tester,
  ) async {
    // "1 semana seguida" é o estado de qualquer pessoa que treinou uma vez, e anunciá-lo
    // esvazia o que a palavra significa.
    await pump(tester, homeOverrides(rewards: rewardStatus(streakWeeks: 1)));

    expect(find.text('Sequência'), findsNothing);
  });

  testWidgets('sem fila de revisão, o ladrilho do revisor não aparece', (
    tester,
  ) async {
    await pump(tester, homeOverrides());

    expect(find.text('Revisor'), findsNothing);
  });

  testWidgets('com fila, o revisor soma as duas e diz a espera', (
    tester,
  ) async {
    await pump(
      tester,
      homeOverrides(
        reviewCounts: const {ReviewKind.workout: 2, ReviewKind.diet: 2},
        oldestReview: DateTime(2026, 7, 23),
      ),
    );

    expect(find.text('Revisor'), findsOne);
    expect(find.text('4'), findsOne);
    // Quatro planos de hoje e quatro de duas semanas atrás são a mesma contagem e urgências
    // bem diferentes.
    expect(find.textContaining('há 12 dias'), findsOne);
  });
}
