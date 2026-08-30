import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/design/format.dart';
import '../../core/jobs/generation_controller.dart';
import '../../core/jobs/job_status.dart';
import '../diary/diary_controller.dart';
import 'data/meal_models.dart';
import 'meal_analysis_controller.dart'
    show mealHistoryProvider, mealRepositoryProvider;

/// A refeição que está sendo montada — **a lista para onde os três caminhos convergem**.
///
/// Digitar um item à mão, aceitar o que a IA estimou de uma frase e escolher um alimento do
/// catálogo produzem exatamente a mesma coisa: um [MealAnalysisItem] que entra aqui. É o que
/// impede a tela de virar três telas coladas — não há três rascunhos, três somas e três botões
/// de salvar, há um.
///
/// **Vive num provider e não no `State` da página** porque a estimativa chega de fora dela: o
/// job termina no controller, e uma lista guardada dentro do widget obrigaria a tela a ficar
/// escutando o resultado para copiá-lo para dentro de si. Aqui quem terminou o trabalho
/// escreve, e a tela só lê.
class ManualMealDraft extends Notifier<List<MealAnalysisItem>> {
  /// O mesmo teto do servidor.
  ///
  /// Espelhar um **limite** é diferente de espelhar uma **fórmula**: o número não tem como
  /// divergir em silêncio — se o servidor mudar, o pior que acontece é a tela recusar antes
  /// dele. O que não se copia para cá é a aritmética que ele reescreve (a caloria reconciliada
  /// com os macros), porque aí sim duas contas ligeiramente diferentes fariam a tela mostrar um
  /// total e o diário guardar outro.
  static const int maxItems = 20;

  @override
  List<MealAnalysisItem> build() => const [];

  bool get isFull => state.length >= maxItems;

  /// Quantos itens ainda cabem.
  int get remaining => maxItems - state.length;

  void add(MealAnalysisItem item) => addAll([item]);

  /// Acrescenta, e **não** substitui.
  ///
  /// É o que permite descrever metade da refeição para a IA, conferir, e depois somar o
  /// cafezinho pelo catálogo. Cortar no teto em vez de recusar: quem chega aqui já passou por
  /// uma tela que sabe quantos cabem, e um estouro no meio de uma estimativa de IA custaria a
  /// chamada inteira.
  void addAll(Iterable<MealAnalysisItem> items) {
    if (isFull) {
      return;
    }
    state = [...state, ...items.take(remaining)];
  }

  void replaceAt(int index, MealAnalysisItem item) {
    if (index < 0 || index >= state.length) {
      return;
    }
    state = [
      for (var i = 0; i < state.length; i++)
        if (i == index) item else state[i],
    ];
  }

  void removeAt(int index) {
    if (index < 0 || index >= state.length) {
      return;
    }
    state = [
      for (var i = 0; i < state.length; i++)
        if (i != index) state[i],
    ];
  }

  void clear() => state = const [];

  /// Grava a refeição e devolve a que o **servidor** gravou.
  ///
  /// O que volta não é o que foi mandado: o servidor reconcilia a caloria com os macros,
  /// prende a porção à faixa e recalcula do catálogo o item que tem vínculo. Devolver o
  /// rascunho seria esconder essas correções justamente de quem precisa vê-las.
  ///
  /// [day] é o dia aberto no diário. Ver [manualMealTimestamp] para o que vira hora.
  Future<MealAnalysis> save({
    required DateTime day,
    required DateTime now,
  }) async {
    final saved = await ref
        .read(mealRepositoryProvider)
        .createManual(
          MealManualRequest(
            createdAt: manualMealTimestamp(day, now),
            items: [
              for (final item in state)
                MealManualItem(
                  description: item.description,
                  foodItemId: item.foodItemId,
                  quantityG: item.quantityG,
                  kcal: item.kcal,
                  proteinG: item.proteinG,
                  carbsG: item.carbsG,
                  fatG: item.fatG,
                ),
            ],
          ),
        );

    clear();
    ref.invalidate(mealHistoryProvider);
    // A refeição acabou de entrar no diário, e é o diário que alimenta o totalizador da Hoje.
    // Sem esta linha o número só mudaria no puxar-para-atualizar.
    ref.refreshDiaryDay(day);

    return saved;
  }
}

final manualMealDraftProvider =
    NotifierProvider<ManualMealDraft, List<MealAnalysisItem>>(
      ManualMealDraft.new,
    );

/// A hora que uma refeição manual leva para o diário.
///
/// **Hoje não manda hora nenhuma** — null deixa o servidor carimbar o relógio dele, que é o
/// mesmo que ordena todas as outras refeições do dia; mandar o do aparelho poria a refeição
/// fora de ordem por causa de um relógio adiantado.
///
/// **Num dia passado, a data é do diário e a hora é a de agora.** Não é a hora em que a pessoa
/// comeu — ninguém sabe qual foi —, e não é meia-noite nem meio-dia: o que a lista do diário
/// precisa é de **ordem**, e duas refeições lançadas com minutos de diferença têm de aparecer
/// nessa mesma ordem. Uma hora fixa faria o almoço e o jantar de ontem empilharem no mesmo
/// instante, indistinguíveis.
///
/// A janela de 30 dias que o servidor exige não é conferida aqui: o carrossel do diário só
/// alcança sete dias para trás, então esta tela não tem como produzir uma data fora dela.
String? manualMealTimestamp(DateTime day, DateTime now) {
  if (Fmt.sameDay(day, now)) {
    return null;
  }
  return DateTime(
    day.year,
    day.month,
    day.day,
    now.hour,
    now.minute,
    now.second,
  ).toIso8601String();
}

/// A soma do que está montado — **só para a tela**.
///
/// O total que vale é o do servidor, e ele pode diferir deste: a caloria de um item é
/// reconciliada com os macros quando destoa demais, e a porção é presa à faixa. Refazer aqui
/// essa aritmética seria manter duas versões dela livres para divergir; o que esta soma faz é
/// dizer, enquanto se monta, mais ou menos onde a refeição está.
class MealDraftTotals {
  const MealDraftTotals({
    required this.kcal,
    required this.proteinG,
    required this.carbsG,
    required this.fatG,
  });

  factory MealDraftTotals.of(List<MealAnalysisItem> items) {
    num kcal = 0;
    num protein = 0;
    num carbs = 0;
    num fat = 0;

    for (final item in items) {
      kcal += item.kcal;
      protein += item.proteinG;
      carbs += item.carbsG;
      fat += item.fatG;
    }

    return MealDraftTotals(
      kcal: kcal,
      proteinG: protein,
      carbsG: carbs,
      fatG: fat,
    );
  }

  final num kcal;
  final num proteinG;
  final num carbsG;
  final num fatG;
}

/// A estimativa de itens a partir de texto livre — o caminho principal do produto.
///
/// **Conduz-se como a análise por foto porque é o mesmo tipo de trabalho**: o servidor
/// enfileira um job (a chave da IA vive só no Worker) e o app acompanha pelo [JobWatcher]. Daí
/// herdar o [JobGenerationController] em vez de escrever um segundo acompanhador — passos
/// escritos, erro em snackbar e a trava contra o disparo duplo saem de graça.
///
/// O que ele tem de diferente de todos os outros: **o produto do job não está gravado em lugar
/// nenhum**. Ele vem inteiro no `resultJson`, e é por isso que o [onResult] existe.
class ManualMealEstimate extends JobGenerationController {
  String _text = '';

  /// A última estimativa entregou itens?
  ///
  /// É a única pergunta que a tela precisa fazer para decidir se limpa o campo, e nenhuma
  /// outra a responde: `error == null` também é verdade depois de um cancelamento, e apagar
  /// ali a frase que a pessoa escreveu seria cobrá-la de digitar tudo de novo justamente por
  /// ter desistido de esperar.
  bool _delivered = false;

  /// O texto que gerou a última estimativa — a tela o mantém no campo para quem quiser
  /// corrigir a frase e pedir de novo.
  String get text => _text;

  /// Pede a estimativa. Devolve `true` quando ela chegou e entrou no rascunho.
  ///
  /// Falso cobre os três desfechos em que a frase precisa continuar no campo: o job falhou, a
  /// espera estourou o prazo, ou a pessoa cancelou.
  Future<bool> estimate(String text) async {
    _text = text.trim();
    _delivered = false;
    await start();
    return _delivered;
  }

  @override
  Future<String> enqueue() =>
      ref.read(mealRepositoryProvider).estimateFromText(_text);

  /// O `resultJson` **é** o resultado: nada foi persistido, e é isso que se veio buscar.
  ///
  /// Lançar daqui é deliberado. O [JobGenerationController.start] envolve tudo num try, então
  /// uma resposta ilegível vira o mesmo erro de sempre e a tela o mostra em snackbar — que é o
  /// que precisa acontecer. Engolir em silêncio faria o job terminar "com sucesso" sem nenhum
  /// item ter aparecido na lista, e não há tela que explique isso.
  @override
  void onResult(JobStatus status) {
    final raw = status.resultJson;
    if (raw == null || raw.isEmpty) {
      throw StateError('A estimativa voltou vazia.');
    }

    final estimate = MealEstimate.fromJson(
      jsonDecode(raw) as Map<String, dynamic>,
    );
    if (estimate.items.isEmpty) {
      throw StateError('A estimativa não trouxe itens.');
    }

    ref.read(manualMealDraftProvider.notifier).addAll(estimate.items);
    _delivered = true;
  }

  /// Não há o que recarregar: a estimativa não criou nada no servidor.
  @override
  Future<void> reload() async {}

  @override
  String get startingLabel => 'Enviando a descrição…';

  @override
  String get genericFailure =>
      'Não foi possível estimar essa refeição. Tente de novo.';

  @override
  String stepLabel(JobState state) => switch (state) {
    JobState.pending => 'Na fila…',
    JobState.processing => 'Calculando as porções…',
    _ => 'Finalizando…',
  };
}

final manualMealEstimateProvider =
    NotifierProvider<ManualMealEstimate, GenerationState>(
      ManualMealEstimate.new,
    );

/// Busca no catálogo. A chave é o texto digitado; em branco, o começo da lista.
///
/// `autoDispose` com família: cada trecho digitado vira uma entrada de cache, e sem o descarte
/// automático uma sessão de busca deixaria uma lista de alimentos viva por letra digitada. O
/// cache entre elas é o que faz apagar um caractere responder na hora, sem nova requisição.
final foodSearchProvider = FutureProvider.autoDispose
    .family<List<FoodItem>, String>(
      (ref, query) => ref.watch(mealRepositoryProvider).foods(query: query),
    );
