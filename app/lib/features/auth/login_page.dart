import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/router.dart';
import 'auth_controller.dart';
import 'data/social_sign_in.dart';
import 'widgets/auth_scaffold.dart';
import 'widgets/password_rules.dart';

/// Entrar ou criar conta. Porte de `LoginPage.tsx`.
class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

enum _Mode { login, register }

class _LoginPageState extends ConsumerState<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _confirmation = TextEditingController();
  final _displayName = TextEditingController();

  _Mode _mode = _Mode.login;
  bool _obscurePassword = true;

  bool get _isRegister => _mode == _Mode.register;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    _confirmation.dispose();
    _displayName.dispose();
    super.dispose();
  }

  void _switchMode() {
    setState(() {
      _mode = _isRegister ? _Mode.login : _Mode.register;
      _confirmation.clear();
    });
    ref.read(authControllerProvider.notifier).clearMessages();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }
    final controller = ref.read(authControllerProvider.notifier);

    final ok = _isRegister
        ? await controller.register(
            email: _email.text.trim(),
            password: _password.text,
            displayName: _displayName.text.trim().isEmpty
                ? null
                : _displayName.text.trim(),
          )
        : await controller.login(
            email: _email.text.trim(),
            password: _password.text,
          );

    if (ok && mounted) {
      context.go(Routes.home);
    }
  }

  Future<void> _social(Future<bool> Function() action) async {
    if (await action() && mounted) {
      context.go(Routes.home);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(authControllerProvider);
    final providers = ref.watch(authProvidersProvider);
    final theme = Theme.of(context);

    final showGoogle = providers.valueOrNull?.google ?? false;
    // Sign in with Apple só no iOS: no Android exigiria um Services ID configurado, e ali
    // o Google já cobre o caso.
    final showApple =
        (providers.valueOrNull?.apple ?? false) &&
        SocialSignIn.isAppleAvailable;
    final showPasswordReset = providers.valueOrNull?.passwordReset ?? false;

    return AuthScaffold(
      subtitle: _isRegister
          ? 'Crie sua conta e comece a treinar'
          : 'Entre para continuar seu treino',
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (state.error != null) _Banner.error(state.error!),
            if (state.info != null) _Banner.info(state.info!),

            if (_isRegister) ...[
              TextFormField(
                controller: _displayName,
                textInputAction: TextInputAction.next,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(
                  labelText: 'Nome (opcional)',
                  prefixIcon: Icon(Icons.person_outline),
                ),
              ),
              const SizedBox(height: 12),
            ],

            TextFormField(
              controller: _email,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              autocorrect: false,
              autofillHints: const [AutofillHints.email],
              decoration: const InputDecoration(
                labelText: 'E-mail',
                prefixIcon: Icon(Icons.mail_outline),
              ),
              validator: (value) {
                final email = value?.trim() ?? '';
                if (email.isEmpty) {
                  return 'Informe seu e-mail.';
                }
                // Validação frouxa de propósito: quem decide se o e-mail existe é o
                // servidor, e regex rigorosa recusa endereços válidos.
                if (!email.contains('@') || !email.contains('.')) {
                  return 'E-mail inválido.';
                }
                return null;
              },
            ),
            const SizedBox(height: 12),

            TextFormField(
              controller: _password,
              obscureText: _obscurePassword,
              textInputAction: _isRegister
                  ? TextInputAction.next
                  : TextInputAction.done,
              autofillHints: [
                _isRegister
                    ? AutofillHints.newPassword
                    : AutofillHints.password,
              ],
              onChanged: _isRegister ? (_) => setState(() {}) : null,
              onFieldSubmitted: _isRegister ? null : (_) => _submit(),
              decoration: InputDecoration(
                labelText: 'Senha',
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
                  return 'Informe sua senha.';
                }
                // No login não se valida composição: a senha pode ser antiga, de antes
                // da política atual, e reprovar aqui impediria alguém de entrar na
                // própria conta.
                if (_isRegister && !PasswordRule.allSatisfied(password)) {
                  return 'A senha não atende às regras abaixo.';
                }
                return null;
              },
            ),

            if (_isRegister) ...[
              const SizedBox(height: 8),
              PasswordRulesView(password: _password.text),
              const SizedBox(height: 12),
              TextFormField(
                controller: _confirmation,
                obscureText: _obscurePassword,
                textInputAction: TextInputAction.done,
                onFieldSubmitted: (_) => _submit(),
                decoration: const InputDecoration(
                  labelText: 'Confirmar senha',
                  prefixIcon: Icon(Icons.lock_outline),
                ),
                validator: (value) =>
                    value == _password.text ? null : 'As senhas não conferem.',
              ),
            ],

            const SizedBox(height: 20),
            FilledButton(
              onPressed: state.loading ? null : _submit,
              child: state.loading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(_isRegister ? 'Criar conta' : 'Entrar'),
            ),

            if (!_isRegister && showPasswordReset)
              TextButton(
                onPressed: state.loading
                    ? null
                    : () => context.push(Routes.forgotPassword),
                child: const Text('Esqueci minha senha'),
              ),

            if (showGoogle || showApple) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  const Expanded(child: Divider()),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Text(
                      'ou',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                  const Expanded(child: Divider()),
                ],
              ),
              const SizedBox(height: 8),
              if (showGoogle)
                OutlinedButton.icon(
                  onPressed: state.loading
                      ? null
                      : () => _social(
                          ref
                              .read(authControllerProvider.notifier)
                              .signInWithGoogle,
                        ),
                  icon: const Icon(Icons.g_mobiledata, size: 28),
                  label: const Text('Continuar com Google'),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(48),
                  ),
                ),
              if (showGoogle && showApple) const SizedBox(height: 8),
              if (showApple)
                OutlinedButton.icon(
                  onPressed: state.loading
                      ? null
                      : () => _social(
                          ref
                              .read(authControllerProvider.notifier)
                              .signInWithApple,
                        ),
                  icon: const Icon(Icons.apple, size: 24),
                  label: const Text('Continuar com Apple'),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(48),
                  ),
                ),
            ],

            const SizedBox(height: 12),
            TextButton(
              onPressed: state.loading ? null : _switchMode,
              child: Text(
                _isRegister
                    ? 'Já tenho conta. Entrar'
                    : 'Não tenho conta. Criar agora',
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Faixa de mensagem acima do formulário.
class _Banner extends StatelessWidget {
  const _Banner._({required this.message, required this.isError});

  factory _Banner.error(String message) =>
      _Banner._(message: message, isError: true);

  factory _Banner.info(String message) =>
      _Banner._(message: message, isError: false);

  final String message;
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
          Icon(
            isError ? Icons.error_outline : Icons.info_outline,
            size: 20,
            color: foreground,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: TextStyle(color: foreground, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}
