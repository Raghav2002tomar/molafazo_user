import Flutter
import UIKit
import FirebaseCore

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {

    FirebaseApp.configure()

    return super.application(
      application,
      didFinishLaunchingWithOptions: launchOptions
    )
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)

    guard let registrar = engineBridge.pluginRegistry.registrar(
      forPlugin: "IOSUrlLauncherChannel"
    ) else {
      return
    }

    let channel = FlutterMethodChannel(
      name: "ios_url_launcher_channel",
      binaryMessenger: registrar.messenger()
    )

    channel.setMethodCallHandler { call, result in
      if call.method == "openUrl" {
        guard
          let args = call.arguments as? [String: Any],
          let urlString = args["url"] as? String,
          let url = URL(string: urlString)
        else {
          result(false)
          return
        }

        UIApplication.shared.open(url, options: [:]) { success in
          result(success)
        }
      } else {
        result(FlutterMethodNotImplemented)
      }
    }
  }
}