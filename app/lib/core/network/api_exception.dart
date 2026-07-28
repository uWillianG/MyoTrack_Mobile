import 'package:dio/dio.dart';

/// Erro de API já traduzido para algo que pode ir à tela.
///
/// O backend responde `{"error": "..."}` ou `{"errors": [...]}` com texto em pt-BR pronto
/// para o usuário (ex.: "Limite diário de 10 análises atingido. Assine o Pro para ampliar.").
/// Esta classe extrai essa mensagem em vez de mostrar "DioException [bad response]".
class ApiException implements Exception {
  ApiException(this.message, {this.statusCode, this.errors = const []});

  final String message;
  final int? statusCode;

  /// Lista de erros — o cadastro devolve todas as regras de senha violadas de uma vez.
  final List<String> errors;

  /// Limite diário de IA atingido: a tela oferece o plano Pro em vez de só mostrar o erro.
  bool get isRateLimited => statusCode == 429;

  bool get isUnauthorized => statusCode == 401;

  bool get isNetworkFailure => statusCode == null;

  /// Vale a pena tentar de novo mais tarde?
  ///
  /// Sem status é rede (offline, timeout); 5xx é o servidor em apuros — os dois passam. Um
  /// 4xx não: o servidor entendeu e recusou, e a mesma requisição amanhã será recusada
  /// igual. É essa distinção que decide o que a fila de sincronização guarda e o que
  /// descarta.
  bool get isRetryable =>
      isNetworkFailure || (statusCode != null && statusCode! >= 500);

  factory ApiException.from(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return ApiException('A conexão demorou demais. Tente de novo.');
      case DioExceptionType.connectionError:
        return ApiException(
          'Sem conexão com o servidor. Verifique sua internet.',
        );
      case DioExceptionType.cancel:
        return ApiException('Operação cancelada.');
      default:
        break;
    }

    final status = e.response?.statusCode;
    final data = e.response?.data;

    if (data is Map<String, dynamic>) {
      final single = data['error'];
      if (single is String && single.isNotEmpty) {
        return ApiException(single, statusCode: status);
      }
      final many = data['errors'];
      if (many is List && many.isNotEmpty) {
        final list = many.whereType<String>().toList();
        return ApiException(list.join(' '), statusCode: status, errors: list);
      }
    }

    return ApiException(_genericFor(status), statusCode: status);
  }

  static String _genericFor(int? status) => switch (status) {
    400 => 'Requisição inválida.',
    401 => 'Sua sessão expirou. Entre novamente.',
    403 => 'Você não tem permissão para isso.',
    404 => 'Não encontrado.',
    409 => 'Conflito com o estado atual.',
    413 => 'Arquivo grande demais.',
    429 => 'Limite atingido. Tente mais tarde.',
    // O padrão `int? s when ...` é necessário: comparar diretamente com `>= 500`
    // não compila porque o receptor pode ser nulo.
    final int s when s >= 500 =>
      'O servidor falhou. Tente de novo em instantes.',
    _ => 'Algo deu errado.',
  };

  @override
  String toString() => message;
}
