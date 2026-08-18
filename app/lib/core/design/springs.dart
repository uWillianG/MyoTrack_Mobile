import 'dart:math' as math;

import 'package:flutter/physics.dart';

/// A física dos gestos.
///
/// **Por que molas e não curvas.** Uma animação de duração fixa é um roteiro: ela sabe de onde
/// sai, para onde vai e quanto demora, e não sabe fazer mais nada. No instante em que o usuário
/// toca no que está se movendo, o roteiro não serve — ou ele é ignorado (o objeto continua até
/// o fim e só então obedece) ou ele é cortado (o objeto salta). Os dois são a mesma sensação:
/// a de estar operando um computador que está ocupado.
///
/// Uma mola não tem roteiro, tem estado. Ela sabe onde o objeto está *agora* e para onde
/// deveria ir; mudar o destino no meio do caminho é só trocar um número, e a velocidade
/// corrente atravessa a troca. É o que permite pegar o anel da Hoje enquanto ele volta e
/// arrastá-lo de novo sem nada engasgar — e é a única razão pela qual a interface parece uma
/// coisa em vez de uma sequência de telas.
///
/// **Os dois parâmetros são os da Apple, não os da física.** Massa, rigidez e amortecimento são
/// três números que interagem de um jeito que ninguém ajusta de cabeça. Resposta e quique são
/// dois números que descrevem o que se vê: quanto tempo até chegar, e se passa do ponto.
abstract final class Springs {
  /// Uma mola descrita como a Apple descreve.
  ///
  /// [response] é o tempo, em segundos, que a mola leva para *chegar* — não a duração da
  /// animação, que numa mola não existe: o assentamento final emerge dos parâmetros.
  ///
  /// [bounce] vai de 0 (chega e para) a ~0,4 (passa do ponto e volta). A regra que evita o
  /// aspecto de brinquedo: **quique só quando o gesto trouxe impulso**. Um painel que abriu
  /// por toque e passa do ponto parece errado; um cartão que a pessoa arremessou e passa do
  /// ponto parece certo, porque ela sente que foi ela quem jogou.
  static SpringDescription of({required double response, double bounce = 0}) {
    final omega = 2 * math.pi / response;
    return SpringDescription.withDampingRatio(
      mass: 1,
      stiffness: omega * omega,
      // Nunca criticamente zero: uma razão de amortecimento em 0 oscilaria para sempre.
      ratio: math.max(0.08, 1 - bounce),
    );
  }

  /// O assentamento de um painel arrastado — o anel da Hoje, a linha do dia.
  static SpringDescription settle({double velocity = 0}) =>
      of(response: 0.34, bounce: velocity.abs() > 90 ? 0.18 : 0);

  /// A troca de página de um carrossel — os dias da Nutrição.
  static SpringDescription page({double velocity = 0}) =>
      of(response: 0.4, bounce: velocity.abs() > 240 ? 0.16 : 0);
}

/// Onde o dedo *ia* parar, e não onde ele parou.
///
/// **É a conta que decide o destino de um arremesso**, e é diferente da que quase todo mundo
/// escreve. O reflexo é usar distância percorrida: passou da metade, vai; não passou, volta.
/// Isso obriga a arrastar o painel inteiro para abri-lo, e transforma um toque rápido de dedo
/// em nada.
///
/// O que a Apple usa é a projeção do momento: a partir da velocidade na soltura, quanto o
/// objeto ainda andaria sozinho até o atrito pará-lo. Um peteleco de 3 mm com velocidade alta
/// projeta longe e abre; um arrasto lento até a metade projeta perto e volta. O usuário
/// controla com a *intenção*, não com o percurso.
///
/// A fórmula é a de um decaimento exponencial com o coeficiente que o iOS usa. Não é `v²/2a`,
/// que é a de desaceleração constante e erra feio na cauda.
double momentumProjection(double velocity, {double decay = 0.998}) =>
    (velocity / 1000) * decay / (1 - decay);

/// A resistência elástica do limite.
///
/// Quando não há mais para onde ir, o certo não é travar: travar não diz se o app entendeu o
/// gesto ou se congelou. O conteúdo continua andando, cada vez menos, e é isso que comunica
/// "acabou" sem interromper ninguém.
///
/// [over] é o quanto passou do limite, [dimension] o tamanho do que se arrasta. Devolve o
/// deslocamento que de fato deve ser aplicado, sempre menor que [over] e assintótico.
double rubberBand(double over, double dimension, {double constant = 0.55}) =>
    (over * dimension * constant) / (dimension + constant * over.abs());
