import SwiftUI

struct InboxView: View {
  @EnvironmentObject private var tripStore: TripStore
  @EnvironmentObject private var categoriesStore: CategoriesStore
  @EnvironmentObject private var clientStore: ClientsStore

  @State private var editingTrip: Trip?
  @State private var isPresentingReviewAll: Bool = false
  @State private var isPresentingManualTrip: Bool = false
  @State private var selectedTripIDs: Set<UUID> = []
  @State private var selectedConfirmedTrip: Trip?

  @AppStorage("useMetricUnits") private var useMetricUnits = false

  // Swipe gesture state
  @State private var swipeOffsets: [UUID: CGFloat] = [:]

  // Undo ignore toast
  @State private var ignoredTripForUndo: Trip?
  @State private var undoTask: Task<Void, Never>?

  private let swipeThreshold: CGFloat = 110
  private var screenWidth: CGFloat { UIScreen.main.bounds.width }

  private var isInMergeMode: Bool { !selectedTripIDs.isEmpty }

  var body: some View {
    ZStack(alignment: .bottom) {
      ScrollView {
        VStack(alignment: .leading, spacing: 14) {
          header

          if tripStore.pendingTrips.isEmpty {
            EmptyStateView(
              systemImage: "tray",
              title: "Inbox is clear",
              subtitle: "Auto-detected trips appear here until you categorize and confirm them.",
              actionTitle: "Log a trip manually",
              action: { isPresentingManualTrip = true }
            )
          } else {
            let pending = tripStore.pendingTrips
            VStack(spacing: 12) {
              ForEach(Array(pending.enumerated()), id: \.element.id) { index, trip in
                let isSelected = selectedTripIDs.contains(trip.id)
                let offset = swipeOffsets[trip.id] ?? 0

                ZStack(alignment: .leading) {
                  // Swipe hint backgrounds (disabled during merge selection)
                  if !isInMergeMode {
                    swipeHintBackground(for: trip, offset: offset)
                  }

                  TripInboxCard(
                    trip: trip,
                    selectedCategory: trip.category,
                    onSelectCategory: { category in
                      setCategory(tripID: trip.id, category: category)
                    },
                    onEdit: {
                      editingTrip = trip
                    }
                  )
                  .allowsHitTesting(!isInMergeMode && offset == 0)
                  .opacity(!isInMergeMode || isSelected ? 1.0 : 0.55)
                  .overlay {
                    if isSelected {
                      RoundedRectangle(cornerRadius: DesignConstants.Radius.card, style: .continuous)
                        .strokeBorder(Color.accentColor, lineWidth: 2)
                    }
                  }
                  .animation(.easeInOut(duration: 0.18), value: isSelected)
                  .animation(.easeInOut(duration: 0.18), value: isInMergeMode)
                  .offset(x: isInMergeMode ? 0 : offset)
                }
                .clipped()
                .contentShape(Rectangle())
                .gesture(!isInMergeMode ? swipeDragGesture(for: trip) : nil)
                .onTapGesture {
                  guard isInMergeMode else { return }
                  withAnimation(.spring(response: 0.25, dampingFraction: 0.7)) {
                    if selectedTripIDs.contains(trip.id) {
                      selectedTripIDs.remove(trip.id)
                    } else {
                      selectedTripIDs.insert(trip.id)
                    }
                  }
                }

                // Join connector between adjacent pending trip cards (hidden while merge bar is showing)
                if index < pending.count - 1, !isInMergeMode {
                  JoinConnectorView {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                      selectedTripIDs = [trip.id, pending[index + 1].id]
                    }
                    Haptics.impact(.medium)
                  }
                }
              }
            }
          }

          recentConfirmedSection
        }
        .frame(maxWidth: DesignConstants.iPadMaxContentWidth)
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .frame(maxWidth: .infinity)
      }
      .background(.background)

      // Floating merge bar — slides up when trips are selected
      if isInMergeMode {
        mergeActionBar
          .transition(.move(edge: .bottom).combined(with: .opacity))
          .zIndex(15)
      }

      // Undo ignore toast (highest layer)
      if let trip = ignoredTripForUndo {
        undoToast(for: trip)
          .transition(.move(edge: .bottom).combined(with: .opacity))
          .zIndex(20)
      }
    } // ZStack
    .navigationTitle("Inbox")
    .toolbar {
      if !tripStore.pendingTrips.isEmpty {
        ToolbarItem(placement: .topBarTrailing) {
          Button("Review All") {
            isPresentingReviewAll = true
          }
          .accessibilityLabel("Review All")
          .accessibilityHint("Review pending trips one by one.")
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
    .sheet(isPresented: $isPresentingManualTrip) {
      ManualTripSheet()
    }
    .fullScreenCover(isPresented: $isPresentingReviewAll) {
      ReviewAllInboxSheet()
        .environmentObject(tripStore)
        .environmentObject(categoriesStore)
        .environmentObject(clientStore)
    }
    .onChange(of: tripStore.pendingTrips.count) { _, _ in
      let pendingIDs = Set(tripStore.pendingTrips.map(\.id))
      selectedTripIDs = selectedTripIDs.intersection(pendingIDs)
    }
  }

  // MARK: - Header

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

  // MARK: - Recent Confirmed

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
    trip.routeLabel
  }

  private func durationFormatted(_ seconds: Int) -> String {
    let minutes = max(0, seconds / 60)
    if minutes < 60 { return "\(minutes)m" }
    let hours = minutes / 60
    let rem = minutes % 60
    return rem == 0 ? "\(hours)h" : "\(hours)h \(rem)m"
  }

  // MARK: - Actions

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

  private func mergeSelectedTrips() {
    let selected = tripStore.pendingTrips.filter { selectedTripIDs.contains($0.id) }
    guard selected.count >= 2 else { return }
    tripStore.merge(trips: selected)
    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
      selectedTripIDs.removeAll()
    }
  }

  // MARK: - Merge Action Bar

  private var mergeActionBar: some View {
    HStack(spacing: 16) {
      Button {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
          selectedTripIDs.removeAll()
        }
      } label: {
        Image(systemName: "xmark.circle.fill")
          .font(.title3)
          .foregroundStyle(.secondary)
      }
      .buttonStyle(.plain)
      .accessibilityLabel("Cancel selection")

      Spacer()

      Text(selectedTripIDs.count == 1 ? "1 trip selected" : "\(selectedTripIDs.count) trips selected")
        .font(.subheadline)
        .foregroundStyle(.primary)
        .contentTransition(.numericText())
        .animation(.spring(response: 0.3), value: selectedTripIDs.count)

      Spacer()

      Button {
        Haptics.success()
        mergeSelectedTrips()
      } label: {
        Label("Merge", systemImage: "arrow.triangle.merge")
          .font(.subheadline.weight(.semibold))
          .padding(.horizontal, 16)
          .padding(.vertical, 9)
          .background(
            selectedTripIDs.count >= 2 ? Color.accentColor : Color.secondary.opacity(0.2),
            in: Capsule()
          )
          .foregroundStyle(selectedTripIDs.count >= 2 ? Color.white : Color.secondary)
          .animation(.easeInOut(duration: 0.18), value: selectedTripIDs.count >= 2)
      }
      .buttonStyle(.plain)
      .disabled(selectedTripIDs.count < 2)
      .accessibilityLabel("Merge selected trips")
      .accessibilityHint(
        selectedTripIDs.count < 2
          ? "Select at least 2 trips to merge"
          : "Merge \(selectedTripIDs.count) trips into one"
      )
    }
    .padding(.horizontal, 20)
    .padding(.vertical, 14)
    .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
    .overlay {
      RoundedRectangle(cornerRadius: 20, style: .continuous)
        .strokeBorder(Color.primary.opacity(0.10), lineWidth: 1)
    }
    .shadow(color: .black.opacity(0.12), radius: 16, x: 0, y: 6)
    .padding(.horizontal, 16)
    .padding(.bottom, 12)
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
        guard abs(value.translation.width) > abs(value.translation.height) * 1.2 else { return }
        let raw = value.translation.width
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
            Haptics.error()
            withAnimation(.spring(response: 0.4, dampingFraction: 0.5)) {
              swipeOffsets[trip.id] = 0
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
              editingTrip = trip
            }
          }
        } else if offset <= -swipeThreshold {
          withAnimation(.easeOut(duration: 0.22)) {
            swipeOffsets[trip.id] = -screenWidth
          }
          DispatchQueue.main.asyncAfter(deadline: .now() + 0.22) {
            Haptics.warning()
            ignore(tripID: trip.id)
            swipeOffsets.removeValue(forKey: trip.id)
          }
        } else {
          withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) {
            swipeOffsets[trip.id] = 0
          }
        }
      }
  }
}

// MARK: - Join Connector

private struct JoinConnectorView: View {
  let action: () -> Void

  var body: some View {
    HStack(spacing: 6) {
      dashedLine
      Button(action: action) {
        HStack(spacing: 4) {
          Image(systemName: "arrow.triangle.merge")
            .font(.caption2)
          Text("Join")
            .font(.caption.weight(.medium))
        }
        .foregroundStyle(.secondary)
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .background(.regularMaterial, in: Capsule())
        .overlay(Capsule().strokeBorder(Color.primary.opacity(0.10), lineWidth: 1))
      }
      .buttonStyle(.plain)
      dashedLine
    }
    .padding(.horizontal, 20)
    .padding(.vertical, 2)
  }

  private var dashedLine: some View {
    GeometryReader { geo in
      Path { p in
        p.move(to: CGPoint(x: 0, y: 0.5))
        p.addLine(to: CGPoint(x: geo.size.width, y: 0.5))
      }
      .stroke(style: StrokeStyle(lineWidth: 1, dash: [4, 4]))
      .foregroundStyle(Color.primary.opacity(0.18))
    }
    .frame(height: 1)
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
