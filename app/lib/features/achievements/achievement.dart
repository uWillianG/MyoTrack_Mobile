import 'package:flutter/material.dart';

/// A que pergunta a conquista responde.
///
/// Três famílias, e não uma lista solta: "treinei quatro semanas seguidas" e "bati um
/// recorde" premiam coisas diferentes — aparecer e melhorar —, e quem só aparece precisa ver
/// que a segunda coluna existe.
enum AchievementFamily {
  constancy('Constância', 'Aparecer', Icons.event_repeat_outlined),
  progression('Progressão', 'Melhorar', Icons.trending_up),
  nutrition('Nutrição', 'Sustentar', Icons.restaurant_outlined);

  const AchievementFamily(this.label, this.subtitle, this.icon);

  final String label;

  /// O verbo da família, para o cabeçalho da seção.
  final String subtitle;

  final IconData icon;
}

/// Uma conquista, já avaliada contra os dados do usuário.
///
/// Carrega o progresso mesmo quando ainda não foi alcançada, e é isso que a torna uma
/// recompensa **por evolução** em vez de um selo binário: "3 de 4 semanas" diz o que fazer
/// esta semana; um cadeado não diz nada.
@immutable
class Achievement {
  const Achievement({
    required this.id,
    required this.family,
    required this.title,
    required this.detail,
    required this.done,
    required this.icon,
    required this.current,
    required this.target,
    this.proDays = 0,
    this.proClaimed = false,
  });

  /// Estável e legível — é a chave que o aparelho guarda para saber o que já comemorou.
  /// Renomear um id transforma a conquista em outra e ela seria comemorada de novo.
  final String id;

  final AchievementFamily family;
  final String title;

  /// O que precisa acontecer, na voz de quem ainda não chegou lá.
  final String detail;

  /// O que aconteceu, no passado, para quem já chegou.
  ///
  /// Duas frases em vez de uma porque a mesma linha não serve às duas situações: "Registre
  /// uma sessão de treino" embaixo de um selo já conquistado transforma a recompensa em
  /// lista de tarefas — o app manda fazer o que a pessoa acabou de fazer.
  final String done;

  final IconData icon;

  /// Dias de Pro que esta conquista rende. Zero na maioria — só duas marcas de constância de
  /// treino têm prêmio material, e é assim de propósito.
  ///
  /// **Aderência à dieta não entra.** A régua da nutrição é o consumo que o próprio usuário
  /// declara; pendurar valor econômico nela cria o incentivo que um produto de saúde não pode
  /// criar — registrar refeição que não houve, ou restringir para bater a faixa.
  final int proDays;

  /// O prêmio desta marca já foi recebido alguma vez. A concessão é uma por marca, para
  /// sempre — anunciar de novo seria prometer o que não vem.
  final bool proClaimed;

  bool get grantsPro => proDays > 0 && !proClaimed;

  /// A frase certa para o estado atual.
  String get caption => earned ? done : detail;

  /// Onde a pessoa está e onde a conquista fecha, na unidade da própria conquista
  /// (semanas, recordes, dias). Guardar os dois — em vez de só um booleano — é o que
  /// permite mostrar a barra e o "3 de 4".
  final num current;
  final num target;

  /// Alvo zero **não** é conquista ganha.
  ///
  /// É o estado de quem ainda não tem contra o que medir — sem meta de treinos no perfil,
  /// sem dieta gerada. `current >= target` sozinho dava `0 >= 0` e premiava exatamente quem
  /// não fez nada, que é o erro mais caro que este arquivo pode cometer: um selo falso põe
  /// em dúvida todos os verdadeiros.
  bool get earned => target > 0 && current >= target;

  /// 0 a 1, saturando em 1. Serve à barra de progresso.
  double get ratio =>
      target <= 0 ? 0 : (current / target).clamp(0, 1).toDouble();

  /// "3 de 4 semanas" — ou nada, quando a conquista não tem contagem que faça sentido
  /// mostrar (as de "primeira vez", em que o alvo é 1).
  String? progressLabel(String unit) {
    if (target <= 1) {
      return null;
    }
    final done = current.clamp(0, target).round();
    return '$done de ${target.round()} $unit';
  }
}

/// Os dados que a avaliação consome.
///
/// Um objeto só, e todos os campos já agregados, porque a avaliação precisa ser uma função
/// pura: é ela que decide se alguém ganhou algo, e uma regra dessas não pode depender de
/// rede, de relógio ou de provider para ser testada.
@immutable
class AchievementInput {
  const AchievementInput({
    this.weeklySessions = const [],
    this.weeklyVolumeKg = const [],
    this.streakWeeks = 0,
    this.records = 0,
    this.weighIns = 0,
    this.trainingDaysGoal,
    this.diaryWeekKcal = const [],
    this.kcalTarget,
    this.proDaysByMilestone = const {},
    this.alreadyGranted = const {},
  });

  /// Treinos por semana, do mais antigo ao mais recente, terminando na semana corrente.
  final List<int> weeklySessions;

  /// Semanas seguidas com treino, **calculada pelo servidor**.
  ///
  /// Já foi contada aqui. Deixou de ser no dia em que a sequência passou a conceder Pro: a
  /// conta que decide quem ganha plano pago não pode morar no cliente, que é reescritível por
  /// qualquer pessoa com um proxy. `TrainingStreak.weeks`, no domínio do backend, é a única
  /// implementação — e este campo é o resultado dela chegando pelo `GET /api/rewards`.
  final int streakWeeks;

  /// Quantos dias de Pro cada marca rende, como o servidor os anuncia. Vazio quando a
  /// consulta falhou — e aí a tela não promete prêmio nenhum.
  final Map<String, int> proDaysByMilestone;

  /// Marcas que este usuário já recebeu alguma vez. A concessão é uma por marca, para sempre;
  /// sem isto a tela ofereceria de novo um prêmio que não viria.
  final Set<String> alreadyGranted;

  /// Volume por semana, na mesma ordem e no mesmo comprimento de [weeklySessions].
  final List<num> weeklyVolumeKg;

  /// Quantos exercícios já têm recorde registrado.
  final int records;

  /// Quantas pesagens existem na curva de peso.
  final int weighIns;

  /// Meta de treinos por semana do perfil. Null em quem ainda não preencheu — e aí a
  /// conquista de semana cheia não tem contra o que medir.
  final int? trainingDaysGoal;

  /// Calorias de cada um dos últimos sete dias.
  final List<num> diaryWeekKcal;

  /// Meta calórica diária. Null sem dieta gerada.
  final num? kcalTarget;
}

/// Avalia o catálogo inteiro contra [input].
///
/// **Deriva, não guarda.** O estado de cada conquista sai dos mesmos agregados que o
/// dashboard mostra, calculados no servidor. Isso tem uma consequência que vale dizer em voz
/// alta: apagar sessões no servidor pode fazer uma conquista voltar a ficar trancada. É o
/// preço de não manter uma segunda verdade — e é preferível a um selo que afirma um treino
/// que não existe mais.
List<Achievement> evaluateAchievements(AchievementInput input) {
  final totalSessions = input.weeklySessions.fold<int>(0, (s, n) => s + n);
  final sessionsThisWeek = input.weeklySessions.isEmpty
      ? 0
      : input.weeklySessions.last;
  final daysLogged = input.diaryWeekKcal.where((k) => k > 0).length;

  return [
    // --- Constância ---
    Achievement(
      id: 'primeiro-treino',
      family: AchievementFamily.constancy,
      title: 'Primeiro treino',
      detail: 'Registre uma sessão de treino.',
      done: 'Você começou. O resto é repetir.',
      icon: Icons.flag_outlined,
      current: totalSessions.clamp(0, 1),
      target: 1,
    ),
    Achievement(
      id: 'semana-cheia',
      family: AchievementFamily.constancy,
      title: 'Semana cheia',
      // A meta é a do perfil, e não um número fixo: quem se comprometeu com três dias não
      // deveria falhar numa conquista calibrada para cinco.
      detail: input.trainingDaysGoal == null
          ? 'Defina sua meta de treinos no perfil para acompanhar esta.'
          : 'Complete os ${input.trainingDaysGoal} treinos da sua semana.',
      done: 'Você cumpriu a meta de treinos que definiu para a semana.',
      icon: Icons.calendar_month_outlined,
      current: input.trainingDaysGoal == null ? 0 : sessionsThisWeek,
      target: input.trainingDaysGoal ?? 0,
    ),
    Achievement(
      id: 'quatro-semanas',
      family: AchievementFamily.constancy,
      title: 'Um mês sem falhar',
      detail: 'Treine em quatro semanas seguidas.',
      done: 'Quatro semanas seguidas treinando — isto já é hábito.',
      icon: Icons.local_fire_department_outlined,
      current: input.streakWeeks,
      target: 4,
      proDays: input.proDaysByMilestone['quatro-semanas'] ?? 0,
      proClaimed: input.alreadyGranted.contains('quatro-semanas'),
    ),
    Achievement(
      id: 'doze-semanas',
      family: AchievementFamily.constancy,
      title: 'Um ciclo inteiro',
      detail: 'Treine em doze semanas seguidas — um bloco de treino completo.',
      done: 'Doze semanas seguidas. Um bloco de treino inteiro, sem furos.',
      icon: Icons.military_tech_outlined,
      current: input.streakWeeks,
      target: 12,
      proDays: input.proDaysByMilestone['doze-semanas'] ?? 0,
      proClaimed: input.alreadyGranted.contains('doze-semanas'),
    ),

    // --- Progressão ---
    Achievement(
      id: 'primeiro-recorde',
      family: AchievementFamily.progression,
      title: 'Primeiro recorde',
      detail: 'Registre sua maior carga em algum exercício.',
      done: 'Seu primeiro recorde de carga está registrado.',
      icon: Icons.emoji_events_outlined,
      current: input.records.clamp(0, 1),
      target: 1,
    ),
    Achievement(
      id: 'cinco-recordes',
      family: AchievementFamily.progression,
      title: 'Cinco recordes',
      detail: 'Tenha recorde de carga em cinco exercícios diferentes.',
      done: 'Cinco exercícios com recorde seu.',
      icon: Icons.workspace_premium_outlined,
      current: input.records,
      target: 5,
    ),
    Achievement(
      id: 'quinze-recordes',
      family: AchievementFamily.progression,
      title: 'Quinze recordes',
      detail: 'Tenha recorde de carga em quinze exercícios diferentes.',
      done: 'Quinze exercícios com recorde seu.',
      icon: Icons.stars_outlined,
      current: input.records,
      target: 15,
    ),
    Achievement(
      id: 'semana-mais-forte',
      family: AchievementFamily.progression,
      // O que mede progresso de verdade: volume é carga × repetições somada, e superá-lo
      // significa ter levantado mais peso total do que em qualquer semana do último mês.
      title: 'Sua semana mais forte',
      detail:
          'Levante mais volume que em qualquer das quatro semanas anteriores.',
      done: 'Esta foi a semana em que você levantou mais peso no último mês.',
      icon: Icons.trending_up,
      current: _beatsRecentWeeks(input.weeklyVolumeKg) ? 1 : 0,
      target: 1,
    ),
    Achievement(
      id: 'dez-pesagens',
      family: AchievementFamily.progression,
      title: 'Dez pesagens',
      detail:
          'Registre seu peso dez vezes — é o que faz a curva virar tendência.',
      done: 'Dez pesagens: sua curva de peso já mostra tendência.',
      icon: Icons.monitor_weight_outlined,
      current: input.weighIns,
      target: 10,
    ),

    // --- Nutrição ---
    Achievement(
      id: 'primeira-refeicao',
      family: AchievementFamily.nutrition,
      title: 'Primeira refeição',
      detail: 'Registre uma refeição no diário.',
      done: 'Sua primeira refeição está no diário.',
      icon: Icons.photo_camera_outlined,
      current: daysLogged.clamp(0, 1),
      target: 1,
    ),
    Achievement(
      id: 'semana-registrada',
      family: AchievementFamily.nutrition,
      title: 'Semana registrada',
      detail: 'Registre alguma refeição em cada um dos sete últimos dias.',
      done: 'Sete dias seguidos de diário — nenhum dia em branco.',
      icon: Icons.event_available_outlined,
      current: daysLogged,
      target: 7,
    ),
    Achievement(
      id: 'semana-na-meta',
      family: AchievementFamily.nutrition,
      title: 'Semana na meta',
      detail: input.kcalTarget == null
          ? 'Gere sua dieta para o app poder comparar o consumo com a meta.'
          : 'Fique a até 10% da meta calórica em cinco dos sete dias.',
      done: 'Cinco dias da semana dentro da sua meta calórica.',
      icon: Icons.track_changes_outlined,
      current: _daysOnTarget(input.diaryWeekKcal, input.kcalTarget),
      target: 5,
    ),
  ];
}

/// A semana corrente superou o volume das quatro anteriores?
///
/// Exige as quatro para comparar: com duas semanas de histórico, "a mais forte" é quase
/// garantida, e uma conquista que se ganha por não ter passado ainda não premia evolução.
bool _beatsRecentWeeks(List<num> weeklyVolumeKg) {
  if (weeklyVolumeKg.length < 5) {
    return false;
  }
  final current = weeklyVolumeKg.last;
  if (current <= 0) {
    return false;
  }
  final previous = weeklyVolumeKg.sublist(
    weeklyVolumeKg.length - 5,
    weeklyVolumeKg.length - 1,
  );
  return previous.every((v) => current > v);
}

/// Dias da semana dentro de 10% da meta calórica.
///
/// A faixa é simétrica: comer bem abaixo da meta não é acerto num app que também serve a
/// quem quer ganhar massa, e premiar o déficit exagerado seria um incentivo perigoso num
/// produto de saúde.
int _daysOnTarget(List<num> weekKcal, num? target) {
  if (target == null || target <= 0) {
    return 0;
  }
  final tolerance = target * 0.10;
  return weekKcal
      .where((kcal) => kcal > 0 && (kcal - target).abs() <= tolerance)
      .length;
}
