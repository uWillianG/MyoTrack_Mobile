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
    bool illustrated = false,
    void Function(int sent, int total)? onProgress,
  }) async {
    final form = FormData.fromMap({
      // Vai como texto: é multipart, não JSON.
      'illustrated': '$illustrated',
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

  /// Pede a estimativa a partir do texto livre e devolve o `jobId`.
  ///
  /// **Nada é gravado por esta chamada.** O job devolve os itens no `resultJson` para o
  /// usuário conferir; quem grava é o [createManual]. É assíncrona pelo mesmo motivo da foto —
  /// a chave da IA vive só no Worker —, e gasta a mesma cota diária: o job é do tipo
  /// `MealPhoto`, que é o que o servidor conta.
  Future<String> estimateFromText(String text) async {
    final json = await _api.post<Map<String, dynamic>>(
      '/api/meal-analyses/estimate',
      body: {'text': text},
    );
    return json['jobId'] as String;
  }

  /// Grava uma refeição montada pelo usuário e devolve a que o servidor gravou.
  ///
  /// Devolve a análise já com os totais somados **lá**: mostrar de volta o que o cliente
  /// calculou esconderia justamente as correções que o servidor aplica — a caloria
  /// reconciliada com os macros, a porção presa à faixa, o item do catálogo recalculado.
  Future<MealAnalysis> createManual(MealManualRequest request) async {
    final json = await _api.post<Map<String, dynamic>>(
      '/api/meal-analyses/manual',
      body: request.toJson(),
    );
    return MealAnalysis.fromJson(json);
  }

  /// Busca no catálogo nutricional. [query] em branco devolve o começo da lista.
  ///
  /// O branco não é um caso degenerado: é o que a folha de busca mostra **antes** de a pessoa
  /// digitar qualquer coisa. Uma lista vazia ali pareceria catálogo vazio, e o caminho do
  /// catálogo morreria antes da primeira tecla.
  Future<List<FoodItem>> foods({String query = '', int limit = 30}) async {
    final json = await _api.get<List<dynamic>>(
      '/api/foods',
      query: {'q': query, 'limit': limit},
    );
    return json
        .map((e) => FoodItem.fromJson(e as Map<String, dynamic>))
        .toList();
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
