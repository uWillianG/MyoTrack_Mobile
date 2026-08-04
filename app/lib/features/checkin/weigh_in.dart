import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/iso_date.dart';
import '../../core/sync/sync_queue.dart';
import '../dashboard/dashboard_controller.dart';
import '../logging/data/logging_models.dart';
import '../logging/log_session_controller.dart';

/// Peso digitado, aceitando vírgula.
///
/// A vírgula é o separador decimal do teclado em pt-BR: sem trocar por ponto, "82,4" vira
/// null e o botão de salvar não faz nada sem explicar por quê.
double? parseWeightKg(String value) {
  final normalized = value.trim().replaceAll(',', '.');
  if (normalized.isEmpty) {
    return null;
  }
  final weight = double.tryParse(normalized);
  // A mesma faixa que o servidor valida. Barrar aqui evita a ida e volta só para receber
  // "Peso fora da faixa válida" de volta.
  if (weight == null || weight <= 0 || weight > 500) {
    return null;
  }
  return weight;
}

/// Pergunta o peso num diálogo de campo único. Devolve null se a pessoa cancelou.
///
/// Existe uma vez só porque as duas portas de entrada da pesagem — o fechamento do dia e a
/// captura rápida — pedem exatamente o mesmo campo, e só o título muda.
Future<double?> askWeightKg(BuildContext context, {required String title}) {
  return showDialog<double>(
    context: context,
    builder: (_) => _WeightDialog(title: title),
  );
}

/// O diálogo do peso.
///
/// **É `StatefulWidget` por causa do `TextEditingController`.** A versão anterior criava o
/// controller numa variável local do chamador e o descartava logo depois do
/// `await showDialog(...)` — mas o `await` volta quando o `pop` começa, e o diálogo continua
/// na tela durante a animação de saída. O `TextField` reconstruía contra um controller já
/// descartado, e o erro que chegava ao usuário nem mencionava isso: a exceção abortava a
/// reconstrução no meio, o `Overlay` ficava com um `InheritedElement` cujos dependentes não
/// haviam se desregistrado, e a tela virava o quadro vermelho de `'_dependents.isEmpty': is
/// not true`. Aqui o controller morre no `dispose` do `State`, que o Flutter chama quando a
/// rota do diálogo sai de verdade.
class _WeightDialog extends StatefulWidget {
  const _WeightDialog({required this.title});

  final String title;

  @override
  State<_WeightDialog> createState() => _WeightDialogState();
}

class _WeightDialogState extends State<_WeightDialog> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() => Navigator.of(context).pop(parseWeightKg(_controller.text));

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: TextField(
        controller: _controller,
        autofocus: true,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        decoration: const InputDecoration(
          labelText: 'Peso (kg)',
          hintText: '82,4',
        ),
        onSubmitted: (_) => _submit(),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        FilledButton(onPressed: _submit, child: const Text('Salvar')),
      ],
    );
  }
}

/// Grava a pesagem de hoje.
///
/// Passa pela fila de escrita como todo o resto: quem se pesa e sai para correr sem sinal
/// não deveria perder o número. Devolve se subiu na hora ou ficou guardado, porque as duas
/// telas que chamam isto dizem coisas diferentes ao usuário em cada caso.
///
/// **Recebe o container, e não o `WidgetRef` de quem chamou.** O fechamento do dia avança
/// para a próxima pergunta sem esperar o POST, então o widget que iniciou a escrita já saiu
/// da árvore quando ela volta — e um `WidgetRef` descartado não invalida mais nada, ele
/// lança. O container é o do `ProviderScope` e dura o app inteiro.
Future<WriteOutcome> saveWeighIn(
  ProviderContainer container,
  double weightKg, {
  DateTime? date,
}) async {
  final outcome = await container
      .read(loggingRepositoryProvider)
      .logMeasurement(
        MeasurementRequest(
          date: isoDate(date ?? DateTime.now()),
          weightKg: weightKg,
        ),
      );

  // O peso alimenta a curva do dashboard e o tijolo "Peso" do fechamento do dia. Sem
  // invalidar, os dois continuariam mostrando a pesagem anterior até o app reabrir.
  container.invalidate(dashboardStatsProvider);

  return outcome;
}

/// O container do `ProviderScope` acima de [context].
///
/// `listen: false` de propósito: quem chama isto está prestes a disparar uma escrita e a
/// sair da tela, e registrar uma dependência a partir de um widget que vai morrer é
/// exatamente o que não queremos.
ProviderContainer containerOf(BuildContext context) =>
    ProviderScope.containerOf(context, listen: false);
