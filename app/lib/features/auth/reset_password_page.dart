import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/router.dart';
import 'auth_controller.dart';
import 'widgets/auth_scaffold.dart';
import 'widgets/password_rules.dart';

/// Escolhe a senha nova a partir do link do e-mail. Porte de `ResetPasswordPage.tsx`.
///
/// O `uid` e o `token` vêm na query do link que o backend montou
/// (`AuthController.sendPasswordResetEmail`) — é a única credencial desta tela, e por isso
/// ela é pública: quem chega aqui ainda não consegue entrar.
class ResetPasswordPage extends ConsumerStatefulWidget {
  const ResetPasswordPage({
    required this.userId,
    required this.token,
    super.key,
  });

  final String? userId;
  final String? token;

  @override
  ConsumerState<ResetPasswordPage> createState() => _ResetPasswordPageState();
}

class _ResetPasswordPageState extends ConsumerState<ResetPasswordPage> {
  final _formKey = GlobalKey<FormState>();
  final _password = TextEditingController();
  final _confirmation = TextEditingController();
  bool _obscure = true;

  @override
  void dispose() {
    _password.dispose();
    _confirmation.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    final ok = await ref
        .read(authControllerProvider.notifier)
        .resetPassword(
          userId: widget.userId!,
          token: widget.token!,
          password: _password.text,
        );

    if (!ok || !mounted) {
      return;
    }

    // A confirmação viaja para o login porque é lá que a pessoa vai usar a senha nova. O
    // SnackBar sobrevive à troca de rota: quem o mostra é o ScaffoldMessenger da raiz.
    final message = ref.read(authControllerProvider).info;
    ref.read(authControllerProvider.notifier).clearMessages();
    context.go(Routes.login);
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(SnackBar(content: Text(message ?? 'Senha redefinida.')));
  }

  @override
  Widget build(BuildContext context) {
    // Sem uid ou token não há o que enviar. Mostrar o formulário levaria a pessoa a digitar
    // uma senha nova duas vezes para receber "link inválido" no fim.
    if (widget.userId == null ||
        widget.userId!.isEmpty ||
        widget.token == null ||
        widget.token!.isEmpty) {
      return const _IncompleteLink();
    }

    final state = ref.watch(authControllerProvider);

    return AuthScaffold(
      subtitle: 'Escolha uma senha nova',
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (state.error != null) _ErrorBanner(state.error!),

            TextFormField(
              controller: _password,
              obscureText: _obscure,
              autofocus: true,
              autofillHints: const [AutofillHints.newPassword],
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                labelText: 'Nova senha',
                prefixIcon: const Icon(Icons.lock_outline),
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscure
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                  ),
                  tooltip: _obscure ? 'Mostrar senha' : 'Ocultar senha',
                  onPressed: () => setState(() => _obscure = !_obscure),
                ),
              ),
              validator: (value) {
                final password = value ?? '';
                if (password.isEmpty) {
                  return 'Escolha uma senha.';
                }
                if (!PasswordRule.allSatisfied(password)) {
                  return 'A senha não atende às regras abaixo.';
                }
                return null;
              },
            ),
            const SizedBox(height: 8),
            PasswordRulesView(password: _password.text),
            const SizedBox(height: 12),

            TextFormField(
              controller: _confirmation,
              obscureText: _obscure,
              textInputAction: TextInputAction.done,
              autofillHints: const [AutofillHints.newPassword],
              onFieldSubmitted: (_) => _submit(),
              decoration: const InputDecoration(
                labelText: 'Repita a nova senha',
                prefixIcon: Icon(Icons.lock_outline),
              ),
              validator: (value) =>
                  value == _password.text ? null : 'As senhas não conferem.',
            ),

            const SizedBox(height: 20),
            FilledButton(
              onPressed: state.loading ? null : _submit,
              child: state.loading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Redefinir senha'),
            ),
            TextButton(
              onPressed: () => context.go(Routes.login),
              child: const Text('Voltar para o login'),
            ),
          ],
        ),
      ),
    );
  }
}

/// Link sem `uid` ou sem `token` — truncado pelo cliente de e-mail, ou já reescrito.
class _IncompleteLink extends StatelessWidget {
  const _IncompleteLink();

  @override
  Widget build(BuildContext context) {
    return AuthScaffold(
      subtitle: 'Link inválido',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Este link de redefinição está incompleto. Peça um novo na tela de recuperação.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 20),
          FilledButton(
            onPressed: () => context.go(Routes.forgotPassword),
            child: const Text('Pedir novo link'),
          ),
        ],
      ),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: scheme.errorContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.error_outline, size: 20, color: scheme.onErrorContainer),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(color: scheme.onErrorContainer, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}
