import 'package:flutter/material.dart';

import '../../../core/design/tokens.dart';

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
///
/// **A marca chega com o caractere que a cumpriu**, no mesmo quadro: é o retorno contínuo
/// durante a digitação, e não o veredito depois do envio. Quem digita está olhando para o campo
/// e vê a lista mudar pela visão periférica — por isso a confirmação é um pulo de escala, que a
/// periferia enxerga, e não só uma troca de cor, que ela não enxerga.
class PasswordRulesView extends StatelessWidget {
  const PasswordRulesView({required this.password, super.key});

  final String password;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      // Cinco linhas anunciadas uma a uma a cada tecla seria impossível de ouvir. O leitor de
      // tela recebe a conta, que é a informação; a lista abaixo dele fica só para os olhos.
      label: PasswordRule.all.every((rule) => rule.isSatisfied(password))
          ? 'A senha atende às cinco regras.'
          : 'A senha atende '
                '${PasswordRule.all.where((r) => r.isSatisfied(password)).length}'
                ' de ${PasswordRule.all.length} regras.',
      child: ExcludeSemantics(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (final rule in PasswordRule.all)
              _RuleRow(
                label: rule.label,
                satisfied: rule.isSatisfied(password),
              ),
          ],
        ),
      ),
    );
  }
}

class _RuleRow extends StatelessWidget {
  const _RuleRow({required this.label, required this.satisfied});

  final String label;
  final bool satisfied;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = satisfied
        ? theme.colorScheme.primary
        : theme.colorScheme.onSurfaceVariant;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 1.5),
      child: Row(
        children: [
          SizedBox(
            width: 16,
            child: AnimatedSwitcher(
              duration: Motion.fast,
              switchInCurve: Motion.enter,
              // A marca cresce um pouco além do tamanho final antes de assentar: é o único
              // lugar da tela onde o quique cabe, porque aqui ele não é decoração — é o
              // "certo" de quem acabou de acertar.
              transitionBuilder: (child, animation) => ScaleTransition(
                scale: Tween(begin: 0.5, end: 1.0).animate(
                  CurvedAnimation(parent: animation, curve: Curves.easeOutBack),
                ),
                child: FadeTransition(opacity: animation, child: child),
              ),
              child: Icon(
                satisfied ? Icons.check_circle : Icons.circle_outlined,
                key: ValueKey(satisfied),
                size: 14,
                color: color,
              ),
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: AnimatedDefaultTextStyle(
              duration: Motion.fast,
              curve: Motion.enter,
              style: (theme.textTheme.bodySmall ?? const TextStyle()).copyWith(
                color: color,
                // O peso sobe junto com a cor: sobre vidro, cor sozinha muda pouco, e a regra
                // cumprida precisa se destacar das que ainda faltam.
                fontWeight: satisfied ? FontWeight.w600 : FontWeight.w400,
              ),
              child: Text(label),
            ),
          ),
        ],
      ),
    );
  }
}
