import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mocktail/mocktail.dart';
import 'package:myotrack/core/db/local_database.dart';
import 'package:myotrack/core/providers.dart';
// `SeenAchievements` também é o nome de uma tabela do drift; o prefixo evita a colisão.
import 'package:myotrack/features/achievements/achievements_controller.dart'
    as achievements;
import 'package:myotrack/features/achievements/data/rewards_repository.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:myotrack/features/billing/billing_controller.dart';
import 'package:myotrack/features/billing/data/billing_models.dart';
import 'package:myotrack/features/account/url_opener.dart';
import 'package:myotrack/features/coach/coach_controller.dart';
import 'package:myotrack/features/dashboard/dashboard_controller.dart';
import 'package:myotrack/features/dashboard/dashboard_stats.dart';
import 'package:myotrack/features/diary/data/diary_models.dart';
import 'package:myotrack/features/diary/diary_controller.dart';
import 'package:myotrack/features/diet/data/diet_models.dart';
import 'package:myotrack/features/diet/diet_plan_controller.dart';
import 'package:myotrack/features/home/today_controller.dart';
import 'package:myotrack/features/meals/data/meal_models.dart';
import 'package:myotrack/features/meals/meal_analysis_controller.dart';
import 'package:myotrack/features/privacy/privacy_controller.dart';
import 'package:myotrack/features/profile/data/profile_models.dart';
import 'package:myotrack/features/profile/data/profile_repository.dart';
import 'package:myotrack/features/profile/onboarding_controller.dart';
import 'package:myotrack/features/progress/progress_controller.dart';
import 'package:myotrack/features/reports/data/report_models.dart';
import 'package:myotrack/features/reports/report_controller.dart';
import 'package:myotrack/features/reviews/review_controller.dart';
import 'package:myotrack/features/videos/data/video_models.dart';
import 'package:myotrack/features/videos/video_analysis_controller.dart';
import 'package:myotrack/features/workout/data/workout_models.dart';

/// Dados de mentira para as telas do hub, e os overrides que as desligam da rede.
///
/// Um arquivo só porque o shell monta as cinco abas de uma vez: testar qualquer uma delas
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

/// Três refeições já analisadas por foto: duas de hoje e uma de ontem.
///
/// **Duas no mesmo dia de propósito.** O histórico é agrupado por dia, e um fixture de uma
/// refeição por dia nunca desenha o caso que o agrupamento existe para resolver — o bloco com
/// duas linhas, o fio entre elas e a contagem no rótulo. Com uma por dia a galeria avaliava
/// três blocos de uma linha, que é a única forma que a tela não tem na prática.
///
/// **Os três estados que a linha escreve** aparecem um em cada: a de 12:34 é a limpa, a de
/// ontem foi corrigida à mão e a de 08:10 está fora do diário.
///
/// **Sem `photoUrl`.** A `Image.network` da análise não busca nada dentro do teste — o
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
  // Do mesmo dia da primeira, e mais cedo — é ela que faz o bloco de "Hoje" ter duas linhas.
  // A ordem da lista é a do servidor, do mais novo para o mais velho: o agrupamento junta
  // corridas consecutivas, e um histórico embaralhado abriria dois blocos "Hoje".
  MealAnalysis(
    id: 'analise-3',
    createdAt: '2026-08-04T08:10:00',
    excludedFromDiary: true,
    totalKcal: 233,
    totalProteinG: 9,
    totalCarbsG: 38,
    totalFatG: 5,
    items: [
      MealAnalysisItem(
        description: 'Mamão papaia',
        quantityG: 200,
        kcal: 90,
        proteinG: 1,
        carbsG: 23,
        fatG: 0,
      ),
      MealAnalysisItem(
        description: 'Iogurte natural integral',
        quantityG: 170,
        kcal: 143,
        proteinG: 8,
        carbsG: 15,
        fatG: 5,
      ),
    ],
  ),
  // A de ontem carrega a marca de quem corrigiu a estimativa à mão.
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

/// Três execuções analisadas por vídeo: duas de hoje e uma de dois dias atrás.
///
/// **Duas no mesmo dia de propósito**, pelo mesmo motivo das refeições: o histórico é agrupado
/// por dia, e um fixture de uma por dia nunca desenha o bloco com duas linhas e o fio entre
/// elas — a única forma que a tela não tem na prática.
///
/// **Uma sem nota**, porque `score` nulo **não é zero**: é o caso que a média do herói tem de
/// pular, e o que a linha fechada tem de escrever como "não avaliado". Uma tela que só mostra o
/// caminho feliz não é bancada de design nenhuma.
///
/// A `overlayVideoUrl` aponta para lugar nenhum de propósito: o `_OverlayPlayer` não baixa nada
/// até alguém tocar, então a captura sai determinística e mostra o lugar do vídeo, que é o que
/// se quer avaliar.
const analisesDeVideo = [
  VideoAnalysis(
    id: 'video-1',
    createdAt: '2026-08-04T18:20:00',
    analyzedExercise: 'Agachamento livre',
    score: 82,
    repCount: 8,
    overlayVideoUrl: 'https://exemplo.invalido/agachamento.mp4',
    result: VideoResult(
      issues: [
        VideoIssue(
          code: 'knee_valgus',
          message:
              'Joelho entrando na subida da terceira e da sexta repetição.',
          timestampsSec: [4.2, 11.8],
        ),
      ],
      correctPoints: [
        VideoCorrectPoint(
          code: 'depth',
          message: 'Profundidade constante nas oito repetições.',
        ),
        VideoCorrectPoint(
          code: 'spine',
          message: 'Coluna neutra do início ao fim.',
        ),
      ],
    ),
  ),
  // Do mesmo dia da primeira, e mais cedo: é ela que faz o bloco de "Hoje" ter duas linhas, e
  // é a segunda nota que faz a manchete virar média em vez de "nota da sua execução".
  VideoAnalysis(
    id: 'video-3',
    createdAt: '2026-08-04T17:50:00',
    analyzedExercise: 'Supino reto',
    score: 74,
    repCount: 10,
    overlayVideoUrl: 'https://exemplo.invalido/supino.mp4',
    result: VideoResult(
      issues: [
        VideoIssue(
          code: 'bar_path',
          message: 'A barra desce à frente do peito nas últimas repetições.',
          timestampsSec: [18.5],
        ),
      ],
      correctPoints: [
        VideoCorrectPoint(
          code: 'scapula',
          message: 'Escápulas presas no banco o tempo todo.',
        ),
      ],
    ),
  ),
  VideoAnalysis(
    id: 'video-2',
    createdAt: '2026-08-02T07:45:00',
    analyzedExercise: 'Levantamento terra',
    repCount: 5,
    result: VideoResult(
      notEvaluableReason:
          'O quadril sai do quadro na subida. Afaste o celular e filme de lado.',
    ),
  ),
];

/// Uma conversa com o coach que atravessa dois dias.
///
/// **Os dois dias são o ponto.** É o que faz a régua de data aparecer — sem ela a resposta de
/// ontem encosta na pergunta de hoje —, e uma conversa de quatro mensagens no mesmo minuto não
/// mostraria isso.
const conversaComOCoach = [
  CoachMessage(
    id: 'msg-1',
    fromUser: true,
    createdAt: '2026-08-03T19:12:00',
    content: 'Posso treinar com dor no ombro?',
  ),
  CoachMessage(
    id: 'msg-2',
    createdAt: '2026-08-03T19:12:40',
    content:
        'Dor no ombro durante o movimento não é para ser vencida no braço: pare a série. '
        'Como seu treino B tem supino e desenvolvimento no mesmo dia, troque os dois por '
        'remada e puxada esta semana e veja se a dor cede. Se persistir por mais de alguns '
        'dias, procure um profissional — isso eu não consigo avaliar por aqui.',
  ),
  CoachMessage(
    id: 'msg-3',
    fromUser: true,
    createdAt: '2026-08-04T08:03:00',
    content: 'Como está minha evolução no supino?',
  ),
  CoachMessage(
    id: 'msg-4',
    createdAt: '2026-08-04T08:03:30',
    content:
        'Você subiu de 62,5 kg para 70 kg em oito semanas, com as três séries fechando as '
        'repetições nas últimas duas sessões. É hora de subir para 72,5 kg.',
  ),
];

/// O histórico de conversas, da mais recente para a mais antiga.
///
/// A primeira é a de [conversaComOCoach] — as duas listas descrevem o mesmo usuário, e é o que
/// permite à tela abrir na conversa mais recente e encontrar mensagens nela. As outras duas
/// existem para a folha ter o que listar: uma lista de um item não mostra nem a ordem nem a
/// marca de qual delas está aberta.
const conversasComOCoach = [
  CoachConversation(
    id: 'conv-1',
    title: 'Dor no ombro no supino',
    updatedAt: '2026-08-04T08:03:30',
    messages: 4,
  ),
  CoachConversation(
    id: 'conv-2',
    title: 'Ceia antes de dormir',
    updatedAt: '2026-08-01T21:40:00',
    messages: 6,
  ),
  CoachConversation(
    id: 'conv-3',
    title: 'Vale a pena treinar em jejum?',
    updatedAt: '2026-07-22T06:15:00',
    messages: 2,
  ),
];

/// Três planos esperando revisão, de três alunos e de idades diferentes.
///
/// **As idades são o ponto.** A manchete promove a ponta da fila, e uma fila em que tudo chegou
/// no mesmo instante não mostraria nem o "há 6 dias" nem que o mais antigo não é o primeiro da
/// lista — que é justamente o erro que `oldestPending` existe para evitar.
const filaDeRevisao = [
  ReviewQueueItem(
    id: 'rev-1',
    name: 'Gerado em 2 de agosto · versão 2',
    version: 2,
    createdAt: '2026-08-02T09:15:00',
    student: 'marina.alves@exemplo.com',
    split: 'ABC',
    goal: 'Hipertrofia',
    targetKcal: 2400,
    calorieGoal: 'Superávit',
  ),
  ReviewQueueItem(
    id: 'rev-2',
    name: 'Gerado em 29 de julho · versão 5',
    version: 5,
    createdAt: '2026-07-29T18:40:00',
    student: 'joao.p.ferreira@exemplo.com',
    split: 'ABCD',
    goal: 'Emagrecimento',
    targetKcal: 1800,
    calorieGoal: 'Déficit',
  ),
  ReviewQueueItem(
    id: 'rev-3',
    name: 'Gerado em 4 de agosto · versão 1',
    version: 1,
    createdAt: '2026-08-04T07:05:00',
    student: 'c.tanaka@exemplo.com',
    split: 'AB',
    goal: 'Condicionamento',
    targetKcal: 2100,
    calorieGoal: 'Manutenção',
  ),
];

/// A assinatura, e o estado da loja — desligados da rede e da Play Store.
///
/// **O `build` do controller de verdade abre o fluxo de compras do aparelho**, e num teste isso
/// é um stream que nunca responde: sobrescrevê-lo inteiro é a única forma de a tela existir
/// fora de um celular com conta de loja configurada.
List<Override> billingOverrides({
  /// O plano gratuito **com** o bloco do Pro, que é o que o servidor devolve hoje. Um fixture
  /// sem ele descreveria um servidor antigo, e a tela de assinatura seria julgada sem a
  /// comparação que é o argumento dela — quem quiser esse caso passa o status à mão.
  SubscriptionStatus status = const SubscriptionStatus(
    maxMealAnalysesPerDay: 3,
    maxVideoAnalysesPerDay: 1,
    maxCoachMessagesPerDay: 5,
    pro: PlanLimits(
      maxMealAnalysesPerDay: 15,
      maxVideoAnalysesPerDay: 4,
      maxCoachMessagesPerDay: 25,
    ),
  ),
  // `ProductDetails` não tem construtor const, então o padrão é montado no corpo.
  BillingState? state,
}) => [
  subscriptionStatusProvider.overrideWith((ref) async => status),
  billingControllerProvider.overrideWith(
    () => _FakeBilling(state ?? lojaComProduto()),
  ),
];

/// A loja respondeu com o produto e o preço.
///
/// O preço vem formatado pela loja, com moeda e imposto da região. O fixture imita o formato
/// brasileiro porque é o que o app mostra — deixar "9.99" faria a captura avaliar uma tela que
/// nenhum usuário vê.
BillingState lojaComProduto() => BillingState(
  loadingStore: false,
  storeAvailable: true,
  product: ProductDetails(
    id: 'pro_monthly',
    title: 'MyoTrack Pro',
    description: 'Assinatura mensal',
    price: 'R\$ 24,90',
    rawPrice: 24.9,
    currencyCode: 'BRL',
  ),
);

/// O plano pago, renovando no fim do mês e gerenciado pela loja.
/// O Pro que veio de constância, e não de pagamento.
///
/// Sem `provider` nem `currentPeriodEnd` de propósito: é exatamente isso que a concessão é —
/// Pro de verdade, sem nenhuma cobrança por trás. O prazo mora em `grantExpiresAt`.
const assinaturaPorConstancia = SubscriptionStatus(
  plan: 'Pro',
  maxMealAnalysesPerDay: 15,
  maxVideoAnalysesPerDay: 4,
  maxCoachMessagesPerDay: 25,
  isGranted: true,
  grantExpiresAt: '2026-09-07T12:00:00',
);

const assinaturaPro = SubscriptionStatus(
  plan: 'Pro',
  maxMealAnalysesPerDay: 20,
  maxVideoAnalysesPerDay: 10,
  maxCoachMessagesPerDay: 50,
  currentPeriodEnd: '2026-08-28T00:00:00',
  provider: 'GooglePlay',
  managedByStore: true,
);

/// De quem é a conta, do lado do servidor.
///
/// O e-mail é o mesmo de `homeOverrides(email:)` de propósito: no app um vem do resumo e o
/// outro do JWT, e um fixture em que os dois divergem esconderia justamente o bug de a tela
/// mostrar a conta errada quando o servidor não responde.
final contaDoRafael = AccountSummary(
  email: 'rafael.souza@myotrack.dev',
  createdAt: DateTime(2026, 3, 12),
  hasPassword: true,
);

/// A versão que o rodapé da aba Conta escreve, e o pacote que monta o link da Play Store.
final pacoteDoApp = PackageInfo(
  appName: 'MyoTrack',
  packageName: 'com.myotrack.app',
  version: '1.0.0',
  buildNumber: '1',
);

/// Engole o toque nas linhas de suporte.
///
/// Devolve `true` — "abriu" —, e não `false`: com falso, todo teste que passasse perto de uma
/// linha de suporte ganharia uma snackbar de erro no meio da tela.
class SilentUrlOpener implements UrlOpener {
  const SilentUrlOpener();

  @override
  Future<bool> open(Uri url) async => true;
}

/// Guarda o que foi pedido, para o teste conferir o endereço.
class RecordingUrlOpener implements UrlOpener {
  final List<Uri> opened = [];

  /// Falso simula aparelho sem cliente de e-mail nem navegador — é o caso em que a tela
  /// precisa avisar em vez de não fazer nada.
  bool succeeds = true;

  @override
  Future<bool> open(Uri url) async {
    opened.add(url);
    return succeeds;
  }
}

class _FakeBilling extends BillingController {
  _FakeBilling(this._state);

  final BillingState _state;

  @override
  BillingState build() => _state;
}

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

/// Tudo que as cinco abas consultam, desligado da rede.
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

  /// De quem é a conta, para o cabeçalho da aba Conta. Vem do servidor; o e-mail acima é o
  /// plano B que sai do JWT, e os dois combinam de propósito.
  AccountSummary? accountSummary,

  /// O plano da aba Conta. Gratuito por padrão, com os mesmos limites de [billingOverrides] —
  /// é o estado da maioria, e é nele que a aba mostra o convite ao Pro.
  SubscriptionStatus subscription = const SubscriptionStatus(
    maxMealAnalysesPerDay: 3,
    maxVideoAnalysesPerDay: 1,
    maxCoachMessagesPerDay: 5,
  ),

  /// Quem abre endereço fora do app, nas linhas de suporte. O padrão engole o toque: nenhum
  /// teste que não é sobre suporte deveria falhar por causa de um `mailto:`.
  UrlOpener? urlOpener,
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

  /// O histórico de execuções analisadas. Vazio pelo mesmo motivo.
  List<VideoAnalysis> analyzedVideos = const [],

  /// A conversa com o coach. Vazia no caso comum — é o primeiro acesso, e é onde a tela
  /// sugere o que perguntar.
  List<CoachMessage> coachMessages = const [],

  /// O histórico de conversas. Vazio pelo mesmo motivo, e é o que faz a tela abrir numa
  /// conversa nova em vez de na mais recente.
  List<CoachConversation> coachConversations = const [],

  /// A fila de revisão. Vazia no caso comum: quase ninguém é revisor, e `reviewableKinds`
  /// já vem vazio por padrão.
  List<ReviewQueueItem> reviewQueue = const [],

  /// O dia do diário **por data**, para quem precisa de dias diferentes entre si — o carrossel
  /// parado em ontem, o totalizador recarregando com outro número. É função e não mapa porque
  /// o teste do recarregamento precisa que a resposta mude entre duas chamadas na mesma data.
  /// Quem não pede recebe [day] em qualquer data.
  DiaryDay Function(DateTime date)? dayOf,
}) => [
  reviewQueueProvider.overrideWith((ref) async => reviewQueue),
  coachConversationsProvider.overrideWith((ref) async => coachConversations),
  coachMessagesProvider.overrideWith((ref) async {
    // Sem histórico, a conversa é [coachMessages] e ponto — é o formato de fio único que a
    // maioria dos testes desta casa assume.
    if (coachConversations.isEmpty) {
      return coachMessages;
    }
    // Com histórico, [coachMessages] é a conversa **mais recente**; as outras, e a nova, que
    // ainda não tem id, abrem vazias. É o que faz trocar de conversa mudar a tela num teste.
    return ref.watch(openConversationProvider) == coachConversations.first.id
        ? coachMessages
        : const [];
  }),
  // Só a família, e de propósito. Sobrescrever também o `diaryDayProvider` deixava os testes
  // cegos para a cadeia que a tela usa de verdade: com o repassador falso no lugar, a Hoje
  // nunca atravessava a família, e o bug de o totalizador não recarregar passou por ela sem
  // que teste nenhum piscasse.
  diaryDayOfProvider.overrideWith(
    (ref, date) async => dayOf?.call(date) ?? day ?? diaryDay(),
  ),
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
  videoHistoryProvider.overrideWith((ref) async => analyzedVideos),
  pendingWritesProvider.overrideWith((ref) => Stream.value(0)),
  // Sem este override o provider real abriria o SQLite do aparelho, que não existe no teste.
  discardedWritesProvider.overrideWith((ref) async => discarded),
  userProfileProvider.overrideWith((ref) async => profile),
  profileRepositoryProvider.overrideWithValue(_profileRepository(profile)),
  userEmailProvider.overrideWith((ref) async => email),
  // A aba Conta. Sem estes três o shell bate na rede assim que alguém a visita — e o Dio
  // deixa um timer pendente que o `flutter_test` reprova como "A Timer is still pending",
  // num teste que não é sobre conta nenhuma.
  accountSummaryProvider.overrideWith(
    (ref) async => accountSummary ?? contaDoRafael,
  ),
  subscriptionStatusProvider.overrideWith((ref) async => subscription),
  // `PackageInfo.fromPlatform` fala com o lado nativo, que não existe no teste.
  packageInfoProvider.overrideWith((ref) async => pacoteDoApp),
  urlOpenerProvider.overrideWithValue(urlOpener ?? const SilentUrlOpener()),
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
