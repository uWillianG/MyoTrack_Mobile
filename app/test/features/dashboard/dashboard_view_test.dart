import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:myotrack/core/theme.dart';
import 'package:myotrack/features/dashboard/dashboard_stats.dart';
import 'package:myotrack/features/dashboard/dashboard_view.dart';
import 'package:myotrack/features/progress/progress_controller.dart';

/// O validador de paleta confere cor, não geometria. Estes testes renderizam o dashboard na
/// largura de um celular pequeno para que qualquer estouro de layout — rótulo colidindo,
/// número transbordando o cartão — falhe aqui em vez de aparecer no aparelho.
void main() {
  const smallPhone = Size(360, 800);

  DashboardStats statsWith({int weeks = 8, int measurements = 6}) {
    return DashboardStats.from(
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
        for (var i = 0; i < weeks; i++)
          ExerciseRecord(
            // Nome longo de propósito: é o caso que estoura a linha de recordes.
            name: 'Desenvolvimento militar com halteres sentado $i',
            maxLoadKg: 40 + i * 5,
            maxLoadReps: 8,
            maxLoadDate: DateTime(2026, 7, 20),
          ),
      ],
    );
  }

  Future<void> pump(
    WidgetTester tester,
    DashboardStats stats,
    Brightness b,
  ) async {
    tester.view.physicalSize = smallPhone;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MaterialApp(
        theme: b == Brightness.light ? AppTheme.light() : AppTheme.dark(),
        home: Scaffold(
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: DashboardView(stats: stats),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  for (final brightness in Brightness.values) {
    testWidgets('renderiza sem estouro de layout (${brightness.name})', (
      tester,
    ) async {
      // O modo escuro não é um espelho do claro: o Material gera outra escala a partir da
      // mesma semente, e é nele que o contraste dos rótulos pode cair.
      await pump(tester, statsWith(), brightness);

      expect(tester.takeException(), isNull);
      expect(find.text('Volume por semana'), findsOneWidget);
      expect(find.text('Peso corporal'), findsOneWidget);
      expect(find.text('Seus recordes'), findsOneWidget);
    });
  }

  testWidgets('sem histórico, o gráfico vira aviso em vez de eixo vazio', (
    tester,
  ) async {
    await pump(tester, DashboardStats.empty, Brightness.light);

    expect(tester.takeException(), isNull);
    expect(find.textContaining('Registre um treino'), findsOneWidget);
    // Peso e recordes somem inteiros: cartão vazio pareceria defeito.
    expect(find.text('Peso corporal'), findsNothing);
    expect(find.text('Seus recordes'), findsNothing);
  });

  testWidgets('com uma pesagem só, o gráfico de peso não aparece', (
    tester,
  ) async {
    // Uma linha ligando um ponto a nada não é gráfico.
    await pump(tester, statsWith(measurements: 1), Brightness.light);

    expect(tester.takeException(), isNull);
    expect(find.text('Peso corporal'), findsNothing);
  });
}
