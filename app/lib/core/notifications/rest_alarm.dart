import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:wakelock_plus/wakelock_plus.dart';

/// Aviso de fim do descanso.
///
/// É interface porque o timer depende dela, e teste de unidade não tem canal de plataforma
/// para responder — a implementação real só existe no aparelho.
abstract class RestAlarm {
  /// Agenda o aviso para daqui a [rest]. Uma chamada nova substitui a anterior.
  Future<void> schedule(Duration rest);

  Future<void> cancel();
}

/// Mantém a tela acesa. Mesmo motivo da [RestAlarm] para ser interface.
abstract class ScreenLock {
  Future<void> enable();

  Future<void> disable();
}

/// Notificação local agendada no relógio do sistema.
///
/// O agendamento é do sistema operacional, não do app: entre uma série e outra o celular vai
/// para o bolso, e aí o processo pode ser congelado a qualquer momento. Um `Timer` do Dart
/// simplesmente não dispara nesse estado — o aviso chegaria quando a pessoa reabrisse o app,
/// que é justamente quando ela não precisa mais dele.
class RestNotifications implements RestAlarm {
  RestNotifications({FlutterLocalNotificationsPlugin? plugin})
    : _plugin = plugin ?? FlutterLocalNotificationsPlugin();

  final FlutterLocalNotificationsPlugin _plugin;

  /// Um id fixo: só existe um descanso por vez, e reagendar deve substituir o anterior em
  /// vez de empilhar avisos.
  static const int _notificationId = 4001;

  static const AndroidNotificationDetails _android = AndroidNotificationDetails(
    'descanso',
    'Timer de descanso',
    channelDescription: 'Avisa quando o descanso entre séries termina.',
    importance: Importance.max,
    priority: Priority.high,
    // Categoria de alarme: é o que autoriza o aviso a furar o Não Perturbe e a tocar
    // com o aparelho no bolso.
    category: AndroidNotificationCategory.alarm,
  );

  static const DarwinNotificationDetails _ios = DarwinNotificationDetails(
    presentAlert: true,
    presentSound: true,
    // No iOS, sem isto o aviso fica silencioso quando o Foco está ligado — e treinar com
    // o Foco ligado é o caso comum, não a exceção.
    interruptionLevel: InterruptionLevel.timeSensitive,
  );

  bool _initialized = false;
  bool _canScheduleExact = false;

  Future<void> _ensureInitialized() async {
    if (_initialized) {
      return;
    }
    tz_data.initializeTimeZones();

    await _plugin.initialize(
      settings: const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        // As permissões são pedidas quando o treino começa, não na abertura do app: o
        // pedido faz sentido para quem acabou de mandar iniciar um descanso.
        iOS: DarwinInitializationSettings(
          requestAlertPermission: false,
          requestBadgePermission: false,
          requestSoundPermission: false,
        ),
      ),
    );
    _initialized = true;
  }

  /// Pede as permissões necessárias. Devolve se dá para avisar de alguma forma.
  ///
  /// Recusa não impede treinar: o timer continua correndo na tela, só não avisa com o app
  /// fechado. Por isso nada aqui lança exceção.
  Future<bool> requestPermission() async {
    await _ensureInitialized();

    if (defaultTargetPlatform == TargetPlatform.iOS) {
      final granted = await _plugin
          .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin
          >()
          ?.requestPermissions(alert: true, sound: true, badge: true);
      return granted ?? false;
    }

    final android = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    if (android == null) {
      return false;
    }

    final granted = await android.requestNotificationsPermission() ?? false;
    // Alarme exato é o que faz o aviso chegar no segundo certo. Sem a permissão o sistema
    // agrupa o disparo com outros e ele pode atrasar minutos — inútil para um descanso de
    // 90 segundos, mas ainda assim melhor do que aviso nenhum.
    _canScheduleExact = await android.canScheduleExactNotifications() ?? false;
    return granted;
  }

  @override
  Future<void> schedule(Duration rest) async {
    await _ensureInitialized();

    await _plugin.zonedSchedule(
      id: _notificationId,
      // O fuso não importa porque o instante é sempre relativo a agora — "daqui a 90s" cai
      // no mesmo ponto do tempo em qualquer zona. Usar UTC evita depender de um pacote a
      // mais só para descobrir o nome do fuso do aparelho.
      scheduledDate: tz.TZDateTime.now(tz.UTC).add(rest),
      androidScheduleMode: _canScheduleExact
          ? AndroidScheduleMode.exactAllowWhileIdle
          : AndroidScheduleMode.inexactAllowWhileIdle,
      title: 'Descanso terminado',
      body: 'Hora da próxima série.',
      notificationDetails: const NotificationDetails(
        android: _android,
        iOS: _ios,
      ),
    );
  }

  @override
  Future<void> cancel() => _plugin.cancel(id: _notificationId);
}

class WakelockScreenLock implements ScreenLock {
  const WakelockScreenLock();

  @override
  Future<void> enable() => WakelockPlus.enable();

  @override
  Future<void> disable() => WakelockPlus.disable();
}

final restAlarmProvider = Provider<RestAlarm>((ref) => RestNotifications());

final screenLockProvider = Provider<ScreenLock>(
  (ref) => const WakelockScreenLock(),
);
