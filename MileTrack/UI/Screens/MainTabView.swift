import SwiftUI

struct MainTabView: View {
  @State private var selectedTab: Tab = .home
  @State private var navigateToSubscriptionSettings = false
  
  @EnvironmentObject private var mileageRatesStore: MileageRatesStore
  @EnvironmentObject private var receiptsStore: ReceiptsStore
  @EnvironmentObject private var tripStore: TripStore
  
  enum Tab: Hashable {
    case home, inbox, reports, expenses, settings
  }
  
  var body: some View {
    TabView(selection: $selectedTab) {
      NavigationStack {
        HomeView(
          onOpenInbox: { selectedTab = .inbox },
          onOpenSettings: { selectedTab = .settings }
        )
      }
      .tabItem {
        Label("Home", systemImage: "house")
      }
      .tag(Tab.home)

      NavigationStack {
        InboxView()
      }
      .tabItem {
        Label("Inbox", systemImage: "tray")
      }
      .tag(Tab.inbox)

      NavigationStack {
        ReportsView(onUpgradeToPro: {
          selectedTab = .settings
          navigateToSubscriptionSettings = true
        })
      }
      .tabItem {
        Label("Reports", systemImage: "chart.bar")
      }
      .tag(Tab.reports)

      NavigationStack {
        ExpenseReportView(
          trips: tripStore.trips,
          ratesStore: mileageRatesStore,
          receiptsStore: receiptsStore
        )
      }
      .tabItem {
        Label("Expenses", systemImage: "dollarsign.circle")
      }
      .tag(Tab.expenses)

      NavigationStack {
        SettingsView()
          .navigationDestination(isPresented: $navigateToSubscriptionSettings) {
            SubscriptionSettingsView()
          }
      }
      .tabItem {
        Label("Settings", systemImage: "gearshape")
      }
      .tag(Tab.settings)
    }
    .onChange(of: selectedTab) { _, newValue in
      if newValue != .settings {
        navigateToSubscriptionSettings = false
      }
    }
  }
}

#Preview {
  MainTabView()
    .environmentObject(TripStore())
    .environmentObject(SubscriptionManager())
    .environmentObject(CategoriesStore())
    .environmentObject(ClientsStore())
    .environmentObject(RulesStore())
    .environmentObject(AutoModeManager(tripStore: TripStore()))
    .environmentObject(MileageRatesStore())
    .environmentObject(ReceiptsStore())
}

