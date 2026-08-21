import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';

import '../design/springs.dart';

/// O aperto do toque: o alvo encolhe no instante em que o dedo encosta.
///
/// **A resposta acontece no `pointerDown`, não no `pointerUp`.** É a diferença entre um botão
/// que obedece e um que espera para ver se você quis mesmo. O respingo do Material já nasce no
/// toque, mas ele é uma mancha *dentro* do botão — o objeto inteiro não se mexe, e num alvo de
/// 52 dp de altura a mancha é o que se vê menos. Encolher o alvo é o gesto que o dedo entende
/// sem olhar: a peça cedeu.
///
/// **Volta por mola, e sem quique.** A regra do sistema (ver `springs.dart`) é que quique é
/// para o que a pessoa arremessou; soltar um botão não é arremesso. A mola aqui é só o que
/// permite ao aperto ser interrompido no meio: apertar de novo antes de a peça terminar de
/// voltar reaproveita a velocidade corrente em vez de recomeçar do zero, que é o salto que
/// denuncia uma animação de duração fixa.
///
/// Nasceu na entrada do app — a tela de login é onde o produto é julgado antes de existir —, e
/// mora aqui porque é primitiva de interação e não peça de autenticação.
class PressableScale extends StatefulWidget {
  const PressableScale({
    super.key,
    required this.child,
    this.enabled = true,
    this.scale = 0.97,
  });

  final Widget child;

  /// Falso enquanto a ação está em andamento: um botão que ainda cede ao toque enquanto o
  /// pedido corre promete uma segunda tentativa que não vai acontecer.
  final bool enabled;

  /// 0,97 e não menos. Abaixo disso o botão parece afundar, e o que se quer é a impressão de
  /// que ele tem massa — não a de que ele tem um buraco embaixo.
  final double scale;

  @override
  State<PressableScale> createState() => _PressableScaleState();
}

class _PressableScaleState extends State<PressableScale>
    with SingleTickerProviderStateMixin {
  /// Sem limites: a mola precisa poder passar do 1 e voltar sem ser cortada pelo controlador.
  ///
  /// Criado no `initState` e não por inicialização preguiçosa: em movimento reduzido o
  /// controlador nunca é lido durante a vida do widget, e o primeiro a tocá-lo seria o
  /// `dispose` — que o criaria só para destruí-lo, com o `vsync` já indo embora.
  late final AnimationController _press;

  @override
  void initState() {
    super.initState();
    _press = AnimationController.unbounded(vsync: this, value: 1);
  }

  @override
  void dispose() {
    _press.dispose();
    super.dispose();
  }

  /// Sempre a partir do valor e da velocidade correntes — nunca do valor de destino. Começar
  /// do destino é o que faz um segundo toque durante a volta piscar.
  void _springTo(double target) => _press.animateWith(
    SpringSimulation(
      Springs.of(response: 0.22),
      _press.value,
      target,
      _press.velocity,
    ),
  );

  @override
  Widget build(BuildContext context) {
    // Movimento reduzido não quer dizer sem resposta: aqui o retorno visual já é o do próprio
    // Material (respingo e mudança de cor), e o que se remove é só o deslocamento.
    if (MediaQuery.disableAnimationsOf(context)) {
      return widget.child;
    }

    return Listener(
      // `Listener` e não `GestureDetector`: ele não entra na disputa do gesto, então o botão
      // por baixo continua recebendo o toque, o arrasto e o cancelamento como se nada
      // estivesse envolvido nele.
      onPointerDown: widget.enabled ? (_) => _springTo(widget.scale) : null,
      onPointerUp: (_) => _springTo(1),
      onPointerCancel: (_) => _springTo(1),
      child: AnimatedBuilder(
        animation: _press,
        builder: (_, child) =>
            Transform.scale(scale: _press.value, child: child),
        child: widget.child,
      ),
    );
  }
}
