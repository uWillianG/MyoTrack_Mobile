import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:myotrack/core/db/local_database.dart';
import 'package:myotrack/core/providers.dart';
import 'package:myotrack/core/theme.dart';
import 'package:myotrack/features/dashboard/progress_page.dart';
import 'package:myotrack/features/achievements/data/rewards_repository.dart';
import 'package:myotrack/features/dashboard/dashboard_controller.dart';
import 'package:myotrack/features/dashboard/dashboard_stats.dart';
import 'package:myotrack/features/diary/diary_controller.dart';
import 'package:myotrack/features/home/home_page.dart';

import '../home/home_test_harness.dart';

/// As conquistas viraram parte do Progresso, e a responsabilidade que nenhuma outra tela tem
/// veio junto: decidir o que é "novo". Errar isso estraga as duas pontas — comemorar de novo o
/// que já foi comemorado, ou engolir em silêncio a conquista que a pessoa acabou de ganhar.
///
/// A fusão criou um risco novo: abrir o Progresso marca tudo como visto. Por isso a comemoração
/// mora **acima da dobra**, e é isso que estes testes fixam junto com o resto.
void main() {
  const smallPhone = Size(360, 800);

  late LocalDatabase db;

  setUp(() {
    // Banco em memória: o teste precisa do drift de verdade porque o que está sob teste é
    // justamente a gravação do "já vi".
    db = LocalDatabase.forTesting(NativeDatabase.memory());
  });

  tearDown(() => db.close());

  Future<void> pump(
    WidgetTester tester, {
    List<Override> extra = const [],
    Widget home = const Scaffold(body: ProgressView()),
  }) async {
    tester.view.physicalSize = smallPhone;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          ...homeOverrides(),
          localDatabaseProvider.overrideWithValue(db),
          ...extra,
        ],
        child: MaterialApp.router(
          theme: AppTheme.light(),
          routerConfig: GoRouter(
            routes: [
              GoRoute(path: '/', builder: (_, _) => home),
              // A página de verdade, com barra de título: é o que dá o botão de voltar que o
              // caminho "abrir e voltar" exercita.
              GoRoute(
                path: '/progresso',
                builder: (_, _) => const ProgressPage(),
              ),
            ],
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('mostra o que foi conquistado e o que está a caminho', (
    tester,
  ) async {
    // O harness dá oito semanas com três treinos cada, meta de quatro no perfil e sem
    // recorde nenhum: sequência longa, semana incompleta.
    await pump(tester);

    await tester.scrollUntilVisible(
      find.text('A caminho'),
      240,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('A caminho'), findsOne);

    // A caminho, com o progresso à vista — é o que faz disto uma recompensa por evolução.
    expect(find.text('3 de 4 treinos'), findsOne);

    // As duas listas moram no mesmo bloco: rolar até "A caminho" já traz "Conquistadas"
    // junto, e a asserção de preguiça que existia aqui deixou de descrever a tela.
    await tester.scrollUntilVisible(
      find.text('Conquistadas'),
      240,
      scrollable: find.byType(Scrollable).first,
    );
    // Mais um empurrão: o cabeçalho entra na tela um quadro antes dos itens abaixo dele, e a
    // `ListView` não constrói o que ainda não vai desenhar.
    await tester.drag(find.byType(ListView).first, const Offset(0, -240));
    await tester.pumpAndSettle();

    // Oito semanas seguidas passam de quatro — e a sequência veio do servidor.
    expect(find.text('Um mês sem falhar'), findsWidgets);
  });

  testWidgets('a marca ainda não alcançada anuncia o Pro que rende', (
    tester,
  ) async {
    // Doze semanas rendem um mês de Pro, e o selo tem de dizer isso enquanto a marca pode ser
    // ganha — é o que transforma a barra de progresso em motivo para treinar.
    await pump(tester);

    await tester.scrollUntilVisible(
      find.text('1 MÊS DE PRO'),
      240,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('1 MÊS DE PRO'), findsOne);
  });

  testWidgets('marca já concedida não promete o prêmio de novo', (
    tester,
  ) async {
    // A concessão é uma por marca, para sempre. Continuar anunciando seria prometer o que
    // não vem.
    await pump(
      tester,
      extra: [
        rewardStatusProvider.overrideWith(
          (ref) async => rewardStatus(
            streakWeeks: 12,
            granted: const {'quatro-semanas', 'doze-semanas'},
          ),
        ),
      ],
    );

    expect(find.text('1 MÊS DE PRO'), findsNothing);
    expect(find.text('7 DIAS DE PRO'), findsNothing);
  });

  testWidgets('o Pro ativo aparece com o prazo', (tester) async {
    // Sem o prazo, a volta ao plano gratuito pareceria defeito: a pessoa perderia as
    // análises de vídeo de um dia para o outro sem entender por quê.
    await pump(
      tester,
      extra: [
        rewardStatusProvider.overrideWith(
          (ref) async => rewardStatus(
            streakWeeks: 12,
            granted: const {'quatro-semanas', 'doze-semanas'},
            activeGrant: ActiveGrant(
              milestone: 'doze-semanas',
              expiresAt: DateTime.now().add(const Duration(days: 21, hours: 2)),
            ),
          ),
        ),
      ],
    );

    expect(find.text('Pro ativo pela sua constância'), findsOne);
    expect(find.textContaining('Faltam 21 dias'), findsOne);
  });

  testWidgets('a primeira visita comemora; a segunda, não', (tester) async {
    await pump(tester);

    // Primeira abertura: o banco está vazio, então tudo que já está ganho é novidade.
    expect(find.textContaining('Você desbloqueou'), findsOne);
    expect(find.text('NOVO'), findsWidgets);

    // A tela grava o "já vi" num post-frame; reabrir não pode comemorar de novo.
    await tester.pumpAndSettle();
    expect(await db.seenAchievementIds(), isNotEmpty);

    await pump(tester);
    expect(find.textContaining('Você desbloqueou'), findsNothing);
    expect(find.text('NOVO'), findsNothing);
  });

  testWidgets('o selo NOVO não some enquanto a tela está aberta', (
    tester,
  ) async {
    // Regressão: marcar como visto reemite o provider, e sem congelar o conjunto do
    // primeiro quadro os selos sumiriam na frente de quem veio justamente vê-los.
    await pump(tester);

    expect(find.text('NOVO'), findsWidgets);
    await tester.pump(const Duration(seconds: 1));
    await tester.pumpAndSettle();
    expect(find.text('NOVO'), findsWidgets);
  });

  testWidgets('o ladrilho da Hoje leva às conquistas e some depois', (
    tester,
  ) async {
    // O caminho inteiro, como o usuário faz: o mosaico avisa, ele abre, e o aviso não volta.
    // O destino é o Progresso, que absorveu as conquistas — e é lá que a comemoração mora,
    // acima da dobra, para que marcar como visto seja honesto.
    await pump(tester, home: const HomePage());

    final tile = find.text('Conquista');
    await tester.scrollUntilVisible(tile, 200);
    expect(tile, findsOne);

    // Mais um empurrão: o `scrollUntilVisible` para assim que o ladrilho entra na tela, e
    // nessa posição ele pode ficar embaixo do botão flutuante de registrar — que intercepta
    // o toque. É a mesma sobreposição que o usuário resolve rolando mais um pouco.
    await tester.drag(find.byType(ListView).first, const Offset(0, -160));
    await tester.pumpAndSettle();

    await tester.tap(tile);
    await tester.pumpAndSettle();
    expect(find.textContaining('Você desbloqueou'), findsOne);

    // Voltar ao hub: o aviso cumpriu o papel e não pode continuar ocupando a tela.
    await tester.pageBack();
    await tester.pumpAndSettle();

    expect(find.text('Conquista'), findsNothing);
  });

  testWidgets('sem histórico a tela não promete nada', (tester) async {
    await pump(
      tester,
      extra: [
        dashboardStatsProvider.overrideWith(
          (ref) async => DashboardStats.empty,
        ),
        diaryDayOfProvider.overrideWith((ref, date) async => diaryDay(kcal: 0)),
        // Sem histórico não há sequência: o servidor devolveria zero, e o fixture precisa
        // dizer o mesmo que os outros dois.
        rewardStatusProvider.overrideWith(
          (ref) async => rewardStatus(streakWeeks: 0),
        ),
      ],
    );

    expect(find.textContaining('Ainda não há'), findsOne);
    expect(find.text('Conquistadas'), findsNothing);
    expect(find.textContaining('Você desbloqueou'), findsNothing);
  });
}
