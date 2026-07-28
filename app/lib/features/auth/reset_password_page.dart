import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/router.dart';
import 'auth_controller.dart';
import 'widgets/auth_message.dart';
import 'widgets/auth_scaffold.dart';
import 'widgets/password_rules.dart';

/// Cria a senha nova a partir do link recebido por e-mail. Porte de `ResetPasswordPage.tsx`.
///
/// O [userId] e o [token] chegam na query do link montado pelo backend
/// (`/redefinir-senha?uid=...&token=...`, em `AuthController.forgotPassword`). Os dois vão
/// juntos no envio porque o servidor exige que o token pertença àquele usuário — sem essa
/// conferência, um token válido de uma conta serviria para trocar a senha de outra.
class ResetPasswordPage extends ConsumerStatefulWidget {
  const ResetPasswordPage({
    required this.userId,
    required this.token,
    super.key,
  });

  final String userId;
  final String token;

  /// Um link truncado no cliente de e-mail chega sem os parâmetros. Vale detectar aqui: o
  /// servidor responderia o mesmo "link inválido" que ele usa para token expirado, e o
  /// usuário tentaria de novo com o mesmo link quebrado.
  bool get hasCredentials => userId.isNotEmpty && token.isNotEmpty;

  @override
  ConsumerState<ResetPasswordPage> createState() => _ResetPasswordPageState();
}

class _ResetPasswordPageState extends ConsumerState<ResetPasswordPage> {
  final _formKey = GlobalKey<FormState>();
  final _password = TextEditingController();
  final _confirmation = TextEditingController();

  bool _obscurePassword = true;
  bool _done = false;

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
          userId: widget.userId,
          token: widget.token,
          password: _password.text,
        );

    if (ok && mounted) {
      setState(() => _done = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(authControllerProvider);

    if (!widget.hasCredentials) {
      return AuthScaffold(
        subtitle: 'Redefinição de senha',
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const AuthMessage.error(
              'Link inválido ou incompleto. Peça um novo e-mail de redefinição.',
            ),
            FilledButton(
              onPressed: () => context.go(Routes.forgotPassword),
              child: const Text('Pedir novo link'),
            ),
          ],
        ),
      );
    }

    if (_done) {
      return AuthScaffold(
        subtitle: 'Redefinição de senha',
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AuthMessage.info(
              state.info ?? 'Senha redefinida. Entre com a nova senha.',
              icon: Icons.check_circle_outline,
            ),
            FilledButton(
              onPressed: () => context.go(Routes.login),
              child: const Text('Entrar com a nova senha'),
            ),
          ],
        ),
      );
    }

    return AuthScaffold(
      subtitle: 'Escolha uma senha nova para sua conta',
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Token expirado, já usado ou de outra conta cai aqui, com a mensagem do
            // servidor — que é genérica de propósito.
            if (state.error != null) AuthMessage.error(state.error!),

            TextFormField(
              controller: _password,
              obscureText: _obscurePassword,
              textInputAction: TextInputAction.next,
              autofillHints: const [AutofillHints.newPassword],
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                labelText: 'Nova senha',
                prefixIcon: const Icon(Icons.lock_outline),
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscurePassword ? Icons.visibility_off : Icons.visibility,
                  ),
                  tooltip: _obscurePassword ? 'Mostrar senha' : 'Ocultar senha',
                  onPressed: () =>
                      setState(() => _obscurePassword = !_obscurePassword),
                ),
              ),
              validator: (value) {
                final password = value ?? '';
                if (password.isEmpty) {
                  return 'Informe a nova senha.';
                }
                // Aqui a composição vale, ao contrário do login: a senha está sendo
                // criada agora e precisa passar pela política atual do servidor.
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
              obscureText: _obscurePassword,
              textInputAction: TextInputAction.done,
              autofillHints: const [AutofillHints.newPassword],
              onFieldSubmitted: (_) => _submit(),
              decoration: const InputDecoration(
                labelText: 'Confirmar nova senha',
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
              onPressed: state.loading ? null : () => context.go(Routes.login),
              child: const Text('Voltar para o login'),
            ),
          ],
        ),
      ),
    );
  }
}
