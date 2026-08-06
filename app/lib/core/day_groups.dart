import 'design/format.dart';

/// Um dia de um histórico: o nome dele e o que aconteceu nele.
typedef DayGroup<T> = ({String label, List<T> items});

/// Parte um histórico em dias, na ordem em que ele veio.
///
/// Um histórico atravessa semanas, e sem o agrupamento ele é uma pilha lisa em que o de ontem
/// encosta no de hoje. A data existe em cada item e não se lê: rolando, o que o olho percorre
/// são os blocos, e a diferença entre dois rótulos parecidos só aparece quando já se parou para
/// comparar. Agrupada, a data vira o **rótulo do bloco do dia** e some do item — repetida nos
/// dois lugares seria a mesma informação duas vezes.
///
/// **Mora no core porque nasceu duas vezes**, na análise de refeição e na de execução, e as três
/// sutilezas abaixo divergiriam na primeira mexida em um dos lados. É o mesmo motivo que trouxe
/// o `BlockNotice` para cá.
///
/// [at] devolve a data ISO do item, ou null quando ele não tem uma. [undated] é o rótulo do
/// bloco que sobra para itens sem data quando não há dia anterior nenhum onde encaixá-los.
///
/// Três decisões que a função carrega:
///
/// - **Item sem data entra no dia anterior** em vez de abrir um seu. Data ausente é falta de
///   informação, e um bloco "sem data" no meio da lista alegaria mais do que se sabe.
/// - **O dia aberto guarda a própria data, e não a do último item dele.** Comparar com o último
///   fazia um item sem data apagar a data do grupo, e o item seguinte, de outro dia, entrava
///   nele como se fosse do mesmo.
/// - **Junta corridas consecutivas, e conta com o histórico ordenado** — que é como a API o
///   devolve, do mais novo para o mais velho. Agrupar por chave seria imune a uma lista
///   embaralhada e cobraria caro: o cliente reordenaria por conta própria, escondendo um
///   defeito que é do servidor.
List<DayGroup<T>> groupByDay<T>(
  List<T> items,
  DateTime now, {
  required String? Function(T) at,
  required String undated,
}) {
  final days = <DayGroup<T>>[];
  DateTime? open;

  for (final item in items) {
    final date = _parse(at(item));
    final continues =
        days.isNotEmpty &&
        (date == null || (open != null && Fmt.sameDay(open, date)));

    if (continues) {
      days.last.items.add(item);
      continue;
    }

    days.add((
      label: date == null ? undated : Fmt.dayLabel(date, now),
      items: [item],
    ));
    open = date;
  }

  return days;
}

/// A data local do item, ou null quando ele não tem uma que se possa ler.
DateTime? _parse(String? createdAt) =>
    createdAt == null ? null : DateTime.tryParse(createdAt)?.toLocal();
