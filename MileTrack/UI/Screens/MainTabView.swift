import SwiftUI

struct MainTabView: View {
  var body: some View {
    TabView {
      NavigationStack {
        HomeView()
      }
      .tabItem {
        Label("Home", systemImage: "house")
      }

      NavigationStack {
        InboxView()
      }
      .tabItem {
        Label("Inbox", systemImage: "tray")
      }

      NavigationStack {
        ReportsView()
      }
      .tabItem {
        Label("Reports", systemImage: "chart.bar")
      }

      NavigationStack {
        SettingsView()
      }
      .tabItem {
        Label("Settings", systemImage: "gearshape")
      }
    }
  }
}

#Preview {
  MainTabView()
    .environmentObject(TripStore())
    .environmentObject(SubscriptionManager())
    .environmentObject(CategoriesStore())
    .environmentObject(ClientStore())
    .environmentObject(RulesStore())
}

