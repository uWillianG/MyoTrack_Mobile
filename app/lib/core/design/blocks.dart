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
    required this.onGlass,
    required this.wash,
    required this.ink,
  });

  /// O fundo cheio de um controle da família: o dia escolhido no diário, o balão da própria
  /// mensagem no coach, o botão de enviar.
  ///
  /// **Não é mais o fundo do herói** — esse virou vidro. Sobrou para o que precisa de cor
  /// chapada porque precisa gritar que está *selecionado* ou que é *a ação*.
  final Color tone;

  /// Texto e ícone sobre [tone].
  final Color onTone;

  /// **O texto de corpo sobre o vidro desta família.**
  ///
  /// É um quase-branco (ou um quase-preto, no tema claro) com um traço do matiz da família —
  /// o suficiente para o herói de treino e o de nutrição não parecerem a mesma peça, longe o
  /// bastante da cor cheia para uma frase inteira não sair colorida. Quem carrega a família em
  /// força total é [ink], e ele fica no rótulo, no ícone e no número.
  ///
  /// Existe separado de [onTone] porque as duas superfícies são opostas: sobre a cor cheia o
  /// texto precisa ser claro no tema claro (branco sobre esmeralda), e sobre o vidro ele
  /// precisa ser escuro (quase-preto sobre branco translúcido). Um campo só cobria os dois
  /// enquanto o herói era pintado; com vidro, ele erraria metade dos casos.
  final Color onGlass;

  /// Um fundo lavado da família, e a cor do texto sobre [ink] quando ele vira botão.
  final Color wash;

  /// O número e o ícone da família em força total.
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
          onGlass: Color(0xFFDDF3E9),
          wash: Color(0xFF12291F),
          ink: Color(0xFF34D399),
        )
      : const BlockColors(
          tone: Color(0xFF047857),
          onTone: Color(0xFFFFFFFF),
          onGlass: Color(0xFF0A2E22),
          wash: Color(0xFFDCF5EA),
          ink: Color(0xFF047857),
        );

  /// **Treino — índigo.** Longe o suficiente do esmeralda para os dois blocos nunca serem
  /// confundidos de relance, que é a única coisa que a cor precisa garantir aqui.
  static BlockColors workout(Brightness b) => b == Brightness.dark
      ? const BlockColors(
          tone: Color(0xFF3730A3),
          onTone: Color(0xFFE0E7FF),
          onGlass: Color(0xFFE4E8F5),
          wash: Color(0xFF1D1D3B),
          ink: Color(0xFFA5B4FC),
        )
      : const BlockColors(
          tone: Color(0xFF4338CA),
          onTone: Color(0xFFFFFFFF),
          onGlass: Color(0xFF171545),
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
          onGlass: Color(0xFFF3EDE2),
          wash: Color(0xFF2E231A),
          ink: Color(0xFFFBBF24),
        )
      : const BlockColors(
          tone: Color(0xFFB45309),
          onTone: Color(0xFFFFFFFF),
          onGlass: Color(0xFF3A2508),
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
          onGlass: Color(0xFFF4E6ED),
          wash: Color(0xFF311828),
          ink: Color(0xFFF472B6),
        )
      : const BlockColors(
          tone: Color(0xFFBE185D),
          onTone: Color(0xFFFFFFFF),
          onGlass: Color(0xFF4A0F2A),
          wash: Color(0xFFFBE3EC),
          ink: Color(0xFFBE185D),
        );

  /// **Sem família.** Para o que é procedimento e não assunto — fechar o dia, a fila do
  /// revisor, um passo de configuração, a conversa com o coach. Dar cor a tudo é o mesmo que
  /// não dar cor a nada.
  ///
  /// **O lavado sobe um degrau no tema claro**, e o motivo é o mesmo que fez os lavados escuros
  /// subirem quando o fundo virou preto: separação. As quatro famílias se destacam pelo matiz,
  /// e o neutro só tem a luminância — com `surfaceContainerHigh` (#F0F2F1) sobre a página
  /// (#F7F8F8) sobram sete pontos de diferença, e no Perfil as seções sem cor apareciam como
  /// retângulos fantasmas ao lado das coloridas. No escuro o degrau atual já basta: contra o
  /// #000 qualquer superfície se afirma, e subir mais faria o neutro gritar mais alto que as
  /// famílias, invertendo a hierarquia.
  static BlockColors neutral(ColorScheme scheme) => BlockColors(
    tone: scheme.inverseSurface,
    onTone: scheme.onInverseSurface,
    // Sem família, sem traço de matiz: o neutro sobre vidro é simplesmente a tinta do tema.
    onGlass: scheme.onSurface,
    wash: scheme.brightness == Brightness.light
        ? scheme.surfaceContainerHighest
        : scheme.surfaceContainerHigh,
    ink: scheme.onSurface,
  );
}
