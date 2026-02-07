import CoreLocation
import CoreMotion
import StoreKit
import SwiftUI
import UIKit

struct SettingsView: View {
  @Environment(\.openURL) private var openURL
  @Environment(\.scenePhase) private var scenePhase
  @EnvironmentObject private var subscriptionManager: SubscriptionManager
  @EnvironmentObject private var tripStore: TripStore
  @EnvironmentObject private var categoriesStore: CategoriesStore
  @EnvironmentObject private var clientStore: ClientStore
  @EnvironmentObject private var rulesStore: RulesStore
  @EnvironmentObject private var autoModeManager: AutoModeManager

  @AppStorage("autoModeEnabled") private var autoModeEnabled: Bool = true
  @State private var motionDeniedMessage: String? = nil
  @State private var isLocationServicesOff: Bool = false

  var body: some View {
    ScrollView {
      VStack(alignment: .leading, spacing: 14) {
        trackingSection
        categoriesSection
        clientsSection
        rulesSection
        subscriptionSection
#if DEBUG
        diagnosticsSection
#endif
        privacySection
        debugSection
      }
      .padding(.horizontal, 16)
      .padding(.vertical, 12)
    }
    .background(.background)
    .navigationTitle("Settings")
    .onAppear {
      subscriptionManager.start()
      autoModeManager.setEnabled(autoModeEnabled)
      refreshLocationServicesOff()
    }
    .onChange(of: scenePhase) { _, newValue in
      // Location Services can be toggled outside the app; refresh when returning active.
      if newValue == .active {
        refreshLocationServicesOff()
      }
    }
    .onChange(of: autoModeManager.status.motionAuthorization) { _, newValue in
      // If motion is denied, force Auto Mode off to avoid confusing "enabled but can't run" states.
      if newValue == .denied || newValue == .restricted {
        if autoModeEnabled {
          autoModeEnabled = false
        }
        motionDeniedMessage = "Motion permission is denied. Enable Motion & Fitness for MileTrack in iOS Settings to use Auto Mode."
      } else {
        motionDeniedMessage = nil
      }
    }
  }

  private func refreshLocationServicesOff() {
    // `CLLocationManager.locationServicesEnabled()` can block; keep it off the main thread.
    DispatchQueue.global(qos: .utility).async {
      let off = !CLLocationManager.locationServicesEnabled()
      Task { @MainActor in
        self.isLocationServicesOff = off
      }
    }
  }

  private var trackingSection: some View {
    /*
     Manual test checklist (permissions):
     - Motion denied/restricted: Toggle should not enable; show calm message; Auto Mode must not start.
     - Location services OFF globally: Show guidance; Auto Mode may be limited.
     - Location When In Use only: Warn that background detection is limited; offer Open iOS Settings.
     - Location denied/restricted: Show blocked status + Open iOS Settings.
     */

    VStack(alignment: .leading, spacing: 10) {
      Text("Tracking")
        .font(.headline)

      GlassCard {
        VStack(alignment: .leading, spacing: 10) {
          Toggle(isOn: autoModeToggleBinding) {
            VStack(alignment: .leading, spacing: 4) {
              Text("Auto Mode")
                .font(.subheadline.weight(.semibold))
              Text("Detect drives and send them to Inbox as pending trips.")
                .font(.footnote)
                .foregroundStyle(.secondary)
            }
          }
          .tint(.accentColor)
          .accessibilityLabel("Auto Mode")
          .accessibilityHint(autoModeToggleHint)

          VStack(alignment: .leading, spacing: 6) {
            Text("Tracking Status")
              .font(.subheadline.weight(.semibold))
              .foregroundStyle(.secondary)

            Text(autoModeStatusLine)
              .font(.footnote)
              .foregroundStyle(.secondary)
              .accessibilityLabel("Auto mode status")
              .accessibilityValue(autoModeStatusLine)

            if let motionDeniedMessage {
              Text(motionDeniedMessage)
                .font(.footnote)
                .foregroundStyle(.secondary)

              Button {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                  openURL(url)
                }
              } label: {
                HStack {
                  Image(systemName: "gearshape")
                    .accessibilityHidden(true)
                  Text("Open iOS Settings")
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
              .accessibilityHint("Opens iOS Settings so you can enable Motion & Fitness for MileTrack.")
            }

            if isLocationServicesOff {
              Text("Needs Location Services. Turn on Location Services in iOS Settings to estimate mileage.")
                .font(.footnote)
                .foregroundStyle(.secondary)

              Button {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                  openURL(url)
                }
              } label: {
                HStack {
                  Image(systemName: "gearshape")
                    .accessibilityHidden(true)
                  Text("Open Settings")
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
              .accessibilityHint("Opens iOS Settings so you can enable Location Services.")
            }

            if autoModeEnabled {
              if autoModeManager.status.locationAuthorization == .notDetermined {
                Button {
                  autoModeManager.requestWhenInUseLocation()
                } label: {
                  HStack {
                    Image(systemName: "location")
                      .accessibilityHidden(true)
                    Text("Enable Location (When In Use)")
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
                .accessibilityHint("Requests location permission.")
              } else if autoModeManager.status.locationAuthorization == .denied || autoModeManager.status.locationAuthorization == .restricted {
                Text("Location access is blocked. You can update permissions in iOS Settings.")
                  .font(.footnote)
                  .foregroundStyle(.secondary)

                Button {
                  if let url = URL(string: UIApplication.openSettingsURLString) {
                    openURL(url)
                  }
                } label: {
                  HStack {
                    Image(systemName: "gearshape")
                      .accessibilityHidden(true)
                    Text("Open iOS Settings")
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
                .accessibilityHint("Opens iOS Settings for MileTrack.")
              }
            }
          }

          VStack(alignment: .leading, spacing: 10) {
            Text("Auto Mode requirements")
              .font(.subheadline.weight(.semibold))
              .foregroundStyle(.secondary)

            Text(backgroundLocationCopy)
              .font(.footnote)
              .foregroundStyle(.secondary)

            Button {
              if let url = URL(string: UIApplication.openSettingsURLString) {
                openURL(url)
              }
            } label: {
              HStack {
                Image(systemName: "arrow.up.right.square")
                  .accessibilityHidden(true)
                Text("Open Settings")
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
            .accessibilityHint("Opens iOS Settings for MileTrack so you can set Location to Always.")
          }

          if subscriptionManager.canUseUnlimitedAutoMode {
            HStack(spacing: 8) {
              Image(systemName: "sparkles")
                .foregroundStyle(.secondary)
                .accessibilityHidden(true)
              Text("Unlimited Auto Mode included with Pro.")
                .font(.footnote)
                .foregroundStyle(.secondary)
            }
          } else {
            HStack(spacing: 8) {
              Image(systemName: "lock.fill")
                .foregroundStyle(.secondary)
                .accessibilityHidden(true)
              Text("Free tier may be limited (prep only; no enforcement).")
                .font(.footnote)
                .foregroundStyle(.secondary)
              ProBadge()
                .accessibilityHidden(true)
            }
          }
        }
      }
    }
  }

  private var autoModeToggleBinding: Binding<Bool> {
    Binding(
      get: { autoModeEnabled },
      set: { newValue in
        // Prevent enabling Auto Mode when Motion permission is denied/restricted.
        if newValue, isMotionDeniedOrRestricted {
          autoModeEnabled = false
          motionDeniedMessage = "Motion permission is denied. Enable Motion & Fitness for MileTrack in iOS Settings to use Auto Mode."
          autoModeManager.setEnabled(false)
          return
        }
        autoModeEnabled = newValue
        autoModeManager.setEnabled(newValue)
      }
    )
  }

  private var isMotionDeniedOrRestricted: Bool {
    autoModeManager.status.motionAuthorization == .denied || autoModeManager.status.motionAuthorization == .restricted
  }

  private var backgroundLocationCopy: String {
    let base = "Auto Mode uses background location to detect drives and prevent missed mileage."
    switch autoModeManager.status.locationAuthorization {
    case .authorizedAlways:
      return base + " Location is used to estimate distance and create trips for your Inbox."
    case .authorizedWhenInUse:
      return "Needs Always Location for background drive detection. " + base + " You can still capture drives while the app is open."
    case .notDetermined:
      return base + " You can enable Location access to estimate mileage during drives."
    case .denied, .restricted:
      return "Needs Location permission. " + base + " Location access is currently blocked."
    @unknown default:
      return base
    }
  }

  private var autoModeToggleHint: String {
    if isMotionDeniedOrRestricted {
      return "Motion permission is required for Auto Mode."
    }
    return "Toggles Auto Mode for drive detection."
  }

  private var autoModeStatusLine: String {
    let s = autoModeManager.status

    let location: String = {
      switch s.locationAuthorization {
      case .authorizedAlways: return "Location: Always"
      case .authorizedWhenInUse: return "Location: When In Use"
      case .denied: return "Location: Denied"
      case .restricted: return "Location: Restricted"
      case .notDetermined: return "Location: Not Determined"
      @unknown default: return "Location: Unknown"
      }
    }()

    let motion: String = {
      switch s.motionAuthorization {
      case .authorized: return "Motion: Allowed"
      case .denied: return "Motion: Denied"
      case .restricted: return "Motion: Restricted"
      case .notDetermined: return "Motion: Not Determined"
      @unknown default: return "Motion: Unknown"
      }
    }()

    let drive = s.isDriving ? "Driving: Yes" : "Driving: No"
    let tracking = s.isLocationTrackingActive ? "GPS: On" : "GPS: Off"
    let miles = (s.distanceMeters / 1609.344).formatted(.number.precision(.fractionLength(0...2)))
    let distance = "Distance: \(miles) mi"

    let last = s.lastEvent.map { "Last: \($0)" } ?? "Last: —"
    return [location, motion, drive, tracking, distance, last].joined(separator: " • ")
  }

  private var categoriesSection: some View {
    VStack(alignment: .leading, spacing: 10) {
      Text("Categories")
        .font(.headline)

      GlassCard {
        VStack(alignment: .leading, spacing: 12) {
          Text("Manage categories used to confirm trips.")
            .font(.footnote)
            .foregroundStyle(.secondary)

          NavigationLink {
            ManageCategoriesView()
          } label: {
            HStack {
              Text("Manage Categories")
                .font(.subheadline.weight(.semibold))
              Spacer()
              Image(systemName: "chevron.right")
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
          .accessibilityLabel("Manage Categories")
        }
      }
    }
  }

  private var clientsSection: some View {
    VStack(alignment: .leading, spacing: 10) {
      Text("Clients")
        .font(.headline)

      GlassCard {
        VStack(alignment: .leading, spacing: 12) {
          Text("Manage clients used for optional trip attribution and reporting.")
            .font(.footnote)
            .foregroundStyle(.secondary)

          NavigationLink {
            ManageClientsView()
          } label: {
            HStack {
              Text("Manage Clients")
                .font(.subheadline.weight(.semibold))
              Spacer()
              Image(systemName: "chevron.right")
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
          .accessibilityLabel("Manage Clients")
        }
      }
    }
  }

  private var rulesSection: some View {
    VStack(alignment: .leading, spacing: 10) {
      Text("Rules")
        .font(.headline)

      GlassCard {
        VStack(alignment: .leading, spacing: 12) {
          Text("Create deterministic suggestions for auto-detected trips.")
            .font(.footnote)
            .foregroundStyle(.secondary)

          NavigationLink {
            RulesView()
          } label: {
            HStack {
              Text("Rules")
                .font(.subheadline.weight(.semibold))
              Spacer()
              Image(systemName: "chevron.right")
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
          .accessibilityLabel("Rules")
        }
      }
    }
  }

  private var subscriptionSection: some View {
    VStack(alignment: .leading, spacing: 10) {
      Text("Subscription")
        .font(.headline)

      GlassCard {
        VStack(alignment: .leading, spacing: 12) {
          HStack {
            VStack(alignment: .leading, spacing: 4) {
              Text("Current Plan")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.secondary)
              Text(subscriptionManager.statusDisplayName)
                .font(.title3.weight(.bold))
            }
            Spacer(minLength: 0)
            if subscriptionManager.status.tier == .pro {
              ProBadge()
            }
          }

          if subscriptionManager.isLoadingProducts && subscriptionManager.products.isEmpty {
            Text("Loading plans…")
              .font(.footnote)
              .foregroundStyle(.secondary)
          } else if subscriptionManager.products.isEmpty {
            Text("Plans unavailable.")
              .font(.footnote)
              .foregroundStyle(.secondary)
          } else {
            VStack(spacing: 10) {
              if let monthly = subscriptionManager.products.first(where: { $0.id == SubscriptionProductIDs.proMonthly }) {
                planRow(product: monthly, buttonTitle: "Subscribe Monthly") {
                  Task { await subscriptionManager.purchase(product: monthly) }
                }
              }
              if let annual = subscriptionManager.products.first(where: { $0.id == SubscriptionProductIDs.proAnnual }) {
                planRow(product: annual, buttonTitle: "Subscribe Annual") {
                  Task { await subscriptionManager.purchase(product: annual) }
                }
              }
            }
          }

          Button {
            Task { await subscriptionManager.restorePurchases() }
          } label: {
            HStack {
              Image(systemName: "arrow.clockwise")
                .accessibilityHidden(true)
              Text("Restore Purchases")
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
          .disabled(subscriptionManager.isProcessingPurchase)
          .accessibilityLabel("Restore Purchases")

          Button {
            Task { await subscriptionManager.refresh() }
          } label: {
            HStack {
              Image(systemName: "arrow.clockwise.circle")
                .accessibilityHidden(true)
              Text("Refresh Status")
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
          .disabled(subscriptionManager.isProcessingPurchase || subscriptionManager.isLoadingProducts)
          .accessibilityLabel("Refresh Status")

          if let msg = subscriptionManager.lastErrorMessage {
            Text(msg)
              .font(.footnote)
              .foregroundStyle(.secondary)
          }

          Divider().opacity(0.25)

          VStack(alignment: .leading, spacing: 8) {
            Text("Subscription terms")
              .font(.footnote.weight(.semibold))
              .foregroundStyle(.secondary)

            Text("Payment will be charged to your Apple ID account at confirmation of purchase. Subscription automatically renews unless it is canceled at least 24 hours before the end of the current period. You can manage or cancel in your Apple ID account settings. Restore purchases is available above.")
              .font(.footnote)
              .foregroundStyle(.secondary)

            Button {
              let deepLink = URL(string: "itms-apps://apps.apple.com/account/subscriptions")
              let web = URL(string: "https://apps.apple.com/account/subscriptions")

              if let deepLink, UIApplication.shared.canOpenURL(deepLink) {
                UIApplication.shared.open(deepLink, options: [:], completionHandler: nil)
              } else if let web {
                openURL(web)
              }
            } label: {
              HStack {
                Image(systemName: "person.crop.circle")
                  .accessibilityHidden(true)
                Text("Manage Subscription")
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
            .accessibilityLabel("Manage Subscription")

            HStack(spacing: 10) {
              Link("Privacy Policy", destination: URL(string: "https://yourcompany.example/privacy")!)
              Text("•").foregroundStyle(.secondary)
              Link("Terms", destination: URL(string: "https://yourcompany.example/terms")!)
            }
            .font(.footnote.weight(.semibold))
            .foregroundStyle(.secondary)
          }

          Text(subscriptionDebugLine)
            .font(.caption)
            .foregroundStyle(.secondary)
        }
      }
    }
  }

  private func planRow(product: Product, buttonTitle: String, action: @escaping () -> Void) -> some View {
    VStack(alignment: .leading, spacing: 8) {
      HStack(alignment: .firstTextBaseline) {
        VStack(alignment: .leading, spacing: 2) {
          Text(product.displayName)
            .font(.subheadline.weight(.semibold))
          if !product.description.isEmpty {
            Text(product.description)
              .font(.footnote)
              .foregroundStyle(.secondary)
          }
        }
        Spacer(minLength: 0)
        Text(product.displayPrice)
          .font(.subheadline.weight(.semibold))
      }

      PrimaryGlassButton(title: buttonTitle, systemImage: "sparkles", isEnabled: !subscriptionManager.isProcessingPurchase) {
        action()
      }
    }
    .accessibilityElement(children: .contain)
  }

  private var subscriptionDebugLine: String {
    let updated: String = {
      guard let date = subscriptionManager.lastUpdated else { return "Updated: —" }
      return "Updated: " + date.formatted(date: .abbreviated, time: .shortened)
    }()
    let entitlement = "Entitlement: \(subscriptionManager.statusDisplayName)"
    return "\(updated) • \(entitlement)"
  }

#if DEBUG
  private var diagnosticsSection: some View {
    VStack(alignment: .leading, spacing: 10) {
      Text("Diagnostics")
        .font(.headline)

      GlassCard {
        VStack(alignment: .leading, spacing: 12) {
          Text("Copy or share on-device logs for Auto Mode testing.")
            .font(.footnote)
            .foregroundStyle(.secondary)

          NavigationLink {
            DiagnosticsView()
          } label: {
            HStack {
              Text("Diagnostics")
                .font(.subheadline.weight(.semibold))
              Spacer()
              Image(systemName: "chevron.right")
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
          .accessibilityLabel("Diagnostics")
        }
      }
    }
  }
#endif

  private var privacySection: some View {
    VStack(alignment: .leading, spacing: 10) {
      Text("Privacy")
        .font(.headline)

      GlassCard {
        VStack(alignment: .leading, spacing: 12) {
          Text("Plain-English disclosures and data controls.")
            .font(.footnote)
            .foregroundStyle(.secondary)

          NavigationLink {
            PrivacyView()
          } label: {
            HStack {
              Text("Privacy")
                .font(.subheadline.weight(.semibold))
              Spacer()
              Image(systemName: "chevron.right")
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
          .accessibilityLabel("Privacy")
        }
      }
    }
  }

  private var debugSection: some View {
#if DEBUG
    VStack(alignment: .leading, spacing: 10) {
      Text("Debug")
        .font(.headline)

      GlassCard {
        VStack(alignment: .leading, spacing: 10) {
          Text("Demo helpers")
            .font(.subheadline.weight(.semibold))
          Text("Resets trips, categories, Auto Mode toggle, and subscription test state.")
            .font(.footnote)
            .foregroundStyle(.secondary)

          Button(role: .destructive) {
            tripStore.resetDemoData()
            categoriesStore.resetToDefaults()
            autoModeEnabled = true
            subscriptionManager.resetToFree()
          } label: {
            HStack {
              Image(systemName: "arrow.counterclockwise")
                .accessibilityHidden(true)
              Text("Reset Demo Data")
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
          .accessibilityLabel("Reset Demo Data")

#if DEBUG
          Button {
            autoModeManager.debugSimulateDrive()
          } label: {
            HStack {
              Image(systemName: "car")
                .accessibilityHidden(true)
              Text("Simulate Drive → Inbox")
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
          .accessibilityLabel("Simulate Drive")
#endif
        }
      }
    }
#else
    EmptyView()
#endif
  }
}

private extension SubscriptionManager {
  var statusDisplayName: String {
    switch status.tier {
    case .free:
      return "Free"
    case .pro:
      return status.isAnnual ? "Pro (Annual)" : "Pro (Monthly)"
    }
  }
}

#Preview {
  NavigationStack {
    SettingsView()
  }
  .environmentObject(SubscriptionManager())
  .environmentObject(TripStore())
  .environmentObject(CategoriesStore())
  .environmentObject(ClientStore())
  .environmentObject(RulesStore())
  .environmentObject(AutoModeManager(tripStore: TripStore()))
}

