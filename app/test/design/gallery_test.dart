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
import 'package:myotrack/features/achievements/achievements_page.dart';
import 'package:myotrack/features/checkin/day_close_page.dart';
import 'package:myotrack/features/home/home_page.dart';
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
          // A família é fixada aqui e só aqui: no app ela é nula, para cada plataforma usar
          // a própria fonte. Sem fixar, o `flutter test` desenha os estilos que não passam
          // pelo `TextTheme` (título da AppBar, rótulo de botão) com a fonte de teste.
          theme: brightness == Brightness.light
              ? AppTheme.light(fontFamily: 'Roboto')
              : AppTheme.dark(fontFamily: 'Roboto'),
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

    testWidgets('hoje ($mode)', (tester) async {
      await pump(tester, brightness, const HomePage());
      await shoot(tester, 'hoje-$mode');
    });

    testWidgets('nutrição ($mode)', (tester) async {
      final container = await pump(tester, brightness, const HomePage());
      container.read(homeTabProvider.notifier).state = HomeTab.nutrition;
      await tester.pumpAndSettle();
      await shoot(tester, 'nutricao-$mode');
    });

    testWidgets('analisar ($mode)', (tester) async {
      final container = await pump(tester, brightness, const HomePage());
      container.read(homeTabProvider.notifier).state = HomeTab.analysis;
      await tester.pumpAndSettle();
      await shoot(tester, 'analisar-$mode');
    });

    testWidgets('perfil ($mode)', (tester) async {
      final container = await pump(tester, brightness, const HomePage());
      container.read(homeTabProvider.notifier).state = HomeTab.profile;
      await tester.pumpAndSettle();
      await shoot(tester, 'perfil-$mode');
    });

    testWidgets('conquistas ($mode)', (tester) async {
      await pump(
        tester,
        brightness,
        const AchievementsPage(),
        extra: [
          localDatabaseProvider.overrideWithValue(
            LocalDatabase.forTesting(NativeDatabase.memory()),
          ),
        ],
      );
      await shoot(tester, 'conquistas-$mode');
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
