import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/design/materials.dart';
import '../../core/router.dart';
import 'home_page.dart';

/// A moldura de baixo, em todas as telas de quem tem sessão.
///
/// **A barra saiu da home e virou o chão do app.** Enquanto ela morava dentro da tela das
/// quatro abas, sair para qualquer outra — o plano de treino, o coach, a assinatura — deixava
/// a pessoa sem nenhum ponto de referência: o único caminho de volta era a seta do canto, e
/// com duas telas empilhadas ela vira um caminho às cegas. Com a barra sempre presente, ir
/// para o coach ler uma resposta e voltar para a Nutrição é um toque, e o app deixa de ter
/// dois modos de navegar — um "dentro das abas" e outro "fora delas".
///
/// **Onde ela não aparece:** login e cadastro, esqueci-a-senha, redefinir senha e o splash.
/// Todas ficam fora deste shell no roteador, e não escondidas por um `if` daqui — quem ainda
/// não tem sessão não tem para onde a barra levar, e um destino que responde com a tela de
/// login é pior que destino nenhum.
///
/// **A aba acesa continua sendo a do provider, mesmo numa tela empilhada.** É a aba de onde a
/// pessoa saiu, e é para onde o toque na barra a devolve — apagar as quatro enquanto o coach
/// está aberto faria a barra parecer desligada justamente quando ela é o caminho de volta.
class AppShell extends ConsumerWidget {
  const AppShell({super.key, required this.location, required this.child});

  /// Rota corrente, vinda do `ShellRoute`. Serve para uma decisão só: se o toque na barra
  /// precisa desempilhar alguma coisa antes de trocar de aba.
  final String location;

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tab = ref.watch(homeTabProvider);

    return Scaffold(
      // **O corpo vai até a base da tela, por baixo da barra.** É o que dá sentido ao vidro
      // dela: o que se vê borrado através da barra é a própria lista continuando, e não um
      // retângulo cinza. Em troca, cada tela precisa reservar o respiro do fim da rolagem —
      // é o que `screenBottomInset` faz, lendo a altura que o `Scaffold` publica aqui.
      extendBody: true,
      body: _ChromeInset(child: child),
      bottomNavigationBar: GlassChrome(
        edge: GlassEdgeSide.top,
        child: SafeArea(
          top: false,
          child: NavigationBar(
            selectedIndex: tab.index,
            onDestinationSelected: (index) {
              ref.read(homeTabProvider.notifier).state = HomeTab.values[index];

              // Numa tela empilhada o toque tem duas partes: trocar a aba e voltar para ela.
              // `go` e não `pop`: a pilha pode ter mais de uma tela — do plano para o modo
              // treino, por exemplo — e um `pop` só devolveria a pessoa à do meio.
              //
              // Na própria home ele não é chamado de propósito: `go` na rota em que já se
              // está remonta o shell da home e leva junto o estado das abas — o diário
              // rolado, a conversa pela metade — que é justamente o que o `IndexedStack`
              // existe para preservar.
              if (location != Routes.home) {
                context.go(Routes.home);
              }
            },
            destinations: [
              for (final destination in HomeTab.values)
                NavigationDestination(
                  icon: Icon(destination.icon),
                  selectedIcon: Icon(destination.selectedIcon),
                  label: destination.label,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Repassa a altura da barra também como `viewPadding`.
///
/// O `Scaffold` com `extendBody` anuncia a barra no `padding` do `MediaQuery`, e é dali que
/// sai o respiro do fim das listas. Só que o `Scaffold` **de dentro** de cada tela não decide
/// a posição do que flutua pelo `padding`, e sim pelo `viewPadding` — que continua sendo só o
/// recorte do sistema. Sem espelhar um no outro, o botão flutuante da Hoje pousaria atrás da
/// barra de vidro, meio escondido, e o mesmo valeria para qualquer `SafeArea` de tela
/// empilhada. Do ponto de vista de quem está dentro, a barra é um recorte do aparelho como
/// outro qualquer — e é assim que ela é anunciada.
class _ChromeInset extends StatelessWidget {
  const _ChromeInset({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final metrics = MediaQuery.of(context);

    return MediaQuery(
      data: metrics.copyWith(
        viewPadding: metrics.viewPadding.copyWith(
          bottom: metrics.padding.bottom,
        ),
      ),
      child: child,
    );
  }
}
