import SwiftUI

struct HomeView: View {
  @EnvironmentObject private var tripStore: TripStore
  @EnvironmentObject private var subscriptionManager: SubscriptionManager

  /// Hook for switching tabs (Inbox). MainTabView can wire this later.
  var onOpenInbox: (() -> Void)?

  @State private var isPresentingManualTrip = false
  @State private var selectedTrip: Trip?

  var body: some View {
    ScrollView {
      VStack(spacing: DesignConstants.Spacing.sm) {
        statusCard
        kpiRow
        actionsCard
        recentTripsCard
      }
      .padding(.horizontal, DesignConstants.Spacing.md)
      .padding(.vertical, DesignConstants.Spacing.sm)
    }
    .background(.background)
    .navigationTitle("Home")
    .sheet(isPresented: $isPresentingManualTrip) {
      ManualTripSheet()
    }
    .sheet(item: $selectedTrip) { trip in
      TripDetailView(trip: trip)
    }
  }

  private var statusCard: some View {
    GlassCard {
      VStack(alignment: .leading, spacing: DesignConstants.Spacing.sm) {
        HStack(alignment: .center, spacing: 10) {
          VStack(alignment: .leading, spacing: 6) {
            Text("Status")
              .font(.headline)

            HStack(spacing: 8) {
              StatusChip(
                title: subscriptionManager.status.tier == .pro ? "Pro" : "Free",
                systemImage: subscriptionManager.status.tier == .pro ? "sparkles" : "leaf"
              )

              StatusChip(
                title: autoModeChipTitle,
                systemImage: "bolt.badge.a"
              )
              .accessibilityLabel("Auto Mode")
              .accessibilityValue(autoModeChipTitle)
            }
          }

          Spacer(minLength: 0)

          Button {
            if let onOpenInbox {
              onOpenInbox()
            } else {
              // Future: Wire to MainTabView selected tab binding to switch to Inbox.
            }
          } label: {
            InboxPill(count: tripStore.pendingTrips.count)
          }
          .buttonStyle(.plain)
          .accessibilityHint("Opens Inbox to categorize pending trips.")
        }

        Text("Auto-detected trips are not counted until you categorize and confirm them in Inbox.")
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
    GlassCard {
      VStack(alignment: .leading, spacing: DesignConstants.Spacing.sm) {
        Text("Quick Actions")
          .font(.headline)

        PrimaryGlassButton(title: "Add Trip", systemImage: "plus") {
          isPresentingManualTrip = true
        }
        .accessibilityHint("Opens manual trip entry.")

        if tripStore.pendingTrips.count > 0 {
          PrimaryGlassButton(title: "Review Inbox", systemImage: "tray") {
            if let onOpenInbox {
              onOpenInbox()
            } else {
              // Future: Wire to MainTabView selected tab binding to switch to Inbox.
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

  private var recentTripsCard: some View {
    VStack(alignment: .leading, spacing: 10) {
      HStack {
        Text("Recent Confirmed")
          .font(.headline)
        Spacer(minLength: 0)
        Text("\(recentConfirmedTrips.count)")
          .foregroundStyle(.secondary)
          .font(.subheadline)
          .accessibilityHidden(true)
      }

      if recentConfirmedTrips.isEmpty {
        EmptyStateView(
          systemImage: "car",
          title: "No confirmed trips yet",
          subtitle: "Confirmed trips appear here and in Reports.",
          actionTitle: "Add Trip",
          action: { isPresentingManualTrip = true }
        )
      } else {
        VStack(spacing: 10) {
          ForEach(recentConfirmedTrips, id: \.id) { trip in
            Button {
              selectedTrip = trip
            } label: {
              GlassCard {
                HStack(alignment: .top, spacing: 12) {
                  VStack(alignment: .leading, spacing: 6) {
                    Text(routeLabel(trip))
                      .font(.subheadline.weight(.semibold))
                      .foregroundStyle(.primary)
                      .lineLimit(2)
                      .minimumScaleFactor(0.85)

                    HStack(spacing: 10) {
                      Text(trip.date, format: .dateTime.month().day())
                        .foregroundStyle(.secondary)
                      if let category = trip.category, !category.isEmpty {
                        Text(category)
                          .foregroundStyle(.secondary)
                      }
                    }
                    .font(.footnote)
                  }

                  Spacer(minLength: 0)

                  VStack(alignment: .trailing, spacing: 6) {
                    Text(trip.distanceMiles.formatted(.number.precision(.fractionLength(0...1))) + " mi")
                      .font(.subheadline.weight(.semibold))
                    if let seconds = trip.durationSeconds, seconds > 0 {
                      Text(durationFormatted(seconds))
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                    }
                  }
                }
              }
            }
            .buttonStyle(.plain)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("Trip, \(routeLabel(trip)), \(trip.distanceMiles.formatted(.number.precision(.fractionLength(0...1)))) miles")
            .accessibilityHint("Opens trip details.")
          }
        }
      }
    }
  }

  private var recentConfirmedTrips: [Trip] {
    Array(tripStore.confirmedTrips.prefix(3))
  }

  private var autoModeChipTitle: String {
    // Uses subscription tier (Auto Mode itself is configured in Settings).
    subscriptionManager.canUseUnlimitedAutoMode ? "Auto: Unlimited" : "Auto: Limited"
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
    let number = miles.formatted(.number.precision(.fractionLength(0...1)))
    return "\(number) mi"
  }

  private func routeLabel(_ trip: Trip) -> String {
    let start = trip.startLabel?.trimmingCharacters(in: .whitespacesAndNewlines)
    let end = trip.endLabel?.trimmingCharacters(in: .whitespacesAndNewlines)
    if let start, !start.isEmpty, let end, !end.isEmpty { return "\(start) → \(end)" }
    if let start, !start.isEmpty { return start }
    if let end, !end.isEmpty { return end }
    return "Trip"
  }

  private func durationFormatted(_ seconds: Int) -> String {
    let minutes = max(0, seconds / 60)
    if minutes < 60 { return "\(minutes)m" }
    let hours = minutes / 60
    let rem = minutes % 60
    return rem == 0 ? "\(hours)h" : "\(hours)h \(rem)m"
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

private struct TripDetailView: View {
  @Environment(\.dismiss) private var dismiss
  let trip: Trip

  var body: some View {
    NavigationStack {
      VStack(alignment: .leading, spacing: 12) {
        Text(routeLabel(trip))
          .font(.title3.weight(.bold))
        Text("Trip details")
          .foregroundStyle(.secondary)

        GlassCard {
          VStack(alignment: .leading, spacing: 8) {
            LabeledContent("Date") { Text(trip.date.formatted(date: .abbreviated, time: .omitted)) }
            LabeledContent("Distance") { Text(milesFormatted(trip.distanceMiles)) }
            if let category = trip.category, !category.isEmpty {
              LabeledContent("Category") { Text(category) }
            }
          }
        }

        Spacer()
      }
      .padding(16)
      .navigationTitle("Trip")
      .navigationBarTitleDisplayMode(.inline)
      .toolbar {
        ToolbarItem(placement: .cancellationAction) {
          Button("Close") { dismiss() }
        }
      }
      .accessibilityElement(children: .contain)
    }
  }

  private func milesFormatted(_ miles: Double) -> String {
    let number = miles.formatted(.number.precision(.fractionLength(0...1)))
    return "\(number) mi"
  }

  private func routeLabel(_ trip: Trip) -> String {
    let start = trip.startLabel?.trimmingCharacters(in: .whitespacesAndNewlines)
    let end = trip.endLabel?.trimmingCharacters(in: .whitespacesAndNewlines)
    if let start, !start.isEmpty, let end, !end.isEmpty { return "\(start) → \(end)" }
    if let start, !start.isEmpty { return start }
    if let end, !end.isEmpty { return end }
    return "Trip"
  }
}

#Preview {
  NavigationStack {
    HomeView(onOpenInbox: {})
  }
  .environmentObject(TripStore())
  .environmentObject(SubscriptionManager())
  .environmentObject(CategoriesStore())
  .environmentObject(ClientStore())
  .environmentObject(RulesStore())
}

