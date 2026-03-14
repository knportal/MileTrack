import SwiftUI
import UIKit

// MARK: - App Delegate
// Required to handle UIApplication.LaunchOptionsKey.location, which is delivered when iOS
// re-launches the app after a significant-location-change event fires while the app was terminated.
// AutoModeManager.init() already calls startIfNeeded(), so no additional setup is needed here —
// we just need a UIApplicationDelegate so the launch option is consumed correctly.
final class AppDelegate: NSObject, UIApplicationDelegate {
  func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
  ) -> Bool {
    // iOS 26 deprecates UIApplication.LaunchOptionsKey.location.
    // Handle expected location events after scene connection using Core Location
    // (e.g., CLLocationManagerDelegate callbacks, CLLocationUpdate, or CLMonitor).
    // AutoModeManager.init() already calls startIfNeeded(), which will (re)start
    // monitoring on launch and after relaunches.
    return true
  }
}

@main
struct MileTrackApp: App {
  @UIApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

  init() {
    // Register default values for UserDefaults
    UserDefaults.standard.register(defaults: [
      "autoModeEnabled": true  // Auto Mode ON by default for new users
    ])
  }

  var body: some Scene {
    WindowGroup {
      ContentView()
    }
  }
}

