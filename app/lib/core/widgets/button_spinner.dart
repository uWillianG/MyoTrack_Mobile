import 'package:flutter/material.dart';

/// O rodinho que substitui o ícone de um botão enquanto ele trabalha.
///
/// Existe como peça por causa do [label]: um `CircularProgressIndicator` sozinho é invisível
/// para quem ouve a tela — o botão continua anunciando "Excluir" e nada diz que ele já foi
/// tocado. Nasceu igual em quatro botões da tela de conta e privacidade, e saiu de lá
/// quando o quinto apareceu na aba Conta.
class ButtonSpinner extends StatelessWidget {
  const ButtonSpinner({super.key, required this.label});

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
