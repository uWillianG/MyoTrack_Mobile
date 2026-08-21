import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:myotrack/core/theme.dart';
import 'package:myotrack/features/dashboard/dashboard_controller.dart';
import 'package:myotrack/features/dashboard/dashboard_stats.dart';
import 'package:myotrack/features/profile/data/profile_models.dart';
import 'package:myotrack/features/profile/data/profile_repository.dart';
import 'package:myotrack/features/profile/onboarding_controller.dart';
import 'package:myotrack/features/profile/profile_page.dart';
import 'package:myotrack/features/progress/progress_controller.dart';

class _MockProfileRepository extends Mock implements ProfileRepository {}

/// O perfil deixou de ser um assistente de cinco etapas e virou duas telas atrás de um nome
/// só: cadastro em página única para quem não tem perfil, resumo editável para quem tem.
///
/// O que estes testes fixam é o que a separação existe para garantir — que quem já tem perfil
/// **veja** o perfil, e que mudar um grupo custe um toque para abrir e um para salvar.
void main() {
  const smallPhone = Size(360, 800);

  setUpAll(() {
    registerFallbackValue(
      const ProfileRequest(
        experienceLevel: 'Beginner',
        goal: 'Hypertrophy',
        trainingDaysPerWeek: 3,
        priorityMuscleGroups: [],
        injuryTags: [],
        availableEquipment: [],
        dietaryRestrictions: [],
        foodPreferences: [],
      ),
    );
    registerFallbackValue(const MeasurementRequest(date: '2026-07-31'));
    registerFallbackValue(<ConsentRequest>[]);
  });

  late _MockProfileRepository repository;

  setUp(() {
    repository = _MockProfileRepository();
    when(
      () => repository.save(any()),
    ).thenAnswer((_) async => const UserProfile(id: 'p1'));
    when(() => repository.recordConsents(any())).thenAnswer((_) async {});
    when(() => repository.addMeasurement(any())).thenAnswer((_) async {});
  });

  Future<void> pump(
    WidgetTester tester, {
    UserProfile? profile,
    Brightness brightness = Brightness.light,
    double? lastWeightKg,
  }) async {
    tester.view.physicalSize = smallPhone;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    when(repository.get).thenAnswer((_) async => profile);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          profileRepositoryProvider.overrideWithValue(repository),
          // O resumo lê a última pesagem para semear o campo de peso — sem override ele
          // tentaria a rede.
          dashboardStatsProvider.overrideWith(
            (ref) async => DashboardStats.from(
              now: DateTime(2026, 7, 30),
              volume: const [],
              records: const [],
              weight: lastWeightKg == null
                  ? const []
                  : [
                      WeightPoint(
                        date: DateTime(2026, 7, 29),
                        weightKg: lastWeightKg,
                      ),
                    ],
            ),
          ),
        ],
        child: MaterialApp(
          theme: brightness == Brightness.light
              ? AppTheme.light()
              : AppTheme.dark(),
          home: const Scaffold(body: ProfileView()),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  const saved = UserProfile(
    id: 'p1',
    sex: 'M',
    heightCm: 178,
    experienceLevel: 'Intermediate',
    goal: 'Hypertrophy',
    trainingDaysPerWeek: 4,
    availableEquipment: ['Barbell', 'Dumbbell'],
    injuryTags: ['knee'],
  );

  group('quem já tem perfil', () {
    for (final brightness in Brightness.values) {
      testWidgets('vê o que está salvo, não um formulário (${brightness.name})', (
        tester,
      ) async {
        // O defeito que originou a reescrita: a aba chamada "Perfil" nunca mostrava o perfil.
        await pump(tester, profile: saved, brightness: brightness);

        expect(tester.takeException(), isNull);
        // O herói resume o plano.
        expect(find.text('4'), findsOne);
        expect(find.text('× por semana'), findsOne);
        expect(find.text('Hipertrofia · Intermediário'), findsOne);

        // E cada grupo diz o que tem dentro, em texto.
        expect(find.text('Intermediário · Hipertrofia'), findsOne);
        expect(find.text('4 dias — ABCD'), findsOne);
        expect(find.text('Barra · Halteres'), findsOne);
        expect(find.text('Joelho'), findsOne);

        // Nenhum campo de edição à vista: é uma tela de consulta.
        expect(find.byType(TextField), findsNothing);
      });
    }

    testWidgets('grupo vazio diz o que a ausência significa', (tester) async {
      // "Academia completa" é o efeito de não marcar equipamento nenhum, e é isso que a
      // pessoa precisa saber para decidir se quer mexer. Em branco pareceria dado faltando.
      await pump(tester, profile: const UserProfile(id: 'p1'));

      expect(find.text('Academia completa'), findsOne);
      expect(find.text('Nenhuma área sensível'), findsOne);
      expect(find.text('Sem restrições'), findsOne);
    });

    testWidgets('tocar num grupo abre só aquele grupo, e salva', (
      tester,
    ) async {
      // Um toque para abrir e um para salvar. No assistente eram cinco.
      await pump(tester, profile: saved);

      await tester.tap(find.text('Treino'));
      await tester.pumpAndSettle();

      // A folha traz os controles daquele grupo — e nenhum dos outros.
      expect(find.text('Dias de treino por semana'), findsOne);
      expect(find.text('Altura (cm)'), findsNothing);

      await tester.tap(find.text('5'));
      await tester.pumpAndSettle();
      // Uma vez só: a folha edita um rascunho, e o resumo atrás continua mostrando o que o
      // servidor tem até o "Salvar". Fechar sem salvar não pode deixar a tela mentindo.
      expect(find.text('5 dias — push/pull/legs'), findsOne);
      expect(find.text('4 dias — ABCD'), findsOne);

      // A folha rola: "Treino" tem quatro controles e o botão nasce abaixo da dobra num
      // celular de 800 dp.
      await tester.ensureVisible(find.widgetWithText(FilledButton, 'Salvar'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, 'Salvar'));
      await tester.pumpAndSettle();

      final request =
          verify(() => repository.save(captureAny())).captured.single
              as ProfileRequest;
      expect(request.trainingDaysPerWeek, 5);
      // Mudar o perfil não regera o plano sozinho, e o aviso diz isso.
      expect(find.textContaining('Gere o treino ou a dieta de novo'), findsOne);
    });

    testWidgets('o peso vem da última pesagem, e não em branco', (
      tester,
    ) async {
      // O peso não mora no perfil, e o campo abria sempre vazio para quem usa o app há meses
      // — um campo em branco onde havia um número lê como dado perdido.
      await pump(tester, profile: saved, lastWeightKg: 82.5);

      await tester.tap(find.text('Você'));
      await tester.pumpAndSettle();

      expect(find.widgetWithText(TextField, '82,5'), findsOne);
    });

    testWidgets('a caixa de consentimento não volta a cada edição', (
      tester,
    ) async {
      // A trilha do aceite já está registrada no servidor; pedir de novo faria parecer que o
      // anterior se perdeu.
      await pump(tester, profile: saved);

      expect(find.byType(Checkbox), findsNothing);
    });
  });

  group('quem ainda não tem perfil', () {
    testWidgets('vê os cinco grupos numa página só', (tester) async {
      await pump(tester);

      expect(find.text('Conte quem\nestá treinando.'), findsOne);
      // E os campos já abertos, sem etapa nenhuma pelo caminho.
      expect(find.text('Altura (cm)'), findsOne);

      // Os cinco grupos numa rolagem só. A `ListView` não constrói o que não vai desenhar,
      // então rolar até cada um é o que prova que estão lá.
      // Cada `TextField` traz um `Scrollable` próprio, então a rolagem da página precisa ser
      // dita — senão o `scrollUntilVisible` tenta rolar o campo de texto.
      for (final group in ['Treino', 'Equipamento', 'Lesões', 'Alimentação']) {
        await tester.scrollUntilVisible(
          find.text(group),
          240,
          scrollable: find.byType(Scrollable).first,
        );
        expect(find.text(group), findsOne, reason: group);
      }
    });

    testWidgets('salvar exige o consentimento de dados de saúde', (
      tester,
    ) async {
      // Sem o aceite o app trataria dado de saúde sem base legal.
      await pump(tester);

      Future<void> tapCreate() async {
        await tester.scrollUntilVisible(
          find.widgetWithText(FilledButton, 'Criar perfil'),
          280,
          scrollable: find.byType(Scrollable).first,
        );
        await tester.tap(find.widgetWithText(FilledButton, 'Criar perfil'));
        await tester.pumpAndSettle();
      }

      await tapCreate();

      expect(find.textContaining('aceitar o tratamento'), findsOne);
      verifyNever(() => repository.save(any()));

      await tester.tap(find.byType(Checkbox));
      await tester.pumpAndSettle();
      await tapCreate();

      verify(() => repository.save(any())).called(1);
      verify(() => repository.recordConsents(any())).called(1);
    });
  });
}
