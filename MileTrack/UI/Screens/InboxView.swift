import SwiftUI

struct InboxView: View {
  @EnvironmentObject private var tripStore: TripStore
  @EnvironmentObject private var categoriesStore: CategoriesStore
  @EnvironmentObject private var clientStore: ClientsStore

  @State private var editingTrip: Trip?
  @State private var isPresentingReviewAll: Bool = false
  @State private var isSelecting: Bool = false
  @State private var selectedTripIDs: Set<UUID> = []
  @State private var isPresentingMergeConfirm: Bool = false
  @State private var selectedConfirmedTrip: Trip?

  @AppStorage("useMetricUnits") private var useMetricUnits = false

  // Swipe gesture state
  @State private var swipeOffsets: [UUID: CGFloat] = [:]
  @State private var noCategoryBounceIDs: Set<UUID> = []

  // Undo ignore toast
  @State private var ignoredTripForUndo: Trip?
  @State private var undoTask: Task<Void, Never>?

  private let swipeThreshold: CGFloat = 110
  private let screenWidth: CGFloat = 500 // Large enough for animations to appear off-screen

  var body: some View {
    ZStack(alignment: .bottom) {
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
              let offset = swipeOffsets[trip.id] ?? 0

              ZStack(alignment: .leading) {
                // Swipe hint backgrounds
                if !isSelecting {
                  swipeHintBackground(for: trip, offset: offset)
                }

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
                  .allowsHitTesting(!isSelecting && offset == 0)
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
                .offset(x: isSelecting ? 0 : offset)
              }
              .clipped()
              .contentShape(Rectangle())
              .gesture(isSelecting ? nil : swipeDragGesture(for: trip))
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
        
        recentConfirmedSection
      }
      .padding(.horizontal, 16)
      .padding(.vertical, 12)
    }
    .background(.background)

    // Undo toast
    if let trip = ignoredTripForUndo {
      undoToast(for: trip)
        .transition(.move(edge: .bottom).combined(with: .opacity))
        .zIndex(10)
    }
    } // ZStack
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
    .sheet(item: $selectedConfirmedTrip) { trip in
      EditTripSheet(tripID: trip.id)
        .environmentObject(tripStore)
        .environmentObject(categoriesStore)
        .environmentObject(clientStore)
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
  
  private var recentConfirmedSection: some View {
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
      .padding(.top, 8)

      if recentConfirmedTrips.isEmpty {
        GlassCard {
          HStack(spacing: 12) {
            Image(systemName: "checkmark.seal")
              .font(.title2)
              .foregroundStyle(.secondary)
              .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 4) {
              Text("No confirmed trips yet")
                .font(.subheadline.weight(.semibold))
              Text("Confirmed trips will appear here.")
                .font(.footnote)
                .foregroundStyle(.secondary)
            }
            Spacer(minLength: 0)
          }
        }
      } else {
        VStack(spacing: 10) {
          ForEach(recentConfirmedTrips, id: \.id) { trip in
            Button {
              selectedConfirmedTrip = trip
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
                    Text(DistanceFormatter.format(trip.distanceMiles))
                      .font(.subheadline.weight(.semibold))
                    if let seconds = trip.durationSeconds, seconds > 0 {
                      Text(durationFormatted(seconds))
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                    }
                  }
                }
              }
              .contentShape(Rectangle())
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
    Array(tripStore.confirmedTrips.prefix(5))
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
    let trip = tripStore.trips[idx]
    tripStore.trips[idx].state = .ignored
    swipeOffsets.removeValue(forKey: tripID)
    showUndoToast(for: trip)
  }

  private func showUndoToast(for trip: Trip) {
    undoTask?.cancel()
    withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
      ignoredTripForUndo = trip
    }
    undoTask = Task {
      try? await Task.sleep(for: .seconds(4))
      guard !Task.isCancelled else { return }
      await MainActor.run {
        withAnimation(.easeOut(duration: 0.25)) {
          ignoredTripForUndo = nil
        }
      }
    }
  }

  private func undoIgnore() {
    guard let trip = ignoredTripForUndo else { return }
    undoTask?.cancel()
    Haptics.impact(.light)
    guard let idx = tripStore.trips.firstIndex(where: { $0.id == trip.id }) else { return }
    tripStore.trips[idx].state = .pendingCategory
    withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
      ignoredTripForUndo = nil
    }
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

  // MARK: - Undo Toast

  @ViewBuilder
  private func undoToast(for trip: Trip) -> some View {
    HStack(spacing: 12) {
      Image(systemName: "xmark.circle.fill")
        .foregroundStyle(.secondary)
        .accessibilityHidden(true)

      VStack(alignment: .leading, spacing: 2) {
        Text("Ignored")
          .font(.caption.weight(.semibold))
          .foregroundStyle(.secondary)
        Text(routeLabel(trip))
          .font(.subheadline.weight(.semibold))
          .lineLimit(1)
      }

      Spacer(minLength: 0)

      Button("Undo") {
        undoIgnore()
      }
      .font(.subheadline.weight(.bold))
      .foregroundStyle(Color.accentColor)
      .buttonStyle(.plain)
      .accessibilityLabel("Undo ignore")
    }
    .padding(.horizontal, 16)
    .padding(.vertical, 14)
    .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
    .overlay {
      RoundedRectangle(cornerRadius: 18, style: .continuous)
        .strokeBorder(Color.primary.opacity(0.10), lineWidth: 1)
    }
    .shadow(color: .black.opacity(0.15), radius: 12, x: 0, y: 4)
    .padding(.horizontal, 16)
    .padding(.bottom, 12)
  }

  // MARK: - Swipe Gestures

  @ViewBuilder
  private func swipeHintBackground(for trip: Trip, offset: CGFloat) -> some View {
    let isConfirmSide = offset > 0
    let isIgnoreSide = offset < 0
    let progress = min(abs(offset) / swipeThreshold, 1.0)
    let hasCategory = !(trip.category?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ?? true)

    ZStack {
      // Confirm hint (right swipe → green)
      if isConfirmSide {
        RoundedRectangle(cornerRadius: DesignConstants.Radius.card, style: .continuous)
          .fill(hasCategory ? Color.green.opacity(0.15 + progress * 0.25) : Color.orange.opacity(0.15 + progress * 0.20))
        HStack {
          Image(systemName: hasCategory ? "checkmark.circle.fill" : "tag.fill")
            .font(.title2.weight(.semibold))
            .foregroundStyle(hasCategory ? .green : .orange)
            .scaleEffect(0.6 + progress * 0.5)
            .padding(.leading, 20)
          Spacer()
        }
      }

      // Ignore hint (left swipe → red)
      if isIgnoreSide {
        RoundedRectangle(cornerRadius: DesignConstants.Radius.card, style: .continuous)
          .fill(Color.red.opacity(0.15 + progress * 0.25))
        HStack {
          Spacer()
          Image(systemName: "xmark.circle.fill")
            .font(.title2.weight(.semibold))
            .foregroundStyle(.red)
            .scaleEffect(0.6 + progress * 0.5)
            .padding(.trailing, 20)
        }
      }
    }
  }

  private func swipeDragGesture(for trip: Trip) -> some Gesture {
    DragGesture(minimumDistance: 20, coordinateSpace: .local)
      .onChanged { value in
        // Only respond to primarily horizontal drags
        guard abs(value.translation.width) > abs(value.translation.height) * 1.2 else { return }
        let raw = value.translation.width
        // Apply rubber-band resistance beyond threshold
        let damped: CGFloat
        if abs(raw) > swipeThreshold {
          let excess = abs(raw) - swipeThreshold
          damped = (raw > 0 ? 1 : -1) * (swipeThreshold + excess * 0.25)
        } else {
          damped = raw
        }
        swipeOffsets[trip.id] = damped
      }
      .onEnded { value in
        let offset = swipeOffsets[trip.id] ?? 0
        let hasCategory = !(trip.category?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ?? true)

        if offset >= swipeThreshold {
          // Swipe right — confirm
          if hasCategory {
            withAnimation(.easeOut(duration: 0.22)) {
              swipeOffsets[trip.id] = screenWidth
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.22) {
              Haptics.success()
              confirm(tripID: trip.id)
              swipeOffsets.removeValue(forKey: trip.id)
            }
          } else {
            // No category — bounce back and signal error
            Haptics.error()
            withAnimation(.spring(response: 0.4, dampingFraction: 0.5)) {
              swipeOffsets[trip.id] = 0
            }
            // Open categorize sheet after bounce
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
              editingTrip = trip
            }
          }
        } else if offset <= -swipeThreshold {
          // Swipe left — ignore
          withAnimation(.easeOut(duration: 0.22)) {
            swipeOffsets[trip.id] = -screenWidth
          }
          DispatchQueue.main.asyncAfter(deadline: .now() + 0.22) {
            Haptics.warning()
            ignore(tripID: trip.id)
            swipeOffsets.removeValue(forKey: trip.id)
          }
        } else {
          // Below threshold — spring back
          withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) {
            swipeOffsets[trip.id] = 0
          }
        }
      }
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
  .environmentObject(ClientsStore())
  .environmentObject(RulesStore())
}

