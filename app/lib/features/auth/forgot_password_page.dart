import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'auth_controller.dart';
import 'widgets/auth_scaffold.dart';

/// Pede o link de redefinição por e-mail. Porte de `ForgotPasswordPage.tsx`.
class ForgotPasswordPage extends ConsumerStatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  ConsumerState<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends ConsumerState<ForgotPasswordPage> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();

  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }
    await ref
        .read(authControllerProvider.notifier)
        .forgotPassword(_email.text.trim());
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(authControllerProvider);

    return AuthScaffold(
      subtitle: 'Enviaremos um link para você criar uma senha nova',
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // A resposta é sempre a mesma, exista ou não a conta — é o que impede
            // usar esta tela para descobrir quem tem cadastro.
            if (state.info != null)
              _Message(state.info!, icon: Icons.mark_email_read_outlined),
            if (state.error != null)
              _Message(state.error!, icon: Icons.error_outline, isError: true),

            TextFormField(
              controller: _email,
              keyboardType: TextInputType.emailAddress,
              autocorrect: false,
              textInputAction: TextInputAction.done,
              autofillHints: const [AutofillHints.email],
              onFieldSubmitted: (_) => _submit(),
              decoration: const InputDecoration(
                labelText: 'E-mail',
                prefixIcon: Icon(Icons.mail_outline),
              ),
              validator: (value) {
                final email = value?.trim() ?? '';
                if (email.isEmpty) {
                  return 'Informe seu e-mail.';
                }
                if (!email.contains('@') || !email.contains('.')) {
                  return 'E-mail inválido.';
                }
                return null;
              },
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
                  : const Text('Enviar link'),
            ),
            TextButton(
              onPressed: () => context.pop(),
              child: const Text('Voltar para o login'),
            ),
          ],
        ),
      ),
    );
  }
}

class _Message extends StatelessWidget {
  const _Message(this.text, {required this.icon, this.isError = false});

  final String text;
  final IconData icon;
  final bool isError;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final background = isError
        ? scheme.errorContainer
        : scheme.primaryContainer;
    final foreground = isError
        ? scheme.onErrorContainer
        : scheme.onPrimaryContainer;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: foreground),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(color: foreground, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}
