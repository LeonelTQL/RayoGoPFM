import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    #if DEBUG
    do {
        let splashBoardPath = NSHomeDirectory() + "/Library/SplashBoard"
        if FileManager.default.fileExists(atPath: splashBoardPath) {
            try FileManager.default.removeItem(atPath: splashBoardPath)
        }
    } catch {
        print("Failed to delete launch screen cache: \(error)")
    }
    #endif
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
  }
}
