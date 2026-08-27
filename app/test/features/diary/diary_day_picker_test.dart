import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:myotrack/core/jobs/generation_controller.dart';
import 'package:myotrack/core/router.dart';
import 'package:myotrack/core/theme.dart';
import 'package:myotrack/features/analysis/analysis_page.dart';
import 'package:myotrack/features/diary/diary_controller.dart';
import 'package:myotrack/features/diary/diary_page.dart';
import 'package:myotrack/features/home/home_page.dart';
import 'package:myotrack/features/meals/meal_analysis_controller.dart';

import '../home/home_test_harness.dart';

/// O diário trocou as setas por sete alvos. O que estes testes fixam é o que a troca pode
/// quebrar: a semana continuar terminando em hoje, e o dia futuro continuar inalcançável.
///
/// E, desde que a captura virou uma fileira de portas de ícone, o que o toque em cada uma faz:
/// a foto é escolhida **antes** de a pessoa mudar de tela, e a mudança acontece **antes** de o
/// envio começar. As duas ordens têm um jeito errado de sair, e nenhum dos dois estoura sozinho.
/// O dia que a rota da refeição manual recebeu por `extra`, guardado pelo marcador da rota.
DateTime? _manualDay;

void main() {
  const smallPhone = Size(360, 800);

  setUp(() => _manualDay = null);

  Future<ProviderContainer> pump(
    WidgetTester tester, {
    Brightness brightness = Brightness.light,
    List<Override> extra = const [],
  }) async {
    tester.view.physicalSize = smallPhone;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final container = ProviderContainer(
      overrides: [...homeOverrides(), ...extra],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp.router(
          theme: brightness == Brightness.light
              ? AppTheme.light()
              : AppTheme.dark(),
          routerConfig: GoRouter(
            routes: [
              GoRoute(
                path: '/',
                builder: (_, _) => const Scaffold(body: DiaryView()),
              ),
              // A rota que o herói empilha quando o diário **não** está dentro do hub — é o
              // caso de quem chegou por link de e-mail. Um marcador basta: o que se prova aqui
              // é o caminho, e a tela de refeições tem testes próprios.
              GoRoute(
                path: Routes.mealAnalysis,
                builder: (_, _) => const Scaffold(body: Text('refeições')),
              ),
              // A rota da refeição sem foto. Um marcador basta, como acima — o que se prova
              // aqui é o caminho e a data que vai por `extra`; a tela tem testes próprios.
              GoRoute(
                path: Routes.manualMeal,
                builder: (_, state) {
                  _manualDay = state.extra as DateTime?;
                  return const Scaffold(body: Text('refeição manual'));
                },
              ),
            ],
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    return container;
  }

  DateTime dateOnly(DateTime date) => DateTime(date.year, date.month, date.day);

  testWidgets('mostra os sete últimos dias, terminando em hoje', (
    tester,
  ) async {
    await pump(tester);

    final today = dateOnly(DateTime.now());
    for (var back = 0; back < 7; back++) {
      final day = today.subtract(Duration(days: back));
      expect(find.text('${day.day}'), findsWidgets, reason: '${day.day}');
    }

    // Amanhã não: o diário registra o que foi comido, e um dia futuro só poderia estar
    // vazio — o usuário acharia que perdeu dados.
    final tomorrow = today.add(const Duration(days: 1));
    expect(find.text('${tomorrow.day}'), findsNothing);
  });

  testWidgets('tocar num dia troca o dia aberto', (tester) async {
    final container = await pump(tester);

    final target = dateOnly(DateTime.now()).subtract(const Duration(days: 3));
    await tester.tap(find.text('${target.day}').first);
    await tester.pumpAndSettle();

    expect(container.read(diaryDateProvider), target);
  });

  for (final brightness in Brightness.values) {
    testWidgets('o diário cabe na tela (${brightness.name})', (tester) async {
      await pump(tester, brightness: brightness);

      expect(tester.takeException(), isNull);
      // O que fecha o ciclo: é no diário que a falta aparece, e é dali que se registra o que
      // faltou. **Por tooltip e não por texto**: a captura deixou de ser um botão escrito e
      // virou uma fileira de ícones, e o nome passou a ser o que o leitor de tela anuncia e o
      // que surge ao segurar o alvo. Ele continua sendo o mesmo da folha de captura rápida, de
      // propósito — dois caminhos para o mesmo recurso não podem ter nomes diferentes.
      expect(find.byTooltip('Fotografar refeição'), findsOne);
      // E a galeria entrou ao lado dela, com o nome que já tem na aba Analisar: metade das
      // fotos de prato já está no rolo quando alguém lembra de registrar o almoço.
      expect(find.byTooltip('Escolher da galeria'), findsOne);
      // A terceira porta: registrar sem foto nenhuma. É o caso que o diário não atendia — a
      // pessoa lembra do almoço às nove da noite, e não há prato para fotografar.
      expect(find.byTooltip('Registrar sem foto'), findsOne);
      // A câmera fecha a fileira à direita, como na Analisar. A mesma captura com a porta da
      // frente em pontas opostas conforme a tela seria vocabulário divergindo entre dois
      // caminhos para o mesmo recurso.
      expect(
        tester.getCenter(find.byTooltip('Escolher da galeria')).dx,
        lessThan(tester.getCenter(find.byTooltip('Fotografar refeição')).dx),
      );
      // E a nova entra **à esquerda** das que já existiam, que é onde `HeroDoors` a espera: a
      // fileira cresce para dentro do vazio em vez de espremer as vizinhas, e o peso continua
      // subindo até a porta da frente.
      expect(
        tester.getCenter(find.byTooltip('Registrar sem foto')).dx,
        lessThan(tester.getCenter(find.byTooltip('Escolher da galeria')).dx),
      );
    });
  }

  testWidgets('a porta manual empilha a rota, com o dia que está na tela', (
    tester,
  ) async {
    // **Empilha mesmo dentro do hub**, ao contrário da câmera: lá a troca de aba leva à tela
    // onde o progresso da análise aparece; aqui o trabalho é montar a refeição, e ele só
    // existe na tela que está sendo aberta.
    final container = await pump(tester);
    container.read(homeTabProvider.notifier).state = HomeTab.nutrition;

    final ontem = dateOnly(DateTime.now()).subtract(const Duration(days: 1));
    container.read(diaryDateProvider.notifier).state = ontem;
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Registrar sem foto'));
    await tester.pumpAndSettle();

    expect(find.text('refeição manual'), findsOne);
    // A data vai por `extra`, e é a **desta página** do carrossel: no meio de um arrasto há
    // duas páginas vivas, e "o dia aberto" pode já ser o vizinho quando o toque chegar.
    expect(_manualDay, ontem);
    // E a aba não mudou: quem estava na Nutrição volta para ela ao fechar a tela.
    expect(container.read(homeTabProvider), HomeTab.nutrition);
  });

  testWidgets('a câmera do herói escolhe a foto e leva ao progresso', (
    tester,
  ) async {
    final meals = _FakeMealAnalysis();
    final container = await pump(
      tester,
      extra: [mealAnalysisProvider.overrideWith(() => meals)],
    );
    container.read(homeTabProvider.notifier).state = HomeTab.nutrition;

    await tester.tap(find.byTooltip('Fotografar refeição'));
    await tester.pumpAndSettle();

    expect(meals.source, ImageSource.camera);
    // O modo ilustrado é estado local da tela de refeições e não vale para uma captura daqui:
    // ele custa uma chamada a mais, e a ressalva que explica isso não está nesta tela.
    expect(meals.illustrated, isFalse);
    expect(container.read(analysisTabProvider), AnalysisTab.meal);
    expect(container.read(homeTabProvider), HomeTab.analysis);
    // **É esta a asserção que segura a ordem.** A análise leva dezenas de segundos e só a tela
    // de refeições mostra a barra e os passos; começar o envio antes de mudar de tela faria a
    // foto subir para um diário que não diz nada sobre ela.
    expect(meals.tabWhenStarted, HomeTab.analysis);
  });

  testWidgets('a galeria é a outra porta da mesma captura', (tester) async {
    final meals = _FakeMealAnalysis();
    final container = await pump(
      tester,
      extra: [mealAnalysisProvider.overrideWith(() => meals)],
    );
    container.read(homeTabProvider.notifier).state = HomeTab.nutrition;

    await tester.tap(find.byTooltip('Escolher da galeria'));
    await tester.pumpAndSettle();

    expect(meals.source, ImageSource.gallery);
    expect(container.read(homeTabProvider), HomeTab.analysis);
  });

  testWidgets('desistir no seletor não tira ninguém do lugar', (tester) async {
    // É o que decide a ordem entre escolher a foto e mudar de tela: invertida, cancelar a
    // folha do sistema deixaria a pessoa numa aba que ela não pediu — a troca acontece
    // invisível, por trás do seletor que cobre o app inteiro.
    final meals = _FakeMealAnalysis(picks: false);
    final container = await pump(
      tester,
      extra: [mealAnalysisProvider.overrideWith(() => meals)],
    );
    container.read(homeTabProvider.notifier).state = HomeTab.nutrition;

    await tester.tap(find.byTooltip('Fotografar refeição'));
    await tester.pumpAndSettle();

    expect(meals.tabWhenStarted, isNull);
    expect(container.read(homeTabProvider), HomeTab.nutrition);
    // E o dia aberto continua na tela, com o número dele.
    expect(find.text('1.476'), findsOne);
  });

  testWidgets('fora do hub, a captura empilha a rota das refeições', (
    tester,
  ) async {
    // Sem mexer no `homeTabProvider`: o padrão é a Hoje, que é o que uma `/diario` aberta por
    // link de e-mail enxerga. Não há hub para trocar de aba, e aí o caminho é a rota.
    final meals = _FakeMealAnalysis();
    await pump(tester, extra: [mealAnalysisProvider.overrideWith(() => meals)]);

    await tester.tap(find.byTooltip('Fotografar refeição'));
    await tester.pumpAndSettle();

    expect(meals.source, ImageSource.camera);
    expect(find.text('refeições'), findsOne);
  });

  testWidgets('com uma análise em curso, a porta só leva ao progresso', (
    tester,
  ) async {
    // O controller é um só: uma segunda foto preparada por cima da primeira seria descartada
    // em silêncio, porque o `start` devolve na hora quando já está rodando. Então o seletor
    // nem abre — a porta vira o caminho até o progresso que já existe.
    final meals = _FakeMealAnalysis(running: true);
    final container = await pump(
      tester,
      extra: [mealAnalysisProvider.overrideWith(() => meals)],
    );
    container.read(homeTabProvider.notifier).state = HomeTab.nutrition;

    await tester.tap(find.byTooltip('Fotografar refeição'));
    await tester.pumpAndSettle();

    expect(meals.source, isNull);
    expect(container.read(homeTabProvider), HomeTab.analysis);
    expect(container.read(analysisTabProvider), AnalysisTab.meal);
  });

  testWidgets('o herói mostra o consumido, não o que resta', (tester) async {
    // É a diferença deliberada entre esta tela e a Hoje: a Hoje responde "quanto ainda cabe",
    // pergunta que só faz sentido hoje; o diário é navegável para trás, e "restam 624" num
    // sábado que já acabou não significa nada.
    await pump(tester);

    expect(find.text('1.476'), findsOne);
    expect(find.textContaining('de 2.100 kcal · faltam 624'), findsOne);
    expect(find.text('3 refeições registradas'), findsOne);
  });

  testWidgets('os macros aparecem contra a meta, e as calorias não', (
    tester,
  ) async {
    // As calorias são o número do herói; repeti-las na seção seria a mesma duplicação que a
    // Hoje evita ao tirar do mosaico o assunto promovido.
    await pump(tester);

    expect(find.text('Macros do dia'), findsOne);
    expect(find.text('110 / 172 g'), findsOne);
    expect(find.text('Calorias'), findsNothing);
  });

  testWidgets('as refeições viram linhas com a hora', (tester) async {
    await pump(tester);

    // A tela tem duas rolagens — o seletor de dias na horizontal e o corpo na vertical —, e
    // sem dizer qual o `scrollUntilVisible` não sabe em qual rolar.
    await tester.scrollUntilVisible(
      find.text('Refeições'),
      200,
      scrollable: find.byType(Scrollable).last,
    );
    expect(find.text('3 no diário'), findsOne);
    // A hora antes do número: a lista é cronológica, e é por ela que se acha a refeição que
    // se quer mexer.
    expect(find.text('420 kcal'), findsOne);
  });

  testWidgets('sem semana no diário, o gráfico não aparece', (tester) async {
    // Gráfico com sete barras zeradas parece defeito, não ausência de dado.
    await pump(tester);

    expect(find.text('Últimos 7 dias'), findsNothing);
  });

  testWidgets('com semana, o gráfico entra e diz a média', (tester) async {
    await pump(
      tester,
      extra: [...homeOverrides(day: diaryDay(week: semanaDeCalorias))],
    );

    await tester.scrollUntilVisible(
      find.text('Últimos 7 dias'),
      200,
      scrollable: find.byType(Scrollable).last,
    );
    expect(find.textContaining('média'), findsOne);
  });
}

/// A análise de refeição sem câmera nem rede: guarda o que o herói pediu e devolve o que o
/// teste mandar.
///
/// **Pelos dois passos, e não pelo `analyzeFrom`.** É justamente a separação entre escolher a
/// foto e disparar o envio que o herói do diário existe para usar, e um dublê que só soubesse
/// do método inteiro não teria como provar a ordem entre eles.
class _FakeMealAnalysis extends MealAnalysisController {
  _FakeMealAnalysis({this.picks = true, this.running = false});

  /// O que o seletor devolve: verdadeiro é a pessoa escolhendo uma foto, falso é ela desistindo.
  final bool picks;

  /// Uma análise já em curso quando o herói é tocado.
  final bool running;

  ImageSource? source;
  bool? illustrated;

  /// Em que aba a pessoa estava no instante em que o envio começou. Nulo quando ele não
  /// começou — é o que separa "navegou e mandou" de "mandou e navegou".
  HomeTab? tabWhenStarted;

  @override
  GenerationState build() => GenerationState(running: running);

  @override
  Future<bool> pick(ImageSource source, {bool illustrated = false}) async {
    this.source = source;
    this.illustrated = illustrated;
    return picks;
  }

  @override
  Future<void> start() async {
    tabWhenStarted = ref.read(homeTabProvider);
  }
}
