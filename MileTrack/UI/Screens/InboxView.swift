import SwiftUI

struct InboxView: View {
  @EnvironmentObject private var tripStore: TripStore
  @EnvironmentObject private var categoriesStore: CategoriesStore
  @EnvironmentObject private var clientStore: ClientStore

  @State private var editingTrip: Trip?
  @State private var isPresentingReviewAll: Bool = false
  @State private var isSelecting: Bool = false
  @State private var selectedTripIDs: Set<UUID> = []
  @State private var isPresentingMergeConfirm: Bool = false

  var body: some View {
    ScrollView {
      VStack(alignment: .leading, spacing: 14) {
        header

        if tripStore.pendingTrips.isEmpty {
          EmptyStateView(
            systemImage: "tray",
            title: "Inbox is clear",
            subtitle: "Auto-detected trips appear here until you categorize and confirm them."
          )
        } else {
          VStack(spacing: 12) {
            ForEach(tripStore.pendingTrips, id: \.id) { trip in
              let isSelected = selectedTripIDs.contains(trip.id)
              ZStack {
                TripInboxCard(
                  trip: trip,
                  selectedCategory: trip.category,
                  onSelectCategory: { category in
                    setCategory(tripID: trip.id, category: category)
                  },
                  onConfirm: {
                    Haptics.success()
                    confirm(tripID: trip.id)
                    selectedTripIDs.remove(trip.id)
                  },
                  onIgnore: {
                    Haptics.warning()
                    ignore(tripID: trip.id)
                    selectedTripIDs.remove(trip.id)
                  },
                  onEdit: {
                    editingTrip = trip
                  }
                )
                .allowsHitTesting(!isSelecting)
                .opacity(isSelecting && !isSelected ? 0.70 : 1.0)
                .overlay {
                  if isSelecting {
                    RoundedRectangle(cornerRadius: DesignConstants.Radius.card, style: .continuous)
                      .strokeBorder(
                        (isSelected ? Color.accentColor : Color.primary.opacity(0.08)),
                        lineWidth: isSelected ? 2 : 1
                      )
                  }
                }

                if isSelecting {
                  selectIndicator(for: trip.id)
                    .padding(10)
                }
              }
              .contentShape(Rectangle())
              .onTapGesture {
                guard isSelecting else { return }
                if selectedTripIDs.contains(trip.id) {
                  selectedTripIDs.remove(trip.id)
                } else {
                  selectedTripIDs.insert(trip.id)
                }
              }
            }
          }
        }
      }
      .padding(.horizontal, 16)
      .padding(.vertical, 12)
    }
    .background(.background)
    .navigationTitle("Inbox")
    .toolbar {
      if !tripStore.pendingTrips.isEmpty {
        ToolbarItem(placement: .topBarLeading) {
          if isSelecting {
            Button("Cancel") {
              isSelecting = false
              selectedTripIDs.removeAll()
            }
            .accessibilityLabel("Cancel selection")
          } else {
            Button("Select") {
              isSelecting = true
              selectedTripIDs.removeAll()
            }
            .accessibilityLabel("Select")
          }
        }

        ToolbarItem(placement: .topBarTrailing) {
          if isSelecting {
            Button("Merge") {
              isPresentingMergeConfirm = true
            }
            .disabled(selectedTripIDs.count < 2)
            .accessibilityLabel("Merge")
            .accessibilityHint(selectedTripIDs.count < 2 ? "Select at least two trips to merge." : "Merge selected trips into one.")
          } else {
            Button("Review All") {
              isPresentingReviewAll = true
            }
            .accessibilityLabel("Review All")
            .accessibilityHint("Review pending trips one by one.")
          }
        }
      }
    }
    .sheet(item: $editingTrip) { trip in
      CategorizeTripSheet(tripID: trip.id)
        .environmentObject(tripStore)
    }
    .fullScreenCover(isPresented: $isPresentingReviewAll) {
      ReviewAllInboxSheet()
        .environmentObject(tripStore)
        .environmentObject(categoriesStore)
        .environmentObject(clientStore)
    }
    .alert("Merge trips?", isPresented: $isPresentingMergeConfirm) {
      Button("Cancel", role: .cancel) {}
      Button("Merge", role: .destructive) {
        Haptics.success()
        mergeSelectedTrips()
      }
    } message: {
      Text("Merge \(selectedTripIDs.count) trips into one pending trip?")
    }
    .onChange(of: tripStore.pendingTrips.count) { _, _ in
      // If trips change (confirm/ignore), remove any IDs that are no longer pending.
      let pendingIDs = Set(tripStore.pendingTrips.map(\.id))
      selectedTripIDs = selectedTripIDs.intersection(pendingIDs)
      if tripStore.pendingTrips.isEmpty {
        isSelecting = false
        selectedTripIDs.removeAll()
      }
    }
  }

  private var header: some View {
    GlassCard {
      HStack(alignment: .top, spacing: 12) {
        VStack(alignment: .leading, spacing: 6) {
          Text("Review & Confirm")
            .font(.headline)
          Text("Pending trips are not counted until categorized and confirmed.")
            .font(.footnote)
            .foregroundStyle(.secondary)
        }
        Spacer(minLength: 0)
        Text("\(tripStore.pendingTrips.count)")
          .font(.subheadline.weight(.bold))
          .padding(.horizontal, 10)
          .padding(.vertical, 7)
          .background(.thinMaterial, in: Capsule())
          .overlay {
            Capsule()
              .strokeBorder(Color.primary.opacity(0.10), lineWidth: 1)
          }
          .accessibilityLabel("Pending trips")
          .accessibilityValue("\(tripStore.pendingTrips.count)")
      }
    }
  }

  private func setCategory(tripID: UUID, category: String?) {
    guard let idx = tripStore.trips.firstIndex(where: { $0.id == tripID }) else { return }
    let trimmed = category?.trimmingCharacters(in: .whitespacesAndNewlines)
    tripStore.trips[idx].category = (trimmed?.isEmpty ?? true) ? nil : trimmed
  }

  private func confirm(tripID: UUID) {
    guard let idx = tripStore.trips.firstIndex(where: { $0.id == tripID }) else { return }
    let category = tripStore.trips[idx].category?.trimmingCharacters(in: .whitespacesAndNewlines)
    guard let category, !category.isEmpty else { return }
    tripStore.trips[idx].category = category
    tripStore.trips[idx].state = .confirmed
  }

  private func ignore(tripID: UUID) {
    guard let idx = tripStore.trips.firstIndex(where: { $0.id == tripID }) else { return }
    tripStore.trips[idx].state = .ignored
  }

  @ViewBuilder
  private func selectIndicator(for tripID: UUID) -> some View {
    let isSelected = selectedTripIDs.contains(tripID)
    Button {
      if isSelected {
        selectedTripIDs.remove(tripID)
      } else {
        selectedTripIDs.insert(tripID)
      }
    } label: {
      Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
        .font(.title3)
        .foregroundStyle(isSelected ? Color.accentColor : Color.secondary)
        .background(.thinMaterial, in: Circle())
        .overlay {
          Circle().strokeBorder(Color.primary.opacity(0.10), lineWidth: 1)
        }
    }
    .buttonStyle(.plain)
    .accessibilityLabel(isSelected ? "Deselect trip" : "Select trip")
  }

  private func mergeSelectedTrips() {
    let pending = tripStore.pendingTrips
    let selected = pending.filter { selectedTripIDs.contains($0.id) }
    guard selected.count >= 2 else { return }

    // Choose earliest for start, latest for end.
    let sorted = selected.sorted { $0.date < $1.date }
    let earliest = sorted.first!
    let latest = sorted.last!

    let totalMiles = selected.reduce(0.0) { $0 + $1.distanceMiles }

    func commonValue(_ values: [String?]) -> String? {
      let trimmed = values.map { $0?.trimmingCharacters(in: .whitespacesAndNewlines) }.map { ($0?.isEmpty ?? true) ? nil : $0 }
      let first = trimmed.first ?? nil
      guard let first else { return nil }
      if trimmed.allSatisfy({ ($0 ?? "").caseInsensitiveCompare(first) == .orderedSame }) {
        return first
      }
      return nil
    }

    let category = commonValue(selected.map(\.category))
    let client = commonValue(selected.map(\.clientOrOrg))
    let project = commonValue(selected.map(\.projectCode))

    let notesParts = selected
      .compactMap { $0.notes?.trimmingCharacters(in: .whitespacesAndNewlines) }
      .filter { !$0.isEmpty }
    let notes = notesParts.isEmpty ? nil : notesParts.joined(separator: " | ")

    let mergedTrip = Trip(
      date: earliest.date,
      distanceMiles: totalMiles,
      durationSeconds: nil,
      startLabel: earliest.startLabel,
      endLabel: latest.endLabel,
      source: .auto,
      state: .pendingCategory,
      category: category,
      clientOrOrg: client,
      projectCode: project,
      suggestedByRuleName: nil,
      notes: notes
    )

    // Mark original trips ignored to preserve audit trail.
    let selectedIDs = Set(selected.map(\.id))
    for idx in tripStore.trips.indices {
      if selectedIDs.contains(tripStore.trips[idx].id) {
        tripStore.trips[idx].state = .ignored
      }
    }

    tripStore.trips.insert(mergedTrip, at: 0)
    selectedTripIDs.removeAll()
    isSelecting = false
  }
}

#Preview {
  NavigationStack {
    InboxView()
  }
  .environmentObject(TripStore())
  .environmentObject(CategoriesStore())
  .environmentObject(ClientStore())
  .environmentObject(RulesStore())
}

