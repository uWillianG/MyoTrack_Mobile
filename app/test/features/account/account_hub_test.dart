import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:myotrack/core/network/api_exception.dart';
import 'package:myotrack/core/router.dart';
import 'package:myotrack/core/theme.dart';
import 'package:myotrack/features/account/account_hub_page.dart';
import 'package:myotrack/features/account/url_opener.dart';
import 'package:myotrack/features/billing/billing_controller.dart';
import 'package:myotrack/features/billing/data/billing_models.dart';
import 'package:myotrack/features/home/today_controller.dart';
import 'package:myotrack/features/privacy/privacy_controller.dart';
import 'package:myotrack/features/reviews/review_controller.dart';

import '../home/home_test_harness.dart';

/// A aba Conta.
///
/// **O que estes testes seguram é o que a aba promete e o que as lojas conferem**: que a pessoa
/// veja de que conta se trata, que o plano em vigor apareça sem ninguém procurar, e que o
/// caminho para sair e para excluir a conta continue de pé mesmo quando o servidor não responde
/// — porque é justamente aí que alguém decide ir embora.
///
/// A regra do link morto também mora aqui: nenhuma linha desta tela pode levar a um endereço
/// que ainda não existe.
void main() {
  const smallPhone = Size(360, 800);

  Future<ProviderContainer> pump(
    WidgetTester tester, {
    List<Override> extraOverrides = const [],
    TargetPlatform platform = TargetPlatform.android,
  }) async {
    tester.view.physicalSize = smallPhone;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final container = ProviderContainer(
      overrides: [
        ...homeOverrides(),
        nowProvider.overrideWithValue(() => DateTime(2026, 8, 4, 15)),
        ...extraOverrides,
      ],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp.router(
          // A plataforma entra pelo tema: é de lá que a aba a lê, justamente para o teste
          // poder trocá-la sem mexer numa variável de debug global.
          theme: AppTheme.dark().copyWith(platform: platform),
          // Roteador de verdade: cada linha da lista chama `context.push`, e o botão de sair
          // termina num `context.go`. Sem rotas de chegada o teste não distingue "levou" de
          // "não fez nada".
          routerConfig: GoRouter(
            routes: [
              GoRoute(path: '/', builder: (_, _) => const _Host()),
              for (final route in [
                Routes.profile,
                Routes.billing,
                Routes.account,
                Routes.workoutPlan,
                Routes.coach,
                Routes.review,
                Routes.login,
              ])
                GoRoute(
                  path: route,
                  builder: (_, _) => Scaffold(body: Center(child: Text(route))),
                ),
            ],
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    return container;
  }

  /// Rola até o alvo aparecer. A lista é mais alta que a tela de um celular pequeno, e o
  /// `ListView` não constrói o que está fora dela.
  ///
  /// O `ensureVisible` no fim não é redundante: o `ListView` constrói um pouco além da
  /// viewport, então o `scrollUntilVisible` para assim que o alvo **existe** — que ainda pode
  /// ser fora da tela, e aí o toque erra o alvo sem falhar.
  Future<void> scrollTo(WidgetTester tester, Finder target) async {
    await tester.scrollUntilVisible(
      target,
      200,
      scrollable: find.byType(Scrollable),
    );
    await tester.ensureVisible(target);
    await tester.pumpAndSettle();
  }

  testWidgets('o cabeçalho diz de que conta se trata', (tester) async {
    // Um aparelho pode ter sido de outra pessoa, e é a partir desta tela que se apaga tudo.
    await pump(tester);

    expect(find.text('rafael.souza@myotrack.dev'), findsOne);
    expect(find.text('RS'), findsOne);
    expect(find.text('No MyoTrack desde 12 de março de 2026'), findsOne);
  });

  testWidgets('sem resumo do servidor, o e-mail do JWT segura o cabeçalho', (
    tester,
  ) async {
    // O token já carrega o e-mail e chega sem rede. É o que faz a aba dizer de quem é a conta
    // com a API fora do ar — que é quando alguém mais precisa ter certeza antes de mexer.
    await pump(
      tester,
      extraOverrides: [
        accountSummaryProvider.overrideWith(
          (ref) => Future<AccountSummary>.error(ApiException('Caiu.')),
        ),
      ],
    );

    expect(find.text('rafael.souza@myotrack.dev'), findsOne);
    expect(find.text('RS'), findsOne);
  });

  testWidgets('no plano gratuito, a aba mostra os limites e convida ao Pro', (
    tester,
  ) async {
    // É o motivo de a Conta ter virado aba: o plano em vigor tem de aparecer sem ninguém
    // procurar. O preço não está aqui de propósito — quem sabe o preço é a loja.
    await pump(tester);

    expect(find.text('Plano gratuito'), findsOne);
    expect(find.textContaining('conhecer o Pro'), findsOne);
    expect(find.text('3 por dia'), findsOne);
    expect(find.text('1 por dia'), findsOne);
    expect(find.text('5 por dia'), findsOne);
    expect(find.textContaining('Assinar por'), findsNothing);
  });

  testWidgets('tocar no bloco do plano abre a assinatura', (tester) async {
    await pump(tester);

    await tester.tap(find.text('Plano gratuito'));
    await tester.pumpAndSettle();

    expect(find.text(Routes.billing), findsOne);
  });

  testWidgets('no Pro, a aba diz quando renova', (tester) async {
    await pump(
      tester,
      extraOverrides: [
        subscriptionStatusProvider.overrideWith((ref) async => assinaturaPro),
      ],
    );

    expect(find.text('MyoTrack Pro'), findsOne);
    expect(find.text('Renova em 28 de agosto'), findsOne);
  });

  testWidgets('o Pro por constância diz que é prêmio, e até quando', (
    tester,
  ) async {
    // Ele dizia "Assinatura ativa", como qualquer outro Pro — e não há assinatura nenhuma. O
    // lugar onde se vai conferir o que se paga era justamente o que não avisava do prazo.
    await pump(
      tester,
      extraOverrides: [
        subscriptionStatusProvider.overrideWith(
          (ref) async => assinaturaPorConstancia,
        ),
      ],
    );

    expect(find.text('MyoTrack Pro'), findsOne);
    expect(find.text('Prêmio por constância até 7 de setembro'), findsOne);
    expect(find.textContaining('Renova em'), findsNothing);
  });

  testWidgets('a renovação de outro ano vem com o ano escrito', (tester) async {
    // Uma assinatura anual vence no ano que vem, e a data sem o ano seria a mais confusa
    // possível numa linha sobre dinheiro.
    await pump(
      tester,
      extraOverrides: [
        subscriptionStatusProvider.overrideWith(
          (ref) async =>
              assinaturaPro.copyWith(currentPeriodEnd: '2027-03-14T00:00:00'),
        ),
      ],
    );

    expect(find.text('Renova em 14 de março de 2027'), findsOne);
  });

  testWidgets('cobrança falhada aparece sem esconder o resto', (tester) async {
    await pump(
      tester,
      extraOverrides: [
        subscriptionStatusProvider.overrideWith(
          (ref) async => assinaturaPro.copyWith(paymentPastDue: true),
        ),
      ],
    );

    expect(find.textContaining('A última cobrança falhou'), findsOne);
    expect(find.text('MyoTrack Pro'), findsOne);
  });

  testWidgets('assinatura que não carrega não leva a aba junto', (
    tester,
  ) async {
    // É a regra que a tela de conta e privacidade já segue: um servidor com soluço não pode
    // tirar do titular o caminho para apagar os próprios dados.
    await pump(
      tester,
      extraOverrides: [
        subscriptionStatusProvider.overrideWith(
          (ref) => Future<SubscriptionStatus>.error(ApiException('Caiu.')),
        ),
      ],
    );

    expect(tester.takeException(), isNull);
    expect(find.text('Plano gratuito'), findsNothing);
    await scrollTo(tester, find.text('Conta e privacidade'));
    expect(find.text('Conta e privacidade'), findsOne);
  });

  testWidgets('os destinos aparecem agrupados', (tester) async {
    // Se algum sumir, o usuário perde o único caminho até ele — inclusive a exclusão de
    // conta, que as lojas exigem que seja fácil de achar.
    await pump(tester);

    for (final title in [
      'Conta',
      'Meu perfil',
      'Conta e privacidade',
      'Seus planos',
      'Meu treino',
      'Coach',
    ]) {
      await scrollTo(tester, find.text(title));
      expect(find.text(title), findsWidgets, reason: title);
    }
  });

  testWidgets('com o cartão do plano na tela, a linha de assinatura sai', (
    tester,
  ) async {
    // O cartão já é a assinatura e leva à mesma tela. Repetida logo abaixo dele, a linha
    // sugeriria um segundo destino — é a razão de o Progresso ter saído desta lista ao virar
    // aba.
    await pump(tester);

    expect(find.text('Plano gratuito'), findsOne);
    expect(
      find.text('Seu plano e os limites diários de análise'),
      findsNothing,
    );
  });

  testWidgets('sem o cartão do plano, a linha de assinatura volta', (
    tester,
  ) async {
    // Esta tela é o único caminho até a assinatura: sem o cartão e sem a linha, ela ficaria
    // inalcançável pela navegação.
    await pump(
      tester,
      extraOverrides: [
        subscriptionStatusProvider.overrideWith(
          (ref) => Future<SubscriptionStatus>.error(ApiException('Caiu.')),
        ),
      ],
    );

    await scrollTo(
      tester,
      find.text('Seu plano e os limites diários de análise'),
    );
    expect(find.text('Assinatura'), findsWidgets);
  });

  testWidgets('tocar num destino leva à tela dele', (tester) async {
    await pump(tester);

    await tester.tap(find.text('Meu perfil'));
    await tester.pumpAndSettle();

    expect(find.text(Routes.profile), findsOne);
  });

  testWidgets('sem papel de revisor, Revisão não aparece', (tester) async {
    // Levaria o aluno a uma tela que o servidor recusa com 403.
    await pump(tester);

    expect(find.text('Revisão'), findsNothing);
  });

  testWidgets('com papel de revisor, Revisão ganha grupo próprio', (
    tester,
  ) async {
    await pump(
      tester,
      extraOverrides: [
        reviewableKindsProvider.overrideWith(
          (ref) async => [ReviewKind.workout],
        ),
      ],
    );

    await scrollTo(
      tester,
      find.text('Fila de planos aguardando sua aprovação'),
    );
    expect(find.text('Revisão'), findsWidgets);
  });

  testWidgets('o e-mail de suporte sai com a versão e a conta no corpo', (
    tester,
  ) async {
    // É o que a primeira resposta do suporte pediria de volta, e ninguém sabe de cabeça em
    // que build está.
    final opener = RecordingUrlOpener();
    await pump(
      tester,
      extraOverrides: [urlOpenerProvider.overrideWithValue(opener)],
    );

    await scrollTo(tester, find.text('Falar com o suporte'));
    await tester.tap(find.text('Falar com o suporte'));
    await tester.pumpAndSettle();

    final sent = opener.opened.single;
    expect(sent.scheme, 'mailto');
    expect(sent.path, 'suporte@myotrack.app');
    expect(sent.queryParameters['body'], contains('1.0.0 (1)'));
    expect(sent.queryParameters['body'], contains('rafael.souza@myotrack.dev'));
  });

  testWidgets('termos e privacidade abrem os endereços do domínio do app', (
    tester,
  ) async {
    // As duas lojas exigem os dois links, e apontá-los para outro domínio é o tipo de
    // divergência que só aparece na revisão.
    final opener = RecordingUrlOpener();
    await pump(
      tester,
      extraOverrides: [urlOpenerProvider.overrideWithValue(opener)],
    );

    for (final label in ['Termos de uso', 'Política de privacidade']) {
      await scrollTo(tester, find.text(label));
      await tester.tap(find.text(label));
      await tester.pumpAndSettle();
    }

    expect(opener.opened.map((u) => u.toString()), [
      'https://myotrack.app/termos',
      'https://myotrack.app/privacidade',
    ]);
  });

  testWidgets('link que não abre avisa em vez de não fazer nada', (
    tester,
  ) async {
    // Aparelho sem cliente de e-mail não estoura nada; ele simplesmente não abre.
    final opener = RecordingUrlOpener()..succeeds = false;
    await pump(
      tester,
      extraOverrides: [urlOpenerProvider.overrideWithValue(opener)],
    );

    await scrollTo(tester, find.text('Termos de uso'));
    await tester.tap(find.text('Termos de uso'));
    await tester.pumpAndSettle();

    expect(find.text('Não foi possível abrir "Termos de uso".'), findsOne);
  });

  testWidgets('no Android, avaliar aponta para a ficha da Play Store', (
    tester,
  ) async {
    final opener = RecordingUrlOpener();
    await pump(
      tester,
      extraOverrides: [urlOpenerProvider.overrideWithValue(opener)],
    );

    await scrollTo(tester, find.text('Avaliar o app'));
    await tester.tap(find.text('Avaliar o app'));
    await tester.pumpAndSettle();

    // O nome do pacote vem do próprio app, e não de uma constante que divergiria do
    // `applicationId` no dia em que ele mudasse.
    expect(
      opener.opened.single.toString(),
      'market://details?id=com.myotrack.app',
    );
  });

  testWidgets('no iOS sem ficha na App Store, avaliar não aparece', (
    tester,
  ) async {
    // `Env.appStoreId` está vazia enquanto o app não for publicado, e a Apple só emite esse
    // número na criação da ficha. Link para uma página que não existe é pior que linha
    // nenhuma.
    await pump(tester, platform: TargetPlatform.iOS);

    await scrollTo(tester, find.text('Política de privacidade'));
    expect(find.text('Avaliar o app'), findsNothing);
  });

  testWidgets('sair pergunta antes', (tester) async {
    await pump(tester);

    await scrollTo(
      tester,
      find.widgetWithText(OutlinedButton, 'Sair da conta'),
    );
    await tester.tap(find.widgetWithText(OutlinedButton, 'Sair da conta'));
    await tester.pumpAndSettle();

    expect(find.text('Sair da conta?'), findsOne);
    expect(find.textContaining('entrar de novo neste aparelho'), findsOne);
  });

  testWidgets('o rodapé escreve a versão e o build', (tester) async {
    // É a linha que se pede a quem relata um problema: em desenvolvimento a versão fica
    // parada por semanas enquanto o build anda todo dia.
    await pump(tester);

    await scrollTo(tester, find.text('MyoTrack 1.0.0 (1)'));
    expect(find.text('MyoTrack 1.0.0 (1)'), findsOne);
  });
}

/// A aba montada como no app: sem `Scaffold` próprio, porque quem desenha a barra de título é
/// a `HomePage`.
class _Host extends StatelessWidget {
  const _Host();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: SafeArea(child: AccountHubView()));
  }
}
