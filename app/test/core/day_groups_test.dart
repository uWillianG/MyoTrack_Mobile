import 'package:flutter_test/flutter_test.dart';
import 'package:myotrack/core/day_groups.dart';

/// O agrupamento por dia é decisão de produto — quem abre um bloco novo, quem entra no
/// anterior — e decisão de produto se testa por tabela, sem montar árvore de widgets.
void main() {
  final now = DateTime(2026, 8, 4, 15);

  List<DayGroup<String?>> group(List<String?> dates) =>
      groupByDay(dates, now, at: (date) => date, undated: 'Sem data');

  test('um bloco por data, na ordem em que veio', () {
    final days = group([
      '2026-08-04T12:34:00',
      '2026-08-04T08:10:00',
      '2026-08-03T20:10:00',
      '2026-07-29T19:00:00',
    ]);

    expect(days.map((d) => d.label), ['Hoje', 'Ontem', '29 de julho']);
    expect(days.first.items, hasLength(2));
  });

  test('item sem data entra no dia anterior', () {
    final days = group(['2026-08-04T12:34:00', null, '2026-08-03T20:10:00']);

    expect(days.map((d) => d.label), ['Hoje', 'Ontem']);
    expect(days.first.items, hasLength(2));
  });

  // O caso que a primeira versão errava: comparar com o **último item** do grupo em vez de com
  // a data do grupo fazia o item sem data apagá-la, e o de outro dia entrava no mesmo bloco.
  test('item sem data não apaga a data do dia aberto', () {
    final days = group([
      '2026-08-04T12:34:00',
      null,
      null,
      '2026-08-03T20:10:00',
    ]);

    expect(days, hasLength(2));
    expect(days.first.items, hasLength(3));
    expect(days.last.label, 'Ontem');
  });

  test('sem dia anterior nenhum, o sem data ganha rótulo próprio', () {
    expect(group([null]).single.label, 'Sem data');
  });

  test('histórico vazio não vira bloco nenhum', () {
    expect(group([]), isEmpty);
  });
}
