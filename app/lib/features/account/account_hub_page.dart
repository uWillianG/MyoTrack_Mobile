import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/design/blocks.dart';
import '../../core/design/format.dart';
import '../../core/design/materials.dart';
import '../../core/design/tokens.dart';
import '../../core/env.dart';
import '../../core/providers.dart';
import '../../core/router.dart';
import '../../core/widgets/blocks.dart';
import '../billing/billing_controller.dart';
import '../billing/data/billing_models.dart';
import '../home/account_destinations.dart';
import '../home/account_notices.dart';
import '../home/today_controller.dart' show nowProvider;
import '../privacy/privacy_controller.dart';
import '../privacy/sign_out_button.dart';
import '../reviews/review_controller.dart';
import 'url_opener.dart';

/// A aba Conta.
///
/// **A quinta aba, e a única que não responde uma pergunta sobre o corpo.** As outras quatro
/// são consulta — quanto ainda cabe hoje, o que a câmera achou, quanto ainda falta, estou
/// evoluindo. Esta é a casa da pessoa dentro do app: de quem é esta conta, o que ela paga, o
/// que o app sabe dela e como ir embora.
///
/// **Não é uma gaveta com uma lista dentro.** A folha que o avatar da barra superior abria já
/// era isso, e foi por isso que ela saiu do app: o que uma aba acrescenta é o que só cabe numa
/// tela inteira — o plano atual visível sem procurar (o app cobra assinatura, e um paywall que
/// só se encontra em três toques é um paywall que ninguém encontra) e a exclusão de conta a uma
/// rolagem do primeiro quadro, que é onde a revisão das lojas procura. Uma folha oferecendo a
/// mesma lista a partir do canto de cima seria só um segundo caminho para cá.
///
/// **Sem herói, e é a mesma decisão da tela de conta e privacidade.** O herói do sistema é o
/// assunto do momento com um número grande; aqui não há número que seja o assunto, e promover
/// procedimento a herói faria a tela gritar sobre pagar e apagar. Tudo em `Blocks.neutral`.
class AccountHubView extends ConsumerWidget {
  const AccountHubView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colors = Blocks.neutral(theme.colorScheme);

    // Falha ao ler os papéis esconde a revisão em vez de derrubar a aba — a mesma regra da
    // folha, e pelo mesmo motivo: levaria o aluno a uma tela que o servidor recusa com 403.
    final canReview =
        ref.watch(reviewableKindsProvider).valueOrNull?.isNotEmpty ?? false;
    // Sem `.when` por cima da tela inteira, e é deliberado — a mesma escolha da `AccountPage`:
    // se a assinatura não carregar, a aba ainda precisa levar à exclusão de conta. Um erro de
    // servidor não pode tirar do titular o caminho para apagar os próprios dados.
    final status = ref.watch(subscriptionStatusProvider).valueOrNull;

    // **Com o cartão do plano na tela, a linha "Assinatura" sai da lista.** O cartão já é a
    // assinatura, já diz o plano em vigor e já leva à mesma tela; repetida logo abaixo, a linha
    // sugeriria um segundo destino — foi por isso que o Progresso saiu desta lista ao virar aba.
    // Quando o cartão não carrega, ela volta: sem os dois, a assinatura ficaria inalcançável
    // pela navegação — esta tela é o único caminho até ela.
    final destinations = [
      for (final destination in accountDestinations)
        if (status == null || destination.route != Routes.billing) destination,
      if (canReview) reviewDestination,
    ];

    return ListView(
      // `screenBottomInset` e não `listBottomInset`: esta é a única aba sem nada flutuando por
      // cima — o coach fica de fora dela, ver [HomeTab].
      padding: EdgeInsets.fromLTRB(
        Space.gutter,
        4,
        Space.gutter,
        screenBottomInset(context),
      ),
      children: [
        const _Identity(),
        // Padding em cima e não embaixo: o aviso é opcional, e um respiro embaixo deixaria um
        // buraco no meio da lista nos dias — quase todos — em que não há nada a avisar.
        ...accountNotices(ref, padding: const EdgeInsets.only(top: Space.sm)),
        if (status != null) ...[
          const SizedBox(height: Space.sm),
          _PlanSection(status: status, colors: colors),
        ],
        for (final group in AccountGroup.values)
          if (destinations.any((d) => d.group == group)) ...[
            const SizedBox(height: Space.sm),
            _DestinationSection(
              group: group,
              destinations: [
                for (final d in destinations)
                  if (d.group == group) d,
              ],
              colors: colors,
            ),
          ],
        const SizedBox(height: Space.sm),
        _SupportSection(colors: colors),
        const SizedBox(height: Space.md),
        const SignOutButton(),
        const SizedBox(height: Space.md),
        const _VersionFooter(),
      ],
    );
  }
}

// ---------------------------------------------------------------------------------------
// De quem é esta conta
// ---------------------------------------------------------------------------------------

/// As iniciais, o e-mail e desde quando.
///
/// Iniciais e não foto porque não há upload de avatar em lugar nenhum — um espaço reservado
/// para uma foto que nunca chega fica pior que a inicial. O cálculo é o de [initialsFrom], logo
/// abaixo; ele veio do avatar da barra superior, que era o outro lugar que desenhava estas duas
/// letras e saiu do app quando esta aba passou a oferecer a mesma lista que a folha dele.
///
/// O e-mail do JWT é o plano B do resumo do servidor, e chega sem rede: a aba diz de que conta
/// se trata mesmo com a API fora do ar, que é quando alguém mais precisa ter certeza antes de
/// mexer em alguma coisa.
class _Identity extends ConsumerWidget {
  const _Identity();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final summary = ref.watch(accountSummaryProvider).valueOrNull;
    final email = summary?.email ?? ref.watch(userEmailProvider).valueOrNull;
    final createdAt = summary?.createdAt;

    return GlassPanel(
      padding: const EdgeInsets.all(Space.md),
      child: Row(
        children: [
          CircleAvatar(
            radius: 26,
            backgroundColor: theme.colorScheme.surfaceContainerHigh,
            child: Text(
              initialsFrom(email),
              style: theme.textTheme.titleMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          const SizedBox(width: Space.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  email ?? 'Sessão ativa neste aparelho',
                  style: theme.textTheme.titleSmall,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                if (createdAt != null) ...[
                  const SizedBox(height: Space.xxs),
                  Text(
                    'No MyoTrack desde ${Fmt.dayMonth(createdAt)} de '
                    '${createdAt.year}',
                    style: theme.textTheme.bodySmall,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Até duas letras a partir do e-mail: `rafael.souza@x.com` vira "RS", `willian@x.com` vira
/// "WI". Sem e-mail — sessão ainda carregando — fica o traço, que não parece nome de outra
/// pessoa.
///
/// **Mora aqui porque só o cabeçalho acima a chama.** Ela morava com o avatar da barra
/// superior, que desenhava as mesmas iniciais; quando o avatar saiu, deixar a função no
/// arquivo dele seria manter de pé um arquivo chamado "avatar" sem avatar nenhum dentro.
/// Função de topo e não método privado porque é cálculo puro sobre uma string, e é isso que a
/// torna testável sem montar tela.
String initialsFrom(String? email) {
  final local = (email ?? '').split('@').first.trim();
  if (local.isEmpty) {
    return '—';
  }

  final parts = local
      .split(RegExp(r'[._\-+\s]+'))
      .where((p) => p.isNotEmpty)
      .toList();
  if (parts.length >= 2) {
    return (parts[0][0] + parts[1][0]).toUpperCase();
  }
  return local.substring(0, local.length >= 2 ? 2 : 1).toUpperCase();
}

// ---------------------------------------------------------------------------------------
// O plano: o que você tem hoje
// ---------------------------------------------------------------------------------------

/// Resumo da assinatura, e não um segundo paywall.
///
/// **O preço não está aqui, e é de propósito.** Quem sabe o preço é a loja, e quem fala com a
/// loja é a `BillingPage` — repetir um valor escrito à mão nesta tela é como um app passa a
/// anunciar um preço que não cobra. O que cabe no resumo é o que o servidor já respondeu: qual
/// plano está valendo, quando renova e quanto de IA cabe por dia.
///
/// O provider já conta certo para quem ganhou Pro por constância: o servidor soma assinatura e
/// concessão antes de responder o plano.
class _PlanSection extends ConsumerWidget {
  const _PlanSection({required this.status, required this.colors});

  final SubscriptionStatus status;
  final BlockColors colors;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    return BlockSection(
      colors: colors,
      label: 'Assinatura',
      icon: Icons.workspace_premium_outlined,
      padding: EdgeInsets.zero,
      // A seção inteira é o alvo, e a seta diz para onde. `onEdit` com um lápis prometeria
      // editar a assinatura aqui, que é justamente o que não dá — quem cobra é a loja.
      onEdit: () => context.push(Routes.billing),
      actionIcon: Icons.chevron_right,
      actionVerb: 'Abrir',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(Space.md, 0, Space.md, Space.sm),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  status.isPro ? 'MyoTrack Pro' : 'Plano gratuito',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: colors.ink,
                  ),
                ),
                const SizedBox(height: Space.xxs),
                Text(
                  _detail(ref.read(nowProvider)()),
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ),
          ),
          if (status.paymentPastDue)
            Padding(
              padding: const EdgeInsets.fromLTRB(
                Space.md,
                0,
                Space.md,
                Space.sm,
              ),
              child: BlockNotice(
                colors: colors,
                icon: Icons.warning_amber_outlined,
                iconColor: theme.colorScheme.error,
                message:
                    'A última cobrança falhou. Atualize a forma de pagamento '
                    'na loja para não perder o acesso.',
              ),
            ),
          for (final limit in _limits) ...[
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
              colors: colors,
            ),
          ],
        ],
      ),
    );
  }

  List<(IconData, String, int)> get _limits => [
    (
      Icons.photo_camera_outlined,
      'Análises de refeição',
      status.maxMealAnalysesPerDay,
    ),
    (
      Icons.videocam_outlined,
      'Análises de execução',
      status.maxVideoAnalysesPerDay,
    ),
    (Icons.forum_outlined, 'Mensagens do coach', status.maxCoachMessagesPerDay),
  ];

  /// A linha sob o nome do plano. No Pro é a data; no gratuito é o convite.
  ///
  /// "28 de agosto", com o ano só quando não é o corrente — a mesma conta da tela de
  /// assinatura, e pelo mesmo motivo: uma assinatura anual vence no ano que vem, e a data sem
  /// o ano ali seria a mais confusa possível.
  ///
  /// **O Pro por constância tem linha própria.** Ele dizia "Assinatura ativa" como qualquer
  /// outro, e não há assinatura nenhuma: o prêmio vence numa data e ninguém era avisado disso
  /// no lugar onde se vai justamente conferir o que se paga.
  String _detail(DateTime now) {
    if (!status.isPro) {
      return 'Toque para conhecer o Pro e ampliar os limites do dia.';
    }

    final iso = status.isGranted
        ? status.grantExpiresAt
        : status.currentPeriodEnd;
    final at = iso == null ? null : DateTime.tryParse(iso)?.toLocal();
    if (at == null) {
      if (status.isGranted) {
        return 'Pro por constância, sem cobrança.';
      }
      return status.managedByStore
          ? 'Assinatura gerenciada pela loja do aparelho.'
          : 'Assinatura ativa.';
    }

    final when = at.year == now.year
        ? Fmt.dayMonth(at)
        : '${Fmt.dayMonth(at)} de ${at.year}';
    return status.isGranted
        ? 'Prêmio por constância até $when'
        : 'Renova em $when';
  }
}

class _LimitRow extends StatelessWidget {
  const _LimitRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.colors,
  });

  final IconData icon;
  final String label;
  final int value;
  final BlockColors colors;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: Space.md,
        vertical: Space.sm,
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: colors.ink),
          const SizedBox(width: Space.sm),
          Expanded(child: Text(label, style: theme.textTheme.bodyMedium)),
          const SizedBox(width: Space.xs),
          Text(
            '$value por dia',
            style: theme.textTheme.labelMedium?.copyWith(color: colors.ink),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------------------
// O mapa: os destinos que não são abas
// ---------------------------------------------------------------------------------------

class _DestinationSection extends StatelessWidget {
  const _DestinationSection({
    required this.group,
    required this.destinations,
    required this.colors,
  });

  final AccountGroup group;
  final List<AccountDestination> destinations;
  final BlockColors colors;

  @override
  Widget build(BuildContext context) {
    return BlockSection(
      colors: colors,
      label: group.label,
      icon: group.icon,
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final destination in destinations) ...[
            if (destination != destinations.first)
              Divider(
                height: 1,
                indent: Space.md,
                endIndent: Space.md,
                color: colors.ink.withValues(alpha: 0.14),
              ),
            _DestinationRow(destination: destination, colors: colors),
          ],
        ],
      ),
    );
  }
}

/// Uma linha da lista, escrita à mão.
///
/// Não é `ListTile`: nesta casa o `ListTile` só aparece dentro de folha modal — a folha do
/// avatar é a única que o usa. Em página o padrão é este, o mesmo das linhas de limite da
/// assinatura e dos recordes do Progresso.
class _DestinationRow extends StatelessWidget {
  const _DestinationRow({required this.destination, required this.colors});

  final AccountDestination destination;
  final BlockColors colors;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return InkWell(
      onTap: () => context.push(destination.route),
      borderRadius: Radii.smAll,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: Space.md,
          vertical: Space.sm,
        ),
        child: Row(
          children: [
            Icon(destination.icon, size: 20, color: colors.ink),
            const SizedBox(width: Space.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(destination.title, style: theme.textTheme.titleSmall),
                  const SizedBox(height: 2),
                  Text(destination.subtitle, style: theme.textTheme.bodySmall),
                ],
              ),
            ),
            const SizedBox(width: Space.xs),
            Icon(
              Icons.chevron_right,
              size: 20,
              color: theme.colorScheme.outline,
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------------------
// Suporte e o que as lojas exigem estar à mão
// ---------------------------------------------------------------------------------------

/// Ajuda, termos, privacidade e a avaliação.
///
/// **O e-mail vem primeiro porque é o único que não depende de nada publicado.** Ele sai com a
/// versão do app, o aparelho e a conta já no corpo — é o que a primeira resposta do suporte
/// pediria de volta, e ninguém sabe de cabeça em que build está.
///
/// **"Avaliar o app" some no iOS enquanto não houver ficha na App Store** ([Env.appStoreId]).
/// Um link para uma página que não existe é pior que linha nenhuma — a mesma regra que mantém a
/// fila de revisão escondida de quem não revisa.
class _SupportSection extends ConsumerWidget {
  const _SupportSection({required this.colors});

  final BlockColors colors;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // `Theme.of(context).platform` e não `defaultTargetPlatform`: os dois dão o mesmo valor
    // no aparelho — o tema herda o global —, mas só este dá para trocar num teste sem mexer
    // numa variável de debug que o `flutter_test` exige ver restaurada no fim.
    final platform = Theme.of(context).platform;

    final rows = <(IconData, String, Uri)>[
      (Icons.mail_outline, 'Falar com o suporte', _supportMail(ref, platform)),
      (Icons.description_outlined, 'Termos de uso', Uri.parse(Env.termsUrl)),
      (
        Icons.privacy_tip_outlined,
        'Política de privacidade',
        Uri.parse(Env.privacyUrl),
      ),
      if (_storeListing(ref, platform) case final listing?)
        (Icons.star_outline, 'Avaliar o app', listing),
    ];

    return BlockSection(
      colors: colors,
      label: 'Suporte',
      icon: Icons.help_outline,
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final row in rows) ...[
            if (row != rows.first)
              Divider(
                height: 1,
                indent: Space.md,
                endIndent: Space.md,
                color: colors.ink.withValues(alpha: 0.14),
              ),
            _LinkRow(icon: row.$1, label: row.$2, url: row.$3, colors: colors),
          ],
        ],
      ),
    );
  }

  /// A ficha do app na loja do aparelho, ou `null` quando ela ainda não existe.
  Uri? _storeListing(WidgetRef ref, TargetPlatform platform) {
    if (platform == TargetPlatform.iOS) {
      return Env.isAppStoreListed
          ? Uri.parse(
              'https://apps.apple.com/app/id${Env.appStoreId}'
              '?action=write-review',
            )
          : null;
    }

    // `market://` abre direto na Play Store instalada, sem passar pelo navegador. O nome do
    // pacote vem do próprio app: uma constante escrita aqui divergiria em silêncio do
    // `applicationId` no dia em que ele mudasse.
    final package = ref.watch(packageInfoProvider).valueOrNull?.packageName;
    return package == null ? null : Uri.parse('market://details?id=$package');
  }

  Uri _supportMail(WidgetRef ref, TargetPlatform platform) {
    final info = ref.watch(packageInfoProvider).valueOrNull;
    final email = ref.watch(userEmailProvider).valueOrNull;

    final footer = [
      if (info != null) 'Versão: ${info.version} (${info.buildNumber})',
      'Plataforma: ${platform.name}',
      if (email != null) 'Conta: $email',
    ].join('\n');

    return Uri(
      scheme: 'mailto',
      path: Env.supportEmail,
      queryParameters: {
        'subject': 'Suporte MyoTrack',
        'body':
            '\n\n---\nNão apague as linhas abaixo: elas dizem de onde veio a '
            'mensagem.\n$footer',
      },
    );
  }
}

class _LinkRow extends ConsumerWidget {
  const _LinkRow({
    required this.icon,
    required this.label,
    required this.url,
    required this.colors,
  });

  final IconData icon;
  final String label;
  final Uri url;
  final BlockColors colors;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    return InkWell(
      onTap: () async {
        final messenger = ScaffoldMessenger.of(context);
        final opened = await ref.read(urlOpenerProvider).open(url);
        if (!opened) {
          // A recusa é silenciosa do lado do sistema: aparelho sem cliente de e-mail não
          // estoura nada, só não abre. Sem este aviso o toque não teria resposta nenhuma.
          messenger
            ..clearSnackBars()
            ..showSnackBar(
              SnackBar(content: Text('Não foi possível abrir "$label".')),
            );
        }
      },
      borderRadius: Radii.smAll,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: Space.md,
          vertical: Space.sm + 2,
        ),
        child: Row(
          children: [
            Icon(icon, size: 20, color: colors.ink),
            const SizedBox(width: Space.sm),
            Expanded(child: Text(label, style: theme.textTheme.titleSmall)),
            Icon(Icons.open_in_new, size: 16, color: theme.colorScheme.outline),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------------------
// O rodapé
// ---------------------------------------------------------------------------------------

/// Versão e build, e a porta para as licenças.
///
/// **É a linha que se pede a quem relata um problema**, e por isso ela mostra o build junto: em
/// desenvolvimento a versão fica parada por semanas enquanto o build anda todo dia. Enquanto o
/// lado nativo não responde, não há linha nenhuma — uma versão errada por um instante é pior
/// que nenhuma numa linha cuja única função é ser copiada.
///
/// O toque abre as licenças de código aberto. O `LicenseRegistry` já registra a da fonte desde
/// que ela foi empacotada, e até aqui nada no app levava até ele.
class _VersionFooter extends ConsumerWidget {
  const _VersionFooter();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final info = ref.watch(packageInfoProvider).valueOrNull;

    if (info == null) {
      return const SizedBox.shrink();
    }

    final version = '${info.version} (${info.buildNumber})';

    return Center(
      child: TextButton(
        onPressed: () => showLicensePage(
          context: context,
          applicationName: 'MyoTrack',
          applicationVersion: version,
        ),
        child: Text(
          'MyoTrack $version',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.outline,
          ),
        ),
      ),
    );
  }
}
