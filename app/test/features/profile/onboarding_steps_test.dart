import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:myotrack/core/theme.dart';
import 'package:myotrack/features/profile/data/profile_models.dart';
import 'package:myotrack/features/profile/data/profile_repository.dart';
import 'package:myotrack/features/profile/onboarding_controller.dart';
import 'package:myotrack/features/profile/onboarding_page.dart';

class _MockProfileRepository extends Mock implements ProfileRepository {}

/// O perfil virou assistente de cinco etapas. O que estes testes fixam é o que a divisão em
/// etapas pode quebrar sem avisar: o valor digitado numa etapa sobreviver à ida e volta, e o
/// consentimento continuar sendo exigido de quem ainda não tem perfil.
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
  }) async {
    tester.view.physicalSize = smallPhone;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    when(repository.get).thenAnswer((_) async => profile);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [profileRepositoryProvider.overrideWithValue(repository)],
        // Roteador de verdade: ao salvar, o assistente pergunta se há tela para desempilhar
        // (`context.canPop`), e isso estoura sem GoRouter na árvore.
        child: MaterialApp.router(
          theme: brightness == Brightness.light
              ? AppTheme.light()
              : AppTheme.dark(),
          routerConfig: GoRouter(
            routes: [
              GoRoute(
                path: '/',
                builder: (_, _) => const Scaffold(body: OnboardingView()),
              ),
            ],
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> advance(WidgetTester tester) async {
    await tester.tap(find.text('Continuar'));
    await tester.pumpAndSettle();
  }

  const saved = UserProfile(
    id: 'p1',
    sex: 'M',
    heightCm: 178,
    trainingDaysPerWeek: 4,
  );

  for (final brightness in Brightness.values) {
    testWidgets('as cinco etapas cabem na tela (${brightness.name})', (
      tester,
    ) async {
      await pump(tester, profile: saved, brightness: brightness);

      const titles = [
        'Quem está treinando',
        'Como você treina',
        'O que você tem à mão',
        'O que evitar',
        'O que você come',
      ];

      for (var step = 0; step < titles.length; step++) {
        expect(find.text('Etapa ${step + 1}/5'), findsNothing);
        expect(find.text(titles[step]), findsOne, reason: titles[step]);
        expect(tester.takeException(), isNull, reason: titles[step]);
        if (step < titles.length - 1) {
          await advance(tester);
        }
      }

      expect(find.text('Salvar perfil'), findsOne);
    });
  }

  testWidgets('o botão Voltar só aparece depois da primeira etapa', (
    tester,
  ) async {
    await pump(tester, profile: saved);

    expect(find.text('Voltar'), findsNothing);
    await advance(tester);
    expect(find.text('Voltar'), findsOne);
  });

  testWidgets('o que foi digitado sobrevive à ida e volta entre etapas', (
    tester,
  ) async {
    // É o risco que a divisão em etapas cria: a etapa some da árvore, e com ela o que estava
    // no campo se não tiver sido levado ao formulário antes.
    await pump(tester, profile: saved);

    await tester.enterText(
      find.widgetWithText(TextField, 'Altura (cm)'),
      '182',
    );
    await advance(tester);
    await tester.tap(find.text('Voltar'));
    await tester.pumpAndSettle();

    expect(find.text('182'), findsOne);
  });

  testWidgets('o seletor de dias diz qual divisão sai de cada escolha', (
    tester,
  ) async {
    await pump(tester, profile: saved);
    await advance(tester);

    expect(find.text('4 dias — ABCD'), findsOne);

    await tester.tap(find.text('5'));
    await tester.pumpAndSettle();

    expect(find.text('5 dias — push/pull/legs'), findsOne);
    expect(find.text('Dias de treino por semana: 5'), findsOne);
  });

  testWidgets('sem perfil, salvar exige o consentimento de dados de saúde', (
    tester,
  ) async {
    // Sem o aceite o app trataria dado de saúde sem base legal. O protótipo não tem esta
    // caixa; ela não é negociável.
    await pump(tester);

    for (var step = 0; step < 4; step++) {
      await advance(tester);
    }
    await tester.tap(find.text('Salvar perfil'));
    await tester.pumpAndSettle();

    expect(find.textContaining('aceitar o tratamento'), findsOne);
    verifyNever(() => repository.save(any()));

    await tester.tap(find.byType(Checkbox));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Salvar perfil'));
    await tester.pumpAndSettle();

    verify(() => repository.save(any())).called(1);
    verify(() => repository.recordConsents(any())).called(1);
  });

  testWidgets('quem já tem perfil não vê a caixa de consentimento de novo', (
    tester,
  ) async {
    // A trilha do aceite já está registrada no servidor; pedir de novo a cada edição faria
    // parecer que o anterior se perdeu.
    await pump(tester, profile: saved);

    for (var step = 0; step < 4; step++) {
      await advance(tester);
    }

    expect(find.byType(Checkbox), findsNothing);
  });
}
