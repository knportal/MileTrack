import SwiftUI

struct ReviewAllInboxSheet: View {
  @Environment(\.dismiss) private var dismiss
  @EnvironmentObject private var tripStore: TripStore
  @EnvironmentObject private var categoriesStore: CategoriesStore
  @EnvironmentObject private var clientStore: ClientsStore

  @State private var pageIndex: Int = 0

  var body: some View {
    NavigationStack {
      ZStack {
        Color.clear
          .background(.ultraThinMaterial)
          .ignoresSafeArea()

        if pendingTrips.isEmpty {
          completionView
        } else {
          VStack(spacing: 12) {
            progressHeader
              .padding(.horizontal, 16)
              .padding(.top, 6)

            TabView(selection: $pageIndex) {
              ForEach(Array(pendingTrips.enumerated()), id: \.element.id) { idx, trip in
                ReviewPage(
                  trip: trip,
                  categories: categoriesStore.categories,
                  clients: clientStore.clients,
                  onConfirm: { category, client in
                    confirm(tripID: trip.id, category: category, client: client)
                    advance(from: idx)
                  },
                  onIgnore: {
                    ignore(tripID: trip.id)
                    advance(from: idx)
                  }
                )
                .tag(idx)
                .padding(.horizontal, 16)
                .padding(.bottom, 16)
              }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
          }
        }
      }
      .navigationTitle("Review All")
      .navigationBarTitleDisplayMode(.inline)
      .toolbar {
        ToolbarItem(placement: .topBarTrailing) {
          Button {
            dismiss()
          } label: {
            Image(systemName: "xmark")
              .font(.headline.weight(.semibold))
              .padding(10)
              .background(.thinMaterial, in: Circle())
              .overlay {
                Circle().strokeBorder(Color.primary.opacity(0.10), lineWidth: 1)
              }
          }
          .buttonStyle(.plain)
          .accessibilityLabel("Close")
        }
      }
      .onChange(of: pendingTrips.count) { _, newCount in
        if newCount == 0 {
          // Auto-dismiss shortly after completion view appears.
          DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
            dismiss()
          }
        } else {
          pageIndex = min(pageIndex, max(0, newCount - 1))
        }
      }
    }
  }

  private var pendingTrips: [Trip] {
    tripStore.pendingTrips
  }

  private var progressHeader: some View {
    GlassCard {
      HStack {
        Text(progressText)
          .font(.subheadline.weight(.semibold))
        Spacer(minLength: 0)
        Text("Pending")
          .font(.footnote.weight(.semibold))
          .foregroundStyle(.secondary)
      }
      .accessibilityElement(children: .ignore)
      .accessibilityLabel("Progress")
      .accessibilityValue(progressText)
    }
  }

  private var progressText: String {
    let total = pendingTrips.count
    let current = min(max(pageIndex + 1, 1), max(total, 1))
    return "\(current) of \(total)"
  }

  private var completionView: some View {
    VStack(spacing: 16) {
      GlassCard(cornerRadius: 24) {
        VStack(spacing: 10) {
          Image(systemName: "checkmark.seal")
            .font(.system(size: 34, weight: .semibold))
            .foregroundStyle(.secondary)
            .accessibilityHidden(true)
          Text("All caught up")
            .font(.headline)
          Text("No remaining pending trips.")
            .font(.subheadline)
            .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
      }
      .padding(.horizontal, 16)
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .accessibilityElement(children: .contain)
  }

  private func advance(from previousIndex: Int) {
    let newCount = pendingTrips.count
    if newCount == 0 { return }
    pageIndex = min(previousIndex, newCount - 1)
  }

  private func confirm(tripID: UUID, category: String, client: String?) {
    guard let idx = tripStore.trips.firstIndex(where: { $0.id == tripID }) else { return }
    let trimmedCategory = category.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !trimmedCategory.isEmpty else { return }

    tripStore.trips[idx].category = trimmedCategory
    let trimmedClient = client?.trimmingCharacters(in: .whitespacesAndNewlines)
    tripStore.trips[idx].clientOrOrg = (trimmedClient?.isEmpty ?? true) ? nil : trimmedClient
    tripStore.trips[idx].state = .confirmed
  }

  private func ignore(tripID: UUID) {
    guard let idx = tripStore.trips.firstIndex(where: { $0.id == tripID }) else { return }
    tripStore.trips[idx].state = .ignored
  }
}

private struct ReviewPage: View {
  let trip: Trip
  let categories: [String]
  let clients: [String]
  let onConfirm: (_ category: String, _ client: String?) -> Void
  let onIgnore: () -> Void

  @State private var selectedCategory: String?
  @State private var selectedClient: String?

  var body: some View {
    VStack(spacing: 12) {
      GlassCard {
        VStack(alignment: .leading, spacing: 10) {
          Text(routeLabel(trip))
            .font(.headline)
            .lineLimit(1)

          HStack {
            Text(trip.date, format: .dateTime.month().day().hour().minute())
              .foregroundStyle(.secondary)
              .font(.footnote)
            Spacer()
            Text(milesLabel(trip.distanceMiles))
              .font(.subheadline.weight(.semibold))
          }
        }
      }

      GlassCard {
        VStack(alignment: .leading, spacing: 12) {
          Text("Category (required)")
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(.secondary)

          Picker("Category", selection: $selectedCategory) {
            Text("Select category").tag(String?.none)
            ForEach(categories, id: \.self) { category in
              Text(category).tag(String?.some(category))
            }
          }
          .pickerStyle(.menu)
          .accessibilityLabel("Category")

          Picker("Client / Organization (optional)", selection: $selectedClient) {
            Text("No client").tag(String?.none)
            ForEach(clients, id: \.self) { client in
              Text(client).tag(String?.some(client))
            }
          }
          .pickerStyle(.menu)
          .accessibilityLabel("Client or organization")
        }
      }

      VStack(spacing: 10) {
        PrimaryGlassButton(title: "Confirm", systemImage: "checkmark", isEnabled: canConfirm) {
          if let selectedCategory {
            onConfirm(selectedCategory, selectedClient)
          }
        }
        .accessibilityHint(canConfirm ? "Confirms this trip." : "Select a category to confirm.")

        Button(role: .destructive) {
          onIgnore()
        } label: {
          HStack {
            Image(systemName: "xmark.circle")
              .accessibilityHidden(true)
          Text("Not a trip")
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
        .accessibilityLabel("Not a trip")
      }

      Spacer(minLength: 0)
    }
    .onAppear {
      selectedCategory = (trip.category?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ?? true) ? nil : trip.category
      selectedClient = trip.clientOrOrg
    }
  }

  private var canConfirm: Bool {
    guard let selectedCategory else { return false }
    return !selectedCategory.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
  }

  private func routeLabel(_ trip: Trip) -> String {
    let start = trip.startLabel?.trimmingCharacters(in: .whitespacesAndNewlines)
    let end = trip.endLabel?.trimmingCharacters(in: .whitespacesAndNewlines)
    if let start, !start.isEmpty, let end, !end.isEmpty { return "\(start) → \(end)" }
    if let start, !start.isEmpty { return start }
    if let end, !end.isEmpty { return end }
    return "Trip"
  }

  private func milesLabel(_ miles: Double) -> String {
    let number = miles.formatted(.number.precision(.fractionLength(0...1)))
    return "\(number) mi"
  }
}

#Preview {
  let store = TripStore(trips: {
    var trips = TripStore.makeMockTrips()
    // Ensure we have multiple pending trips for paging.
    trips.insert(
      Trip(
        date: Date().addingTimeInterval(-2 * 60 * 60),
        distanceMiles: 7.4,
        durationSeconds: 20 * 60,
        startLabel: "Trip start",
        endLabel: "Trip end",
        source: .auto,
        state: .pendingCategory,
        category: nil,
        clientOrOrg: nil,
        projectCode: nil,
        notes: nil
      ),
      at: 0
    )
    return trips
  }())

  return ReviewAllInboxSheet()
    .environmentObject(store)
    .environmentObject(CategoriesStore())
    .environmentObject(ClientsStore())
}

