import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/design/blocks.dart';
import '../../core/design/format.dart';
import '../../core/design/tokens.dart';
import '../../core/design/typography.dart';
import '../../core/widgets/blocks.dart';
import '../../core/widgets/empty_state.dart';
// O relógio do app, injetável: a data de renovação é escrita com o ano só quando ele não é o
// corrente, e essa decisão não pode depender de quando o teste roda.
import '../home/today_controller.dart' show nowProvider;
import 'billing_controller.dart';
import 'data/billing_models.dart';

/// Assinatura do plano Pro. Porte de `BillingPage.tsx`, com a compra pela loja no lugar do
/// checkout do Stripe.
///
/// **Neutra, e isso é uma decisão.** A tentação era o magenta das conquistas — é a família
/// festiva, e um paywall quer festa. Mas magenta significa "você conquistou", e aplicá-lo a uma
/// compra seria bajulação: o app estaria parabenizando alguém por pagar. Cobrança é
/// procedimento, e procedimento é neutro (§4). A contenção também cai bem numa tela de venda —
/// quem precisa enfeitar o preço é quem não confia no produto.
class BillingPage extends ConsumerWidget {
  const BillingPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final billing = ref.watch(billingControllerProvider);
    final statusAsync = ref.watch(subscriptionStatusProvider);
    final colors = Blocks.neutral(Theme.of(context).colorScheme);

    ref.listen(billingControllerProvider, (previous, next) {
      final text = next.error ?? next.message;
      if (text != null && text != (previous?.error ?? previous?.message)) {
        ScaffoldMessenger.of(context)
          ..clearSnackBars()
          ..showSnackBar(SnackBar(content: Text(text)));
        ref.read(billingControllerProvider.notifier).dismissMessages();
      }
    });

    return Scaffold(
      appBar: AppBar(title: const Text('Assinatura')),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(subscriptionStatusProvider);
          await ref.read(subscriptionStatusProvider.future);
        },
        child: statusAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => EmptyState(
            icon: Icons.cloud_off_outlined,
            title: 'Não foi possível carregar seu plano.',
            detail: '$error',
            action: FilledButton.tonal(
              onPressed: () => ref.invalidate(subscriptionStatusProvider),
              child: const Text('Tentar de novo'),
            ),
          ),
          data: (status) => _Body(
            status: status,
            billing: billing,
            colors: colors,
            now: ref.read(nowProvider)(),
          ),
        ),
      ),
    );
  }
}

class _Body extends ConsumerWidget {
  const _Body({
    required this.status,
    required this.billing,
    required this.colors,
    required this.now,
  });

  final SubscriptionStatus status;
  final BillingState billing;
  final BlockColors colors;
  final DateTime now;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListView(
      padding: EdgeInsets.fromLTRB(
        Space.gutter,
        4,
        Space.gutter,
        screenBottomInset(context),
      ),
      children: [
        _PlanHero(
          status: status,
          billing: billing,
          colors: colors,
          now: now,
          onBuy: () => ref.read(billingControllerProvider.notifier).buy(),
        ),
        const SizedBox(height: Space.sm),
        _Limits(status: status, colors: colors),

        // A loja não respondeu com o produto: sem isto o bloco ficaria sem ação e sem
        // explicação, que é a forma mais rápida de alguém achar que o app quebrou. Vale também
        // para quem está com o prêmio, que agora tem botão e portanto pode ficar sem ele.
        if (!status.isPaidPro &&
            !billing.loadingStore &&
            !billing.storeAvailable) ...[
          const SizedBox(height: Space.sm),
          BlockNotice(
            colors: colors,
            message:
                'A assinatura não está disponível neste aparelho no momento. '
                'Tente de novo mais tarde.',
          ),
        ],

        // Assinatura de loja não se cancela pelo app — a instrução certa evita o botão que
        // não funciona e o suporte que vem atrás dele. `isPaidPro` e não `isPro`: quem está com
        // o prêmio e tem uma assinatura antiga e inativa na tabela leria "sua assinatura é
        // gerenciada pela loja" sobre uma assinatura que não existe mais.
        if (status.isPaidPro && status.managedByStore) ...[
          const SizedBox(height: Space.sm),
          BlockNotice(
            colors: colors,
            message:
                'Sua assinatura é gerenciada pela loja. Para alterar ou cancelar, use os '
                'ajustes de assinaturas do seu aparelho.',
          ),
        ],

        const SizedBox(height: Space.xs),
        Align(
          alignment: Alignment.centerLeft,
          // As duas lojas exigem este botão em app com compra não consumível: quem trocou de
          // aparelho precisa reaver o que já pagou sem pagar de novo.
          //
          // Em cor de texto e não na cor de ação: na cor do tema ele era a única coisa
          // saturada de uma tela neutra, e a peça mais chamativa passava a ser a menos
          // importante — acima dela está a decisão de assinar.
          child: TextButton(
            onPressed: billing.purchasing
                ? null
                : () => ref.read(billingControllerProvider.notifier).restore(),
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            child: const Text('Restaurar compras'),
          ),
        ),
      ],
    );
  }
}

/// O plano, e a decisão que cabe a ele.
///
/// **O preço mora na ação.** Ele é a única coisa que o usuário precisa saber para decidir, e
/// separá-lo do botão — como "Assine o Pro" acima e "Assinar" abaixo — obriga a juntar as duas
/// metades na leitura. Vem da loja já com moeda e imposto da região: o app nunca o monta.
///
/// **Quem tem Pro por constância continua vendo o botão**, e é a correção de um defeito real:
/// esconder a compra de todo mundo que "é Pro" tirava a venda justamente de quem está usando o
/// Pro e vai perdê-lo numa data marcada. Ele acabava caindo no plano gratuito em silêncio, sem
/// nunca ter tido como pagar. O prêmio é uma amostra; a amostra existe para virar assinatura.
class _PlanHero extends StatelessWidget {
  const _PlanHero({
    required this.status,
    required this.billing,
    required this.colors,
    required this.now,
    required this.onBuy,
  });

  final SubscriptionStatus status;
  final BillingState billing;
  final BlockColors colors;
  final DateTime now;
  final VoidCallback onBuy;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // A data do prêmio no lugar da de renovação quando o Pro veio de constância: não há
    // cobrança por trás dele, e uma assinatura antiga e inativa na tabela faria "Renova em"
    // anunciar uma data que já passou.
    final renewal = _renewal(
      status.isGranted ? status.grantExpiresAt : status.currentPeriodEnd,
      now,
    );

    return HeroBlock(
      colors: colors,
      label: 'Assinatura',
      icon: status.isPro
          ? Icons.workspace_premium_outlined
          : Icons.person_outline,
      action: status.isPaidPro ? null : _buyAction(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            status.isPro ? 'MyoTrack Pro' : 'Plano gratuito',
            style: AppTypography.numeric(size: 34, color: colors.onGlass),
          ),
          if (renewal != null) ...[
            const SizedBox(height: Space.xs),
            Text(
              status.isGranted
                  ? 'Prêmio por constância, até $renewal'
                  : status.isPro
                  ? 'Renova em $renewal'
                  : 'Válido até $renewal',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colors.onGlass.withValues(alpha: 0.85),
              ),
            ),
          ],

          // Cobrança falhada é a coisa mais importante da tela, então vive no herói e não
          // numa faixa lá embaixo. Aviso e não bloqueio: o acesso ainda vale durante a
          // tolerância da loja, e cortar antes puniria quem só precisa trocar o cartão.
          if (status.paymentPastDue) ...[
            const SizedBox(height: Space.md),
            _PastDue(colors: colors),
          ],

          if (!status.isPaidPro) ...[
            const SizedBox(height: Space.md),
            // Curto porque a seção abaixo agora traz os números. Enquanto ela só dizia os
            // limites de hoje, esta frase era o único lugar que contava o que mudava; repetir
            // em palavras o que as linhas dizem em algarismos gastaria o herói, que existe
            // para carregar o preço.
            //
            // Para quem está com o prêmio, o assunto é outro: ele já tem os números, e o que
            // precisa saber é que eles têm prazo. Dizer isso agora é o oposto de apressar a
            // venda — é evitar a queda em silêncio que acontecia quando o prazo vencia.
            Text(
              status.isGranted
                  ? 'Quando o prêmio acabar, os limites voltam aos do plano '
                        'gratuito. Assinar mantém o Pro sem prazo.'
                  : 'O que muda no Pro são os três limites diários de IA — os '
                        'números estão logo abaixo.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colors.onGlass.withValues(alpha: 0.85),
              ),
            ),
            const SizedBox(height: Space.sm),
            // A letra miúda vem **antes** do botão, e não depois: quem já tocou não a lê.
            Text(
              'A cobrança é feita pela loja e renova sozinha. Cancele quando quiser, nos '
              'ajustes do aparelho.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: colors.onGlass.withValues(alpha: 0.75),
              ),
            ),
          ],
        ],
      ),
    );
  }

  HeroAction? _buyAction() {
    if (billing.loadingStore) {
      return const HeroAction(label: 'Consultando a loja…', onPressed: null);
    }
    // Sem produto não há preço, e um botão "Assinar" sem preço é o que faz alguém tocar sem
    // saber quanto vai pagar. Quem explica a ausência é a faixa abaixo do bloco.
    if (!billing.storeAvailable || billing.product == null) {
      return null;
    }
    return HeroAction(
      label: billing.purchasing
          ? 'Abrindo a loja…'
          : 'Assinar por ${billing.product!.price}',
      onPressed: billing.purchasing ? null : onBuy,
    );
  }

  /// "28 de agosto", com o ano só quando não é o corrente.
  ///
  /// Uma assinatura anual vence no ano que vem, e "28 de agosto" sem o ano ali seria a data
  /// mais confusa possível numa tela sobre dinheiro.
  static String? _renewal(String? iso, DateTime now) {
    final at = iso == null ? null : DateTime.tryParse(iso)?.toLocal();
    if (at == null) {
      return null;
    }
    return at.year == now.year
        ? Fmt.dayMonth(at)
        : '${Fmt.dayMonth(at)} de ${at.year}';
  }
}

/// O aviso de cobrança falhada, sobre a cor cheia do herói.
class _PastDue extends StatelessWidget {
  const _PastDue({required this.colors});

  final BlockColors colors;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.onGlass.withValues(alpha: 0.15),
        borderRadius: Radii.mdAll,
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: Space.sm + 2,
          vertical: Space.sm,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.warning_amber_outlined, size: 18, color: colors.onGlass),
            const SizedBox(width: Space.xs + 2),
            Expanded(
              child: Text(
                'A última cobrança falhou. Atualize a forma de pagamento na loja para não '
                'perder o acesso.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colors.onGlass,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// O que o plano libera por dia — e, para quem não é Pro, o que ele passaria a liberar.
///
/// **Os números vêm do servidor e não do app**: os limites são configuráveis por ambiente, e um
/// valor fixo aqui mentiria no dia em que forem ajustados. Isso valia contra a comparação
/// enquanto o servidor só devolvia os **seus** limites — inventar os do Pro para montar a
/// tabela seria escrever um número que ninguém garante. A conclusão era do DTO, não da tela:
/// agora `GET /api/billing` manda os dois lados, e a comparação continua sendo palavra do
/// servidor.
///
/// Sem o bloco `pro` na resposta, a tela volta ao que era. Um app novo contra um servidor
/// antigo mostra menos, e não uma linha errada.
class _Limits extends StatelessWidget {
  const _Limits({required this.status, required this.colors});

  final SubscriptionStatus status;
  final BlockColors colors;

  @override
  Widget build(BuildContext context) {
    // Só quem não é Pro tem o que comparar. Mostrar "50 → 50" a um assinante seria ruído, e
    // oferecer-lhe o que ele já paga é o que o servidor evita na própria mensagem de limite.
    final upgrade = status.isPro ? null : status.pro;

    return BlockSection(
      colors: colors,
      // No plano gratuito esta seção é o argumento da venda, e o rótulo diz isso: ela conta o
      // que a pessoa tem hoje, ao lado do que o Pro entrega.
      label: status.isPro
          ? 'Seus limites diários'
          : upgrade == null
          ? 'O que você tem hoje'
          : 'Hoje e com o Pro',
      icon: Icons.speed_outlined,
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          for (final limit in [
            (
              Icons.photo_camera_outlined,
              'Análises de refeição',
              status.maxMealAnalysesPerDay,
              upgrade?.maxMealAnalysesPerDay,
            ),
            (
              Icons.videocam_outlined,
              'Análises de execução',
              status.maxVideoAnalysesPerDay,
              upgrade?.maxVideoAnalysesPerDay,
            ),
            (
              Icons.forum_outlined,
              'Mensagens do coach',
              status.maxCoachMessagesPerDay,
              upgrade?.maxCoachMessagesPerDay,
            ),
          ]) ...[
            if (limit.$1 != Icons.photo_camera_outlined)
              Divider(
                height: 1,
                indent: Space.md,
                endIndent: Space.md,
                color: colors.ink.withValues(alpha: 0.14),
              ),
            _LimitRow(
              icon: limit.$1,
              label: limit.$2,
              value: limit.$3,
              proValue: limit.$4,
              colors: colors,
            ),
          ],
        ],
      ),
    );
  }
}

/// Uma cota: o número de hoje e, quando há para onde subir, o do Pro depois de uma seta.
///
/// **O número de hoje perde a cor quando há comparação.** Com os dois na linha, o que a pessoa
/// precisa ler é o segundo; deixar os dois em [BlockColors.ink] faria a linha ter dois pesos
/// iguais e nenhum destino. A seta é "→" e não "vs": não é uma tabela de planos, é o mesmo
/// número subindo.
class _LimitRow extends StatelessWidget {
  const _LimitRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.colors,
    this.proValue,
  });

  final IconData icon;
  final String label;
  final int value;

  /// O mesmo limite no Pro, ou null quando não há o que comparar — porque a pessoa já é Pro,
  /// ou porque o servidor não mandou o bloco.
  final int? proValue;

  final BlockColors colors;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.colorScheme.onSurfaceVariant;
    final comparing = proValue != null;

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: Space.md,
        vertical: Space.sm,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.baseline,
        textBaseline: TextBaseline.alphabetic,
        children: [
          Icon(icon, size: 18, color: colors.ink),
          const SizedBox(width: Space.sm),
          Expanded(child: Text(label, style: theme.textTheme.bodyMedium)),
          const SizedBox(width: Space.xs),
          Text(
            '$value',
            style: AppTypography.numeric(
              size: 22,
              color: comparing ? muted : colors.ink,
            ),
          ),
          if (comparing) ...[
            const SizedBox(width: Space.xs),
            Text(
              '→',
              style: theme.textTheme.bodyMedium?.copyWith(color: muted),
            ),
            const SizedBox(width: Space.xs),
            Text(
              '$proValue',
              style: AppTypography.numeric(size: 22, color: colors.ink),
            ),
          ],
          const SizedBox(width: 3),
          Text(
            'por dia',
            style: theme.textTheme.bodySmall?.copyWith(color: muted),
          ),
        ],
      ),
    );
  }
}
