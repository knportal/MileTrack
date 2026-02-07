import SwiftUI

struct ContentView: View {
  @ObservedObject var store: MileStore

  @StateObject private var tripStore: TripStore
  @StateObject private var subscriptionManager: SubscriptionManager
  @StateObject private var categoriesStore: CategoriesStore
  @StateObject private var clientStore: ClientStore
  @StateObject private var rulesStore: RulesStore
  @StateObject private var autoModeManager: AutoModeManager

  init(store: MileStore) {
    self.store = store
    let tripStore = TripStore()
    _tripStore = StateObject(wrappedValue: tripStore)
    _subscriptionManager = StateObject(wrappedValue: SubscriptionManager())
    _categoriesStore = StateObject(wrappedValue: CategoriesStore())
    _clientStore = StateObject(wrappedValue: ClientStore())
    let rulesStore = RulesStore()
    _rulesStore = StateObject(wrappedValue: rulesStore)
    _autoModeManager = StateObject(wrappedValue: AutoModeManager(tripStore: tripStore, rulesStore: rulesStore))
  }

  var body: some View {
    /*
     Pre-launch manual QA checklist:
     - Empty states: Home/Reports/Inbox/Clients/Categories/Rules show friendly guidance and optional actions.
     - Accessibility: verify VoiceOver reads key buttons (Confirm/Not a trip/Merge/Save/Export) with hints.
     - Dynamic Type: set Larger Text and verify key cards avoid truncation (route labels can wrap).
     - Haptics: Confirm/Merge/Save give subtle feedback (optional).
     - Diagnostics: Debug-only UI; Release build has no debug logging output.
     */
    MainTabView()
      .environmentObject(tripStore)
      .environmentObject(subscriptionManager)
      .environmentObject(categoriesStore)
      .environmentObject(clientStore)
      .environmentObject(rulesStore)
      .environmentObject(autoModeManager)
  }
}

#Preview {
  ContentView(store: MileStore())
}

