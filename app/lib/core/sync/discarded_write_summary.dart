import 'dart:convert';

import 'package:intl/intl.dart';

import '../db/local_database.dart';
import '../design/format.dart';

/// Uma escrita recusada, dita em português.
///
/// A tabela guarda endpoint, payload e a mensagem do servidor — três coisas que não significam
/// nada para quem usa o app. Um aviso de "falha em POST /api/measurements" é indistinguível de
/// ruído e vai ser ignorado; "a pesagem de 82,4 kg do dia 28/07 não subiu" é acionável, porque
/// a pessoa sabe exatamente o que refazer.
class DiscardedWriteSummary {
  const DiscardedWriteSummary({required this.what, required this.reason});

  /// O registro perdido, com data quando o payload tem uma: "Pesagem de 82,4 kg (28/07)".
  final String what;

  /// O que o servidor respondeu, como veio.
  final String reason;

  /// Lê o payload para descrever o registro.
  ///
  /// Todo acesso ao JSON é defensivo. O payload foi serializado por uma versão do app que pode
  /// ser mais antiga que esta, e um aviso que **quebra ao ser exibido** seria pior que o
  /// silêncio que ele veio substituir: a pessoa perderia o registro e a tela junto.
  factory DiscardedWriteSummary.of(DiscardedWrite write) {
    Map<String, dynamic> payload;
    try {
      final decoded = jsonDecode(write.payload);
      payload = decoded is Map<String, dynamic> ? decoded : const {};
    } on FormatException {
      payload = const {};
    }

    final date = _dayOf(payload['date']);
    final suffix = date == null ? '' : ' ($date)';

    return DiscardedWriteSummary(
      what: '${_describe(write.endpoint, payload)}$suffix',
      reason: write.error,
    );
  }

  static String _describe(String endpoint, Map<String, dynamic> payload) {
    switch (endpoint) {
      case '/api/measurements':
        final weight = payload['weightKg'];
        // Uma medida pode ser só cintura ou só percentual de gordura — o peso é opcional no
        // corpo da requisição, e dizer "Pesagem de null kg" seria pior que não dizer o número.
        return weight is num
            ? 'Pesagem de ${Fmt.kg(weight)}'
            : 'Medida corporal';
      case '/api/sessions':
        final sets = payload['sets'];
        final count = sets is List ? sets.length : 0;
        return count == 1 ? 'Treino com 1 série' : 'Treino com $count séries';
      default:
        return 'Registro enviado a $endpoint';
    }
  }

  /// "28/07" a partir da data ISO do payload, ou null se não der para ler.
  ///
  /// Sem o ano: quem está lendo o aviso perdeu o registro nos últimos dias, e "28/07/2026"
  /// gasta espaço com a parte que a pessoa já sabe.
  static String? _dayOf(Object? raw) {
    if (raw is! String) {
      return null;
    }
    final date = DateTime.tryParse(raw);
    return date == null ? null : DateFormat('dd/MM', 'pt_BR').format(date);
  }
}
