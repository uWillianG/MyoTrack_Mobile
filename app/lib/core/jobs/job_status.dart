/// Estado de um job assíncrono de IA (`AnalysisJob` no backend).
///
/// Os nomes vêm em PascalCase porque o backend serializa o enum pelo nome da constante
/// C#/Java — o mesmo contrato que a SPA consome em `api.ts:81`.
enum JobState {
  pending('Pending'),
  processing('Processing'),
  completed('Completed'),
  failed('Failed');

  const JobState(this.wireName);

  final String wireName;

  /// Um estado desconhecido é tratado como "ainda processando": é melhor continuar
  /// aguardando do que declarar falha por um valor que o backend passou a emitir.
  static JobState parse(String? value) => JobState.values.firstWhere(
    (s) => s.wireName == value,
    orElse: () => JobState.processing,
  );

  bool get isTerminal => this == completed || this == failed;
}

/// Retrato do job devolvido por `GET /api/jobs/{id}` e pelo stream SSE.
class JobStatus {
  const JobStatus({
    required this.id,
    required this.type,
    required this.state,
    this.resultJson,
    this.lastError,
  });

  final String id;
  final String type;
  final JobState state;

  /// JSON com o id do que foi produzido — ex.: `{"workoutPlanId":"..."}`.
  final String? resultJson;

  /// Mensagem de erro em pt-BR quando o job falhou.
  final String? lastError;

  bool get isTerminal => state.isTerminal;
  bool get succeeded => state == JobState.completed;

  factory JobStatus.fromJson(Map<String, dynamic> json) => JobStatus(
    id: json['id'] as String,
    type: json['type'] as String? ?? '',
    state: JobState.parse(json['status'] as String?),
    resultJson: json['resultJson'] as String?,
    lastError: json['lastError'] as String?,
  );
}
