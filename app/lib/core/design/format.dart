import 'package:intl/intl.dart';

/// Como um número aparece na tela.
///
/// Mora no design system, e não em cada tela, porque formatação de número **é** design: o
/// mesmo 1476 saía "1.476" no hub e "1476" no diário, e "110 g" no fechamento do dia contra
/// "110g" na mesma linha do diário. Nenhuma dessas telas está errada sozinha; erradas são as
/// duas juntas, e é isso que faz um app parecer costurado de pedaços.
///
/// As regras aqui são as de pt-BR: ponto como separador de milhar, vírgula como decimal, e
/// espaço antes da unidade (o SI exige, e "110g" é o tipo de detalhe que ninguém aponta mas
/// todo mundo sente).
abstract final class Fmt {
  /// "1.476". Arredonda: nenhuma tela do app mostra caloria com casa decimal.
  static String integer(num value) =>
      NumberFormat.decimalPattern('pt_BR').format(value.round());

  /// "1.476 kcal".
  static String kcal(num value) => '${integer(value)} kcal';

  /// "110 g".
  static String grams(num value) => '${integer(value)} g';

  /// "82,5 kg" — com decimal só quando ela existe.
  ///
  /// Peso corporal e carga de barra têm meio quilo de precisão; escrever "82,0 kg" numa
  /// balança que marcou 82 é precisão inventada, e "82,45" é precisão que ninguém usa.
  static String kg(num value) {
    final asDouble = value.toDouble();
    final pattern = asDouble == asDouble.roundToDouble() ? '#,##0' : '#,##0.0';
    return '${NumberFormat(pattern, 'pt_BR').format(asDouble)} kg';
  }

  /// "4 de agosto".
  ///
  /// **Os nomes vão escritos e não pelo `DateFormat`.** Um formato de data exige que os
  /// símbolos do locale já tenham sido carregados, e onde isso não acontece — um teste de
  /// widget que não chama `initializeDateFormatting` — a data sai em inglês em vez de falhar
  /// visivelmente. O app é pt-BR e só.
  ///
  /// Estava escrito à mão em cada tela que mostra data por extenso; a terceira cópia é o que
  /// trouxe para cá.
  static String dayMonth(DateTime date) =>
      '${date.day} de ${_months[date.month - 1]}';

  /// "terça, 4 de agosto".
  static String weekdayDayMonth(DateTime date) =>
      '${_weekdays[date.weekday - 1]}, ${dayMonth(date)}';

  /// "12:34", em 24 horas — o relógio que o Brasil lê.
  static String time(DateTime at) =>
      '${at.hour.toString().padLeft(2, '0')}:'
      '${at.minute.toString().padLeft(2, '0')}';

  /// "hoje", "ontem", "há 4 dias" — a idade de alguma coisa, em caixa baixa.
  ///
  /// Caixa baixa porque isto entra no meio de uma frase ("o mais antigo, há 4 dias"), e não
  /// como rótulo solto. Conta dias de calendário e não horas: quem revisa uma fila pensa em
  /// "de anteontem", não em "de 41 horas atrás".
  static String ago(DateTime at, DateTime now) {
    final days = DateTime(
      now.year,
      now.month,
      now.day,
    ).difference(DateTime(at.year, at.month, at.day)).inDays;

    return switch (days) {
      <= 0 => 'hoje',
      1 => 'ontem',
      _ => 'há $days dias',
    };
  }

  /// "Hoje, 12:34" — ou "3 de agosto, 20:10" quando não é de hoje.
  ///
  /// O rótulo de um lançamento numa lista que atravessa dias. Sem a data, dois registros das
  /// 12:30 em dias diferentes ficam idênticos, e o de ontem passa a parecer duplicado.
  ///
  /// **Não serve para lista agrupada por dia**: ali quem carrega a data é a régua do grupo, e
  /// repeti-la em cada item é a mesma informação duas vezes na mesma tela. Use [dayLabel] na
  /// régua e [time] no item.
  static String dayTime(DateTime at, DateTime now) =>
      sameDay(at, now) ? 'Hoje, ${time(at)}' : '${dayMonth(at)}, ${time(at)}';

  /// "Hoje", "Ontem" ou "3 de agosto" — o nome de um dia como título de grupo.
  ///
  /// Nasceu escrito duas vezes: na régua da conversa com o coach e na do histórico de
  /// refeições. Está aqui pela razão que trouxe os números — duas cópias divergem, e aí o
  /// mesmo app passa a ter dois jeitos de chamar ontem.
  static String dayLabel(DateTime at, DateTime now) {
    if (sameDay(at, now)) {
      return 'Hoje';
    }
    if (sameDay(at, now.subtract(const Duration(days: 1)))) {
      return 'Ontem';
    }
    return dayMonth(at);
  }

  /// Se as duas datas caem no mesmo dia do calendário — comparado campo a campo, e não pela
  /// diferença em horas: 23:00 e 01:00 distam duas horas e são dias diferentes.
  static bool sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  static const _weekdays = [
    'segunda',
    'terça',
    'quarta',
    'quinta',
    'sexta',
    'sábado',
    'domingo',
  ];

  static const _months = [
    'janeiro',
    'fevereiro',
    'março',
    'abril',
    'maio',
    'junho',
    'julho',
    'agosto',
    'setembro',
    'outubro',
    'novembro',
    'dezembro',
  ];

  /// Diferença com o sinal sempre explícito: "+0,3 kg", "−624 kcal".
  ///
  /// O sinal vai escrito, e o de menos é o traço matemático (−, U+2212) e não o hífen: no
  /// meio de dígitos o hífen fica curto demais e alto demais para ser lido como sinal. A cor
  /// não substitui isso — quem não distingue verde de vermelho perderia a informação inteira.
  static String delta(num value, String Function(num) unit) =>
      '${value >= 0 ? '+' : '−'}${unit(value.abs())}';
}
