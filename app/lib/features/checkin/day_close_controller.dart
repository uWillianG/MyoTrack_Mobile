import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Como o dia foi, na pergunta que muda o treino de amanhã.
enum DayEffort {
  easy('Leve', 'Sobrou gás no fim'),
  normal('Normal', 'Foi o esperado'),
  hard('Puxado', 'Custou terminar');

  const DayEffort(this.label, this.detail);

  final String label;
  final String detail;
}

/// Energia percebida no fim do dia.
enum DayEnergy {
  high('Alta', 'Pronto para mais'),
  medium('Média', 'Dá para o treino'),
  low('Baixa', 'Preciso dormir');

  const DayEnergy(this.label, this.detail);

  final String label;
  final String detail;
}

/// O que já foi respondido no fechamento de hoje.
class DayCloseAnswers {
  const DayCloseAnswers({this.effort, this.weightKg, this.energy});

  final DayEffort? effort;

  /// Null quando a pessoa disse que não se pesou hoje — que é diferente de ainda não ter
  /// respondido a pergunta.
  final double? weightKg;

  final DayEnergy? energy;

  DayCloseAnswers copyWith({
    DayEffort? effort,
    double? weightKg,
    DayEnergy? energy,
  }) => DayCloseAnswers(
    effort: effort ?? this.effort,
    weightKg: weightKg ?? this.weightKg,
    energy: energy ?? this.energy,
  );
}

/// Respostas do fechamento do dia corrente.
///
/// **Vivem só na memória, e é uma limitação conhecida.** O peso é gravado de verdade em
/// `POST /api/measurements`; esforço e energia não têm para onde ir — o backend ainda não
/// tem endpoint de check-in, e enfileirar uma escrita para uma rota inexistente só encheria
/// a fila de falhas. Por isso a tela de resumo não promete que o plano de amanhã se ajustou:
/// ela mostra o que de fato mudou (o peso, o consumo do dia) e o que o plano já diz.
///
/// Quando `POST /api/check-ins` existir, o lugar de mandar as respostas é o
/// [DayCloseController.setEnergy] — a última das três —, pela `SyncQueue`, como todas as
/// outras escritas do app.
class DayCloseController extends Notifier<DayCloseAnswers> {
  @override
  DayCloseAnswers build() => const DayCloseAnswers();

  void setEffort(DayEffort effort) => state = state.copyWith(effort: effort);

  void setEnergy(DayEnergy energy) => state = state.copyWith(energy: energy);

  /// Registra a pesagem respondida. `null` = "não pesei hoje".
  void setWeight(double? weightKg) => state = DayCloseAnswers(
    effort: state.effort,
    weightKg: weightKg,
    energy: state.energy,
  );

  /// Zera para o próximo fechamento — chamado quando a tela abre.
  void restart() => state = const DayCloseAnswers();
}

final dayCloseProvider = NotifierProvider<DayCloseController, DayCloseAnswers>(
  DayCloseController.new,
);
