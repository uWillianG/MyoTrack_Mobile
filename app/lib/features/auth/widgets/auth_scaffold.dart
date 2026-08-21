import 'package:flutter/material.dart';

import '../../../core/design/materials.dart';
import '../../../core/design/tokens.dart';

/// A moldura das telas de fora do app — entrar, criar conta, esqueci a senha, senha nova.
///
/// **É a primeira tela do produto, e por muito tempo foi a única que não pertencia ao
/// sistema**: fundo chapado, formulário solto no meio, nenhuma das superfícies que o resto do
/// app usa. Aqui ela passa a ser feita do mesmo material das outras — o cartão de vidro de
/// `materials.dart` — e ganha a única coisa que nenhuma outra tela tem: um fundo com a cor da
/// marca.
///
/// **Por que o brilho atrás.** Vidro precisa de alguma coisa atrás para ser vidro; sobre fundo
/// liso o véu translúcido é indistinguível de um cinza pintado. Nas telas de sessão quem passa
/// por trás é o conteúdo rolando. Aqui não há conteúdo — então entra o brilho da marca,
/// esmeralda e âmbar, os dois muito fracos e **parados**. Parados de propósito: fundo que se
/// mexe atrás de um formulário é o que a diretriz de movimento reduzido pede para não existir,
/// e ele estaria na tela justamente enquanto se lê e se digita.
///
/// O borrão do cartão fica desligado pela regra de `materials.dart`: borrar um degradê suave
/// devolve o mesmo degradê, e cobra uma passada de composição inteira por isso.
class AuthScaffold extends StatelessWidget {
  const AuthScaffold({required this.subtitle, required this.child, super.key});

  /// A frase que muda com o que a tela está pedindo. Ela troca por transição, e não por corte:
  /// entre o login e o cadastro o resto da moldura é o mesmo, e um texto que pisca no meio de
  /// uma tela parada é o único movimento que se vê — parece defeito.
  final String subtitle;

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: Stack(
        children: [
          const Positioned.fill(child: _BrandGlow()),
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                // Rola por padrão: com o teclado aberto num aparelho pequeno, o formulário de
                // cadastro não cabe entre a marca e a base.
                padding: const EdgeInsets.symmetric(
                  horizontal: Space.gutter,
                  vertical: Space.xxl,
                ),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 420),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const _AppMark(),
                      const SizedBox(height: Space.md),
                      RichText(
                        textAlign: TextAlign.center,
                        text: TextSpan(
                          style: theme.textTheme.headlineLarge,
                          children: [
                            TextSpan(
                              text: 'Myo',
                              style: TextStyle(
                                color: theme.colorScheme.onSurface,
                              ),
                            ),
                            TextSpan(
                              text: 'Track',
                              style: TextStyle(
                                color: theme.colorScheme.primary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: Space.xs),
                      _Subtitle(subtitle),
                      const SizedBox(height: Space.xl),
                      GlassPanel(
                        padding: const EdgeInsets.all(Space.xl),
                        child: child,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// O ícone do app, no formato do ícone do app.
///
/// Superelipse e não retângulo arredondado: é a forma que o sistema desenha em volta de todo
/// ícone na tela inicial, e reencontrar a mesma silhueta no primeiro quadro depois do toque é o
/// que costura o app ao aparelho. Com raio comum é o mesmo ícone com as quinas erradas — dá
/// para não saber apontar o que mudou e ainda assim achar estranho.
class _AppMark extends StatelessWidget {
  const _AppMark();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      height: 64,
      width: 64,
      alignment: Alignment.center,
      decoration: ShapeDecoration(
        shape: RoundedSuperellipseBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        // Esmeralda com brilho, e não esmeralda para âmbar: no tema claro o caminho entre o
        // verde escuro e o âmbar passa por um oliva que suja o meio do ícone. O âmbar continua
        // na tela — é a segunda mancha do fundo —, só não atravessa a marca.
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color.lerp(theme.colorScheme.primary, Colors.white, 0.28)!,
            theme.colorScheme.primary,
          ],
        ),
        // Sem sombra: uma peça de 64 dp em cor cheia já se separa da página sozinha, e a
        // sombra de elevação — desenhada para folha e diálogo — desenha uma segunda silhueta
        // cinzenta embaixo do ícone, que é a cara de adesivo colado na tela.
      ),
      child: Text(
        'M',
        style: theme.textTheme.headlineMedium?.copyWith(
          color: Colors.white,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _Subtitle extends StatelessWidget {
  const _Subtitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AnimatedSwitcher(
      duration: Motion.base,
      switchInCurve: Motion.enter,
      switchOutCurve: Motion.exit,
      // Sobe entrando e sobe saindo, pelo mesmo caminho: a frase nova empurra a antiga em vez
      // de as duas se cruzarem em direções opostas.
      transitionBuilder: (child, animation) => FadeTransition(
        opacity: animation,
        child: SlideTransition(
          position: Tween(
            begin: const Offset(0, 0.35),
            end: Offset.zero,
          ).animate(animation),
          child: child,
        ),
      ),
      child: Text(
        text,
        key: ValueKey(text),
        textAlign: TextAlign.center,
        style: theme.textTheme.bodyMedium?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}

/// O brilho da marca por trás do vidro.
///
/// Dois degradês radiais que morrem em transparente — e não círculos borrados. Um
/// `BackdropFilter` ou uma sombra de raio grande cobrariam uma passada de composição para
/// chegar ao mesmo resultado que um degradê já é.
///
/// Some no modo de alto contraste: ali a regra é fundo definido e limite escrito, e um véu de
/// cor atrás do texto é exatamente o que atrapalha quem pediu esse modo.
class _BrandGlow extends StatelessWidget {
  const _BrandGlow();

  @override
  Widget build(BuildContext context) {
    if (MediaQuery.highContrastOf(context)) {
      return const SizedBox.shrink();
    }

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return IgnorePointer(
      child: Stack(
        children: [
          Positioned(
            top: -160,
            left: -110,
            child: _Glow(
              color: theme.colorScheme.primary,
              alpha: isDark ? 0.26 : 0.20,
              size: 420,
            ),
          ),
          Positioned(
            bottom: -190,
            right: -140,
            child: _Glow(
              color: theme.colorScheme.tertiary,
              alpha: isDark ? 0.18 : 0.16,
              size: 460,
            ),
          ),
        ],
      ),
    );
  }
}

class _Glow extends StatelessWidget {
  const _Glow({required this.color, required this.alpha, required this.size});

  final Color color;
  final double alpha;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: size,
      width: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [
            color.withValues(alpha: alpha),
            color.withValues(alpha: alpha * 0.35),
            color.withValues(alpha: 0),
          ],
          // A parada do meio é o que impede o degradê de virar anel: com dois pontos só, a
          // queda de opacidade é linear e o olho acha a borda do círculo.
          stops: const [0, 0.45, 1],
        ),
      ),
    );
  }
}
