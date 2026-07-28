import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/notifications/rest_alarm.dart';

enum RestPhase {
  /// Nenhum descanso em curso.
  idle,
  running,
  paused,

  /// Chegou a zero e ainda não foi dispensado — a tela mostra "pode ir".
  finished,
}

/// Estado do descanso entre séries.
///
/// O que fica guardado é o instante em que o descanso acaba, não quantos segundos faltam.
/// Somar ticks daria errado exatamente no caso que mais acontece: com o app em segundo
/// plano os `Timer` do Dart param, e a contagem voltaria atrasada pelo tempo que passou.
class RestTimerState {
  const RestTimerState({
    this.phase = RestPhase.idle,
    this.total = Duration.zero,
    this.remaining = Duration.zero,
  });

  final RestPhase phase;

  /// Quanto foi pedido, para desenhar a barra de progresso.
  final Duration total;

  final Duration remaining;

  bool get isIdle => phase == RestPhase.idle;
  bool get isRunning => phase == RestPhase.running;
  bool get isPaused => phase == RestPhase.paused;
  bool get isFinished => phase == RestPhase.finished;

  /// Fração já cumprida, de 0 a 1. Vale 1 quando não há descanso em curso.
  double get progress {
    if (total.inMilliseconds <= 0) {
      return 1;
    }
    final done = total.inMilliseconds - remaining.inMilliseconds;
    return (done / total.inMilliseconds).clamp(0, 1).toDouble();
  }

  /// `mm:ss` — o formato que se lê de relance com a barra na mão.
  String get label {
    final seconds = remaining.inSeconds.clamp(0, 86399);
    final minutes = seconds ~/ 60;
    return '${minutes.toString().padLeft(2, '0')}:'
        '${(seconds % 60).toString().padLeft(2, '0')}';
  }

  static const idle = RestTimerState();
}

/// Conduz o descanso: conta, avisa e segura a tela acesa.
///
/// O relógio entra por [now] para que o teste controle a passagem do tempo sem esperar de
/// verdade, e o tique é separado do cálculo — quem manda no valor exibido é sempre a
/// diferença até [_endsAt], nunca a quantidade de tiques recebidos.
class RestTimerController extends Notifier<RestTimerState> {
  RestTimerController({DateTime Function()? now}) : _now = now ?? DateTime.now;

  final DateTime Function() _now;

  Timer? _ticker;
  DateTime? _endsAt;

  RestAlarm get _alarm => ref.read(restAlarmProvider);
  ScreenLock get _screen => ref.read(screenLockProvider);

  @override
  RestTimerState build() {
    // Resolvidos agora e capturados: durante o descarte o container já não aceita
    // `ref.read`, e a limpeza abaixo morreria com "provider was already disposed"
    // justamente quando ela é a única coisa que ainda precisa acontecer.
    final alarm = ref.read(restAlarmProvider);
    final screen = ref.read(screenLockProvider);

    ref.onDispose(() {
      _ticker?.cancel();
      // Sair da tela não pode deixar a tela do aparelho presa acesa nem um aviso agendado
      // para um descanso que ninguém está mais fazendo.
      alarm.cancel();
      screen.disable();
    });
    return RestTimerState.idle;
  }

  Future<void> start(Duration rest) async {
    if (rest <= Duration.zero) {
      return;
    }
    _endsAt = _now().add(rest);
    state = RestTimerState(
      phase: RestPhase.running,
      total: rest,
      remaining: rest,
    );

    _startTicker();
    await _screen.enable();
    await _alarm.schedule(rest);
  }

  Future<void> pause() async {
    if (!state.isRunning) {
      return;
    }
    _ticker?.cancel();
    _endsAt = null;
    state = RestTimerState(
      phase: RestPhase.paused,
      total: state.total,
      remaining: state.remaining,
    );
    // O aviso agendado vale para um horário que deixou de valer.
    await _alarm.cancel();
  }

  Future<void> resume() async {
    if (!state.isPaused) {
      return;
    }
    final remaining = state.remaining;
    _endsAt = _now().add(remaining);
    state = RestTimerState(
      phase: RestPhase.running,
      total: state.total,
      remaining: remaining,
    );

    _startTicker();
    await _alarm.schedule(remaining);
  }

  /// Acrescenta tempo ao descanso em curso — o clássico "mais 30 segundos".
  Future<void> extend(Duration extra) async {
    if (state.isIdle) {
      return;
    }
    final total = state.total + extra;

    if (state.isPaused) {
      state = RestTimerState(
        phase: RestPhase.paused,
        total: total,
        remaining: state.remaining + extra,
      );
      return;
    }

    // Estender depois de terminado recomeça a contagem: é o que "mais 30s" quer dizer
    // quando o descanso já zerou.
    final base = state.isFinished ? _now() : (_endsAt ?? _now());
    _endsAt = base.add(extra);
    state = RestTimerState(
      phase: RestPhase.running,
      total: total,
      remaining: _endsAt!.difference(_now()),
    );

    _startTicker();
    await _alarm.schedule(state.remaining);
  }

  /// Encerra o descanso — por "pular" ou por já ter sido dispensado.
  Future<void> stop() async {
    _ticker?.cancel();
    _ticker = null;
    _endsAt = null;
    state = RestTimerState.idle;

    await _alarm.cancel();
    await _screen.disable();
  }

  /// Recalcula o restante a partir do relógio. Chamado pelo tique e pelos testes.
  void tick() {
    final endsAt = _endsAt;
    if (endsAt == null || !state.isRunning) {
      return;
    }

    final remaining = endsAt.difference(_now());
    if (remaining <= Duration.zero) {
      _ticker?.cancel();
      _ticker = null;
      _endsAt = null;
      state = RestTimerState(
        phase: RestPhase.finished,
        total: state.total,
        remaining: Duration.zero,
      );
      // A tela pode continuar acesa: quem terminou o descanso vai levantar a próxima série
      // e precisa enxergar o campo de repetições.
      return;
    }

    state = RestTimerState(
      phase: RestPhase.running,
      total: state.total,
      remaining: remaining,
    );
  }

  void _startTicker() {
    _ticker?.cancel();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) => tick());
  }
}

final restTimerProvider = NotifierProvider<RestTimerController, RestTimerState>(
  RestTimerController.new,
);
