import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:myotrack/core/jobs/generation_controller.dart';
import 'package:myotrack/core/theme.dart';
import 'package:myotrack/core/widgets/blocks.dart';
import 'package:myotrack/features/home/today_controller.dart';
import 'package:myotrack/features/meals/data/meal_models.dart';
import 'package:myotrack/features/meals/meal_analysis_controller.dart';
import 'package:myotrack/features/meals/meal_analysis_page.dart';

import '../home/home_test_harness.dart';

/// O herói da análise de refeição é o **estado do trabalho**: o convite enquanto nada corre, o
/// progresso enquanto a foto é analisada. O que estes testes fixam é a troca — e que o convite
/// só explica a IA para quem ainda não a viu funcionar.
///
/// A lista, por sua vez, é agrupada por dia: a régua carrega a data e o rótulo do cartão fica
/// só com a hora.
void main() {
  const smallPhone = Size(360, 800);

  Future<void> pump(WidgetTester tester, List<Override> overrides) async {
    tester.view.physicalSize = smallPhone;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          nowProvider.overrideWithValue(() => DateTime(2026, 8, 4, 15)),
          ...overrides,
        ],
        child: MaterialApp(
          theme: AppTheme.dark(),
          home: const Scaffold(body: MealAnalysisView()),
        ),
      ),
    );
    // Sem `pumpAndSettle`: com a análise em curso a barra de progresso é indeterminada, e uma
    // animação que nunca termina faria o `settle` estourar por tempo.
    await tester.pump();
    await tester.pump();
  }

  testWidgets('sem histórico, o herói explica o que a IA faz e o que não faz', (
    tester,
  ) async {
    await pump(tester, homeOverrides());

    expect(find.text('Fotografar prato'), findsOne);
    expect(find.textContaining('estimativa fica editável'), findsOne);
  });

  testWidgets('com histórico, o herói fica só com a ação', (tester) async {
    await pump(tester, homeOverrides(analyzedMeals: refeicoesAnalisadas));

    // Quem já analisou uma foto descobriu isso na primeira; repetir a cada abertura é ruído.
    expect(find.textContaining('estimativa fica editável'), findsNothing);
    // E o contador saiu: os blocos de dia já somam quantas refeições existem, e o herói
    // gastava 118 dp para repetir a soma deles.
    expect(find.text('analisadas por foto'), findsNothing);

    // O que fica é o que só ele tem: as duas formas de mandar uma foto. A da galeria virou
    // ícone ao lado da ação — sem palavra na tela, e com o nome ainda dito a quem não a vê.
    expect(find.text('Fotografar prato'), findsOne);
    expect(find.byTooltip('Escolher da galeria'), findsOne);
  });

  testWidgets('enquanto a análise corre, o herói vira o progresso', (
    tester,
  ) async {
    await pump(tester, [
      ...homeOverrides(),
      mealAnalysisProvider.overrideWith(_RunningAnalysis.new),
    ]);

    expect(find.text('Analisando'), findsOne);
    expect(find.text('Identificando os alimentos…'), findsOne);
    // O convite sai enquanto o trabalho corre: um botão de fotografar vivo aqui convidaria a
    // disparar uma segunda análise por cima da primeira.
    expect(find.text('Fotografar prato'), findsNothing);
    // E o modo ilustrado sai com ele: mora dentro do convite, e vale para a próxima captura —
    // mexer nele agora não mudaria a foto que já subiu.
    expect(find.text('Marcar os alimentos na foto'), findsNothing);
  });

  testWidgets('a lista traz nome, hora e total — e nenhuma análise aberta', (
    tester,
  ) async {
    await pump(tester, homeOverrides(analyzedMeals: refeicoesAnalisadas));

    // O dia é o rótulo do bloco, a contagem é o trailing, e as refeições dele são linhas.
    expect(find.text('Hoje'), findsOne);
    expect(find.text('2 refeições'), findsOne);
    // O nome é o alimento de maior caloria, mais a contagem do resto.
    expect(find.text('Peito de frango grelhado e mais 2'), findsOne);
    expect(find.text('12:34 · 624 kcal'), findsOne);
    // A do mesmo dia entra no mesmo bloco, com o estado dela no fim da linha.
    expect(find.text('Iogurte natural integral e mais 1'), findsOne);
    expect(find.text('08:10 · 233 kcal · fora do diário'), findsOne);

    // Nada da análise aparece antes do toque — nem a foto, nem os itens, nem os botões.
    expect(find.text('Arroz branco cozido'), findsNothing);
    expect(find.text('Ajustar'), findsNothing);
    expect(find.byType(Image), findsNothing);
  });

  testWidgets('tocar no nome abre a análise daquela refeição', (tester) async {
    await pump(tester, homeOverrides(analyzedMeals: refeicoesAnalisadas));

    await tester.tap(find.text('Peito de frango grelhado e mais 2'));
    await tester.pumpAndSettle();

    // Os itens com os botões de porção, os macros e as ações.
    expect(find.text('Arroz branco cozido'), findsOne);
    expect(find.textContaining('P 48 g'), findsOne);
    expect(find.text('Ajustar'), findsOne);
    // O total continua onde estava, na linha que não sai da tela — e não repetido embaixo.
    expect(find.text('12:34 · 624 kcal'), findsOne);

    // E só aquela: a refeição de ontem continua fechada.
    await tester.scrollUntilVisible(find.text('Ontem'), 120);
    expect(find.text('Omelete de três ovos e mais 1'), findsOne);
    expect(find.text('Pão integral'), findsNothing);
  });

  testWidgets('a análise que acabou de sair já vem aberta', (tester) async {
    await pump(tester, [
      ...homeOverrides(analyzedMeals: refeicoesAnalisadas),
      mealAnalysisProvider.overrideWith(_JustAnalyzed.new),
    ]);

    // Sem nenhum toque: os itens e as ações da refeição das 12:34 estão à vista.
    expect(find.text('Arroz branco cozido'), findsOne);
    expect(find.text('Ajustar'), findsOne);
    // E só ela: a do mesmo dia continua fechada.
    expect(find.text('Mamão papaia'), findsNothing);
  });

  // O interruptor já morou no fim da lista, e depois num cartão só dele acima do histórico.
  // Agora mora onde está o que ele muda — dentro do bloco que manda a foto, e antes do botão:
  // lido depois dele, chegaria com a câmera já aberta.
  testWidgets('o modo ilustrado é parte do bloco da captura', (tester) async {
    await pump(tester, homeOverrides(analyzedMeals: refeicoesAnalisadas));

    const modo = 'Marcar os alimentos na foto';
    expect(
      find.descendant(of: find.byType(HeroBlock), matching: find.text(modo)),
      findsOne,
    );
    expect(
      tester.getTopLeft(find.text(modo)).dy,
      lessThan(tester.getTopLeft(find.text('Fotografar prato')).dy),
    );
    expect(
      tester.getTopLeft(find.text(modo)).dy,
      lessThan(tester.getTopLeft(find.text('Hoje')).dy),
    );
  });

  testWidgets('o estado da refeição vira o fim da linha do cabeçalho', (
    tester,
  ) async {
    await pump(tester, homeOverrides(analyzedMeals: refeicoesAnalisadas));
    await tester.scrollUntilVisible(find.text('Ontem'), 120);

    expect(find.text('20:10 · 412 kcal · você ajustou'), findsOne);
  });

  testWidgets('a foto abre a refeição em tela cheia', (tester) async {
    await withPhotos(() async {
      await pump(tester, homeOverrides(analyzedMeals: [_comFoto]));
      await tester.tap(find.text('Peito de frango grelhado e mais 2'));
      await tester.pumpAndSettle();

      await tester.tap(find.bySemanticsLabel('Ver a foto da refeição'));
      await tester.pumpAndSettle();

      expect(find.byType(InteractiveViewer), findsOne);
      // Com as duas versões no servidor, o visor é o único lugar do app onde a foto crua tem
      // caminho: na análise só a marcada aparece.
      expect(find.text('Sem marcações'), findsOne);
    });
  });

  testWidgets('sem versão ilustrada, o visor não oferece a troca', (
    tester,
  ) async {
    await withPhotos(() async {
      await pump(tester, homeOverrides(analyzedMeals: [_soOriginal]));
      await tester.tap(find.text('Peito de frango grelhado e mais 2'));
      await tester.pumpAndSettle();

      await tester.tap(find.bySemanticsLabel('Ver a foto da refeição'));
      await tester.pumpAndSettle();

      expect(find.byType(InteractiveViewer), findsOne);
      expect(find.text('Sem marcações'), findsNothing);
    });
  });

  // A regra do agrupamento tem tabela própria em `test/core/day_groups_test.dart`. O que fica
  // aqui é a ligação: a data vem do `createdAt` da refeição, e o bloco órfão se chama assim.
  test('o histórico de refeições é agrupado pela data da análise', () {
    final days = groupMealsByDay(refeicoesAnalisadas, DateTime(2026, 8, 4, 15));

    expect(days.map((d) => d.label), ['Hoje', 'Ontem']);
    expect(days.first.items, hasLength(2));
    expect(
      groupMealsByDay(const [
        MealAnalysis(id: 'x'),
      ], DateTime(2026, 8, 4)).single.label,
      'Refeições',
    );
  });

  group('mealName', () {
    MealAnalysisItem item(String description, num kcal) =>
        MealAnalysisItem(description: description, kcal: kcal);

    test('o nome é o alimento de maior caloria, não o primeiro', () {
      final meal = MealAnalysis(
        id: 'x',
        items: [item('Alface', 12), item('Bife acebolado', 340)],
      );

      expect(mealName(meal), 'Bife acebolado e mais 1');
    });

    test('item sozinho não ganha contagem', () {
      final meal = MealAnalysis(id: 'x', items: [item('Banana', 90)]);

      expect(mealName(meal), 'Banana');
    });

    test('análise sem itens ainda tem como se chamar', () {
      expect(mealName(const MealAnalysis(id: 'x')), 'Refeição');
    });
  });
}

/// Uma refeição com as duas fotos — a marcada pela IA e a original.
final _comFoto = refeicoesAnalisadas.first.copyWith(
  photoUrl: 'https://exemplo.invalido/prato.jpg',
  illustratedPhotoUrl: 'https://exemplo.invalido/prato-marcado.jpg',
);

final _soOriginal = refeicoesAnalisadas.first.copyWith(
  photoUrl: 'https://exemplo.invalido/prato.jpg',
);

/// A mesma tela com uma análise em curso.
class _RunningAnalysis extends MealAnalysisController {
  @override
  GenerationState build() =>
      const GenerationState(running: true, step: 'Identificando os alimentos…');
}

/// A tela logo depois de uma análise terminar: o trabalho parou e o resultado é o da lista.
class _JustAnalyzed extends MealAnalysisController {
  @override
  MealAnalysis? get result => refeicoesAnalisadas.first;
}

/// Roda [body] com um servidor de mentira que devolve sempre o mesmo PNG de 1×1 transparente.
///
/// Existe porque a foto é o alvo de toque: sem bytes que decodifiquem, a `Image.network` cai no
/// `errorBuilder`, a pilha colapsa com ela e o teste passaria a medir a ausência da foto em vez
/// do visor.
///
/// **Pelo zone, e não por `HttpOverrides.global`.** O próprio `flutter_test` põe um cliente
/// global que responde 400 a tudo, e ele é reposto a cada teste; o valor do zone tem
/// precedência sobre o global e sobrevive ao `pump`.
Future<void> withPhotos(Future<void> Function() body) =>
    HttpOverrides.runZoned(body, createHttpClient: (_) => _PixelHttpClient());

class _PixelHttpClient implements HttpClient {
  @override
  bool autoUncompress = true;

  @override
  Future<HttpClientRequest> getUrl(Uri url) async => _PixelRequest();

  @override
  void close({bool force = false}) {}

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnsupportedError('${invocation.memberName} fora do uso do teste');
}

class _PixelRequest implements HttpClientRequest {
  @override
  final HttpHeaders headers = _PixelHeaders();

  @override
  Future<HttpClientResponse> close() async => _PixelResponse();

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnsupportedError('${invocation.memberName} fora do uso do teste');
}

class _PixelHeaders implements HttpHeaders {
  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

class _PixelResponse implements HttpClientResponse {
  @override
  int get statusCode => HttpStatus.ok;

  @override
  int get contentLength => _pixel.length;

  @override
  HttpClientResponseCompressionState get compressionState =>
      HttpClientResponseCompressionState.notCompressed;

  @override
  StreamSubscription<List<int>> listen(
    void Function(List<int> event)? onData, {
    Function? onError,
    void Function()? onDone,
    bool? cancelOnError,
  }) => Stream<List<int>>.value(_pixel).listen(
    onData,
    onError: onError,
    onDone: onDone,
    cancelOnError: cancelOnError,
  );

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnsupportedError('${invocation.memberName} fora do uso do teste');
}

/// PNG de 1×1 totalmente transparente.
final _pixel = Uint8List.fromList(<int>[
  0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, //
  0x00, 0x00, 0x00, 0x0D, 0x49, 0x48, 0x44, 0x52,
  0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x01,
  0x08, 0x06, 0x00, 0x00, 0x00, 0x1F, 0x15, 0xC4,
  0x89, 0x00, 0x00, 0x00, 0x0A, 0x49, 0x44, 0x41,
  0x54, 0x78, 0x9C, 0x63, 0x00, 0x01, 0x00, 0x00,
  0x05, 0x00, 0x01, 0x0D, 0x0A, 0x2D, 0xB4, 0x00,
  0x00, 0x00, 0x00, 0x49, 0x45, 0x4E, 0x44, 0xAE,
  0x42, 0x60, 0x82,
]);
