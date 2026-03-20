import SwiftUI
import StoreKit

struct SettingsView: View {
  @Environment(\.openURL) private var openURL
  @EnvironmentObject private var subscriptionManager: SubscriptionManager
  @EnvironmentObject private var tripStore: TripStore
  @EnvironmentObject private var categoriesStore: CategoriesStore
  @EnvironmentObject private var clientStore: ClientsStore
  @EnvironmentObject private var rulesStore: RulesStore
  @EnvironmentObject private var locationsStore: LocationsStore
  @EnvironmentObject private var vehiclesStore: VehiclesStore
  @EnvironmentObject private var autoModeManager: AutoModeManager
  @EnvironmentObject private var mileageRatesStore: MileageRatesStore


  var body: some View {
    ScrollView {
      VStack(alignment: .leading, spacing: 20) {
        appSection
        userSection
        legalSection
        supportSection
      }
      .frame(maxWidth: DesignConstants.iPadMaxContentWidth)
      .padding(.horizontal, 16)
      .padding(.vertical, 12)
      .frame(maxWidth: .infinity)
    }
    .background(.background)
    .navigationTitle("Settings")
  }
  
  // MARK: - App Section
  private var appSection: some View {
    VStack(alignment: .leading, spacing: 12) {
      Text("App")
        .font(.title2.weight(.semibold))
        .foregroundStyle(.primary)
      
      GlassCard {
        VStack(spacing: 0) {
          settingsRow(
            title: "Auto Mode & Tracking", 
            icon: "location.magnifyingglass",
            destination: { AutoModeSettingsView() }
          )
          
          Divider().padding(.leading, 50)

          settingsRow(
            title: "Units & Display",
            icon: "ruler",
            destination: { UnitsSettingsView() }
          )

          Divider().padding(.leading, 50)

          settingsRow(
            title: "Mileage Rates",
            icon: "dollarsign.circle",
            destination: { MileageRatesView(ratesStore: mileageRatesStore) }
          )

          Divider().padding(.leading, 50)

          iCloudSyncRow
        }
      }
    }
  }

  private var iCloudSyncRow: some View {
    let sync = tripStore.iCloudSync
    return HStack(spacing: 16) {
      Image(systemName: sync.status.systemImage)
        .font(.title3)
        .foregroundStyle(sync.status.isError ? .red : .secondary)
        .frame(width: 24, alignment: .center)

      VStack(alignment: .leading, spacing: 2) {
        Text("iCloud Backup")
          .font(.body)
          .foregroundStyle(.primary)
        Text(iCloudSubtitle(sync))
          .font(.caption)
          .foregroundStyle(sync.status.isError ? .red : .secondary)
      }

      Spacer()

      Text(sync.status.displayLabel)
        .font(.subheadline)
        .foregroundStyle(sync.status == .idle ? .green : .secondary)
    }
    .padding(.horizontal, 16)
    .padding(.vertical, 14)
  }

  private func iCloudSubtitle(_ sync: iCloudSyncService) -> String {
    switch sync.status {
    case .unavailable:
      return "Enable iCloud Drive in Settings → Apple ID → iCloud"
    case .error(let msg):
      return msg
    case .syncing:
      return "Syncing trips…"
    case .idle:
      if let date = sync.lastSyncDate {
        return "Last synced \(date.formatted(.relative(presentation: .named)))"
      }
      return "Trips backed up to iCloud Drive"
    }
  }
  
  // MARK: - User Section
  private var userSection: some View {
    VStack(alignment: .leading, spacing: 12) {
      Text("User")
        .font(.title2.weight(.semibold))
        .foregroundStyle(.primary)
      
      GlassCard {
        VStack(spacing: 0) {
          settingsRow(
            title: "Categories", 
            icon: "folder",
            destination: { ManageCategoriesView() }
          )
          
          Divider().padding(.leading, 50)
          
          settingsRow(
            title: "Locations", 
            icon: "mappin.circle",
            destination: { ManageLocationsView() }
          )
          
          Divider().padding(.leading, 50)
          
          settingsRow(
            title: "Vehicles", 
            icon: "car",
            destination: { ManageVehiclesView() }
          )
          
          Divider().padding(.leading, 50)
          
          settingsRow(
            title: "Rules", 
            icon: "list.bullet.rectangle",
            destination: { RulesView() }
          )
          
          Divider().padding(.leading, 50)
          
          settingsRow(
            title: "Clients & Organizations", 
            icon: "building.2",
            destination: { ManageClientsView() }
          )
          
          Divider().padding(.leading, 50)
          
          settingsRow(
            title: "Subscription & Billing", 
            icon: "crown",
            destination: { SubscriptionSettingsView() }
          )
        }
      }
    }
  }
  
  // MARK: - Legal Section  
  private var legalSection: some View {
    VStack(alignment: .leading, spacing: 12) {
      Text("Legal")
        .font(.title2.weight(.semibold))
        .foregroundStyle(.primary)
      
      GlassCard {
        VStack(spacing: 0) {
          settingsRow(
            title: "Privacy & Data", 
            icon: "hand.raised",
            destination: { PrivacyView() }
          )
          
          Divider().padding(.leading, 50)
          
          settingsRowExternal(
            title: "Terms of Service", 
            icon: "doc.text",
            url: "https://www.plenitudo.ai/app/miletrack/terms"
          )
          
          Divider().padding(.leading, 50)
          
          settingsRowExternal(
            title: "Privacy Policy", 
            icon: "shield",
            url: "https://www.plenitudo.ai/app/miletrack/privacy-policy"
          )
        }
      }
    }
  }
  
  // MARK: - Support Section
  private var supportSection: some View {
    VStack(alignment: .leading, spacing: 12) {
      Text("Support")
        .font(.title2.weight(.semibold))
        .foregroundStyle(.primary)
      
      GlassCard {
        VStack(spacing: 0) {
          settingsRowExternal(
            title: "Help & Support", 
            icon: "questionmark.circle",
            url: "https://www.plenitudo.ai/app/miletrack/support"
          )
          
          Divider().padding(.leading, 50)
          
          settingsRow(
            title: "About", 
            icon: "info.circle",
            destination: { AboutView() }
          )
          
#if DEBUG
          Divider().padding(.leading, 50)
          
          settingsRow(
            title: "Diagnostics", 
            icon: "stethoscope",
            destination: { DiagnosticsView() }
          )
#endif
        }
      }
    }
  }
  
  // MARK: - Helper Views
  private func settingsRow<Destination: View>(
    title: String, 
    icon: String, 
    @ViewBuilder destination: () -> Destination
  ) -> some View {
    NavigationLink(destination: destination) {
      HStack(spacing: 16) {
        Image(systemName: icon)
          .font(.title3)
          .foregroundStyle(.secondary)
          .frame(width: 24, alignment: .center)
        
        Text(title)
          .font(.body)
          .foregroundStyle(.primary)
        
        Spacer()
        
        Image(systemName: "chevron.right")
          .font(.caption.weight(.semibold))
          .foregroundStyle(.tertiary)
      }
      .padding(.horizontal, 16)
      .padding(.vertical, 14)
      .contentShape(Rectangle())
    }
    .buttonStyle(.plain)
  }
  
  private func settingsRowExternal(
    title: String, 
    icon: String, 
    url: String
  ) -> some View {
    Button {
      if let url = URL(string: url) {
        openURL(url)
      }
    } label: {
      HStack(spacing: 16) {
        Image(systemName: icon)
          .font(.title3)
          .foregroundStyle(.secondary)
          .frame(width: 24, alignment: .center)
        
        Text(title)
          .font(.body)
          .foregroundStyle(.primary)
        
        Spacer()
        
        Image(systemName: "arrow.up.right.square")
          .font(.caption.weight(.semibold))
          .foregroundStyle(.tertiary)
      }
      .padding(.horizontal, 16)
      .padding(.vertical, 14)
      .contentShape(Rectangle())
    }
    .buttonStyle(.plain)
  }
}

#Preview {
  NavigationStack {
    SettingsView()
  }
  .environmentObject(SubscriptionManager())
  .environmentObject(TripStore())
  .environmentObject(CategoriesStore())
  .environmentObject(ClientsStore())
  .environmentObject(RulesStore())
  .environmentObject(LocationsStore())
  .environmentObject(VehiclesStore())
  .environmentObject(AutoModeManager(tripStore: TripStore()))
  .environmentObject(MileageRatesStore())
  .environmentObject(ReceiptsStore())
}

