import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/design/tokens.dart';
import '../../core/router.dart';
import '../../core/sync/sync_queue.dart';
import '../analysis/analysis_page.dart';
import '../checkin/weigh_in.dart';
import '../nutrition/nutrition_page.dart';
import '../profile/profile_page.dart';
import 'account_avatar.dart';
import 'today_page.dart';

/// As quatro abas do app.
///
/// Quatro e não seis: a barra do Material cabe cinco, mas o quinto item só teria assunto
/// para quem revisa planos — e revisor é minoria. A fila dele entra como cartão na aba Hoje,
/// que é onde ele já vai olhar.
enum HomeTab {
  /// Sem título: a Hoje desenha o próprio cabeçalho — o painel escuro com a data e as
  /// calorias, que ocupa o lugar da barra superior. Uma barra escrevendo "MyoTrack" acima
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
  profile('Perfil', Icons.person_outline, Icons.person, 'Meu perfil');

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

/// O shell do app: barra inferior, botão de registrar e a aba corrente.
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
      // `IndexedStack` e não uma troca de filho: o diário rolado, a foto em análise e o
      // formulário do perfil pela metade sobrevivem à ida e volta entre abas. Refazer esse
      // estado a cada toque é o que faz um app parecer que esqueceu o que a pessoa fazia.
      body: IndexedStack(
        index: tab.index,
        children: const [
          TodayView(),
          NutritionView(),
          AnalysisView(),
          ProfileView(),
        ],
      ),
      // Só na Hoje. Nas outras abas a ação principal já está na tela (fotografar, gerar
      // dieta), e um botão flutuante repetindo-a esconderia conteúdo por nada.
      floatingActionButton: tab == HomeTab.today
          ? FloatingActionButton.extended(
              onPressed: () => showQuickCaptureSheet(context, ref),
              icon: const Icon(Icons.add),
              label: const Text('Registrar'),
            )
          : null,
      bottomNavigationBar: NavigationBar(
        selectedIndex: tab.index,
        onDestinationSelected: (index) =>
            ref.read(homeTabProvider.notifier).state = HomeTab.values[index],
        destinations: [
          for (final destination in HomeTab.values)
            NavigationDestination(
              icon: Icon(destination.icon),
              selectedIcon: Icon(destination.selectedIcon),
              label: destination.label,
            ),
        ],
      ),
    );
  }
}

/// Captura rápida: as quatro coisas que se registra no meio do dia.
///
/// Existe porque cada uma delas mora numa tela diferente, e no momento em que o prato está
/// na mesa ninguém quer navegar. Duas levam para a aba Analisar já na sub-aba certa; as
/// outras duas resolvem ali mesmo.
Future<void> showQuickCaptureSheet(BuildContext context, WidgetRef ref) {
  return showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    // Rolável e sem teto de altura fixo: quatro itens com legenda já encostam no limite de
    // 9/16 da tela num celular pequeno, e com a fonte do sistema ampliada passariam dele —
    // aí a última opção ficaria cortada em vez de alcançável.
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
              leading: const Icon(Icons.fitness_center_outlined),
              title: const Text('Registrar treino'),
              subtitle: const Text('Séries e cargas — funciona offline'),
              onTap: () {
                Navigator.of(sheetContext).pop();
                context.push(Routes.logSession);
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
