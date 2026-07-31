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

/// Grava a pesagem de hoje.
///
/// Passa pela fila de escrita como todo o resto: quem se pesa e sai para correr sem sinal
/// não deveria perder o número. Devolve se subiu na hora ou ficou guardado, porque as duas
/// telas que chamam isto dizem coisas diferentes ao usuário em cada caso.
Future<WriteOutcome> saveWeighIn(
  WidgetRef ref,
  double weightKg, {
  DateTime? date,
}) async {
  final outcome = await ref
      .read(loggingRepositoryProvider)
      .logMeasurement(
        MeasurementRequest(
          date: isoDate(date ?? DateTime.now()),
          weightKg: weightKg,
        ),
      );

  // O peso alimenta a curva do dashboard e o tijolo "Peso" do fechamento do dia. Sem
  // invalidar, os dois continuariam mostrando a pesagem anterior até o app reabrir.
  ref.invalidate(dashboardStatsProvider);

  return outcome;
}
