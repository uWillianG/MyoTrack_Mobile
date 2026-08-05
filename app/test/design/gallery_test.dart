@Tags(['gallery'])
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';
import 'package:drift/native.dart';
import 'package:mocktail/mocktail.dart';
import 'package:myotrack/core/db/local_database.dart';
import 'package:myotrack/core/providers.dart';
import 'package:myotrack/core/sync/sync_queue.dart';
import 'package:myotrack/core/theme.dart';
import 'package:myotrack/features/dashboard/progress_page.dart';
import 'package:myotrack/features/workout/workout_plan_page.dart';
import 'package:myotrack/features/workout/workout_plan_controller.dart';
import 'package:myotrack/features/dashboard/dashboard_stats.dart';
import 'package:myotrack/features/checkin/day_close_page.dart';
import 'package:myotrack/features/home/home_page.dart';
import 'package:myotrack/features/home/today_controller.dart';
import 'package:myotrack/features/nutrition/nutrition_page.dart';
import 'package:myotrack/features/logging/data/logging_models.dart';
import 'package:myotrack/features/logging/data/logging_repository.dart';
import 'package:myotrack/features/logging/log_session_controller.dart';

import '../features/home/home_test_harness.dart';
import 'gallery_fonts.dart';

class _MockLoggingRepository extends Mock implements LoggingRepository {}

/// Galeria visual: renderiza as telas principais em PNG para inspeção.
///
/// Não é teste de regressão — é a bancada onde o design é avaliado. Roda com
/// `flutter test --update-goldens --tags gallery` e escreve em `test/design/goldens/`.
/// A suíte normal a ignora (`dart_test.yaml`), porque comparar pixel a pixel a cada commit
/// transformaria qualquer ajuste de espaçamento numa falha de CI.
void main() {
  const phone = Size(390, 844);

  setUpAll(() async {
    registerFallbackValue(const MeasurementRequest(date: '2026-07-30'));
    await loadGalleryFonts();
    // O mesmo que o `main` faz. Sem isto as bolinhas da semana saem "M T W T F S S", que
    // não é o que o usuário vê — e a captura serviria para avaliar um app que não existe.
    await initializeDateFormatting('pt_BR');
    Intl.defaultLocale = 'pt_BR';
  });

  late _MockLoggingRepository repository;

  setUp(() {
    repository = _MockLoggingRepository();
    when(
      () => repository.logMeasurement(any()),
    ).thenAnswer((_) async => WriteOutcome.sent);
  });

  Future<ProviderContainer> pump(
    WidgetTester tester,
    Brightness brightness,
    Widget home, {
    List<Override> extra = const [],
  }) async {
    tester.view.physicalSize = phone * 3;
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    final container = ProviderContainer(
      overrides: [
        ...homeOverrides(),
        loggingRepositoryProvider.overrideWithValue(repository),
        seenAchievements(),
        ...extra,
      ],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp.router(
          // Como no `main`: a faixa de debug cobriria justamente o avatar da barra superior.
          debugShowCheckedModeBanner: false,
          locale: const Locale('pt', 'BR'),
          // Sem família fixada: o tema já traz a Manrope, que é a fonte do app e vem
          // empacotada — a captura mostra o que o usuário vê, em qualquer máquina.
          theme: brightness == Brightness.light
              ? AppTheme.light()
              : AppTheme.dark(),
          routerConfig: GoRouter(
            routes: [GoRoute(path: '/', builder: (_, _) => home)],
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    return container;
  }

  Future<void> shoot(WidgetTester tester, String name) async {
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('goldens/$name.png'),
    );
  }

  for (final brightness in Brightness.values) {
    final mode = brightness.name;

    // As três caras da Hoje. A tela troca de herói conforme a hora, então avaliar só uma
    // delas é avaliar um terço do desenho — e as outras duas ninguém abriria a galeria para
    // ver por acaso.
    testWidgets('hoje — tarde ($mode)', (tester) async {
      await pump(
        tester,
        brightness,
        const HomePage(),
        extra: [nowProvider.overrideWithValue(() => DateTime(2026, 8, 4, 15))],
      );
      await shoot(tester, 'hoje-$mode');
    });

    testWidgets('hoje — manhã ($mode)', (tester) async {
      await pump(
        tester,
        brightness,
        const HomePage(),
        extra: [nowProvider.overrideWithValue(() => DateTime(2026, 8, 4, 7))],
      );
      await shoot(tester, 'hoje-manha-$mode');
    });

    testWidgets('hoje — noite ($mode)', (tester) async {
      await pump(
        tester,
        brightness,
        const HomePage(),
        extra: [nowProvider.overrideWithValue(() => DateTime(2026, 8, 4, 21))],
      );
      await shoot(tester, 'hoje-noite-$mode');
    });

    testWidgets('hoje — primeiro acesso ($mode)', (tester) async {
      // A tela de quem acabou de criar a conta. É o pior estado do produto e o primeiro que
      // alguém vê, então precisa ser avaliado como qualquer outro — sem perfil, sem plano e
      // sem dieta, todo cartão da Hoje se esconde e sobrava a tela em branco.
      await pump(
        tester,
        brightness,
        const HomePage(),
        extra: [
          nowProvider.overrideWithValue(() => DateTime(2026, 8, 4, 15)),
          ...homeOverrides(
            day: diaryDay(
              kcal: 0,
              protein: 0,
              carbs: 0,
              fat: 0,
              withTargets: false,
              meals: const [],
            ),
            stats: DashboardStats.from(
              now: DateTime(2026, 7, 30),
              volume: const [],
              weight: const [],
              records: const [],
            ),
            hasNextWorkout: false,
            streak: const [false, false, false, false, false, false, false],
            profile: null,
          ),
        ],
      );
      await shoot(tester, 'hoje-primeiro-acesso-$mode');
    });

    // As duas metades da nutrição. São telas diferentes atrás do mesmo segmentado, e avaliar
    // só o diário deixaria o plano — que é a tela mais longa do app — sem nenhuma captura.
    testWidgets('nutrição — diário ($mode)', (tester) async {
      final container = await pump(
        tester,
        brightness,
        const HomePage(),
        // A semana de calorias vem explícita: no fixture ela é vazia por padrão, senão muda a
        // avaliação de conquistas em testes que não são sobre o diário.
        extra: [...homeOverrides(day: diaryDay(week: semanaDeCalorias))],
      );
      container.read(homeTabProvider.notifier).state = HomeTab.nutrition;
      await tester.pumpAndSettle();
      await shoot(tester, 'nutricao-$mode');
    });

    testWidgets('nutrição — plano ($mode)', (tester) async {
      final container = await pump(
        tester,
        brightness,
        const HomePage(),
        extra: [...homeOverrides(diet: dietPlanWithMeals)],
      );
      container.read(homeTabProvider.notifier).state = HomeTab.nutrition;
      container.read(nutritionTabProvider.notifier).state = NutritionTab.plan;
      await tester.pumpAndSettle();
      await shoot(tester, 'nutricao-plano-$mode');
    });

    testWidgets('analisar ($mode)', (tester) async {
      final container = await pump(tester, brightness, const HomePage());
      container.read(homeTabProvider.notifier).state = HomeTab.analysis;
      await tester.pumpAndSettle();
      await shoot(tester, 'analisar-$mode');
    });

    // A mesma aba com histórico. A captura vazia é a que julga o convite; esta é a que julga a
    // lista — e o relógio vai fixo porque o rótulo de cada refeição decide entre "Hoje" e a
    // data por ele.
    testWidgets('analisar — refeições ($mode)', (tester) async {
      final container = await pump(
        tester,
        brightness,
        const HomePage(),
        extra: [
          ...homeOverrides(analyzedMeals: refeicoesAnalisadas),
          nowProvider.overrideWithValue(() => DateTime(2026, 8, 4, 15)),
        ],
      );
      container.read(homeTabProvider.notifier).state = HomeTab.analysis;
      await tester.pumpAndSettle();
      await shoot(tester, 'analisar-refeicoes-$mode');
    });

    // As duas caras do perfil. O cadastro é o que só quem chega vê, e a razão de a galeria
    // capturá-lo é a mesma do primeiro acesso da Hoje.
    testWidgets('perfil ($mode)', (tester) async {
      final container = await pump(tester, brightness, const HomePage());
      container.read(homeTabProvider.notifier).state = HomeTab.profile;
      await tester.pumpAndSettle();
      await shoot(tester, 'perfil-$mode');
    });

    testWidgets('perfil — cadastro ($mode)', (tester) async {
      final container = await pump(
        tester,
        brightness,
        const HomePage(),
        extra: [...homeOverrides(profile: null)],
      );
      container.read(homeTabProvider.notifier).state = HomeTab.profile;
      await tester.pumpAndSettle();
      await shoot(tester, 'perfil-cadastro-$mode');
    });

    // O Progresso absorveu as conquistas, e a manchete dele muda com o objetivo do perfil —
    // duas capturas, porque avaliar só uma seria avaliar metade do desenho.
    testWidgets('progresso ($mode)', (tester) async {
      await pump(tester, brightness, const ProgressPage());
      await shoot(tester, 'progresso-$mode');
    });

    testWidgets('progresso — emagrecimento ($mode)', (tester) async {
      await pump(
        tester,
        brightness,
        const ProgressPage(),
        extra: [
          localDatabaseProvider.overrideWithValue(
            LocalDatabase.forTesting(NativeDatabase.memory()),
          ),
          ...homeOverrides(profile: userProfile.copyWith(goal: 'WeightLoss')),
        ],
      );
      await shoot(tester, 'progresso-peso-$mode');
    });

    // As três telas de treino nunca tiveram captura. A do plano é a mais consultada; as
    // outras duas dependem de estado que a galeria não monta sozinha.
    testWidgets('treino — plano ($mode)', (tester) async {
      await pump(
        tester,
        brightness,
        const WorkoutPlanPage(),
        extra: [
          activeWorkoutPlanProvider.overrideWith((ref) async => workoutPlan),
        ],
      );
      await shoot(tester, 'treino-plano-$mode');
    });

    testWidgets('fechar o dia — pergunta ($mode)', (tester) async {
      await pump(tester, brightness, const DayClosePage());
      await shoot(tester, 'fechar-pergunta-$mode');
    });

    testWidgets('fechar o dia — resumo ($mode)', (tester) async {
      await pump(tester, brightness, const DayClosePage());
      await tester.tap(find.text('Puxado'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Igual à última pesagem'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Baixa'));
      await tester.pumpAndSettle();
      await shoot(tester, 'fechar-resumo-$mode');
    });
  }
}
