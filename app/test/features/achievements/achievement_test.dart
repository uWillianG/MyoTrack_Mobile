import 'package:flutter_test/flutter_test.dart';
import 'package:myotrack/features/achievements/achievement.dart';

/// A avaliação decide se alguém ganhou alguma coisa. Uma regra dessas erra de dois jeitos, e
/// os dois são ruins: negar o que a pessoa fez, ou premiar o que ela não fez — e o segundo
/// corrói a confiança em todo o resto que o app afirma.
void main() {
  Achievement find(List<Achievement> all, String id) =>
      all.firstWhere((a) => a.id == id);

  /// Doze semanas de sessões, do mais antigo ao mais recente.
  AchievementInput input({
    List<int> sessions = const [],
    List<num> volume = const [],
    int streakWeeks = 0,
    int records = 0,
    int weighIns = 0,
    int? goal,
    List<num> weekKcal = const [],
    num? kcalTarget,
    Map<String, int> proDays = const {},
    Set<String> granted = const {},
  }) => AchievementInput(
    weeklySessions: sessions,
    weeklyVolumeKg: volume.isEmpty
        ? [for (final s in sessions) s * 1000]
        : volume,
    streakWeeks: streakWeeks,
    records: records,
    weighIns: weighIns,
    trainingDaysGoal: goal,
    diaryWeekKcal: weekKcal,
    kcalTarget: kcalTarget,
    proDaysByMilestone: proDays,
    alreadyGranted: granted,
  );

  group('sequência de semanas', () {
    // A contagem em si deixou de ser deste lado: ela concede plano pago, então vive no
    // domínio do backend (`TrainingStreak`, com testes lá). O que se fixa aqui é só que o
    // número do servidor chega às duas conquistas certas.
    test('a sequência do servidor alimenta as duas marcas', () {
      final all = evaluateAchievements(input(streakWeeks: 8));

      expect(find(all, 'quatro-semanas').current, 8);
      expect(find(all, 'quatro-semanas').earned, isTrue);
      expect(find(all, 'doze-semanas').current, 8);
      expect(find(all, 'doze-semanas').earned, isFalse);
      expect(
        find(all, 'doze-semanas').progressLabel('semanas'),
        '8 de 12 semanas',
      );
    });

    test('sem resposta do servidor a sequência é zero, não um palpite', () {
      // O provider devolve o estado vazio quando `/api/rewards` falha. A conquista fica
      // trancada em vez de inventar um número a partir do gráfico de volume.
      final all = evaluateAchievements(input(sessions: [3, 3, 3, 3, 3]));

      expect(find(all, 'quatro-semanas').current, 0);
      expect(find(all, 'quatro-semanas').earned, isFalse);
      // O treino registrado, esse sim, continua valendo.
      expect(find(all, 'primeiro-treino').earned, isTrue);
    });

    test('sem treino nenhum não há primeira sessão', () {
      final all = evaluateAchievements(input(sessions: [0, 0, 0, 0]));

      expect(find(all, 'primeiro-treino').earned, isFalse);
    });
  });

  group('prêmio em Pro', () {
    test('anuncia os dias que o servidor informou', () {
      final all = evaluateAchievements(
        input(proDays: const {'quatro-semanas': 7, 'doze-semanas': 30}),
      );

      expect(find(all, 'quatro-semanas').proDays, 7);
      expect(find(all, 'quatro-semanas').grantsPro, isTrue);
      expect(find(all, 'doze-semanas').proDays, 30);
    });

    test('marca já concedida deixa de prometer prêmio', () {
      // A concessão é uma por marca, para sempre. Continuar anunciando "1 mês de Pro" numa
      // marca já paga seria prometer o que não vem.
      final all = evaluateAchievements(
        input(
          proDays: const {'quatro-semanas': 7},
          granted: const {'quatro-semanas'},
        ),
      );

      expect(find(all, 'quatro-semanas').proDays, 7);
      expect(find(all, 'quatro-semanas').grantsPro, isFalse);
    });

    test('sem resposta do servidor não se promete prêmio nenhum', () {
      final all = evaluateAchievements(input(streakWeeks: 12));

      expect(find(all, 'quatro-semanas').grantsPro, isFalse);
      expect(find(all, 'doze-semanas').grantsPro, isFalse);
    });

    test('só constância de treino tem prêmio material', () {
      // Aderência à dieta fica de fora de propósito: a régua é o consumo declarado pelo
      // próprio usuário, e valor econômico ali incentiva registrar refeição que não houve.
      final all = evaluateAchievements(
        input(
          proDays: const {'quatro-semanas': 7, 'doze-semanas': 30},
          weekKcal: const [2000, 2000, 2000, 2000, 2000, 2000, 2000],
          kcalTarget: 2000,
          records: 20,
        ),
      );

      final withPrize = [
        for (final a in all)
          if (a.proDays > 0) a.id,
      ];
      expect(withPrize, ['quatro-semanas', 'doze-semanas']);
    });
  });

  group('semana mais forte', () {
    test('exige quatro semanas anteriores para comparar', () {
      // Com histórico curto, "a semana mais forte" seria ganha por não haver passado — o
      // oposto de premiar evolução.
      final all = evaluateAchievements(
        input(sessions: [1, 1, 1], volume: [1000, 2000, 9000]),
      );

      expect(find(all, 'semana-mais-forte').earned, isFalse);
    });

    test('supera todas as quatro anteriores', () {
      final all = evaluateAchievements(
        input(
          sessions: [1, 1, 1, 1, 1],
          volume: [8000, 8200, 8100, 8300, 8400],
        ),
      );

      expect(find(all, 'semana-mais-forte').earned, isTrue);
    });

    test('empatar com a melhor anterior não conta', () {
      final all = evaluateAchievements(
        input(
          sessions: [1, 1, 1, 1, 1],
          volume: [8000, 8400, 8100, 8300, 8400],
        ),
      );

      expect(find(all, 'semana-mais-forte').earned, isFalse);
    });

    test('semana corrente sem treino não é a mais forte', () {
      final all = evaluateAchievements(
        input(sessions: [1, 1, 1, 1, 0], volume: [10, 20, 30, 40, 0]),
      );

      expect(find(all, 'semana-mais-forte').earned, isFalse);
    });
  });

  group('semana cheia', () {
    test('mede contra a meta do perfil, e não contra um número fixo', () {
      // Quem se comprometeu com três dias não deveria falhar numa régua calibrada para cinco.
      final all = evaluateAchievements(input(sessions: [3], goal: 3));

      expect(find(all, 'semana-cheia').earned, isTrue);
      expect(
        find(all, 'semana-cheia').progressLabel('treinos'),
        '3 de 3 treinos',
      );
    });

    test('sem perfil não há alvo, e a conquista não se ganha por acidente', () {
      // Regressão: com `current` e `target` ambos em zero, `current >= target` dava
      // verdadeiro e premiava justamente quem não tinha meta nenhuma.
      final all = evaluateAchievements(input(sessions: [5]));
      final semanaCheia = find(all, 'semana-cheia');

      expect(semanaCheia.earned, isFalse);
      expect(semanaCheia.ratio, 0);
      expect(semanaCheia.detail, contains('Defina sua meta'));
    });
  });

  group('dieta', () {
    test('conta os dias dentro de 10% da meta, com a borda incluída', () {
      // Meta 2.000, faixa de ±200. 2.200 é exatamente a borda e **entra**: quem fechou o dia
      // a 10% cravados acertou o alvo, e negar por um décimo seria régua de outro esporte.
      final all = evaluateAchievements(
        input(
          weekKcal: [2000, 2100, 1900, 1750, 2200, 0, 2050],
          kcalTarget: 2000,
        ),
      );

      // Entram 2000, 2100, 1900, 2200 e 2050; 1.750 passa de 10% e 0 é dia sem registro.
      expect(find(all, 'semana-na-meta').current, 5);
      expect(find(all, 'semana-na-meta').earned, isTrue);
    });

    test('quatro dias na faixa ainda não fecham a semana', () {
      final all = evaluateAchievements(
        input(weekKcal: [2000, 2100, 1900, 2050, 1500], kcalTarget: 2000),
      );

      expect(find(all, 'semana-na-meta').current, 4);
      expect(find(all, 'semana-na-meta').earned, isFalse);
    });

    test('comer muito abaixo da meta não é acerto', () {
      // Num app que também serve a quem quer ganhar massa, premiar o déficit exagerado
      // seria um incentivo perigoso.
      final all = evaluateAchievements(
        input(weekKcal: [900, 800, 950, 700, 850], kcalTarget: 2000),
      );

      expect(find(all, 'semana-na-meta').current, 0);
    });

    test('sem dieta gerada a conquista fica sem alvo e explica por quê', () {
      final all = evaluateAchievements(input(weekKcal: [2000, 2000, 2000]));
      final naMeta = find(all, 'semana-na-meta');

      expect(naMeta.current, 0);
      expect(naMeta.detail, contains('Gere sua dieta'));
    });

    test('dia sem registro não conta como dia registrado', () {
      final all = evaluateAchievements(
        input(weekKcal: [1800, 0, 2000, 0, 1900, 2100, 0]),
      );

      expect(find(all, 'semana-registrada').current, 4);
      expect(find(all, 'primeira-refeicao').earned, isTrue);
    });
  });

  group('progresso mostrado', () {
    test('a razão satura em 1 quando se passa do alvo', () {
      // Vinte recordes não são "133% de quinze": a barra cheia é o teto.
      final all = evaluateAchievements(input(records: 20));

      expect(find(all, 'quinze-recordes').ratio, 1);
      expect(
        find(all, 'quinze-recordes').progressLabel('exercícios'),
        '15 de 15 exercícios',
      );
    });

    test('conquista de primeira vez não mostra contagem', () {
      // "1 de 1 treino" não informa nada que o próprio selo já não diga.
      final all = evaluateAchievements(input(sessions: [1]));

      expect(find(all, 'primeiro-treino').progressLabel('treinos'), isNull);
    });

    test('o catálogo não tem id repetido', () {
      // O id é a chave do que já foi comemorado: dois iguais fariam uma conquista silenciar
      // a outra para sempre.
      final ids = evaluateAchievements(input()).map((a) => a.id).toList();

      expect(ids.toSet().length, ids.length);
    });
  });
}
