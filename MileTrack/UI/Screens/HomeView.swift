import SwiftUI

struct HomeView: View {
  @EnvironmentObject private var tripStore: TripStore
  @EnvironmentObject private var subscriptionManager: SubscriptionManager
  @EnvironmentObject private var autoModeManager: AutoModeManager
  @EnvironmentObject private var mileageRatesStore: MileageRatesStore

  /// Hook for switching tabs (Inbox). MainTabView can wire this later.
  var onOpenInbox: (() -> Void)?
  /// Hook for switching to Settings tab.
  var onOpenSettings: (() -> Void)?

  @AppStorage("useMetricUnits") private var useMetricUnits = false

  var body: some View {
    ScrollView {
      VStack(spacing: DesignConstants.Spacing.sm) {
        statusCard
        deductionHeroCard
        kpiRow
        actionsCard
      }
      .padding(.horizontal, DesignConstants.Spacing.md)
      .padding(.vertical, DesignConstants.Spacing.sm)
    }
    .background(.background)
    .navigationTitle("Home")
  }

  private var statusCard: some View {
    GlassCard(
      showGlow: autoModeManager.trackingHealth == .green,
      depth: .surface
    ) {
      VStack(alignment: .leading, spacing: DesignConstants.Spacing.sm) {
        Text("Status")
          .font(.headline)

        HStack(alignment: .center, spacing: 8) {
          StatusChip(
            title: subscriptionManager.status.tier == .pro ? "Pro" : "Free",
            systemImage: subscriptionManager.status.tier == .pro ? "sparkles" : "leaf"
          )

          TrackingHealthChip(
            health: autoModeManager.trackingHealth,
            onTap: onOpenSettings
          )

          Spacer(minLength: 0)

          Button {
            if let onOpenInbox {
              onOpenInbox()
            }
          } label: {
            InboxPill(count: tripStore.pendingTrips.count)
          }
          .buttonStyle(.plain)
          .accessibilityHint("Opens Inbox to categorize pending trips.")
        }

        Text(autoModeManager.trackingHealth.description)
          .font(.footnote)
          .foregroundStyle(.secondary)
      }
    }
  }

  private var kpiRow: some View {
    HStack(spacing: 12) {
      MetricTile(
        title: "Today",
        value: milesFormatted(todayConfirmedMiles),
        systemImage: "sun.max",
        footnote: "Confirmed"
      )
      MetricTile(
        title: "This Week",
        value: milesFormatted(weekConfirmedMiles),
        systemImage: "calendar",
        footnote: "Confirmed"
      )
    }
  }

  private var actionsCard: some View {
    GlassCard(depth: .surface) {
      VStack(alignment: .leading, spacing: DesignConstants.Spacing.sm) {
        Text("Quick Actions")
          .font(.headline)

        if tripStore.pendingTrips.count > 0 {
          PrimaryGlassButton(title: "Review Inbox", systemImage: "tray") {
            if let onOpenInbox {
              onOpenInbox()
            }
          }
          .accessibilityHint("Review and confirm pending auto-detected trips.")
        } else {
          HStack(spacing: 8) {
            Image(systemName: "checkmark.seal")
              .foregroundStyle(.secondary)
              .accessibilityHidden(true)
            Text("Inbox is clear")
              .foregroundStyle(.secondary)
              .font(.subheadline.weight(.semibold))
          }
          .padding(.top, 2)
          .accessibilityLabel("Inbox is clear")
        }
      }
    }
  }


  // MARK: - Deduction Hero Card

  private var deductionHeroCard: some View {
    GlassCard(showGlow: yearDeductionAmount > 0, depth: .elevated) {
      VStack(alignment: .leading, spacing: 6) {
        HStack(alignment: .firstTextBaseline, spacing: 0) {
          Text(yearDeductionFormatted)
            .font(.system(size: 40, weight: .bold, design: .rounded))
            .foregroundStyle(yearDeductionAmount > 0 ? .primary : .secondary)
            .contentTransition(.numericText())
            .animation(.spring(response: 0.5, dampingFraction: 0.8), value: yearDeductionFormatted)

          Spacer(minLength: 0)

          Image(systemName: "dollarsign.arrow.circlepath")
            .font(.title2)
            .foregroundStyle(.green.opacity(0.8))
            .accessibilityHidden(true)
        }

        Text("estimated \(String(Calendar.current.component(.year, from: Date()))) deduction")
          .font(.footnote.weight(.medium))
          .foregroundStyle(.secondary)
          .textCase(.lowercase)

        if yearConfirmedMiles > 0 {
          HStack(spacing: 16) {
            Label(DistanceFormatter.format(yearConfirmedMiles), systemImage: "road.lanes")
              .font(.caption.weight(.semibold))
              .foregroundStyle(.secondary)

            if let topCategory = yearTopCategory {
              Label(topCategory, systemImage: "tag")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
                .lineLimit(1)
            }
          }
          .padding(.top, 2)
        } else {
          Text("Confirm trips to start tracking your deduction.")
            .font(.caption)
            .foregroundStyle(.tertiary)
            .padding(.top, 2)
        }
      }
    }
    .accessibilityElement(children: .ignore)
    .accessibilityLabel("Year-to-date estimated deduction")
    .accessibilityValue(yearDeductionFormatted)
  }

  // MARK: - Year Calculations

  private var yearConfirmedTrips: [Trip] {
    let calendar = Calendar.current
    let year = calendar.component(.year, from: Date())
    return tripStore.confirmedTrips.filter {
      calendar.component(.year, from: $0.date) == year
    }
  }

  private var yearConfirmedMiles: Double {
    yearConfirmedTrips.reduce(0) { $0 + $1.distanceMiles }
  }

  private var yearDeductionAmount: Decimal {
    yearConfirmedTrips.reduce(Decimal(0)) { acc, trip in
      let rate = mileageRatesStore.rate(for: trip)?.ratePerMile ?? Decimal(string: "0.70")!
      return acc + Decimal(trip.distanceMiles) * rate
    }
  }

  private var yearDeductionFormatted: String {
    let formatter = NumberFormatter()
    formatter.numberStyle = .currency
    formatter.currencyCode = "USD"
    formatter.maximumFractionDigits = 0
    return formatter.string(from: yearDeductionAmount as NSNumber) ?? "$0"
  }

  private var yearTopCategory: String? {
    let counts = yearConfirmedTrips.reduce(into: [String: Double]()) { dict, trip in
      guard let cat = trip.category, !cat.isEmpty else { return }
      dict[cat, default: 0] += trip.distanceMiles
    }
    return counts.max(by: { $0.value < $1.value })?.key
  }

  private var todayConfirmedMiles: Double {
    let calendar = Calendar.current
    return tripStore.confirmedTrips
      .filter { calendar.isDateInToday($0.date) }
      .reduce(0) { $0 + $1.distanceMiles }
  }

  private var weekConfirmedMiles: Double {
    let calendar = Calendar.current
    guard let interval = calendar.dateInterval(of: .weekOfYear, for: Date()) else {
      return tripStore.confirmedTrips.reduce(0) { $0 + $1.distanceMiles }
    }
    return tripStore.confirmedTrips
      .filter { interval.contains($0.date) }
      .reduce(0) { $0 + $1.distanceMiles }
  }

  private func milesFormatted(_ miles: Double) -> String {
    DistanceFormatter.format(miles)
  }
}

private struct StatusChip: View {
  let title: String
  let systemImage: String

  var body: some View {
    HStack(spacing: 6) {
      Image(systemName: systemImage)
        .imageScale(.small)
        .accessibilityHidden(true)
      Text(title)
        .font(.caption.weight(.semibold))
    }
    .padding(.horizontal, 10)
    .padding(.vertical, 6)
    .background(.thinMaterial, in: Capsule())
    .overlay {
      Capsule()
        .strokeBorder(Color.primary.opacity(0.10), lineWidth: 1)
    }
    .accessibilityElement(children: .ignore)
    .accessibilityLabel(title)
  }
}

private struct InboxPill: View {
  let count: Int

  var body: some View {
    HStack(spacing: 6) {
      Image(systemName: "tray")
        .imageScale(.small)
        .accessibilityHidden(true)
      Text("\(count)")
        .font(.caption.weight(.bold))
      Text("Inbox")
        .font(.caption.weight(.semibold))
        .foregroundStyle(.secondary)
    }
    .padding(.horizontal, 10)
    .padding(.vertical, 7)
    .background(.ultraThinMaterial, in: Capsule())
    .overlay {
      Capsule()
        .strokeBorder(Color.primary.opacity(0.10), lineWidth: 1)
    }
    .accessibilityElement(children: .ignore)
    .accessibilityLabel("Inbox")
    .accessibilityValue("\(count) pending")
  }
}

private struct TrackingHealthChip: View {
  let health: AutoModeManager.TrackingHealth
  var onTap: (() -> Void)?

  @State private var isPulsing = false

  private var indicatorColor: Color {
    switch health {
    case .green: return .green
    case .orange: return .orange
    case .red: return .red
    }
  }

  var body: some View {
    Button {
      onTap?()
    } label: {
      HStack(spacing: 6) {
        Circle()
          .fill(indicatorColor)
          .frame(width: 8, height: 8)
          .scaleEffect(isPulsing ? 1.15 : 1.0)
          .opacity(isPulsing ? 0.7 : 1.0)
          .animation(
            health == .green
              ? .easeInOut(duration: 1.4).repeatForever(autoreverses: true)
              : .default,
            value: isPulsing
          )
          .accessibilityHidden(true)
        Text(health.title)
          .font(.caption.weight(.semibold))
        if health != .green {
          Image(systemName: "chevron.right")
            .imageScale(.small)
            .foregroundStyle(.secondary)
            .accessibilityHidden(true)
        }
      }
      .padding(.horizontal, 10)
      .padding(.vertical, 6)
      .background(indicatorColor.opacity(0.15), in: Capsule())
      .overlay {
        Capsule()
          .strokeBorder(indicatorColor.opacity(0.3), lineWidth: 1)
      }
    }
    .buttonStyle(.plain)
    .accessibilityElement(children: .ignore)
    .accessibilityLabel("Tracking Status")
    .accessibilityValue(health.title)
    .accessibilityHint(health != .green ? "Opens Settings to fix tracking issues." : "")
    .onAppear {
      if health == .green {
        isPulsing = true
      }
    }
    .onChange(of: health) { _, newHealth in
      isPulsing = newHealth == .green
    }
  }
}

#Preview {
  NavigationStack {
    HomeView(onOpenInbox: {}, onOpenSettings: {})
  }
  .environmentObject(TripStore())
  .environmentObject(SubscriptionManager())
  .environmentObject(CategoriesStore())
  .environmentObject(ClientsStore())
  .environmentObject(RulesStore())
  .environmentObject(AutoModeManager(tripStore: TripStore()))
  .environmentObject(MileageRatesStore())
}
