import SwiftUI

struct PrivacyView: View {
  @Environment(\.openURL) private var openURL

  @EnvironmentObject private var tripStore: TripStore
  @EnvironmentObject private var categoriesStore: CategoriesStore
  @EnvironmentObject private var clientStore: ClientsStore
  @EnvironmentObject private var rulesStore: RulesStore

  @State private var isPresentingDeleteConfirm: Bool = false

  var body: some View {
    ScrollView {
      VStack(alignment: .leading, spacing: 14) {
        onDeviceCard
        collectedCard
        exportCard
        deleteCard
        legalLinksCard
      }
      .padding(.horizontal, 16)
      .padding(.vertical, 12)
    }
    .background(.background)
    .navigationTitle("Privacy")
    .navigationBarTitleDisplayMode(.inline)
    .alert("Delete all data?", isPresented: $isPresentingDeleteConfirm) {
      Button("Cancel", role: .cancel) {}
      Button("Delete", role: .destructive) { deleteAllData() }
    } message: {
      Text("This deletes trips, clients, and rules stored on this device. Default categories will be restored. This can’t be undone.")
    }
  }

  private var onDeviceCard: some View {
    GlassCard {
      VStack(alignment: .leading, spacing: 10) {
        Text("Data stays on device")
          .font(.headline)

        Text("Trips, categories, clients, and rules are stored locally on this device. MileTrack does not operate its own backend servers for your trip data.")
          .font(.footnote)
          .foregroundStyle(.secondary)

        Text("If you subscribe, subscription status is handled by Apple via StoreKit.")
          .font(.footnote)
          .foregroundStyle(.secondary)
      }
    }
  }

  private var collectedCard: some View {
    GlassCard {
      VStack(alignment: .leading, spacing: 10) {
        Text("What’s collected")
          .font(.headline)

        Group {
          Text("To detect drives, Auto Mode accesses:")
            .font(.footnote.weight(.semibold))
            .foregroundStyle(.secondary)

          VStack(alignment: .leading, spacing: 6) {
            bullet("Motion activity (driving/not driving)")
            bullet("Location updates during a detected drive to estimate distance")
          }
        }

        Divider().opacity(0.25)

        Group {
          Text("What’s stored")
            .font(.footnote.weight(.semibold))
            .foregroundStyle(.secondary)

          VStack(alignment: .leading, spacing: 6) {
            bullet("Trip distance and timestamps")
            bullet("Optional start/end labels (city/area), category, client, project code, and notes")
            bullet("Auto-detected trips are only treated as “real” after you confirm them in Inbox")
          }
        }
      }
    }
  }

  private var exportCard: some View {
    GlassCard {
      VStack(alignment: .leading, spacing: 10) {
        Text("Export")
          .font(.headline)

        Text("You can export confirmed trips from the Reports tab:")
          .font(.footnote)
          .foregroundStyle(.secondary)

        VStack(alignment: .leading, spacing: 6) {
          bullet("CSV exports available on free tier")
          bullet("PDF summary exports available with Pro subscription")
        }

        Text("Exported files are temporarily saved to your device and can be shared via the standard iOS share sheet. No data is uploaded to external servers during export.")
          .font(.footnote)
          .foregroundStyle(.secondary)
      }
    }
  }

  private var deleteCard: some View {
    GlassCard {
      VStack(alignment: .leading, spacing: 10) {
        Text("Delete")
          .font(.headline)

        Text("Delete all locally stored trip data from this device.")
          .font(.footnote)
          .foregroundStyle(.secondary)

        Button(role: .destructive) {
          isPresentingDeleteConfirm = true
        } label: {
          HStack {
            Image(systemName: "trash")
              .accessibilityHidden(true)
            Text("Delete all data")
              .font(.subheadline.weight(.semibold))
            Spacer()
          }
          .padding(.horizontal, 16)
          .padding(.vertical, 12)
          .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
          .overlay {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
              .strokeBorder(Color.primary.opacity(0.10), lineWidth: 1)
          }
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Delete all data")
      }
    }
  }

  private var legalLinksCard: some View {
    GlassCard {
      VStack(alignment: .leading, spacing: 10) {
        Text("Legal")
          .font(.headline)

        VStack(spacing: 10) {
          legalLinkRow(title: "Privacy Policy", urlString: "https://www.plenitudo.ai/app/miletrack/privacy-policy")
          legalLinkRow(title: "Terms of Service", urlString: "https://www.plenitudo.ai/app/miletrack/terms")
        }
      }
    }
  }

  private func legalLinkRow(title: String, urlString: String) -> some View {
    Button {
      if let url = URL(string: urlString) {
        openURL(url)
      }
    } label: {
      HStack {
        Text(title)
          .font(.subheadline.weight(.semibold))
        Spacer()
        Image(systemName: "arrow.up.right.square")
          .foregroundStyle(.secondary)
      }
      .padding(.horizontal, 16)
      .padding(.vertical, 12)
      .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
      .overlay {
        RoundedRectangle(cornerRadius: 16, style: .continuous)
          .strokeBorder(Color.primary.opacity(0.10), lineWidth: 1)
      }
    }
    .buttonStyle(.plain)
    .accessibilityLabel(title)
  }

  private func bullet(_ text: String) -> some View {
    HStack(alignment: .top, spacing: 8) {
      Text("•")
        .foregroundStyle(.secondary)
      Text(text)
        .font(.footnote)
        .foregroundStyle(.secondary)
      Spacer(minLength: 0)
    }
    .accessibilityElement(children: .combine)
  }

  private func deleteAllData() {
    tripStore.trips = []
    tripStore.saveNow()

    // Restore defaults for required pickers.
    categoriesStore.resetToDefaults()

    // Clear optional metadata stores.
    clientStore.clients = []
    clientStore.saveNow()

    rulesStore.rules = []
    rulesStore.saveNow()
  }
}

#Preview {
  NavigationStack {
    PrivacyView()
  }
  .environmentObject(TripStore())
  .environmentObject(CategoriesStore())
  .environmentObject(ClientsStore())
  .environmentObject(RulesStore())
  .environmentObject(SubscriptionManager())
  .environmentObject(AutoModeManager(tripStore: TripStore()))
}

