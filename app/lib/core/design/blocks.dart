import 'package:flutter/material.dart';

/// A cor de cada assunto do app.
///
/// **Por que existe.** Até aqui o app tinha uma cor só — o esmeralda — e todo o resto era
/// cinza. Isso é o padrão do Material com um acento, e é a razão de a tela parecer genérica
/// por mais que se mexesse no espaçamento. Um app de treino e dieta tem assuntos diferentes
/// acontecendo ao mesmo tempo, e dar cor a cada um é o que permite ler a tela de relance em
/// vez de ler cada rótulo.
///
/// **A disciplina que impede o arco-íris** — e sem ela isto vira um app infantil:
///
/// 1. **Um bloco saturado por tela**, o herói. Os demais são *lavados*: um fundo bem claro
///    (ou bem escuro) tingido da cor, com a cor cheia aparecendo só no número e no ícone.
/// 2. **A cor pertence ao assunto, não ao estado.** Nutrição é sempre esmeralda, aqui e na
///    aba Nutrição. Cor que muda de significado entre telas não é sistema, é decoração.
/// 3. **Nunca é o único portador.** Cada bloco tem rótulo escrito e ícone próprio.
///
/// As quatro famílias estão à mesma distância de croma e de luminância entre si, para que
/// nenhuma pareça mais importante que a outra por acidente de cor.
///
/// Contraste conferido em todos os pares: `ink` sobre `wash` fica entre 4,6:1 e 6,2:1 no
/// claro, e acima de 8:1 no escuro; `onTone` sobre `tone`, entre 5,0:1 e 7,9:1.
///
/// **Os lavados do tema escuro subiram um degrau** quando o fundo do app virou preto absoluto.
/// Contra o quase-preto anterior eles já se destacavam; contra o #000 o problema é outro — a
/// borda do ladrilho precisa ser inequívoca, senão o bloco parece um retângulo de texto solto
/// no escuro em vez de uma peça apoiada sobre a tela.
class BlockColors {
  const BlockColors({
    required this.tone,
    required this.onTone,
    required this.wash,
    required this.ink,
  });

  /// O fundo cheio do bloco herói.
  final Color tone;

  /// Texto e ícone sobre [tone].
  final Color onTone;

  /// O fundo lavado do ladrilho.
  final Color wash;

  /// O número e o ícone sobre [wash]. É a cor da família em força total.
  final Color ink;
}

/// As cores por assunto, nos dois temas.
abstract final class Blocks {
  /// **Nutrição — esmeralda.** É a cor da marca (`#059669` nos e-mails e no front React), e
  /// fica com o assunto mais consultado do app.
  static BlockColors nutrition(Brightness b) => b == Brightness.dark
      ? const BlockColors(
          tone: Color(0xFF0B5F45),
          onTone: Color(0xFFD6F5E7),
          wash: Color(0xFF12291F),
          ink: Color(0xFF34D399),
        )
      : const BlockColors(
          tone: Color(0xFF047857),
          onTone: Color(0xFFFFFFFF),
          wash: Color(0xFFDCF5EA),
          ink: Color(0xFF047857),
        );

  /// **Treino — índigo.** Longe o suficiente do esmeralda para os dois blocos nunca serem
  /// confundidos de relance, que é a única coisa que a cor precisa garantir aqui.
  static BlockColors workout(Brightness b) => b == Brightness.dark
      ? const BlockColors(
          tone: Color(0xFF3730A3),
          onTone: Color(0xFFE0E7FF),
          wash: Color(0xFF1D1D3B),
          ink: Color(0xFFA5B4FC),
        )
      : const BlockColors(
          tone: Color(0xFF4338CA),
          onTone: Color(0xFFFFFFFF),
          wash: Color(0xFFE4E3FB),
          ink: Color(0xFF4338CA),
        );

  /// **Progresso — âmbar.** Cobre os dois ladrilhos que medem o tempo passando — a constância
  /// da semana e o peso corporal —, e os dois levam ao mesmo lugar, `/progresso`. Duas peças
  /// da mesma cor lado a lado é o que faz o olho lê-las como um grupo sem precisar de um
  /// título por cima dizendo que são.
  static BlockColors progress(Brightness b) => b == Brightness.dark
      ? const BlockColors(
          tone: Color(0xFF92400E),
          onTone: Color(0xFFFEF3C7),
          wash: Color(0xFF2E231A),
          ink: Color(0xFFFBBF24),
        )
      : const BlockColors(
          tone: Color(0xFFB45309),
          onTone: Color(0xFFFFFFFF),
          // Mais claro que os outros lavados de propósito: o âmbar é a família mais escura
          // das quatro, e sobre um fundo do mesmo tom dos demais ele não alcançava 4,5:1.
          wash: Color(0xFFFDF3E6),
          ink: Color(0xFFB45309),
        );

  /// **Conquista — magenta.** A única família que não descreve uma rotina, e por isso a
  /// única que pode ser festiva sem mentir.
  static BlockColors award(Brightness b) => b == Brightness.dark
      ? const BlockColors(
          tone: Color(0xFF9D174D),
          onTone: Color(0xFFFCE7F3),
          wash: Color(0xFF311828),
          ink: Color(0xFFF472B6),
        )
      : const BlockColors(
          tone: Color(0xFFBE185D),
          onTone: Color(0xFFFFFFFF),
          wash: Color(0xFFFBE3EC),
          ink: Color(0xFFBE185D),
        );

  /// **Sem família.** Para o que é procedimento e não assunto — fechar o dia, a fila do
  /// revisor, um passo de configuração. Dar cor a tudo é o mesmo que não dar cor a nada.
  static BlockColors neutral(ColorScheme scheme) => BlockColors(
    tone: scheme.inverseSurface,
    onTone: scheme.onInverseSurface,
    wash: scheme.surfaceContainerHigh,
    ink: scheme.onSurface,
  );
}
