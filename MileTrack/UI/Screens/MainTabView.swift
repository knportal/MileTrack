import SwiftUI

struct MainTabView: View {
  @State private var selectedTab: Tab = .home
  @State private var navigateToSubscriptionSettings = false
  @State private var isPresentingManualTrip = false
  @State private var fabIsPressed = false

  @EnvironmentObject private var mileageRatesStore: MileageRatesStore
  @EnvironmentObject private var receiptsStore: ReceiptsStore
  @EnvironmentObject private var tripStore: TripStore

  enum Tab: Hashable {
    case home, inbox, reports, expenses, settings
  }

  var body: some View {
    ZStack(alignment: .bottom) {
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

      // FAB — hidden on Settings tab
      if selectedTab != .settings {
        Button {
          isPresentingManualTrip = true
        } label: {
          Image(systemName: "plus")
            .font(.title2.weight(.semibold))
            .foregroundStyle(.white)
            .frame(width: 60, height: 60)
            .background(Color.accentColor, in: Circle())
            .shadow(color: Color.accentColor.opacity(0.35), radius: 12, y: 4)
        }
        .buttonStyle(FABButtonStyle())
        .padding(.bottom, 90)
        .accessibilityLabel("Add trip")
        .accessibilityHint("Opens manual trip entry.")
        .transition(.scale(scale: 0.85).combined(with: .opacity))
      }
    }
    .animation(.spring(response: 0.35, dampingFraction: 0.75), value: selectedTab)
    .sheet(isPresented: $isPresentingManualTrip) {
      ManualTripSheet()
    }
  }
}

private struct FABButtonStyle: ButtonStyle {
  func makeBody(configuration: Configuration) -> some View {
    configuration.label
      .scaleEffect(configuration.isPressed ? 0.93 : 1.0)
      .animation(.spring(response: 0.25, dampingFraction: 0.7), value: configuration.isPressed)
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
