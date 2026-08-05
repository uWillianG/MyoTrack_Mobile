import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mocktail/mocktail.dart';
import 'package:myotrack/core/db/local_database.dart';
import 'package:myotrack/core/providers.dart';
// `SeenAchievements` também é o nome de uma tabela do drift; o prefixo evita a colisão.
import 'package:myotrack/features/achievements/achievements_controller.dart'
    as achievements;
import 'package:myotrack/features/achievements/data/rewards_repository.dart';
import 'package:myotrack/features/dashboard/dashboard_controller.dart';
import 'package:myotrack/features/dashboard/dashboard_stats.dart';
import 'package:myotrack/features/diary/data/diary_models.dart';
import 'package:myotrack/features/diary/diary_controller.dart';
import 'package:myotrack/features/diet/data/diet_models.dart';
import 'package:myotrack/features/diet/diet_plan_controller.dart';
import 'package:myotrack/features/home/today_controller.dart';
import 'package:myotrack/features/meals/data/meal_models.dart';
import 'package:myotrack/features/meals/meal_analysis_controller.dart';
import 'package:myotrack/features/profile/data/profile_models.dart';
import 'package:myotrack/features/profile/data/profile_repository.dart';
import 'package:myotrack/features/profile/onboarding_controller.dart';
import 'package:myotrack/features/progress/progress_controller.dart';
import 'package:myotrack/features/reports/data/report_models.dart';
import 'package:myotrack/features/reports/report_controller.dart';
import 'package:myotrack/features/reviews/review_controller.dart';
import 'package:myotrack/features/videos/video_analysis_controller.dart';
import 'package:myotrack/features/workout/data/workout_models.dart';

/// Dados de mentira para as telas do hub, e os overrides que as desligam da rede.
///
/// Um arquivo só porque o shell monta as quatro abas de uma vez: testar qualquer uma delas
/// exige silenciar as chamadas de todas as outras, e repetir essa lista em cada teste faria
/// um provider novo quebrar arquivos que não têm nada a ver com ele.

DiaryDay diaryDay({
  num kcal = 1476,
  num protein = 110,
  num carbs = 150,
  num fat = 48,
  bool withTargets = true,

  /// As refeições que somam [kcal]. A barra do herói desenha um segmento por lançamento, e um
  /// dia sem eles sairia como uma barra lisa — que é justamente o que ela deixou de ser. Café,
  /// almoço e um lanche: o dia de quem chega às três da tarde, que é a hora em que a tela mais
  /// é aberta.
  List<num> meals = const [420, 760, 296],

  /// Calorias dos sete últimos dias, para o gráfico do diário.
  ///
  /// **Vazia por padrão, e isso é deliberado.** A avaliação de conquistas de nutrição lê esta
  /// lista, então enchê-la por padrão muda o que está conquistado e o que está a caminho — e
  /// quebra testes que não têm nada a ver com o diário. Quem precisa do gráfico pede.
  List<num> week = const [],
}) => DiaryDay(
  date: '2026-07-30',
  targets: withTargets
      ? const DiaryMacros(kcal: 2100, proteinG: 172, carbsG: 210, fatG: 64)
      : null,
  consumed: DiaryMacros(
    kcal: kcal,
    proteinG: protein,
    carbsG: carbs,
    fatG: fat,
  ),
  // Os macros de cada refeição saem rateados pela fatia de caloria dela, e não zerados: o
  // diário da aba Nutrição mostra "P · C · G" por lançamento, e uma refeição de 760 kcal com
  // zero de tudo é uma tela que a galeria avaliaria sem existir.
  //
  // A hora vem junto pelo mesmo motivo: a lista do diário é cronológica, e sem `createdAt`
  // toda linha sai com um traço no lugar do horário.
  entries: [
    for (var i = 0; i < meals.length; i++)
      () {
        final share = kcal <= 0 ? 0.0 : meals[i] / kcal;
        return DiaryEntry(
          id: 'meal-$i',
          createdAt: DateTime.utc(
            2026,
            7,
            30,
            11 + i * 4,
            12,
          ).toIso8601String(),
          totalKcal: meals[i],
          totalProteinG: (protein * share).round(),
          totalCarbsG: (carbs * share).round(),
          totalFatG: (fat * share).round(),
        );
      }(),
  ],
  week: [
    for (var i = 0; i < week.length; i++)
      DiaryDayTotal(
        date: DateTime(
          2026,
          7,
          30,
        ).subtract(Duration(days: week.length - 1 - i)).toIso8601String(),
        kcal: week[i],
      ),
  ],
);

/// Uma semana de calorias plausível, para quem quer o gráfico do diário na tela.
const semanaDeCalorias = <num>[1820, 2140, 1690, 2010, 2260, 1930, 1476];

DashboardStats dashboardStats({int weeks = 8}) => DashboardStats.from(
  now: DateTime(2026, 7, 30),
  volume: [
    for (var i = 0; i < weeks; i++)
      WeeklyVolume(
        weekStart: DateTime(2026, 7, 27).subtract(Duration(days: 7 * i)),
        volumeKg: 8000 + i * 600,
        sessions: 3,
      ),
  ],
  weight: [
    for (var i = 0; i < 6; i++)
      WeightPoint(date: DateTime(2026, 7, i + 1), weightKg: 82.7 - i * 0.05),
  ],
  records: const [],
);

NextWorkout nextWorkout({int exercises = 6, DateTime? lastDoneAt}) =>
    NextWorkout(
      day: WorkoutDay(
        id: 'day-b',
        order: 2,
        label: 'Treino B · Peito e tríceps',
        exercises: [
          for (var i = 0; i < exercises; i++)
            WorkoutExercise(
              id: 'ex-$i',
              exerciseId: i,
              exerciseName: 'Exercício $i',
              sets: 4,
              restSeconds: 90,
            ),
        ],
      ),
      lastDoneAt: lastDoneAt ?? DateTime(2026, 7, 26),
    );

const userProfile = UserProfile(
  id: 'profile-1',
  sex: 'M',
  heightCm: 178,
  experienceLevel: 'Intermediate',
  goal: 'Hypertrophy',
  trainingDaysPerWeek: 4,
);

const dietPlan = DietPlan(
  id: 'diet-1',
  name: 'Gerado em 28 de julho · versão 3',
  // Um dos três valores que o servidor emite. Inventar um quarto faria a captura mostrar
  // "MildDeficit" cru na tela — que é o que `DietLabels` faz de propósito com valor
  // desconhecido, e não o que se quer avaliar numa galeria.
  calorieGoal: 'Deficit',
  targets: Macros(kcal: 2100, proteinG: 172, carbsG: 210, fatG: 64),
  totals: Macros(kcal: 2098, proteinG: 171, carbsG: 209, fatG: 64),
);

/// O mesmo plano, com as refeições que ele prescreve.
///
/// Existe à parte porque a maioria dos testes não olha para dentro do plano e um fixture com
/// quatro refeições encheria o console de ruído. Quem precisa dele é a galeria: sem refeições, a
/// tela do plano cai no estado vazio e a captura avaliaria uma tela que quase ninguém vê.
const dietPlanWithMeals = DietPlan(
  id: 'diet-1',
  name: 'Gerado em 28 de julho · versão 3',
  // Um dos três valores que o servidor emite. Inventar um quarto faria a captura mostrar
  // "MildDeficit" cru na tela — que é o que `DietLabels` faz de propósito com valor
  // desconhecido, e não o que se quer avaliar numa galeria.
  calorieGoal: 'Deficit',
  reviewStatus: 'Approved',
  targets: Macros(kcal: 2100, proteinG: 172, carbsG: 210, fatG: 64),
  totals: Macros(kcal: 2098, proteinG: 171, carbsG: 209, fatG: 64),
  meals: [
    DietMeal(
      id: 'meal-1',
      order: 1,
      name: 'Café da manhã',
      items: [
        DietMealItem(
          id: 'i1',
          foodName: 'Ovo de galinha inteiro',
          quantityG: 120,
          kcal: 172,
          proteinG: 15,
          carbsG: 1,
          fatG: 12,
        ),
        DietMealItem(
          id: 'i2',
          foodName: 'Aveia em flocos',
          quantityG: 60,
          kcal: 235,
          proteinG: 8,
          carbsG: 40,
          fatG: 5,
        ),
      ],
    ),
    DietMeal(
      id: 'meal-2',
      order: 2,
      name: 'Almoço',
      items: [
        DietMealItem(
          id: 'i3',
          foodName: 'Peito de frango grelhado',
          quantityG: 180,
          kcal: 297,
          proteinG: 56,
          carbsG: 0,
          fatG: 7,
        ),
        DietMealItem(
          id: 'i4',
          foodName: 'Arroz branco cozido',
          quantityG: 200,
          kcal: 256,
          proteinG: 5,
          carbsG: 56,
          fatG: 1,
        ),
      ],
    ),
  ],
);

/// Duas refeições já analisadas por foto: a de hoje e a de ontem.
///
/// **Sem `photoUrl`.** A `Image.network` do cartão não busca nada dentro do teste — o
/// `flutter_test` responde 400 a qualquer requisição —, e uma URL de mentira só deixaria o
/// `errorBuilder` sumir com 160 dp de altura entre uma captura e outra.
///
/// As datas são locais e sem fuso de propósito: com `Z` no fim, o `toLocal()` do rótulo moveria
/// a hora conforme a máquina que roda a galeria.
const refeicoesAnalisadas = [
  MealAnalysis(
    id: 'analise-1',
    createdAt: '2026-08-04T12:34:00',
    totalKcal: 624,
    totalProteinG: 48,
    totalCarbsG: 62,
    totalFatG: 18,
    items: [
      MealAnalysisItem(
        description: 'Arroz branco cozido',
        quantityG: 150,
        kcal: 195,
        proteinG: 4,
        carbsG: 42,
        fatG: 1,
      ),
      MealAnalysisItem(
        description: 'Peito de frango grelhado',
        quantityG: 140,
        kcal: 231,
        proteinG: 43,
        carbsG: 0,
        fatG: 5,
      ),
      MealAnalysisItem(
        description: 'Feijão carioca',
        quantityG: 120,
        kcal: 91,
        proteinG: 6,
        carbsG: 16,
        fatG: 1,
      ),
    ],
  ),
  // A segunda carrega os dois estados que o rótulo escreve: a data de outro dia e a marca de
  // quem corrigiu a estimativa.
  MealAnalysis(
    id: 'analise-2',
    createdAt: '2026-08-03T20:10:00',
    userAdjusted: true,
    totalKcal: 412,
    totalProteinG: 31,
    totalCarbsG: 28,
    totalFatG: 19,
    items: [
      MealAnalysisItem(
        description: 'Omelete de três ovos',
        quantityG: 180,
        kcal: 274,
        proteinG: 21,
        carbsG: 2,
        fatG: 20,
      ),
      MealAnalysisItem(
        description: 'Pão integral',
        quantityG: 60,
        kcal: 138,
        proteinG: 6,
        carbsG: 26,
        fatG: 2,
      ),
    ],
  ),
];

class _MockProfileRepository extends Mock implements ProfileRepository {}

/// Repositório de perfil que responde na hora.
///
/// O assistente da aba Perfil mostra um indicador de progresso enquanto o perfil não chega,
/// e sem backend ele gira para sempre — o `pumpAndSettle` de qualquer teste do shell estoura
/// por causa disso, mesmo quando o teste não é sobre o perfil.
ProfileRepository _profileRepository(UserProfile? profile) {
  final repository = _MockProfileRepository();
  when(repository.get).thenAnswer((_) async => profile);
  return repository;
}

/// Tudo que as quatro abas consultam, desligado da rede.
///
/// Os parâmetros cobrem só o que os testes precisam variar; o resto é o caso comum — usuário
/// com dieta, com plano e sem papel de revisor.
List<Override> homeOverrides({
  DiaryDay? day,
  DashboardStats? stats,
  NextWorkout? next,

  /// Falso simula quem ainda não gerou plano — `next` sozinho não daria conta, porque null
  /// nele significa "use o padrão".
  bool hasNextWorkout = true,
  List<bool>? streak,
  Map<ReviewKind, int> reviewCounts = const {},
  DateTime? oldestReview,
  UserProfile? profile = userProfile,
  String? email = 'rafael.souza@myotrack.dev',
  List<ReviewKind> reviewableKinds = const [],
  DietPlan? diet = dietPlan,

  /// A recompensa por constância. O padrão espelha as oito semanas de sessões acima — sem
  /// isso a sequência viria zerada e as duas conquistas de constância ficariam trancadas num
  /// fixture que diz o contrário.
  RewardStatus? rewards,

  /// Escritas que o servidor recusou. Vazio no caso comum: o aviso é excepcional e não pode
  /// aparecer no meio dos testes que não são sobre ele.
  List<DiscardedWrite> discarded = const [],

  /// O relatório da semana passada. Null é o caso comum — quem instalou o app hoje não tem
  /// semana fechada, e o card então oferece gerar.
  WeeklyReport? report,

  /// A carga sugerida por exercício. Vazio no caso comum: a sugestão é complemento, e o
  /// exercício continua legível sem ela.
  Map<int, ProgressSuggestion> suggestions = const {},

  /// O histórico de fotos analisadas. Vazio no caso comum — é o primeiro acesso da aba
  /// Analisar, e é a tela que precisa explicar o que a IA faz.
  List<MealAnalysis> analyzedMeals = const [],
}) => [
  diaryDayProvider.overrideWith((ref) async => day ?? diaryDay()),
  dashboardStatsProvider.overrideWith((ref) async => stats ?? dashboardStats()),
  nextWorkoutProvider.overrideWith(
    (ref) async => hasNextWorkout ? (next ?? nextWorkout()) : null,
  ),
  weekStreakProvider.overrideWith(
    (ref) async =>
        streak ?? const [true, false, true, false, true, false, false],
  ),
  pendingReviewsProvider.overrideWith(
    (ref) async => PendingReviews(counts: reviewCounts, oldest: oldestReview),
  ),
  reviewableKindsProvider.overrideWith((ref) async => reviewableKinds),
  activeDietPlanProvider.overrideWith((ref) async => diet),
  mealHistoryProvider.overrideWith((ref) async => analyzedMeals),
  videoHistoryProvider.overrideWith((ref) async => const []),
  pendingWritesProvider.overrideWith((ref) => Stream.value(0)),
  // Sem este override o provider real abriria o SQLite do aparelho, que não existe no teste.
  discardedWritesProvider.overrideWith((ref) async => discarded),
  userProfileProvider.overrideWith((ref) async => profile),
  profileRepositoryProvider.overrideWithValue(_profileRepository(profile)),
  userEmailProvider.overrideWith((ref) async => email),
  rewardStatusProvider.overrideWith((ref) async => rewards ?? rewardStatus()),
  // O relatório semanal do Progresso. Sem override ele bate na rede, e o Dio deixa um timer
  // pendente que o `flutter_test` reprova como "A Timer is still pending" — num teste que não
  // é sobre relatório nenhum.
  latestReportProvider.overrideWith((ref) async => report),
  // A carga sugerida por exercício, que a tela do plano de treino mostra. Mesmo motivo.
  suggestionsByExerciseProvider.overrideWith((ref) async => suggestions),
];

/// Recompensa de mentira. Oito semanas seguidas e as duas marcas anunciadas, que é o estado de
/// quem já ganhou a de quatro semanas e persegue a de doze.
RewardStatus rewardStatus({
  int streakWeeks = 8,
  ActiveGrant? activeGrant,
  Set<String> granted = const {},
}) => RewardStatus(
  streakWeeks: streakWeeks,
  activeGrant: activeGrant,
  granted: granted,
  milestones: const [
    RewardMilestone(id: 'quatro-semanas', requiredWeeks: 4, proDays: 7),
    RewardMilestone(id: 'doze-semanas', requiredWeeks: 12, proDays: 30),
  ],
);

/// Quais conquistas o aparelho já comemorou, sem passar pelo banco.
///
/// O drift em memória agenda um timer de duração zero ao abrir, e o `flutter_test` reprova o
/// caso com "A Timer is still pending" antes de qualquer `tearDown` fechar o banco. Quem só
/// precisa do **estado** — a galeria, por exemplo — usa este override e não abre banco nenhum.
/// Quem testa a gravação do "já vi" continua precisando do drift de verdade.
class FakeSeenAchievements extends achievements.SeenAchievements {
  FakeSeenAchievements(this.seen);

  final Set<String> seen;

  @override
  Future<Set<String>> build() async => seen;

  @override
  Future<void> markSeen(Iterable<String> ids) async {
    state = AsyncData({...seen, ...ids});
  }
}

Override seenAchievements({Set<String> seen = const {}}) => achievements
    .seenAchievementsProvider
    .overrideWith(() => FakeSeenAchievements(seen));

/// Um plano de treino com dois dias, para a galeria e para quem testa a tela do plano.
final workoutPlan = WorkoutPlan(
  id: 'plan-1',
  name: 'Hipertrofia · 4 dias',
  split: 'ABCD',
  goal: 'Hypertrophy',
  version: 3,
  reviewStatus: 'Approved',
  days: [
    WorkoutDay(
      id: 'day-a',
      order: 1,
      label: 'Treino A · Costas e bíceps',
      exercises: [
        for (final (i, name) in const [
          'Barra fixa',
          'Remada curvada',
          'Puxada alta',
          'Rosca direta',
        ].indexed)
          WorkoutExercise(
            id: 'a-\$i',
            exerciseId: 100 + i,
            exerciseName: name,
            sets: 4,
            repsMin: 8,
            repsMax: 12,
            restSeconds: 90,
          ),
      ],
    ),
    WorkoutDay(
      id: 'day-b',
      order: 2,
      label: 'Treino B · Peito e tríceps',
      exercises: [
        for (final (i, name) in const [
          'Supino reto',
          'Supino inclinado com halteres',
          'Tríceps na polia',
        ].indexed)
          WorkoutExercise(
            id: 'b-\$i',
            exerciseId: 200 + i,
            exerciseName: name,
            sets: 4,
            repsMin: 8,
            repsMax: 12,
            restSeconds: 90,
          ),
      ],
    ),
  ],
);
