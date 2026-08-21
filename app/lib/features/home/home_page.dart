import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/design/materials.dart';
import '../../core/design/tokens.dart';
import '../../core/sync/sync_queue.dart';
import '../analysis/analysis_page.dart';
import '../checkin/weigh_in.dart';
import '../coach/coach_fab.dart';
import '../dashboard/progress_page.dart';
import '../nutrition/nutrition_page.dart';
import 'account_avatar.dart';
import 'today_page.dart';

/// As quatro abas do app.
///
/// Quatro e não seis: a barra do Material cabe cinco, mas o quinto item só teria assunto
/// para quem revisa planos — e revisor é minoria. A fila dele entra como cartão na aba Hoje,
/// que é onde ele já vai olhar.
///
/// **O Perfil saiu da barra e o Progresso entrou no lugar dele.** A troca é de natureza: as
/// outras três abas são coisas que se *consulta* — quanto ainda cabe hoje, o que a câmera
/// achou, quanto ainda falta —, e o Progresso é a quarta pergunta da mesma família ("estou
/// evoluindo?"), a única que ninguém responde de cabeça e que estava enterrada dentro da folha
/// do avatar. O Perfil é o contrário: assinatura, conta, objetivo, exclusão de dados — coisas
/// que se mexe uma vez e não se olha de novo, e que qualquer app põe atrás do avatar. Ele
/// continua com rota própria (`/perfil`) e agora é o primeiro item dessa folha.
enum HomeTab {
  /// Sem título: a Hoje desenha o próprio cabeçalho — ele materializa com a rolagem e leva o
  /// anel em miniatura quando o grande sai de cena. Uma barra escrevendo "MyoTrack" acima
  /// dele gastaria a tira mais valiosa da tela repetindo o que o usuário já sabe.
  today('Hoje', Icons.today_outlined, Icons.today, null),
  nutrition(
    'Nutrição',
    Icons.restaurant_outlined,
    Icons.restaurant,
    'Nutrição',
  ),
  analysis(
    'Analisar',
    Icons.center_focus_strong_outlined,
    Icons.center_focus_strong,
    'Analisar',
  ),
  progress('Progresso', Icons.insights_outlined, Icons.insights, 'Progresso');

  const HomeTab(this.label, this.icon, this.selectedIcon, this.title);

  /// Texto sob o ícone na barra.
  final String label;

  final IconData icon;
  final IconData selectedIcon;

  /// Título da barra superior enquanto a aba está aberta. Null na aba que traz o próprio
  /// cabeçalho.
  final String? title;
}

/// Aba aberta no shell.
///
/// Mora num provider, e não no `State` da tela, porque quem troca de aba nem sempre é a
/// barra: a folha de captura rápida manda o usuário para Analisar, e ela é um diálogo — não
/// enxerga o estado do widget que a abriu.
final homeTabProvider = StateProvider<HomeTab>((ref) => HomeTab.today);

/// O shell do app: barra inferior, os dois flutuantes e a aba corrente.
///
/// Todas as telas continuam tendo rota própria — os deep links do e-mail e das notificações
/// apontam para elas, e uma aba não tem endereço. O shell é um segundo caminho, o de quem
/// abriu o app sem link nenhum.
class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tab = ref.watch(homeTabProvider);

    final title = tab.title;

    return Scaffold(
      // **O corpo vai até a base da tela, por baixo da barra de abas.** É o que dá sentido ao
      // vidro dela: o que se vê borrado através da barra é a própria lista continuando, e não
      // um retângulo cinza. Quem reserva o respiro no fim de cada lista é `listBottomInset`,
      // que lê a altura da barra do próprio `Scaffold`.
      extendBody: true,
      // A Hoje abre com o painel do dia, que sangra até o topo da tela e leva o avatar no
      // próprio canto. As outras três continuam com a barra do Material: elas são destinos,
      // e destino precisa dizer o nome.
      appBar: title == null
          ? null
          : AppBar(
              title: Text(title),
              // A margem da direita é a mesma do conteúdo (`Space.gutter`) menos o respiro
              // que o próprio `IconButton` já reserva: sem ela o avatar encosta na borda da
              // tela e some pela metade no recorte da câmera.
              actions: const [
                AccountAvatar(),
                SizedBox(width: Space.gutter - Space.sm),
              ],
            ),
      // `IndexedStack` e não uma troca de filho: o diário rolado, a foto em análise e a
      // conversa pela metade sobrevivem à ida e volta entre abas. Refazer esse estado a cada
      // toque é o que faz um app parecer que esqueceu o que a pessoa fazia.
      //
      // **Mas só depois de a aba ser aberta uma vez** — ver [_LazyIndexedStack].
      body: _LazyIndexedStack(
        index: tab.index,
        children: const [
          TodayView(),
          NutritionView(),
          AnalysisView(),
          ProgressView(),
        ],
      ),
      // Os dois flutuantes ocupam a tira de baixo inteira, um em cada ponta, e cada um tem
      // uma regra de presença diferente.
      //
      // **O coach fica nas quatro abas, sempre à direita.** A pergunta que ele responde
      // ("posso trocar esse exercício?", "isso cabe na minha meta de hoje?") nasce olhando
      // qualquer uma delas, e até aqui o único caminho até a conversa era a folha do avatar —
      // dois toques e um item no meio de seis. À direita porque é o canto onde o polegar
      // chega sem a mão sair do lugar, e porque é o mesmo canto nas quatro: botão que muda de
      // lado conforme a aba obriga a procurá-lo toda vez.
      //
      // **O `Registrar` continua só na Hoje**, agora à esquerda. Nas outras abas a ação
      // principal já está na tela (fotografar, gerar dieta), e um botão repetindo-a esconderia
      // conteúdo por nada.
      //
      // Uma linha e não uma coluna: empilhados, o de cima cobria mais um cartão do mosaico e
      // os dois liam como um controle só de duas partes.
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: SafeArea(
        // Só as laterais: o recorte da câmera em paisagem comeria o botão da ponta. O respiro
        // de baixo é do `Scaffold`, que já conta a barra de navegação.
        top: false,
        bottom: false,
        child: Padding(
          // A mesma margem que o `endFloat` reservaria sozinho. Ela precisa ser escrita aqui
          // porque a linha ocupa a largura toda: sem ela, cada botão encostaria na sua borda.
          padding: const EdgeInsets.symmetric(horizontal: Space.md),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Nas outras três abas a ponta esquerda fica vazia, e o `spaceBetween` empurra
              // o coach para a direita do mesmo jeito — é o que mantém o canto dele estável.
              if (tab == HomeTab.today)
                FloatingActionButton.extended(
                  heroTag: 'registrar-fab',
                  onPressed: () => showQuickCaptureSheet(context, ref),
                  icon: const Icon(Icons.add),
                  label: const Text('Registrar'),
                )
              else
                const SizedBox.shrink(),
              const CoachFab(),
            ],
          ),
        ),
      ),
      // A barra é de vidro, e por isso ela mesma não pinta fundo nenhum — quem pinta é o
      // `GlassChrome`, que borra ao vivo o que passa por baixo. A borda em cima é a única
      // coisa que separa a barra do conteúdo; sem ela, com a lista rolando atrás, não dá para
      // dizer onde a moldura começa.
      bottomNavigationBar: GlassChrome(
        edge: GlassEdgeSide.top,
        child: SafeArea(
          top: false,
          child: NavigationBar(
            selectedIndex: tab.index,
            onDestinationSelected: (index) =>
                ref.read(homeTabProvider.notifier).state =
                    HomeTab.values[index],
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

/// Um `IndexedStack` que só constrói a aba depois de a pessoa ter ido nela.
///
/// **O `IndexedStack` puro constrói os quatro filhos no primeiro quadro** — é assim que ele
/// preserva o estado das abas que não estão à vista. Enquanto as quatro eram telas passivas
/// isso custava só trabalho adiantado. Deixou de ser quando o Progresso entrou na barra: ele
/// carrega a comemoração das conquistas, e ela **marca como vista** a novidade no primeiro
/// quadro em que aparece. Montado junto com o shell, ele apagava o aviso de conquista nova da
/// Hoje antes de o usuário ter visto conquista nenhuma — o prêmio era consumido pelo app.
///
/// Guardando quais abas já foram abertas resolve o caso e ainda paga outra conta: no arranque
/// o app dispara as chamadas de uma aba, não de quatro. E o que o `IndexedStack` garante
/// continua valendo, porque só vale para aba que já existiu.
class _LazyIndexedStack extends StatefulWidget {
  const _LazyIndexedStack({required this.index, required this.children});

  final int index;
  final List<Widget> children;

  @override
  State<_LazyIndexedStack> createState() => _LazyIndexedStackState();
}

class _LazyIndexedStackState extends State<_LazyIndexedStack> {
  late final Set<int> _visited = {widget.index};

  @override
  void didUpdateWidget(_LazyIndexedStack old) {
    super.didUpdateWidget(old);
    _visited.add(widget.index);
  }

  @override
  Widget build(BuildContext context) {
    return IndexedStack(
      index: widget.index,
      children: [
        for (var i = 0; i < widget.children.length; i++)
          if (_visited.contains(i))
            widget.children[i]
          else
            // Uma caixa vazia e não `SizedBox.shrink()`: o `IndexedStack` dimensiona a pilha
            // pelo maior filho, e um filho de tamanho zero no meio não muda nada — mas um
            // `const SizedBox()` deixa claro na árvore que ali existe uma aba ainda não
            // visitada, e não um erro de construção.
            const SizedBox(),
      ],
    );
  }
}

/// Captura rápida: as três coisas que se registra no meio do dia.
///
/// Existe porque cada uma delas mora numa tela diferente, e no momento em que o prato está
/// na mesa ninguém quer navegar. Duas levam para a aba Analisar já na sub-aba certa; a
/// terceira resolve ali mesmo.
///
/// **Registrar treino não está aqui, e é de propósito.** As três que ficaram terminam num
/// toque ou numa foto; lançar séries e cargas é uma sessão inteira de digitação, que nada
/// tem de rápida. Ela continua a um toque de distância na folha do avatar e no Progresso —
/// ver `accountDestinations`.
Future<void> showQuickCaptureSheet(BuildContext context, WidgetRef ref) {
  return showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    // Rolável e sem teto de altura fixo: com a fonte do sistema ampliada três itens com
    // legenda ainda passam do limite de 9/16 da tela num celular pequeno — e aí a última
    // opção ficaria cortada em vez de alcançável.
    isScrollControlled: true,
    builder: (sheetContext) => SafeArea(
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 12),
              child: Text(
                'O que você quer registrar?',
                style: Theme.of(sheetContext).textTheme.titleSmall,
              ),
            ),
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined),
              title: const Text('Fotografar refeição'),
              subtitle: const Text('A IA estima calorias e macros'),
              onTap: () {
                Navigator.of(sheetContext).pop();
                ref.read(analysisTabProvider.notifier).state = AnalysisTab.meal;
                ref.read(homeTabProvider.notifier).state = HomeTab.analysis;
              },
            ),
            ListTile(
              leading: const Icon(Icons.videocam_outlined),
              title: const Text('Gravar execução'),
              subtitle: const Text('Veja onde a técnica sai do lugar'),
              onTap: () {
                Navigator.of(sheetContext).pop();
                ref.read(analysisTabProvider.notifier).state = AnalysisTab.form;
                ref.read(homeTabProvider.notifier).state = HomeTab.analysis;
              },
            ),
            ListTile(
              leading: const Icon(Icons.monitor_weight_outlined),
              title: const Text('Anotar peso'),
              subtitle: const Text('Alimenta o gráfico e as metas da dieta'),
              onTap: () {
                Navigator.of(sheetContext).pop();
                showWeighInDialog(context);
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    ),
  );
}

/// Pesagem avulsa, sem passar pelo registro de treino.
///
/// Um campo só. A tela de `/registrar` pede peso junto com as séries, e é o caminho de quem
/// acabou de treinar; quem sobe na balança de manhã não tem série nenhuma para lançar.
Future<void> showWeighInDialog(BuildContext context) async {
  final weight = await askWeightKg(context, title: 'Anotar peso');

  if (weight == null || !context.mounted) {
    return;
  }

  final messenger = ScaffoldMessenger.of(context);
  final outcome = await saveWeighIn(containerOf(context), weight);

  messenger
    ..clearSnackBars()
    ..showSnackBar(
      SnackBar(
        content: Text(
          outcome == WriteOutcome.sent
              ? 'Peso registrado.'
              : 'Peso guardado no aparelho. Sobe quando houver rede.',
        ),
      ),
    );
}
