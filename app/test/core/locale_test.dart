import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';

/// O app é só em pt-BR, mas o `intl` não sabe disso sozinho: sem carregar os símbolos de
/// data e sem dizer o locale padrão, ele formata em en_US. O diário mostrava
/// "Wednesday, 28 de July" — metade em cada idioma.
void main() {
  setUpAll(() async {
    await initializeDateFormatting('pt_BR');
    Intl.defaultLocale = 'pt_BR';
  });

  final date = DateTime(2026, 7, 29);

  test('dia da semana por extenso sai em português', () {
    // É o formato do cabeçalho do diário.
    expect(
      DateFormat("EEEE, d 'de' MMMM").format(date),
      'quarta-feira, 29 de julho',
    );
  });

  test('dia abreviado sai em português', () {
    // É o rótulo das barras do gráfico da semana.
    expect(DateFormat('E').format(date), startsWith('qua'));
  });

  test('formato numérico não depende de locale, e continua igual', () {
    // Os gráficos do dashboard usam este, e por isso nunca quebraram.
    expect(DateFormat('d/M').format(date), '29/7');
  });
}
