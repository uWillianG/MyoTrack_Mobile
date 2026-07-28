import Flutter
import UIKit
import workmanager_apple

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    // Sincronização em background da fila de escrita (B6). Os identificadores têm de bater
    // com os de core/sync/background_sync.dart e com BGTaskSchedulerPermittedIdentifiers no
    // Info.plist. O registro precisa acontecer aqui, antes do retorno: o BGTaskScheduler
    // recusa registro depois que o lançamento termina.
    //
    // Ao contrário do Android, o iOS não promete quando isso roda — ele decide pelo padrão
    // de uso do app. A frequência abaixo é um piso, não um agendamento.
    WorkmanagerPlugin.registerPeriodicTask(
      withIdentifier: "myotrack.sync.periodic",
      frequency: NSNumber(value: 3600)
    )
    WorkmanagerPlugin.registerBGProcessingTask(withIdentifier: "myotrack.sync.now")

    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
  }
}
