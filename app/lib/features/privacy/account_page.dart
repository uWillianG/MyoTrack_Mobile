import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/auth/session.dart';
import '../../core/design/blocks.dart';
import '../../core/design/format.dart';
import '../../core/design/tokens.dart';
import '../../core/providers.dart';
import '../../core/router.dart';
import '../../core/widgets/blocks.dart';
import '../billing/billing_controller.dart';
import 'privacy_controller.dart';

/// Conta e privacidade.
///
/// **A tela responde três perguntas, nesta ordem: de quem é esta conta, o que o app tem sobre
/// você, e como sair — deste aparelho ou de vez.**
///
/// A exclusão fica na última seção, e antes ficava na primeira. Ela precisa continuar **fácil
/// de achar** — as duas lojas exigem que todo app que permite criar conta permita apagá-la, e
/// a Apple pede explicitamente que o caminho seja curto; enterrá-la num submenu é motivo de
/// recusa. Mas "fácil de achar" não é "primeira coisa da tela": pela regra do sistema de
/// design, o que é mais chamativo deve ser o que se quer que a pessoa faça, e a tela abria com
/// a única ação irreversível do app em destaque. Ela continua nesta tela, sem accordion e sem
/// segundo nível, a uma rolagem de distância — o mesmo caminho que a revisão das lojas percorre.
///
/// **Sem herói.** O herói do sistema é o assunto do momento com um número grande; aqui não há
/// número, e promover a exclusão a herói seria justamente o que o parágrafo acima evita. As
/// quatro seções são neutras porque as quatro são procedimento, não assunto.
///
/// **O nome da tela continua sendo "Conta e privacidade"** mesmo tendo virado a tela da conta:
/// "privacidade" é a palavra que a pessoa procura quando quer apagar seus dados, e é a que o
/// revisor da loja procura quando confere se dá.
class AccountPage extends ConsumerWidget {
  const AccountPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('Conta e privacidade')),
      // Sem `.when` por cima da página inteira, e é deliberado: se o resumo da conta não
      // carregar, a tela ainda tem de mostrar a exclusão. Uma tela de erro no lugar dela
      // significaria que um servidor com soluço tira do titular o direito de apagar a conta —
      // e tira da revisão da loja o botão que ela veio conferir. Cada seção resolve a própria
      // espera.
      body: ListView(
        padding: const EdgeInsets.fromLTRB(Space.gutter, 4, Space.gutter, 32),
        children: const [
          _AccountSection(),
          SizedBox(height: Space.sm),
          _DataSection(),
          SizedBox(height: Space.sm),
          _ConsentSection(),
          SizedBox(height: Space.sm),
          _DeleteSection(),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------------------
// Sua conta: de quem é esta sessão, e como encerrá-la
// ---------------------------------------------------------------------------------------

class _AccountSection extends ConsumerWidget {
  const _AccountSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final summary = ref.watch(accountSummaryProvider).valueOrNull;

    // O e-mail do JWT é o plano B, e chega sem rede: o token já o carrega, e é dele que saem
    // as iniciais do avatar. Com ele, a tela diz de que conta se trata mesmo com o servidor
    // fora do ar — que é quando alguém mais precisa ter certeza antes de apagar alguma coisa.
    final email = summary?.email ?? ref.watch(userEmailProvider).valueOrNull;
    final createdAt = summary?.createdAt;

    return BlockSection(
      colors: Blocks.neutral(theme.colorScheme),
      label: 'Sua conta',
      icon: Icons.person_outline,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            email ?? 'Sessão ativa neste aparelho',
            style: theme.textTheme.titleMedium,
          ),
          if (createdAt != null) ...[
            const SizedBox(height: Space.xxs),
            Text(
              'No MyoTrack desde ${Fmt.dayMonth(createdAt)} de ${createdAt.year}',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
          const SizedBox(height: Space.md),
          const _SignOutButton(),
        ],
      ),
    );
  }
}

/// Sair da conta.
///
/// **Não existia em tela nenhuma até aqui** — só dava para sair desinstalando o app ou
/// esperando a sessão vencer. O caminho todo já estava escrito e testado (desregistrar o push,
/// descartar os tokens); faltava um botão que o chamasse.
class _SignOutButton extends ConsumerStatefulWidget {
  const _SignOutButton();

  @override
  ConsumerState<_SignOutButton> createState() => _SignOutButtonState();
}

class _SignOutButtonState extends ConsumerState<_SignOutButton> {
  bool _leaving = false;

  Future<void> _signOut(int pending) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => _SignOutDialog(pending: pending),
    );
    if (confirmed != true || !mounted) {
      return;
    }

    setState(() => _leaving = true);
    try {
      await ref.read(sessionCloserProvider).close();
    } finally {
      if (mounted) {
        setState(() => _leaving = false);
      }
    }

    if (mounted) {
      // Como na exclusão: a guarda do router já levaria ao login com a sessão limpa, mas ir
      // explicitamente evita depender da ordem em que o estado se propaga.
      context.go(Routes.login);
    }
  }

  @override
  Widget build(BuildContext context) {
    // A contagem é observada aqui, e não lida dentro do `_signOut`: ela chega por stream, e um
    // `read` no instante do toque pegaria a fila ainda sem valor — o aviso de "isto vai ser
    // descartado" sumiria justamente quando há algo a perder.
    final pending = ref.watch(pendingWritesProvider).valueOrNull ?? 0;

    return OutlinedButton.icon(
      onPressed: _leaving ? null : () => _signOut(pending),
      icon: _leaving
          ? const _ButtonSpinner(label: 'Saindo')
          : const Icon(Icons.logout),
      label: const Text('Sair da conta'),
      style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(48)),
    );
  }
}

class _SignOutDialog extends StatelessWidget {
  const _SignOutDialog({required this.pending});

  /// Quantas escritas ainda não subiram. Sair apaga o que é da pessoa neste aparelho, e a fila
  /// vai junto — avisar antes é a diferença entre descartar e perder.
  final int pending;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AlertDialog(
      title: const Text('Sair da conta?'),
      // Rolável: com a fonte do sistema ampliada, o aviso de fila pendente passa da altura do
      // diálogo e o botão "Sair" fica fora de alcance.
      scrollable: true,
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Você vai precisar entrar de novo neste aparelho. Seus dados continuam no '
            'servidor.',
            style: theme.textTheme.bodyMedium,
          ),
          if (pending > 0) ...[
            const SizedBox(height: Space.sm),
            Text(
              pending == 1
                  ? '1 registro ainda não subiu e só existe neste aparelho. Sair agora '
                        'descarta esse registro.'
                  : '$pending registros ainda não subiram e só existem neste aparelho. '
                        'Sair agora descarta esses registros.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.error,
              ),
            ),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(true),
          child: const Text('Sair'),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------------------
// Seus dados: portabilidade (art. 18, LGPD)
// ---------------------------------------------------------------------------------------

/// **Dois caminhos para o mesmo arquivo, e o de baixar é o principal.**
///
/// O envio por e-mail era o único que existia, e ele depende de SMTP configurado: onde não há,
/// o servidor responde 503 e o direito à portabilidade simplesmente não chegava ao titular. O
/// endpoint que devolve o arquivo já existia e nunca tinha sido ligado.
class _DataSection extends ConsumerWidget {
  const _DataSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final export = ref.watch(exportProvider);

    return BlockSection(
      colors: Blocks.neutral(theme.colorScheme),
      label: 'Seus dados',
      icon: Icons.file_download_outlined,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Um arquivo com tudo que temos sobre você — perfil, planos, treinos, medidas '
            'e análises.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: Space.md),
          FilledButton.tonalIcon(
            onPressed: export.busy
                ? null
                : () =>
                      _run(context, ref.read(exportProvider.notifier).download),
            icon: export.downloading
                ? const _ButtonSpinner(label: 'Preparando seus dados')
                : const Icon(Icons.download_outlined),
            label: const Text('Baixar meus dados'),
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(48),
            ),
          ),
          const SizedBox(height: Space.xs),
          TextButton.icon(
            onPressed: export.busy
                ? null
                : () => _run(
                    context,
                    ref.read(exportProvider.notifier).emailToAccount,
                  ),
            icon: export.emailing
                ? const _ButtonSpinner(label: 'Enviando')
                : const Icon(Icons.mail_outline),
            label: const Text('Enviar para o e-mail da conta'),
            style: TextButton.styleFrom(minimumSize: const Size.fromHeight(48)),
          ),
        ],
      ),
    );
  }

  /// Mostra o que a ação tiver a dizer. String vazia é silêncio de propósito: no caminho de
  /// baixar, quem confirma é a folha de compartilhamento que abriu por cima da tela.
  Future<void> _run(
    BuildContext context,
    Future<String> Function() action,
  ) async {
    final messenger = ScaffoldMessenger.of(context);
    final message = await action();
    if (message.isEmpty) {
      return;
    }
    messenger
      ..clearSnackBars()
      ..showSnackBar(SnackBar(content: Text(message)));
  }
}

// ---------------------------------------------------------------------------------------
// O que você autorizou: a trilha de consentimento
// ---------------------------------------------------------------------------------------

/// **Só leitura, e isso é uma decisão.** A trilha é append-only no servidor e não há endpoint
/// para revogar; oferecer o botão seria prometer um controle que não existe. Mostrar o que foi
/// aceito, quando e em que versão dos termos é o que uma tela chamada "privacidade" deve
/// conseguir responder sem que a pessoa precise pedir o export para descobrir.
class _ConsentSection extends ConsumerWidget {
  const _ConsentSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colors = Blocks.neutral(theme.colorScheme);

    return BlockSection(
      colors: colors,
      label: 'O que você autorizou',
      icon: Icons.fact_check_outlined,
      child: ref
          .watch(consentTrailProvider)
          .when(
            loading: () => const Align(
              alignment: Alignment.centerLeft,
              child: _ButtonSpinner(label: 'Carregando'),
            ),
            error: (error, _) => BlockNotice(
              colors: colors,
              icon: Icons.error_outline,
              iconColor: theme.colorScheme.error,
              message: 'Não foi possível ler seus consentimentos agora.',
            ),
            data: (entries) => entries.isEmpty
                ? Text(
                    'Nada registrado ainda. O aceite é gravado quando você cria seu perfil.',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      for (var i = 0; i < entries.length; i++)
                        Padding(
                          padding: EdgeInsets.only(top: i == 0 ? 0 : Space.sm),
                          child: _ConsentLine(entry: entries[i]),
                        ),
                    ],
                  ),
          ),
    );
  }
}

class _ConsentLine extends StatelessWidget {
  const _ConsentLine({required this.entry});

  final ConsentEntry entry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final granted = entry.grantedAt;

    return MergeSemantics(
      // As duas linhas são uma coisa só para quem ouve: separadas, o leitor de tela anuncia
      // "Termos de uso" e, depois de uma pausa, uma data solta.
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(entry.label, style: theme.textTheme.titleSmall),
          Text(
            [
              if (granted != null)
                'Aceito em ${Fmt.dayMonth(granted)} de ${granted.year}',
              if (entry.termsVersion.isNotEmpty) 'versão ${entry.termsVersion}',
              // A coluna existe no servidor mesmo sem tela que revogue; se um dia ela vier
              // preenchida — por um pedido pelo suporte —, a linha diz isso em vez de mentir.
              if (entry.revokedAt case final revoked?)
                'revogado em ${Fmt.dayMonth(revoked)} de ${revoked.year}',
            ].join(' · '),
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------------------
// Excluir a conta
// ---------------------------------------------------------------------------------------

class _DeleteSection extends ConsumerWidget {
  const _DeleteSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colors = Blocks.neutral(theme.colorScheme);

    // **Condicionado, e não removido.** O aviso é dinheiro: quem assina pela loja continua
    // sendo cobrado depois de apagar a conta, e essa é a única forma de saber. Fixo na tela
    // ele aparecia para quem nunca assinou — um recado que não é para você é como se aprende
    // a não ler o que está escrito ali. Só aparece quando o servidor **afirma** que há
    // assinatura de loja: enquanto carrega, ou se a leitura falhar, a tela prefere calar a
    // chutar.
    final subscription = ref.watch(subscriptionStatusProvider).valueOrNull;
    final warnsAboutStore =
        subscription != null &&
        subscription.isPro &&
        subscription.managedByStore;

    return BlockSection(
      colors: colors,
      label: 'Excluir a conta',
      icon: Icons.delete_forever_outlined,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Apaga definitivamente sua conta e tudo que está nela: treinos, dieta, '
            'histórico de séries, medidas, fotos de refeição e vídeos.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: Space.xs),
          Text(
            // "Nem neste aparelho" passou a ser verdade quando a exclusão começou a apagar o
            // banco local junto. Antes a frase já estava escrita, e era falsa: a fila de
            // escrita ficava no celular com séries e pesagens de uma conta que não existia
            // mais — e subia para a próxima conta que entrasse aqui.
            'Não há como desfazer, e não fica cópia de segurança: nem no servidor, nem '
            'neste aparelho.',
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          if (warnsAboutStore) ...[
            const SizedBox(height: Space.sm),
            BlockNotice(
              colors: colors,
              message:
                  'Sua assinatura é gerenciada pela loja e não é cancelada por aqui. '
                  'Cancele-a nos ajustes de assinaturas do seu aparelho, ou a cobrança '
                  'continua.',
            ),
          ],
          const SizedBox(height: Space.md),
          OutlinedButton.icon(
            onPressed: () => _confirm(context, ref),
            icon: const Icon(Icons.delete_forever_outlined),
            label: const Text('Excluir minha conta'),
            style: OutlinedButton.styleFrom(
              foregroundColor: theme.colorScheme.error,
              side: BorderSide(color: theme.colorScheme.error),
              minimumSize: const Size.fromHeight(48),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _confirm(BuildContext context, WidgetRef ref) async {
    final deleted = await showDialog<bool>(
      context: context,
      // Fechar tocando fora seria fácil demais para uma ação irreversível, mas também
      // impediria desistir sem ler — o botão "Cancelar" cobre isso.
      barrierDismissible: false,
      builder: (_) => _ConfirmDialog(
        // Nulo quando o resumo da conta não carregou: aí o diálogo volta a explicar as duas
        // formas, como fazia antes de o servidor saber responder.
        hasPassword: ref.read(accountSummaryProvider).valueOrNull?.hasPassword,
      ),
    );

    if (deleted == true && context.mounted) {
      ScaffoldMessenger.of(context)
        ..clearSnackBars()
        ..showSnackBar(
          const SnackBar(content: Text('Sua conta foi excluída.')),
        );
      // A guarda do router já levaria ao login com a sessão limpa; ir explicitamente evita
      // depender da ordem em que o estado se propaga.
      context.go(Routes.login);
    }
  }
}

class _ConfirmDialog extends ConsumerStatefulWidget {
  const _ConfirmDialog({required this.hasPassword});

  /// Se a conta tem senha. **Nulo é "não sei"**, e não "não tem": o resumo da conta pode não
  /// ter chegado, e adivinhar erraria a instrução justamente no diálogo que não perdoa erro.
  final bool? hasPassword;

  @override
  ConsumerState<_ConfirmDialog> createState() => _ConfirmDialogState();
}

class _ConfirmDialogState extends ConsumerState<_ConfirmDialog> {
  final _confirmation = TextEditingController();
  late bool _obscure = widget.hasPassword != false;

  @override
  void dispose() {
    _confirmation.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final text = _confirmation.text.trim();
    if (text.isEmpty) {
      return;
    }

    final deleted = await ref.read(deleteAccountProvider.notifier).delete(text);
    if (deleted && mounted) {
      Navigator.of(context).pop(true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(deleteAccountProvider);
    final theme = Theme.of(context);

    // Três textos para três situações, e é por isso que o endpoint do resumo existe. Antes
    // havia um só — "Senha ou e-mail" — e metade das pessoas lia a instrução da outra metade.
    final (label, hint) = switch (widget.hasPassword) {
      true => ('Senha', 'Para confirmar, digite a senha da sua conta.'),
      false => (
        'E-mail da conta',
        'Sua conta entrou com Google ou Apple e não tem senha. Para confirmar, digite o '
            'e-mail dela.',
      ),
      null => (
        'Senha ou e-mail',
        'Para confirmar, digite sua senha — ou, se você entrou com Google ou Apple, o '
            'e-mail da sua conta.',
      ),
    };

    return AlertDialog(
      title: const Text('Excluir a conta?'),
      // Rolável: o texto de confirmação, o campo e o erro do servidor não cabem juntos na
      // altura de um diálogo com a fonte do sistema ampliada, e o que sai da tela é a linha
      // de botões.
      scrollable: true,
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Tudo será apagado definitivamente.',
            style: theme.textTheme.bodyMedium,
          ),
          const SizedBox(height: Space.xxs),
          Text(
            hint,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: Space.md),
          TextField(
            controller: _confirmation,
            obscureText: _obscure,
            autocorrect: false,
            enabled: !state.deleting,
            // O teclado de e-mail para quem vai digitar um e-mail: sem isto a pessoa procura
            // o "@" no teclado de texto comum, num campo em que errar custa uma tentativa.
            keyboardType: widget.hasPassword == false
                ? TextInputType.emailAddress
                : TextInputType.text,
            onSubmitted: (_) => _submit(),
            decoration: InputDecoration(
              labelText: label,
              // Sem o olho quando o que se pede é o e-mail: esconder o que a pessoa digita
              // num campo que não é segredo só atrapalha a conferência.
              suffixIcon: widget.hasPassword == false
                  ? null
                  : IconButton(
                      icon: Icon(
                        _obscure ? Icons.visibility_off : Icons.visibility,
                      ),
                      tooltip: _obscure ? 'Mostrar' : 'Ocultar',
                      onPressed: () => setState(() => _obscure = !_obscure),
                    ),
            ),
          ),
          if (state.error case final error?) ...[
            const SizedBox(height: Space.sm),
            // `liveRegion`: o erro aparece sem que nada receba foco, e sem isto o leitor de
            // tela deixa a pessoa esperando um diálogo que já respondeu — em silêncio.
            Semantics(
              liveRegion: true,
              child: Text(
                error,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.error,
                ),
              ),
            ),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: state.deleting
              ? null
              : () => Navigator.of(context).pop(false),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: state.deleting ? null : _submit,
          style: FilledButton.styleFrom(
            backgroundColor: theme.colorScheme.error,
            foregroundColor: theme.colorScheme.onError,
          ),
          child: state.deleting
              ? const _ButtonSpinner(label: 'Excluindo')
              : const Text('Excluir'),
        ),
      ],
    );
  }
}

/// O rodinho que substitui o ícone de um botão enquanto ele trabalha.
///
/// Existe como peça por causa do [label]: um `CircularProgressIndicator` sozinho é invisível
/// para quem ouve a tela — o botão continua anunciando "Excluir" e nada diz que ele já foi
/// tocado. Nasceu igual em quatro botões desta tela.
class _ButtonSpinner extends StatelessWidget {
  const _ButtonSpinner({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      liveRegion: true,
      label: label,
      child: const SizedBox(
        height: 18,
        width: 18,
        child: CircularProgressIndicator(strokeWidth: 2),
      ),
    );
  }
}
