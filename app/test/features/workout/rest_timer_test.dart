import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:myotrack/core/notifications/rest_alarm.dart';
import 'package:myotrack/features/workout/rest_timer.dart';

/// Registra o que foi pedido ao sistema, sem canal de plataforma.
class _FakeAlarm implements RestAlarm {
  final List<Duration> scheduled = [];
  int cancels = 0;

  @override
  Future<void> schedule(Duration rest) async => scheduled.add(rest);

  @override
  Future<void> cancel() async => cancels++;
}

class _FakeScreen implements ScreenLock {
  bool on = false;

  @override
  Future<void> enable() async => on = true;

  @override
  Future<void> disable() async => on = false;
}

void main() {
  late _FakeAlarm alarm;
  late _FakeScreen screen;
  late DateTime clock;
  late ProviderContainer container;

  /// Um provider próprio com o relógio nas mãos do teste: esperar 90 segundos de verdade
  /// deixaria a suíte inutilizável.
  final testTimerProvider =
      NotifierProvider<RestTimerController, RestTimerState>(
        () => RestTimerController(now: () => clock),
      );

  setUp(() {
    alarm = _FakeAlarm();
    screen = _FakeScreen();
    clock = DateTime(2026, 7, 28, 19, 0);
    container = ProviderContainer(
      overrides: [
        restAlarmProvider.overrideWithValue(alarm),
        screenLockProvider.overrideWithValue(screen),
      ],
    );
    addTearDown(container.dispose);
  });

  RestTimerController controller() =>
      container.read(testTimerProvider.notifier);
  RestTimerState state() => container.read(testTimerProvider);

  /// Avança o relógio e recalcula, como faria o tique de um segundo.
  void advance(Duration elapsed) {
    clock = clock.add(elapsed);
    controller().tick();
  }

  group('contagem', () {
    test('conta pelo relógio, não pela quantidade de tiques', () async {
      // É o caso do app em segundo plano: os Timer do Dart param e voltam muito depois.
      // Somando tiques o descanso "congelaria"; pelo relógio ele chega correto.
      await controller().start(const Duration(seconds: 90));
      expect(state().remaining, const Duration(seconds: 90));

      advance(const Duration(seconds: 70));

      expect(state().remaining, const Duration(seconds: 20));
      expect(state().isRunning, isTrue);
    });

    test('um único tique depois do fim já encerra', () async {
      await controller().start(const Duration(seconds: 90));

      // Celular no bolso por dois minutos: volta com o descanso vencido, não com 88s.
      advance(const Duration(minutes: 2));

      expect(state().isFinished, isTrue);
      expect(state().remaining, Duration.zero);
    });

    test('mm:ss com dois dígitos dos dois lados', () async {
      await controller().start(const Duration(seconds: 90));
      expect(state().label, '01:30');

      advance(const Duration(seconds: 85));
      expect(state().label, '00:05');
    });

    test('progresso vai de 0 a 1', () async {
      await controller().start(const Duration(seconds: 100));
      expect(state().progress, 0);

      advance(const Duration(seconds: 25));
      expect(state().progress, closeTo(0.25, 0.001));

      advance(const Duration(seconds: 200));
      expect(state().progress, 1);
    });
  });

  group('efeitos no aparelho', () {
    test('começar agenda o aviso e segura a tela acesa', () async {
      await controller().start(const Duration(seconds: 90));

      expect(alarm.scheduled, [const Duration(seconds: 90)]);
      expect(screen.on, isTrue);
    });

    test('pular cancela o aviso e solta a tela', () async {
      await controller().start(const Duration(seconds: 90));
      await controller().stop();

      expect(alarm.cancels, 1);
      expect(screen.on, isFalse);
      expect(state().isIdle, isTrue);
    });

    test('pausar cancela o aviso, que valia para outro horário', () async {
      await controller().start(const Duration(seconds: 90));
      advance(const Duration(seconds: 30));
      await controller().pause();

      expect(state().isPaused, isTrue);
      expect(state().remaining, const Duration(seconds: 60));
      expect(alarm.cancels, 1);
    });

    test('retomar reagenda pelo que faltava, não pelo total', () async {
      // Reagendar os 90 originais daria ao usuário meio descanso a mais.
      await controller().start(const Duration(seconds: 90));
      advance(const Duration(seconds: 30));
      await controller().pause();
      await controller().resume();

      expect(alarm.scheduled.last, const Duration(seconds: 60));
      expect(state().isRunning, isTrue);
    });

    test('pausado não anda com a passagem do tempo', () async {
      await controller().start(const Duration(seconds: 90));
      advance(const Duration(seconds: 30));
      await controller().pause();

      clock = clock.add(const Duration(minutes: 5));
      controller().tick();

      expect(state().remaining, const Duration(seconds: 60));
      expect(state().isPaused, isTrue);
    });
  });

  group('+30s', () {
    test('estende o descanso em curso', () async {
      await controller().start(const Duration(seconds: 90));
      advance(const Duration(seconds: 30));
      await controller().extend(const Duration(seconds: 30));

      expect(state().remaining, const Duration(seconds: 90));
      expect(state().total, const Duration(seconds: 120));
    });

    test('depois de terminado, recomeça a contagem', () async {
      // "+30s" com o descanso já zerado quer dizer "me dá mais 30", não "volta ao que era".
      await controller().start(const Duration(seconds: 90));
      advance(const Duration(minutes: 2));
      expect(state().isFinished, isTrue);

      await controller().extend(const Duration(seconds: 30));

      expect(state().isRunning, isTrue);
      expect(state().remaining, const Duration(seconds: 30));
    });

    test('pausado ganha o tempo sem voltar a correr', () async {
      await controller().start(const Duration(seconds: 90));
      advance(const Duration(seconds: 30));
      await controller().pause();
      await controller().extend(const Duration(seconds: 30));

      expect(state().isPaused, isTrue);
      expect(state().remaining, const Duration(seconds: 90));
    });
  });

  test('descanso de zero segundo não começa nada', () async {
    await controller().start(Duration.zero);

    expect(state().isIdle, isTrue);
    expect(alarm.scheduled, isEmpty);
    expect(screen.on, isFalse);
  });
}
