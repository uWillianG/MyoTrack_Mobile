import 'dart:typed_data';

import 'package:dio/dio.dart';

import '../../../core/network/api_client.dart';
import 'meal_models.dart';

/// Fala com `/api/meal-analyses`.
///
/// Ao contrário do registro de treino, **não passa pela fila offline**: a análise depende de
/// uma chamada de IA no servidor, então não há como "aceitar agora e subir depois" — e uma
/// foto de vários MB guardada numa fila local encheria o aparelho sem entregar resultado.
class MealRepository {
  MealRepository(this._api);

  final ApiClient _api;

  /// Sobe a foto e devolve o `jobId` da análise, que o [JobWatcher] acompanha.
  Future<String> analyze({
    required Uint8List photo,
    required String fileName,
    required String contentType,
    void Function(int sent, int total)? onProgress,
  }) async {
    final form = FormData.fromMap({
      'photo': MultipartFile.fromBytes(
        photo,
        filename: fileName,
        // Sem o contentType explícito o Dio manda application/octet-stream e o backend
        // recusa a foto por tipo não permitido.
        contentType: DioMediaType.parse(contentType),
      ),
    });

    final json = await _api.upload<Map<String, dynamic>>(
      '/api/meal-analyses',
      form,
      onProgress: onProgress,
    );
    return json['jobId'] as String;
  }

  Future<List<MealAnalysis>> recent({int limit = 30}) async {
    final json = await _api.get<List<dynamic>>(
      '/api/meal-analyses',
      query: {'limit': limit},
    );
    return json
        .map((e) => MealAnalysis.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<MealAnalysis> byId(String id) async {
    final json = await _api.get<Map<String, dynamic>>('/api/meal-analyses/$id');
    return MealAnalysis.fromJson(json);
  }

  /// Corrige itens e/ou tira a refeição do diário. Devolve a análise já recalculada.
  Future<MealAnalysis> adjust(String id, MealAdjustRequest request) async {
    final json = await _api.put<Map<String, dynamic>>(
      '/api/meal-analyses/$id',
      body: request.toJson(),
    );
    return MealAnalysis.fromJson(json);
  }
}
