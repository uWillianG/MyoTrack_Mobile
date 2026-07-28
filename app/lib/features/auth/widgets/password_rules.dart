import 'package:flutter/material.dart';

/// Regra de senha que dá para conferir no aparelho, sem ida ao servidor.
class PasswordRule {
  const PasswordRule(this.label, this._test);

  final String label;
  final bool Function(String password) _test;

  bool isSatisfied(String password) => _test(password);

  /// Espelham as regras de composição do backend
  /// ({@code PasswordCompositionRule} no módulo de infraestrutura).
  ///
  /// As faixas incluem acentuadas porque o público é brasileiro: sem `À-Þ`, um "Ácido!9"
  /// apareceria como "falta maiúscula" enquanto o servidor o aceitaria.
  static final List<PasswordRule> all = [
    PasswordRule('pelo menos 8 caracteres', (p) => p.length >= 8),
    PasswordRule('uma letra maiúscula', (p) => RegExp(r'[A-ZÀ-Þ]').hasMatch(p)),
    PasswordRule('uma letra minúscula', (p) => RegExp(r'[a-zß-ÿ]').hasMatch(p)),
    PasswordRule('um número', (p) => RegExp(r'\d').hasMatch(p)),
    PasswordRule(
      'um símbolo (!, @, #…)',
      (p) => RegExp(r'[^A-Za-zÀ-ÿ0-9]').hasMatch(p),
    ),
  ];

  static bool allSatisfied(String password) =>
      all.every((rule) => rule.isSatisfied(password));
}

/// Lista de regras que vai marcando conforme o usuário digita.
///
/// Só mostra as regras verificáveis aqui. As outras duas — senha muito comum e senha
/// parecida com o e-mail ou o nome — dependem de dados que só o servidor tem, e chegam
/// como mensagem de erro depois do envio.
class PasswordRulesView extends StatelessWidget {
  const PasswordRulesView({required this.password, super.key});

  final String password;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final satisfiedColor = theme.colorScheme.primary;
    final pendingColor = theme.colorScheme.onSurfaceVariant;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final rule in PasswordRule.all)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 1),
            child: Row(
              children: [
                Icon(
                  rule.isSatisfied(password)
                      ? Icons.check_circle
                      : Icons.circle_outlined,
                  size: 14,
                  color: rule.isSatisfied(password)
                      ? satisfiedColor
                      : pendingColor,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    rule.label,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: rule.isSatisfied(password)
                          ? satisfiedColor
                          : pendingColor,
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
