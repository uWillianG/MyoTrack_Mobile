/// Data no formato `YYYY-MM-DD`, que é como a API recebe dia de sessão e de medida.
///
/// Feito à mão em vez de com o `intl`: formatar sem fuso é o ponto aqui. Passar pelo UTC
/// mudaria o dia para quem treina à noite no Brasil, e o treino de terça apareceria como
/// quarta no histórico.
String isoDate(DateTime date) =>
    '${date.year.toString().padLeft(4, '0')}-'
    '${date.month.toString().padLeft(2, '0')}-'
    '${date.day.toString().padLeft(2, '0')}';
