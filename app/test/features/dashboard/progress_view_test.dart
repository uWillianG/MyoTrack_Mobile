import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:myotrack/core/db/local_database.dart';
import 'package:myotrack/core/providers.dart';
import 'package:myotrack/core/theme.dart';
import 'package:myotrack/features/dashboard/dashboard_controller.dart';
import 'package:myotrack/features/dashboard/dashboard_stats.dart';
import 'package:myotrack/features/dashboard/progress_page.dart';
import 'package:myotrack/features/progress/progress_controller.dart';

import '../home/home_test_harness.dart';

/// O Progresso troca de manchete conforme o objetivo do perfil, e absorveu as conquistas.
///
/// O que estes testes fixam: a regra da manchete (que é pura e cabe numa tabela), o recorte de
/// período, e que a tela continua cabendo num celular pequeno com nome de exercício comprido —
/// que é o caso que estourava a linha de recordes.
void main() {
  const smallPhone = Size(360, 800);

  /// Fechado no fim de cada caso: o drift deixa um timer de duração zero vivo, e o
  /// `flutter_test` reprova o caso com "A Timer is still pending".
  late LocalDatabase db;

  setUp(() => db = LocalDatabase.forTesting(NativeDatabase.memory()));
  tearDown(() => db.close());

  DashboardStats statsWith({
    int weeks = 8,
    int measurements = 6,
    int records = 8,
  }) => DashboardStats.from(
    now: DateTime(2026, 7, 29),
    volume: [
      for (var i = 0; i < weeks; i++)
        WeeklyVolume(
          weekStart: DateTime(2026, 7, 27).subtract(Duration(days: 7 * i)),
          volumeKg: 4000 + i * 850,
          sessions: 2 + (i % 3),
        ),
    ],
    weight: [
      for (var i = 0; i < measurements; i++)
        WeightPoint(date: DateTime(2026, 7, i + 1), weightKg: 84.6 - i * 0.4),
    ],
    records: [
      for (var i = 0; i < records; i++)
        ExerciseRecord(
          // Nome longo de propósito: é o caso que estoura a linha de recordes.
          name: 'Desenvolvimento militar com halteres sentado $i',
          maxLoadKg: 40 + i * 5,
          maxLoadReps: 8,
          maxLoadDate: DateTime(2026, 7, 20),
        ),
    ],
  );

  Future<void> pump(
    WidgetTester tester, {
    DashboardStats? stats,
    String goal = 'Hypertrophy',
    Brightness brightness = Brightness.light,
  }) async {
    tester.view.physicalSize = smallPhone;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          ...homeOverrides(profile: userProfile.copyWith(goal: goal)),
          dashboardStatsProvider.overrideWith(
            (ref) async => stats ?? statsWith(),
          ),
          // A seção de conquistas lê o banco local para saber o que já foi comemorado.
          localDatabaseProvider.overrideWithValue(db),
        ],
        child: MaterialApp.router(
          theme: brightness == Brightness.light
              ? AppTheme.light()
              : AppTheme.dark(),
          routerConfig: GoRouter(
            routes: [
              GoRoute(
                path: '/',
                builder: (_, _) => const Scaffold(body: ProgressView()),
              ),
            ],
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  /// Rola até achar. A `ListView` não constrói o que não vai desenhar, e a tela é longa —
  /// procurar sem rolar encontraria "zero widgets" mesmo com o bloco montado corretamente.
  Future<void> scrollTo(WidgetTester tester, Finder finder) =>
      tester.scrollUntilVisible(
        finder,
        240,
        scrollable: find.byType(Scrollable).first,
      );

  group('pickProgressFocus', () {
    // A função é pura justamente para esta tabela existir: cada objetivo abre a tela num
    // assunto, e conferir isso à mão exigiria quatro perfis diferentes.
    test('emagrecimento abre no peso', () {
      expect(pickProgressFocus('WeightLoss'), ProgressFocus.weight);
    });

    test('condicionamento abre na constância', () {
      expect(pickProgressFocus('Conditioning'), ProgressFocus.consistency);
    });

    test('hipertrofia e estética abrem no volume', () {
      expect(pickProgressFocus('Hypertrophy'), ProgressFocus.volume);
      expect(pickProgressFocus('Aesthetics'), ProgressFocus.volume);
    });

    test('sem perfil, o volume — é o que o app calcula sozinho', () {
      // O peso depende de a pessoa subir na balança; o volume sai do que ela já registrou.
      expect(pickProgressFocus(null), ProgressFocus.volume);
    });
  });

  for (final brightness in Brightness.values) {
    testWidgets('a tela cabe num celular pequeno (${brightness.name})', (
      tester,
    ) async {
      // O modo escuro não é espelho do claro, e é nele que o contraste dos rótulos cai.
      await pump(tester, brightness: brightness);

      expect(tester.takeException(), isNull);
      expect(find.text('Volume da semana'), findsOne);
    });
  }

  testWidgets('quem quer emagrecer abre no peso, e o volume desce', (
    tester,
  ) async {
    await pump(tester, goal: 'WeightLoss');

    expect(find.text('Peso corporal'), findsOne);
    // O que não é manchete vira seção, sem sumir.
    await scrollTo(tester, find.text('Volume por semana'));
    expect(find.text('Volume por semana'), findsOne);
  });

  testWidgets('quem quer condicionamento abre na constância', (tester) async {
    await pump(tester, goal: 'Conditioning');

    expect(find.text('Constância'), findsOne);
    await scrollTo(tester, find.text('Volume por semana'));
    expect(find.text('Volume por semana'), findsOne);
  });

  testWidgets('o assunto promovido a manchete não se repete abaixo', (
    tester,
  ) async {
    await pump(tester, goal: 'Hypertrophy');

    expect(find.text('Volume da semana'), findsOne);
    expect(find.text('Volume por semana'), findsNothing);
  });

  testWidgets('o período recorta os gráficos', (tester) async {
    await pump(tester);

    await tester.tap(find.text('1 mês'));
    await tester.pumpAndSettle();

    // O rótulo de cada bloco conta o recorte real, para o segmentado não prometer o que não
    // existe: o volume satura no que o app guarda por semana.
    await scrollTo(tester, find.text('Constância'));
    expect(find.textContaining('4 semanas'), findsWidgets);
  });

  testWidgets('os recordes mostram três, e o resto fica a um toque', (
    tester,
  ) async {
    // Dez linhas de inventário no meio de uma tela de gráficos é o bloco que a pessoa aprende
    // a rolar por cima.
    await pump(tester);

    await scrollTo(tester, find.text('Ver mais 5 exercícios'));
    expect(find.textContaining('Desenvolvimento militar'), findsNWidgets(3));
    expect(find.text('Ver mais 5 exercícios'), findsOne);

    await tester.ensureVisible(find.text('Ver mais 5 exercícios'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Ver mais 5 exercícios'), warnIfMissed: false);
    await tester.pumpAndSettle();

    expect(find.text('Seus recordes'), findsOne);
  });

  testWidgets('sem histórico, a tela vira o próximo passo', (tester) async {
    // Gráfico vazio pareceria defeito.
    await pump(tester, stats: DashboardStats.empty);

    expect(find.text('Ainda não há\no que comparar.'), findsOne);
    expect(find.text('Treinar'), findsOne);
  });

  testWidgets('com uma pesagem só, a linha do peso não é desenhada', (
    tester,
  ) async {
    await pump(tester, stats: statsWith(measurements: 1));

    await scrollTo(tester, find.text('Duas pesagens e a linha aparece.'));
    expect(find.text('Duas pesagens e a linha aparece.'), findsOne);
  });
}
