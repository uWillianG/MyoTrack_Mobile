import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:myotrack/core/db/local_database.dart';
import 'package:myotrack/core/sync/discarded_write_summary.dart';

/// O texto que a pessoa lê quando um registro dela foi recusado.
///
/// O que se protege aqui é o caminho do payload malformado. Este resumo é a **única** coisa
/// que aparece na tela quando algo se perdeu; se ele lançar ao ler um JSON de uma versão
/// antiga do app, a pessoa perde o registro e a folha da conta junto — e volta ao silêncio que
/// esta funcionalidade veio acabar, agora com um crash em cima.
void main() {
  setUpAll(() => initializeDateFormatting('pt_BR'));

  late LocalDatabase db;

  setUp(() => db = LocalDatabase.forTesting(NativeDatabase.memory()));
  tearDown(() => db.close());

  Future<DiscardedWrite> arquivar(String endpoint, String payload) async {
    await db.enqueue(endpoint, payload);
    await db.discardPending((await db.pending()).single, 'O servidor recusou.');
    return (await db.discarded()).single;
  }

  test('pesagem vira peso e dia', () async {
    final write = await arquivar(
      '/api/measurements',
      '{"date":"2026-07-28","weightKg":82.4}',
    );

    final summary = DiscardedWriteSummary.of(write);

    expect(summary.what, 'Pesagem de 82,4 kg (28/07)');
    expect(summary.reason, 'O servidor recusou.');
  });

  test('medida sem peso não inventa o número', () async {
    // `weightKg` é opcional no corpo: dá para registrar só cintura. "Pesagem de null kg" seria
    // pior que não dizer nada.
    final write = await arquivar(
      '/api/measurements',
      '{"date":"2026-07-28","waistCm":81}',
    );

    expect(DiscardedWriteSummary.of(write).what, 'Medida corporal (28/07)');
  });

  test(
    'treino vira a contagem de séries, que é o que a pessoa refaz',
    () async {
      final write = await arquivar(
        '/api/sessions',
        '{"date":"2026-07-28","sets":[{"a":1},{"b":2},{"c":3}]}',
      );

      expect(
        DiscardedWriteSummary.of(write).what,
        'Treino com 3 séries (28/07)',
      );
    },
  );

  test('uma série só não vira "1 séries"', () async {
    final write = await arquivar(
      '/api/sessions',
      '{"date":"2026-07-28","sets":[{"a":1}]}',
    );

    expect(DiscardedWriteSummary.of(write).what, 'Treino com 1 série (28/07)');
  });

  test('payload ilegível ainda produz uma linha', () async {
    // Uma versão futura pode mudar o corpo; o aviso não pode ser o que quebra.
    final write = await arquivar('/api/sessions', 'isto não é json');

    final summary = DiscardedWriteSummary.of(write);

    expect(summary.what, 'Treino com 0 séries');
    expect(summary.reason, 'O servidor recusou.');
  });

  test('endpoint desconhecido não some da tela', () async {
    // Um endpoint que a fila passe a usar depois desta versão continua sendo avisado, mesmo
    // sem descrição bonita — silêncio é o defeito que estamos consertando.
    final write = await arquivar('/api/check-ins', '{"date":"2026-07-28"}');

    expect(
      DiscardedWriteSummary.of(write).what,
      'Registro enviado a /api/check-ins (28/07)',
    );
  });

  test('data ausente ou inválida apenas não aparece', () async {
    final write = await arquivar('/api/measurements', '{"weightKg":82}');

    expect(DiscardedWriteSummary.of(write).what, 'Pesagem de 82 kg');
  });
}
