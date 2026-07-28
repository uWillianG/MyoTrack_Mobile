import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/widgets/empty_state.dart';
import 'billing_controller.dart';
import 'data/billing_models.dart';

/// Assinatura do plano Pro. Porte de `BillingPage.tsx`, com a compra pela loja no lugar do
/// checkout do Stripe.
class BillingPage extends ConsumerWidget {
  const BillingPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final billing = ref.watch(billingControllerProvider);
    final statusAsync = ref.watch(subscriptionStatusProvider);

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
          data: (status) => ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            children: [
              _PlanCard(status: status),
              const SizedBox(height: 16),
              _Limits(status: status),
              if (!status.isPro) ...[
                const SizedBox(height: 16),
                _Offer(billing: billing),
              ],
              if (status.isPro && status.managedByStore) ...[
                const SizedBox(height: 16),
                const _ManagedByStoreNote(),
              ],
              const SizedBox(height: 8),
              TextButton(
                onPressed: billing.purchasing
                    ? null
                    : () => ref
                          .read(billingControllerProvider.notifier)
                          .restore(),
                // As duas lojas exigem este botão em app com compra não consumível: quem
                // trocou de aparelho precisa reaver o que já pagou sem pagar de novo.
                child: const Text('Restaurar compras'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PlanCard extends StatelessWidget {
  const _PlanCard({required this.status});

  final SubscriptionStatus status;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  status.isPro ? Icons.workspace_premium : Icons.person_outline,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  status.isPro ? 'MyoTrack Pro' : 'Plano gratuito',
                  style: theme.textTheme.titleLarge,
                ),
              ],
            ),
            if (status.currentPeriodEnd != null) ...[
              const SizedBox(height: 8),
              Text(
                'Válido até ${_formatDate(status.currentPeriodEnd!)}',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
            if (status.paymentPastDue) ...[
              const SizedBox(height: 12),
              // Aviso e não bloqueio: o acesso ainda vale durante a tolerância da loja, e
              // cortar antes puniria quem só precisa atualizar o cartão.
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: theme.colorScheme.errorContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.warning_amber_outlined,
                      size: 20,
                      color: theme.colorScheme.onErrorContainer,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'A última cobrança falhou. Atualize a forma de pagamento na '
                        'loja para não perder o acesso.',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onErrorContainer,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// `2026-08-28T...` vira `28/08/2026`. Feito à mão porque só o dia importa aqui.
  static String _formatDate(String iso) {
    if (iso.length < 10) {
      return iso;
    }
    final parts = iso.substring(0, 10).split('-');
    return parts.length == 3 ? '${parts[2]}/${parts[1]}/${parts[0]}' : iso;
  }
}

/// O que cada plano libera por dia.
///
/// Os números vêm do servidor e não do app: os limites são configuráveis por ambiente, e um
/// valor fixo aqui mentiria no dia em que forem ajustados.
class _Limits extends StatelessWidget {
  const _Limits({required this.status});

  final SubscriptionStatus status;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Seus limites diários', style: theme.textTheme.titleMedium),
            const SizedBox(height: 12),
            _LimitRow(
              icon: Icons.photo_camera_outlined,
              label: 'Análises de refeição',
              value: status.maxMealAnalysesPerDay,
            ),
            _LimitRow(
              icon: Icons.videocam_outlined,
              label: 'Análises de vídeo',
              value: status.maxVideoAnalysesPerDay,
            ),
            _LimitRow(
              icon: Icons.chat_bubble_outline,
              label: 'Mensagens do coach',
              value: status.maxCoachMessagesPerDay,
            ),
          ],
        ),
      ),
    );
  }
}

class _LimitRow extends StatelessWidget {
  const _LimitRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final int value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 18, color: theme.colorScheme.onSurfaceVariant),
          const SizedBox(width: 8),
          Expanded(child: Text(label, style: theme.textTheme.bodyMedium)),
          Text(
            '$value/dia',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

class _Offer extends ConsumerWidget {
  const _Offer({required this.billing});

  final BillingState billing;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Assine o Pro', style: theme.textTheme.titleMedium),
            const SizedBox(height: 4),
            Text(
              'Mais análises de refeição e de vídeo por dia, e mais conversa com o coach.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 16),

            if (billing.loadingStore)
              const Center(child: CircularProgressIndicator())
            else if (!billing.storeAvailable)
              Text(
                'A assinatura não está disponível neste aparelho no momento.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              )
            else ...[
              FilledButton(
                onPressed: billing.purchasing
                    ? null
                    : () => ref.read(billingControllerProvider.notifier).buy(),
                child: billing.purchasing
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    // O preço é o que a loja devolveu, já com moeda e impostos da região.
                    : Text('Assinar por ${billing.product!.price}'),
              ),
              const SizedBox(height: 8),
              Text(
                'A cobrança é feita pela loja e renova sozinha. Cancele quando quiser, '
                'nos ajustes do aparelho.',
                textAlign: TextAlign.center,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Assinatura de loja não se cancela pelo app — a instrução certa evita o botão que não
/// funciona e o suporte que vem atrás dele.
class _ManagedByStoreNote extends StatelessWidget {
  const _ManagedByStoreNote();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              Icons.info_outline,
              size: 20,
              color: theme.colorScheme.outline,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Sua assinatura é gerenciada pela loja. Para alterar ou cancelar, '
                'use os ajustes de assinaturas do seu aparelho.',
                style: theme.textTheme.bodySmall,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
