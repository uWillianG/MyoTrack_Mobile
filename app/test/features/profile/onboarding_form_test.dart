import 'package:flutter_test/flutter_test.dart';
import 'package:myotrack/features/profile/data/profile_models.dart';
import 'package:myotrack/features/profile/onboarding_controller.dart';

void main() {
  group('conversão para o contrato da API', () {
    test('vírgula decimal é aceita — é o que o teclado brasileiro oferece', () {
      // Com o ponto obrigatório, quem digita "1,80" mandaria null e a altura sumiria
      // sem qualquer aviso.
      expect(
        const OnboardingForm(heightCm: '175,5').toRequest().heightCm,
        175.5,
      );
      expect(
        const OnboardingForm(heightCm: '175.5').toRequest().heightCm,
        175.5,
      );
      expect(const OnboardingForm(weightKg: '82,4').weightAsDouble, 82.4);
    });

    test('campo numérico vazio ou inválido vira null, não zero', () {
      // Zero passaria pela validação do servidor e viraria um TDEE absurdo.
      expect(const OnboardingForm(heightCm: '').toRequest().heightCm, isNull);
      expect(
        const OnboardingForm(heightCm: '   ').toRequest().heightCm,
        isNull,
      );
      expect(
        const OnboardingForm(heightCm: 'abc').toRequest().heightCm,
        isNull,
      );
      expect(const OnboardingForm(weightKg: '').weightAsDouble, isNull);
    });

    test('listas separadas por vírgula descartam espaços e itens vazios', () {
      final request = const OnboardingForm(
        dietaryRestrictions: ' lactose , glúten ,, ',
        foodPreferences: 'frango,arroz',
      ).toRequest();

      expect(request.dietaryRestrictions, ['lactose', 'glúten']);
      expect(request.foodPreferences, ['frango', 'arroz']);
    });

    test('texto livre em branco vira null', () {
      expect(
        const OnboardingForm(injuryNotes: '   ').toRequest().injuryNotes,
        isNull,
      );
      expect(
        const OnboardingForm(
          injuryNotes: ' dor no ombro ',
        ).toRequest().injuryNotes,
        'dor no ombro',
      );
    });

    test('biotipo vazio vira null — o campo é opcional', () {
      expect(const OnboardingForm(biotype: '').toRequest().biotype, isNull);
      expect(const OnboardingForm().toRequest().biotype, isNull);
      expect(
        const OnboardingForm(biotype: 'Mesomorph').toRequest().biotype,
        'Mesomorph',
      );
    });

    test('data de nascimento sai como yyyy-MM-dd', () {
      final request = OnboardingForm(
        birthDate: DateTime(1996, 7, 12),
      ).toRequest();

      // O backend desserializa em LocalDate; com hora junto, falharia.
      expect(request.birthDate, '1996-07-12');
    });

    test('sem data de nascimento o campo vai nulo', () {
      expect(const OnboardingForm().toRequest().birthDate, isNull);
    });
  });

  group('toggle de múltipla escolha', () {
    test('adiciona e remove', () {
      expect(OnboardingController.toggle([], 'Chest'), ['Chest']);
      expect(OnboardingController.toggle(['Chest'], 'Back'), ['Chest', 'Back']);
      expect(OnboardingController.toggle(['Chest', 'Back'], 'Chest'), ['Back']);
    });

    test('não altera a lista original', () {
      const original = ['Chest'];
      OnboardingController.toggle(original, 'Back');
      expect(original, ['Chest']);
    });
  });

  group('edição de perfil existente', () {
    test('preenche o formulário e considera o consentimento já dado', () {
      const profile = UserProfile(
        birthDate: '1996-07-12',
        sex: 'F',
        heightCm: 165,
        biotype: 'Ectomorph',
        experienceLevel: 'Advanced',
        goal: 'WeightLoss',
        trainingDaysPerWeek: 5,
        priorityMuscleGroups: ['Glutes'],
        injuryTags: ['knee'],
        injuryNotes: 'menisco',
        availableEquipment: ['Dumbbell'],
        dietaryRestrictions: ['lactose', 'glúten'],
        foodPreferences: ['frango'],
      );

      final form = OnboardingForm.fromProfile(profile);

      expect(form.birthDate, DateTime(1996, 7, 12));
      expect(form.sex, 'F');
      expect(form.heightCm, '165');
      expect(form.trainingDaysPerWeek, 5);
      expect(form.priorityMuscleGroups, ['Glutes']);
      // Listas voltam como texto separado por vírgula para caber num campo só.
      expect(form.dietaryRestrictions, 'lactose, glúten');
      // Quem já tem perfil já consentiu; a trilha está registrada no servidor.
      expect(form.consented, isTrue);
    });

    test('perfil com campos nulos não quebra', () {
      final form = OnboardingForm.fromProfile(const UserProfile());

      expect(form.birthDate, isNull);
      expect(form.sex, 'M');
      expect(form.heightCm, '');
      expect(form.injuryNotes, '');
      expect(form.dietaryRestrictions, '');
    });
  });

  group('catálogos de opções', () {
    test('valores batem com os enums do backend', () {
      // Um erro de digitação aqui só apareceria como 400 na hora de salvar.
      expect(ProfileOptions.experienceLevels.map((o) => o.value), [
        'Beginner',
        'Intermediate',
        'Advanced',
      ]);
      expect(ProfileOptions.goals.map((o) => o.value), [
        'Hypertrophy',
        'WeightLoss',
        'Conditioning',
        'Aesthetics',
      ]);
      expect(ProfileOptions.biotypes.map((o) => o.value), [
        'Ectomorph',
        'Mesomorph',
        'Endomorph',
      ]);
      expect(ProfileOptions.sexes.map((o) => o.value), ['M', 'F']);
    });

    test(
      'tags de lesão batem com as contraindicações do catálogo de exercícios',
      () {
        // Vocabulário fixado no ExerciseSeed: knee, lower-back, shoulder, elbow,
        // wrist, hip, neck. Uma tag fora disso não filtraria exercício nenhum.
        expect(ProfileOptions.injuries.map((o) => o.value).toSet(), {
          'knee',
          'lower-back',
          'shoulder',
          'elbow',
          'wrist',
          'hip',
          'neck',
        });
      },
    );

    test('não há valores duplicados', () {
      for (final catalog in [
        ProfileOptions.muscleGroups,
        ProfileOptions.equipment,
        ProfileOptions.injuries,
        ProfileOptions.goals,
      ]) {
        final values = catalog.map((o) => o.value).toList();
        expect(values.toSet().length, values.length);
      }
    });
  });
}
