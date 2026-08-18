import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:intl/intl.dart';

import '../../core/network/api_client.dart';
import '../../core/providers.dart';
import 'data/diary_models.dart';

/// Fala com `/api/diary`.
class DiaryRepository {
  DiaryRepository(this._api);

  final ApiClient _api;

  /// O dia pedido, no fuso do aparelho.
  Future<DiaryDay> day(DateTime date) async {
    final json = await _api.get<Map<String, dynamic>>(
      '/api/diary',
      query: {
        // Data local, sem passar por UTC: converter aqui mudaria o dia de quem abre o
        // diário à noite, justamente o caso que o parâmetro de fuso existe para resolver.
        'date': DateFormat('yyyy-MM-dd').format(date),
        'tz': timezoneOffsetMinutes(date),
      },
    );
    return DiaryDay.fromJson(json);
  }

  /// Inclui ou tira uma refeição do diário.
  Future<void> setIncluded(String entryId, bool included) => _api.put<void>(
    '/api/diary/entries/$entryId',
    body: {'included': included},
  );
}

/// Offset do fuso na convenção do `getTimezoneOffset()` do JavaScript, que é a que o backend
/// espera — e ela é **invertida** em relação à do Dart.
///
/// No Brasil (UTC−3), o Dart devolve −180 minutos e o JavaScript devolve +180. Mandar o sinal
/// do Dart jogaria o corte do dia seis horas para o lado errado, e a janta de ontem apareceria
/// somando no almoço de hoje.
int timezoneOffsetMinutes(DateTime date) => -date.timeZoneOffset.inMinutes;

final diaryRepositoryProvider = Provider<DiaryRepository>(
  (ref) => DiaryRepository(ref.watch(apiClientProvider)),
);

/// Dia atualmente aberto no diário. Começa em hoje.
final diaryDateProvider = StateProvider<DateTime>((ref) {
  final now = DateTime.now();
  return DateTime(now.year, now.month, now.day);
});

/// Um dia qualquer do diário, por data.
///
/// **Existe por causa do carrossel.** Enquanto o diário abria um dia por vez, um provider só
/// bastava: trocar de dia era trocar o parâmetro dele. O gesto de arrastar entre dias precisa
/// de outra coisa — durante o arrasto **duas datas estão na tela ao mesmo tempo**, a que sai e
/// a que entra, e um provider único não sabe responder duas perguntas.
///
/// Com a família, cada página assiste à sua data e o Riverpod guarda o que já veio: voltar dois
/// dias e avançar de novo não refaz chamada nenhuma, e o dia vizinho aparece pronto no meio do
/// gesto em vez de piscar um carregando.
final diaryDayOfProvider = FutureProvider.family<DiaryDay, DateTime>(
  (ref, date) => ref.watch(diaryRepositoryProvider).day(date),
);

/// O dia aberto. É o que a Hoje e as telas que não navegam por data usam.
final diaryDayProvider = FutureProvider<DiaryDay>(
  (ref) => ref.watch(diaryDayOfProvider(ref.watch(diaryDateProvider)).future),
);
