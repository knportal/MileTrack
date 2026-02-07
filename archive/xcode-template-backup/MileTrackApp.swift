import SwiftUI

@main
struct MileTrackApp: App {
  @StateObject private var store = MileStore()

  var body: some Scene {
    WindowGroup {
      ContentView(store: store)
    }
  }
}

