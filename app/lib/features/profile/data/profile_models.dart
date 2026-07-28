import 'package:freezed_annotation/freezed_annotation.dart';

part 'profile_models.freezed.dart';
part 'profile_models.g.dart';

/// Perfil do usuário — `GET`/`PUT /api/profile`.
///
/// Os enums viajam pelo nome em PascalCase, como o backend os serializa. Aqui são `String`
/// de propósito: um valor novo no servidor (um biotipo a mais, por exemplo) não pode
/// quebrar a desserialização num app já publicado, que o usuário talvez demore a atualizar.
/// A tradução para português vive em [ProfileOptions].
@freezed
abstract class UserProfile with _$UserProfile {
  const factory UserProfile({
    String? id,
    String? userId,
    String? birthDate,
    String? sex,
    double? heightCm,
    String? biotype,
    @Default('Beginner') String experienceLevel,
    @Default('Hypertrophy') String goal,
    @Default(3) int trainingDaysPerWeek,
    @Default([]) List<String> priorityMuscleGroups,
    String? injuryNotes,
    @Default([]) List<String> injuryTags,
    @Default([]) List<String> availableEquipment,
    @Default([]) List<String> dietaryRestrictions,
    @Default([]) List<String> foodPreferences,
  }) = _UserProfile;

  factory UserProfile.fromJson(Map<String, dynamic> json) =>
      _$UserProfileFromJson(json);
}

/// Corpo do `PUT /api/profile`.
@freezed
abstract class ProfileRequest with _$ProfileRequest {
  const factory ProfileRequest({
    String? birthDate,
    String? sex,
    double? heightCm,
    String? biotype,
    required String experienceLevel,
    required String goal,
    required int trainingDaysPerWeek,
    required List<String> priorityMuscleGroups,
    String? injuryNotes,
    required List<String> injuryTags,
    required List<String> availableEquipment,
    required List<String> dietaryRestrictions,
    required List<String> foodPreferences,
  }) = _ProfileRequest;

  factory ProfileRequest.fromJson(Map<String, dynamic> json) =>
      _$ProfileRequestFromJson(json);
}

@freezed
abstract class ConsentRequest with _$ConsentRequest {
  const factory ConsentRequest({
    required String type,
    required String termsVersion,
  }) = _ConsentRequest;

  factory ConsentRequest.fromJson(Map<String, dynamic> json) =>
      _$ConsentRequestFromJson(json);
}

@freezed
abstract class MeasurementRequest with _$MeasurementRequest {
  const factory MeasurementRequest({
    required String date,
    double? weightKg,
    double? bodyFatPercent,
    double? waistCm,
    double? chestCm,
    double? hipCm,
    double? armCm,
    double? thighCm,
    double? calfCm,
  }) = _MeasurementRequest;

  factory MeasurementRequest.fromJson(Map<String, dynamic> json) =>
      _$MeasurementRequestFromJson(json);
}

/// Uma opção de escolha: o valor que vai para a API e o rótulo que o usuário lê.
typedef Option = ({String value, String label});

/// Catálogos das opções do onboarding.
///
/// Os valores precisam bater exatamente com os enums do backend — um erro de digitação aqui
/// só apareceria como 400 na hora de salvar. Os rótulos são os mesmos da SPA, para que quem
/// usa os dois não veja nomes diferentes para a mesma coisa.
class ProfileOptions {
  const ProfileOptions._();

  /// Versão dos termos aceita no cadastro. Subir isto força um novo aceite.
  static const termsVersion = '1.0';

  static const List<Option> muscleGroups = [
    (value: 'Chest', label: 'Peito'),
    (value: 'Back', label: 'Costas'),
    (value: 'Shoulders', label: 'Ombros'),
    (value: 'Traps', label: 'Trapézio'),
    (value: 'Biceps', label: 'Bíceps'),
    (value: 'Triceps', label: 'Tríceps'),
    (value: 'Forearms', label: 'Antebraços'),
    (value: 'Quadriceps', label: 'Quadríceps'),
    (value: 'Hamstrings', label: 'Posteriores'),
    (value: 'Glutes', label: 'Glúteos'),
    (value: 'Calves', label: 'Panturrilhas'),
    (value: 'Abs', label: 'Abdômen'),
    (value: 'LowerBack', label: 'Lombar'),
  ];

  static const List<Option> equipment = [
    (value: 'Barbell', label: 'Barra'),
    (value: 'Dumbbell', label: 'Halteres'),
    (value: 'Machine', label: 'Máquinas'),
    (value: 'Cable', label: 'Polia'),
    (value: 'Kettlebell', label: 'Kettlebell'),
    (value: 'Bodyweight', label: 'Peso corporal'),
  ];

  /// Cruzadas com as tags de contraindicação do catálogo de exercícios: marcar "joelho"
  /// remove agachamento, leg press e afins do treino gerado.
  static const List<Option> injuries = [
    (value: 'knee', label: 'Joelho'),
    (value: 'lower-back', label: 'Lombar'),
    (value: 'shoulder', label: 'Ombro'),
    (value: 'elbow', label: 'Cotovelo'),
    (value: 'wrist', label: 'Punho'),
    (value: 'hip', label: 'Quadril'),
    (value: 'neck', label: 'Pescoço'),
  ];

  static const List<Option> experienceLevels = [
    (value: 'Beginner', label: 'Iniciante'),
    (value: 'Intermediate', label: 'Intermediário'),
    (value: 'Advanced', label: 'Avançado'),
  ];

  static const List<Option> goals = [
    (value: 'Hypertrophy', label: 'Hipertrofia'),
    (value: 'WeightLoss', label: 'Emagrecimento'),
    (value: 'Conditioning', label: 'Condicionamento'),
    (value: 'Aesthetics', label: 'Estética'),
  ];

  static const List<Option> biotypes = [
    (
      value: 'Ectomorph',
      label: 'Ectomorfo (magro, dificuldade de ganhar peso)',
    ),
    (value: 'Mesomorph', label: 'Mesomorfo (ganha músculo com facilidade)'),
    (value: 'Endomorph', label: 'Endomorfo (ganha peso com facilidade)'),
  ];

  static const List<Option> sexes = [
    (value: 'M', label: 'Masculino'),
    (value: 'F', label: 'Feminino'),
  ];
}
