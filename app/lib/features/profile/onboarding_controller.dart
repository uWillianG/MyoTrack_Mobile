import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/network/api_exception.dart';
import '../../core/providers.dart';
import 'data/profile_models.dart';
import 'data/profile_repository.dart';

final profileRepositoryProvider = Provider<ProfileRepository>(
  (ref) => ProfileRepository(ref.watch(apiClientProvider)),
);

/// Perfil salvo, ou null se o onboarding ainda não foi feito.
final userProfileProvider = FutureProvider<UserProfile?>(
  (ref) => ref.watch(profileRepositoryProvider).get(),
);

/// O que o formulário de onboarding tem em mãos.
///
/// Campos numéricos ficam como texto porque é isso que o usuário digita: guardar `double`
/// faria "1,8" virar null no meio da digitação e o campo se apagar sozinho.
class OnboardingForm {
  const OnboardingForm({
    this.birthDate,
    this.sex = 'M',
    this.heightCm = '',
    this.weightKg = '',
    this.biotype,
    this.experienceLevel = 'Beginner',
    this.goal = 'Hypertrophy',
    this.trainingDaysPerWeek = 3,
    this.priorityMuscleGroups = const [],
    this.injuryTags = const [],
    this.injuryNotes = '',
    this.availableEquipment = const [],
    this.dietaryRestrictions = '',
    this.foodPreferences = '',
    this.consented = false,
  });

  final DateTime? birthDate;
  final String sex;
  final String heightCm;
  final String weightKg;
  final String? biotype;
  final String experienceLevel;
  final String goal;
  final int trainingDaysPerWeek;
  final List<String> priorityMuscleGroups;
  final List<String> injuryTags;
  final String injuryNotes;
  final List<String> availableEquipment;
  final String dietaryRestrictions;
  final String foodPreferences;
  final bool consented;

  OnboardingForm copyWith({
    DateTime? birthDate,
    String? sex,
    String? heightCm,
    String? weightKg,
    String? biotype,
    String? experienceLevel,
    String? goal,
    int? trainingDaysPerWeek,
    List<String>? priorityMuscleGroups,
    List<String>? injuryTags,
    String? injuryNotes,
    List<String>? availableEquipment,
    String? dietaryRestrictions,
    String? foodPreferences,
    bool? consented,
  }) => OnboardingForm(
    birthDate: birthDate ?? this.birthDate,
    sex: sex ?? this.sex,
    heightCm: heightCm ?? this.heightCm,
    weightKg: weightKg ?? this.weightKg,
    biotype: biotype ?? this.biotype,
    experienceLevel: experienceLevel ?? this.experienceLevel,
    goal: goal ?? this.goal,
    trainingDaysPerWeek: trainingDaysPerWeek ?? this.trainingDaysPerWeek,
    priorityMuscleGroups: priorityMuscleGroups ?? this.priorityMuscleGroups,
    injuryTags: injuryTags ?? this.injuryTags,
    injuryNotes: injuryNotes ?? this.injuryNotes,
    availableEquipment: availableEquipment ?? this.availableEquipment,
    dietaryRestrictions: dietaryRestrictions ?? this.dietaryRestrictions,
    foodPreferences: foodPreferences ?? this.foodPreferences,
    consented: consented ?? this.consented,
  );

  /// Preenche o formulário a partir de um perfil já salvo (modo edição).
  static OnboardingForm fromProfile(UserProfile profile) => OnboardingForm(
    birthDate: DateTime.tryParse(profile.birthDate ?? ''),
    sex: profile.sex ?? 'M',
    heightCm: profile.heightCm?.toStringAsFixed(0) ?? '',
    biotype: profile.biotype,
    experienceLevel: profile.experienceLevel,
    goal: profile.goal,
    trainingDaysPerWeek: profile.trainingDaysPerWeek,
    priorityMuscleGroups: profile.priorityMuscleGroups,
    injuryTags: profile.injuryTags,
    injuryNotes: profile.injuryNotes ?? '',
    availableEquipment: profile.availableEquipment,
    dietaryRestrictions: profile.dietaryRestrictions.join(', '),
    foodPreferences: profile.foodPreferences.join(', '),
    // Quem já tem perfil já consentiu — a trilha está registrada no servidor.
    consented: true,
  );

  ProfileRequest toRequest() => ProfileRequest(
    birthDate: birthDate?.toIso8601String().substring(0, 10),
    sex: sex,
    heightCm: _toDouble(heightCm),
    biotype: (biotype?.isEmpty ?? true) ? null : biotype,
    experienceLevel: experienceLevel,
    goal: goal,
    trainingDaysPerWeek: trainingDaysPerWeek,
    priorityMuscleGroups: priorityMuscleGroups,
    injuryNotes: injuryNotes.trim().isEmpty ? null : injuryNotes.trim(),
    injuryTags: injuryTags,
    availableEquipment: availableEquipment,
    dietaryRestrictions: _splitList(dietaryRestrictions),
    foodPreferences: _splitList(foodPreferences),
  );

  double? get weightAsDouble => _toDouble(weightKg);

  /// Aceita vírgula como separador decimal — é o que o teclado brasileiro oferece.
  static double? _toDouble(String value) {
    final normalized = value.trim().replaceAll(',', '.');
    return normalized.isEmpty ? null : double.tryParse(normalized);
  }

  static List<String> _splitList(String value) =>
      value.split(',').map((s) => s.trim()).where((s) => s.isNotEmpty).toList();
}

class OnboardingState {
  const OnboardingState({
    this.form = const OnboardingForm(),
    this.loading = true,
    this.saving = false,
    this.hasProfile = false,
    this.error,
  });

  final OnboardingForm form;
  final bool loading;
  final bool saving;

  /// Já existia perfil ao abrir a tela: muda o texto dos botões e dispensa o consentimento.
  final bool hasProfile;
  final String? error;

  OnboardingState copyWith({
    OnboardingForm? form,
    bool? loading,
    bool? saving,
    bool? hasProfile,
    String? error,
  }) => OnboardingState(
    form: form ?? this.form,
    loading: loading ?? this.loading,
    saving: saving ?? this.saving,
    hasProfile: hasProfile ?? this.hasProfile,
    error: error,
  );
}

class OnboardingController extends StateNotifier<OnboardingState> {
  OnboardingController(this._ref) : super(const OnboardingState()) {
    _load();
  }

  final Ref _ref;

  ProfileRepository get _repo => _ref.read(profileRepositoryProvider);

  Future<void> _load() async {
    try {
      final profile = await _repo.get();
      state = OnboardingState(
        form: profile == null
            ? const OnboardingForm()
            : OnboardingForm.fromProfile(profile),
        loading: false,
        hasProfile: profile != null,
      );
    } on ApiException catch (e) {
      state = OnboardingState(loading: false, error: e.message);
    }
  }

  void update(OnboardingForm form) =>
      state = state.copyWith(form: form, error: null);

  /// Liga ou desliga um item de uma lista de múltipla escolha.
  static List<String> toggle(List<String> list, String value) =>
      list.contains(value)
      ? (list.where((v) => v != value).toList())
      : ([...list, value]);

  /// Salva perfil, consentimentos e o peso inicial. Devolve se deu certo.
  Future<bool> submit() async {
    final form = state.form;

    // O consentimento só é exigido de quem ainda não tem perfil: quem já passou por
    // aqui já tem a trilha registrada no servidor.
    if (!state.hasProfile && !form.consented) {
      state = state.copyWith(
        error:
            'É necessário aceitar o tratamento de dados de saúde para continuar.',
      );
      return false;
    }

    state = state.copyWith(saving: true, error: null);
    try {
      await _repo.save(form.toRequest());

      if (!state.hasProfile) {
        await _repo.recordConsents(const [
          ConsentRequest(
            type: 'HealthData',
            termsVersion: ProfileOptions.termsVersion,
          ),
          ConsentRequest(
            type: 'TermsOfService',
            termsVersion: ProfileOptions.termsVersion,
          ),
        ]);
      }

      // O peso é o que permite calcular o TDEE; sem ele a dieta não sai.
      final weight = form.weightAsDouble;
      if (weight != null) {
        await _repo.addMeasurement(
          MeasurementRequest(
            date: DateTime.now().toIso8601String().substring(0, 10),
            weightKg: weight,
          ),
        );
      }

      _ref.invalidate(userProfileProvider);
      state = state.copyWith(saving: false, hasProfile: true);
      return true;
    } on ApiException catch (e) {
      state = state.copyWith(saving: false, error: e.message);
      return false;
    }
  }
}

final onboardingControllerProvider =
    StateNotifierProvider.autoDispose<OnboardingController, OnboardingState>(
      (ref) => OnboardingController(ref),
    );
