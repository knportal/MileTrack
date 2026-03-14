import SwiftUI

/// Sheet for merging a confirmed trip with another nearby confirmed trip.
/// Presented from EditTripSheet when compatible trips exist within ±24 hours.
struct MergeTripsSheet: View {
  @Environment(\.dismiss) private var dismiss
  @EnvironmentObject private var tripStore: TripStore

  let anchorTrip: Trip

  @State private var selectedTripID: UUID?

  private let timeWindow: TimeInterval = 24 * 60 * 60

  private var candidateTrips: [Trip] {
    tripStore.confirmedTrips.filter { other in
      other.id != anchorTrip.id &&
        abs(other.date.timeIntervalSince(anchorTrip.date)) <= timeWindow
    }
    .sorted { abs($0.date.timeIntervalSince(anchorTrip.date)) < abs($1.date.timeIntervalSince(anchorTrip.date)) }
  }

  var body: some View {
    NavigationStack {
      ScrollView {
        VStack(alignment: .leading, spacing: 14) {
          anchorCard
          candidateList
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
      }
      .background(.background)
      .navigationTitle("Merge With Trip")
      .navigationBarTitleDisplayMode(.inline)
      .toolbar {
        ToolbarItem(placement: .cancellationAction) {
          Button("Cancel") { dismiss() }
        }
        ToolbarItem(placement: .confirmationAction) {
          Button {
            performMerge()
          } label: {
            Label("Merge", systemImage: "arrow.triangle.merge")
              .fontWeight(.semibold)
          }
          .disabled(selectedTripID == nil)
        }
      }
    }
    .presentationBackground(.ultraThinMaterial)
    .presentationDetents([.medium, .large])
  }

  // MARK: - Anchor card

  private var anchorCard: some View {
    GlassCard {
      VStack(alignment: .leading, spacing: 8) {
        Text("Merging this trip…")
          .font(.caption.weight(.semibold))
          .foregroundStyle(.secondary)

        tripRow(anchorTrip, isAnchor: true)
      }
    }
  }

  // MARK: - Candidate list

  private var candidateList: some View {
    VStack(alignment: .leading, spacing: 10) {
      Text("…with")
        .font(.caption.weight(.semibold))
        .foregroundStyle(.secondary)
        .padding(.top, 4)

      if candidateTrips.isEmpty {
        GlassCard {
          HStack(spacing: 12) {
            Image(systemName: "calendar.badge.exclamationmark")
              .font(.title2)
              .foregroundStyle(.secondary)
            VStack(alignment: .leading, spacing: 4) {
              Text("No nearby trips")
                .font(.subheadline.weight(.semibold))
              Text("No confirmed trips found within 24 hours of this trip.")
                .font(.footnote)
                .foregroundStyle(.secondary)
            }
            Spacer(minLength: 0)
          }
        }
      } else {
        VStack(spacing: 8) {
          ForEach(candidateTrips, id: \.id) { trip in
            let isSelected = selectedTripID == trip.id
            Button {
              withAnimation(.spring(response: 0.25, dampingFraction: 0.7)) {
                selectedTripID = isSelected ? nil : trip.id
              }
              Haptics.impact(.light)
            } label: {
              GlassCard {
                HStack(spacing: 12) {
                  tripRow(trip, isAnchor: false)

                  Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.title3)
                    .foregroundStyle(isSelected ? Color.accentColor : Color.secondary.opacity(0.4))
                    .animation(.spring(response: 0.25, dampingFraction: 0.7), value: isSelected)
                }
              }
              .overlay {
                if isSelected {
                  RoundedRectangle(cornerRadius: DesignConstants.Radius.card, style: .continuous)
                    .strokeBorder(Color.accentColor, lineWidth: 2)
                }
              }
            }
            .buttonStyle(.plain)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("\(routeLabel(trip)), \(DistanceFormatter.format(trip.distanceMiles))")
            .accessibilityAddTraits(isSelected ? .isSelected : [])
            .accessibilityHint(isSelected ? "Tap to deselect" : "Tap to select for merging")
          }
        }
      }

      if let selectedID = selectedTripID,
         let selected = candidateTrips.first(where: { $0.id == selectedID }) {
        mergePreview(selected)
      }
    }
  }

  // MARK: - Merge preview

  private func mergePreview(_ other: Trip) -> some View {
    GlassCard {
      VStack(alignment: .leading, spacing: 8) {
        Text("Result")
          .font(.caption.weight(.semibold))
          .foregroundStyle(.secondary)

        let totalMiles = anchorTrip.distanceMiles + other.distanceMiles
        let sorted = [anchorTrip, other].sorted { $0.date < $1.date }
        let start = sorted.first!.startLabel
        let end = sorted.last!.endLabel

        HStack {
          VStack(alignment: .leading, spacing: 4) {
            Text(mergedRouteLabel(start: start, end: end))
              .font(.subheadline.weight(.semibold))
            Text(sorted.first!.date, format: .dateTime.month().day().year())
              .font(.footnote)
              .foregroundStyle(.secondary)
          }
          Spacer(minLength: 0)
          Text(DistanceFormatter.format(totalMiles))
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(Color.accentColor)
        }

        if categoriesDiffer(anchorTrip, other) {
          Label("Merged trip will need re-categorization", systemImage: "exclamationmark.triangle")
            .font(.caption)
            .foregroundStyle(.orange)
        }
      }
    }
  }

  // MARK: - Row helper

  @ViewBuilder
  private func tripRow(_ trip: Trip, isAnchor: Bool) -> some View {
    HStack(alignment: .top) {
      VStack(alignment: .leading, spacing: 4) {
        Text(routeLabel(trip))
          .font(.subheadline.weight(.semibold))
          .lineLimit(2)
          .minimumScaleFactor(0.85)

        HStack(spacing: 8) {
          Text(trip.date, format: .dateTime.month().day().hour().minute())
            .foregroundStyle(.secondary)
          if let category = trip.category {
            Text(category)
              .foregroundStyle(.secondary)
          }
        }
        .font(.footnote)
      }
      Spacer(minLength: 0)
      Text(DistanceFormatter.format(trip.distanceMiles))
        .font(.subheadline.weight(isAnchor ? .bold : .semibold))
        .foregroundStyle(isAnchor ? Color.accentColor : Color.primary)
    }
  }

  // MARK: - Helpers

  private func routeLabel(_ trip: Trip) -> String {
    let start = trip.startLabel?.trimmingCharacters(in: .whitespacesAndNewlines)
    let end = trip.endLabel?.trimmingCharacters(in: .whitespacesAndNewlines)
    if let s = start, !s.isEmpty, let e = end, !e.isEmpty { return "\(s) → \(e)" }
    if let s = start, !s.isEmpty { return s }
    if let e = end, !e.isEmpty { return e }
    return "Trip"
  }

  private func mergedRouteLabel(start: String?, end: String?) -> String {
    let s = start?.trimmingCharacters(in: .whitespacesAndNewlines)
    let e = end?.trimmingCharacters(in: .whitespacesAndNewlines)
    if let s, !s.isEmpty, let e, !e.isEmpty { return "\(s) → \(e)" }
    if let s, !s.isEmpty { return s }
    if let e, !e.isEmpty { return e }
    return "Merged Trip"
  }

  private func categoriesDiffer(_ a: Trip, _ b: Trip) -> Bool {
    let aCategory = a.category?.trimmingCharacters(in: .whitespacesAndNewlines)
    let bCategory = b.category?.trimmingCharacters(in: .whitespacesAndNewlines)
    return aCategory != bCategory
  }

  // MARK: - Action

  private func performMerge() {
    guard let selectedID = selectedTripID,
          let other = candidateTrips.first(where: { $0.id == selectedID }) else { return }
    Haptics.success()
    tripStore.merge(trips: [anchorTrip, other])
    dismiss()
  }
}

#Preview {
  let store = TripStore(trips: TripStore.makeMockTrips())
  let confirmed = store.confirmedTrips
  return MergeTripsSheet(anchorTrip: confirmed.first ?? Trip(
    date: Date(),
    distanceMiles: 5.2,
    durationSeconds: 18 * 60,
    startLabel: "Home",
    endLabel: "Office",
    source: .manual,
    state: .confirmed,
    category: "Business",
    clientOrOrg: nil,
    notes: nil
  ))
  .environmentObject(store)
}
