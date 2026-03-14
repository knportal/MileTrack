import SwiftUI

struct ContentView: View {
  @Environment(\.scenePhase) private var scenePhase

  @StateObject private var tripStore: TripStore
  @StateObject private var subscriptionManager: SubscriptionManager
  @StateObject private var categoriesStore: CategoriesStore
  @StateObject private var clientStore: ClientsStore
  @StateObject private var locationsStore: LocationsStore
  @StateObject private var vehiclesStore: VehiclesStore
  @StateObject private var rulesStore: RulesStore
  @StateObject private var autoModeManager: AutoModeManager
  
  // Expense tracking stores
  @StateObject private var mileageRatesStore: MileageRatesStore
  @StateObject private var receiptsStore: ReceiptsStore
  
  @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
  @State private var hasRetriedGeocoding = false

  init() {
    let tripStore = TripStore()
    _tripStore = StateObject(wrappedValue: tripStore)
    _subscriptionManager = StateObject(wrappedValue: SubscriptionManager())
    _categoriesStore = StateObject(wrappedValue: CategoriesStore())
    _clientStore = StateObject(wrappedValue: ClientsStore())
    let locationsStore = LocationsStore()
    _locationsStore = StateObject(wrappedValue: locationsStore)
    _vehiclesStore = StateObject(wrappedValue: VehiclesStore())
    let rulesStore = RulesStore()
    _rulesStore = StateObject(wrappedValue: rulesStore)
    _autoModeManager = StateObject(wrappedValue: AutoModeManager(tripStore: tripStore, rulesStore: rulesStore, locationsStore: locationsStore))
    
    // Initialize expense stores
    _mileageRatesStore = StateObject(wrappedValue: MileageRatesStore())
    _receiptsStore = StateObject(wrappedValue: ReceiptsStore())
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
      .environmentObject(locationsStore)
      .environmentObject(vehiclesStore)
      .environmentObject(rulesStore)
      .environmentObject(autoModeManager)
      .environmentObject(mileageRatesStore)
      .environmentObject(receiptsStore)
      .fullScreenCover(isPresented: Binding(
        get: { !hasCompletedOnboarding },
        set: { _ in }
      )) {
        OnboardingView()
      }
      .onChange(of: scenePhase) { _, newPhase in
        if newPhase == .background {
          // Flush all pending saves immediately before app suspends
          flushAllStores()
        } else if newPhase == .active && !hasRetriedGeocoding {
          // Retry failed geocoding on first activation (e.g., came back online)
          hasRetriedGeocoding = true
          tripStore.retryFailedGeocoding()
        }
      }
  }
  
  /// Force immediate save on all stores to prevent data loss on app termination.
  private func flushAllStores() {
    tripStore.saveNow()
    categoriesStore.saveNow()
    clientStore.saveNow()
    locationsStore.saveNow()
    vehiclesStore.saveNow()
    rulesStore.saveNow()
    // Save expense stores
    mileageRatesStore.saveNow()
    receiptsStore.saveNow()
  }
}

#Preview {
  ContentView()
}

