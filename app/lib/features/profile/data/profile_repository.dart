import '../../../core/network/api_client.dart';
import '../../../core/network/api_exception.dart';
import 'profile_models.dart';

/// Fala com `/api/profile`, `/api/profile/consents` e `/api/measurements`.
class ProfileRepository {
  ProfileRepository(this._api);

  final ApiClient _api;

  /// Perfil atual, ou null quando ainda não existe.
  ///
  /// O backend responde **404 quando não há perfil** — não é erro, é o sinal de que o
  /// onboarding precisa ser preenchido. Converter para null aqui evita que cada tela
  /// tenha de saber disso.
  Future<UserProfile?> get() async {
    try {
      final json = await _api.get<Map<String, dynamic>>('/api/profile');
      return UserProfile.fromJson(json);
    } on ApiException catch (e) {
      if (e.statusCode == 404) {
        return null;
      }
      rethrow;
    }
  }

  Future<UserProfile> save(ProfileRequest request) async {
    final json = await _api.put<Map<String, dynamic>>(
      '/api/profile',
      body: request.toJson(),
    );
    return UserProfile.fromJson(json);
  }

  /// Registra os consentimentos. Trilha append-only: cada aceite vira uma linha nova.
  Future<void> recordConsents(List<ConsentRequest> consents) => _api.post<void>(
    '/api/profile/consents',
    body: consents.map((c) => c.toJson()).toList(),
  );

  Future<void> addMeasurement(MeasurementRequest request) => _api
      .post<Map<String, dynamic>>('/api/measurements', body: request.toJson());
}
