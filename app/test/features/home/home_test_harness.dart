import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mocktail/mocktail.dart';
import 'package:myotrack/core/db/local_database.dart';
import 'package:myotrack/core/providers.dart';
import 'package:myotrack/features/achievements/data/rewards_repository.dart';
import 'package:myotrack/features/dashboard/dashboard_controller.dart';
import 'package:myotrack/features/dashboard/dashboard_stats.dart';
import 'package:myotrack/features/diary/data/diary_models.dart';
import 'package:myotrack/features/diary/diary_controller.dart';
import 'package:myotrack/features/diet/data/diet_models.dart';
import 'package:myotrack/features/diet/diet_plan_controller.dart';
import 'package:myotrack/features/home/today_controller.dart';
import 'package:myotrack/features/meals/meal_analysis_controller.dart';
import 'package:myotrack/features/profile/data/profile_models.dart';
import 'package:myotrack/features/profile/data/profile_repository.dart';
import 'package:myotrack/features/profile/onboarding_controller.dart';
import 'package:myotrack/features/progress/progress_controller.dart';
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
);

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

NextWorkout nextWorkout({int exercises = 6}) => NextWorkout(
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
  lastDoneAt: DateTime(2026, 7, 26),
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
  name: 'Déficit leve 2.100 kcal',
  targets: Macros(kcal: 2100, proteinG: 172, carbsG: 210, fatG: 64),
  totals: Macros(kcal: 2098, proteinG: 171, carbsG: 209, fatG: 64),
);

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
  mealHistoryProvider.overrideWith((ref) async => const []),
  videoHistoryProvider.overrideWith((ref) async => const []),
  pendingWritesProvider.overrideWith((ref) => Stream.value(0)),
  // Sem este override o provider real abriria o SQLite do aparelho, que não existe no teste.
  discardedWritesProvider.overrideWith((ref) async => discarded),
  userProfileProvider.overrideWith((ref) async => profile),
  profileRepositoryProvider.overrideWithValue(_profileRepository(profile)),
  userEmailProvider.overrideWith((ref) async => email),
  rewardStatusProvider.overrideWith((ref) async => rewards ?? rewardStatus()),
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
