import SwiftUI

struct CategorizeTripSheet: View {
  @Environment(\.dismiss) private var dismiss
  @EnvironmentObject private var tripStore: TripStore
  @EnvironmentObject private var categoriesStore: CategoriesStore
  @EnvironmentObject private var clientStore: ClientStore

  let tripID: UUID

  @State private var selectedCategory: String?
  @State private var isPresentingAddCategory: Bool = false
  @State private var newCategoryName: String = ""
  @State private var addCategoryError: String?

  @State private var selectedClient: String?
  @State private var isPresentingAddClient: Bool = false
  @State private var newClientName: String = ""
  @State private var addClientError: String?

  @State private var projectCodeText: String = ""
  @State private var notes: String = ""
  @State private var isRoundTrip: Bool = false

  var body: some View {
    NavigationStack {
      ScrollView {
        VStack(alignment: .leading, spacing: 14) {
          headerCard
          categoryCard
          optionalDetailsCard
          actionsCard
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
      }
      .background(.background)
      .navigationTitle("Categorize")
      .navigationBarTitleDisplayMode(.inline)
      .toolbar {
        ToolbarItem(placement: .cancellationAction) {
          Button("Cancel") { dismiss() }
        }
      }
    }
    .onAppear {
      hydrateFromTrip()
    }
    .presentationBackground(.ultraThinMaterial)
    .alert("Add New Category", isPresented: $isPresentingAddCategory) {
      TextField("Category name", text: $newCategoryName)
      Button("Add") { addCategory() }
      Button("Cancel", role: .cancel) {}
    } message: {
      Text("Names can’t be empty or duplicates.")
    }
    .alert("Add New Client", isPresented: $isPresentingAddClient) {
      TextField("Client name", text: $newClientName)
      Button("Add") { addClient() }
      Button("Cancel", role: .cancel) {}
    } message: {
      Text("Names can’t be empty or duplicates.")
    }
  }

  private var tripIndex: Int? {
    tripStore.trips.firstIndex(where: { $0.id == tripID })
  }

  private var trip: Trip? {
    guard let idx = tripIndex else { return nil }
    return tripStore.trips[idx]
  }

  private var headerCard: some View {
    GlassCard {
      VStack(alignment: .leading, spacing: 10) {
        Text("Review")
          .font(.headline)

        if let trip {
          HStack(alignment: .firstTextBaseline) {
            Text(routeLabel(trip))
              .font(.subheadline.weight(.semibold))
              .lineLimit(1)
            Spacer(minLength: 0)
            Text(distanceLabel(trip))
              .font(.subheadline.weight(.semibold))
          }

          HStack(spacing: 10) {
            Text(trip.date, format: .dateTime.month().day().hour().minute())
              .foregroundStyle(.secondary)
            if let seconds = trip.durationSeconds, seconds > 0 {
              Text(durationLabel(seconds))
                .foregroundStyle(.secondary)
            }
          }
          .font(.footnote)
        } else {
          Text("This trip is no longer available.")
            .foregroundStyle(.secondary)
            .font(.footnote)
        }

        Text("Auto-detected trips are not counted until categorized and confirmed.")
          .font(.footnote)
          .foregroundStyle(.secondary)
      }
    }
    .accessibilityElement(children: .contain)
  }

  private var categoryCard: some View {
    GlassCard {
      VStack(alignment: .leading, spacing: 12) {
        Text("Category (required)")
          .font(.headline)

        Picker("Category", selection: $selectedCategory) {
          Text("Select category").tag(String?.none)
          ForEach(categoriesStore.categories, id: \.self) { category in
            Text(category).tag(String?.some(category))
          }
          Text("+ Add New Category…").tag(String?.some(Self.addNewSentinel))
        }
        .pickerStyle(.menu)
        .accessibilityLabel("Category")
        .onChange(of: selectedCategory) { _, newValue in
          if newValue == Self.addNewSentinel {
            selectedCategory = nil
            newCategoryName = ""
            addCategoryError = nil
            isPresentingAddCategory = true
          }
        }

        if let addCategoryError {
          Text(addCategoryError)
            .font(.footnote)
            .foregroundStyle(.red)
        }
      }
    }
  }

  private var optionalDetailsCard: some View {
    GlassCard {
      VStack(alignment: .leading, spacing: 12) {
        Text("Optional")
          .font(.headline)

        Picker("Client / Organization (optional)", selection: $selectedClient) {
          Text("No client").tag(String?.none)
          ForEach(clientStore.clients, id: \.self) { client in
            Text(client).tag(String?.some(client))
          }
          Text("+ Add New Client…").tag(String?.some(Self.addNewClientSentinel))
        }
        .pickerStyle(.menu)
        .accessibilityLabel("Client or organization")
        .onChange(of: selectedClient) { _, newValue in
          if newValue == Self.addNewClientSentinel {
            selectedClient = nil
            newClientName = ""
            addClientError = nil
            isPresentingAddClient = true
          }
        }

        if let addClientError {
          Text(addClientError)
            .font(.footnote)
            .foregroundStyle(.red)
        }

        TextField("Project / Job code (optional)", text: $projectCodeText)
          .textInputAutocapitalization(.characters)
          .padding(.horizontal, 12)
          .padding(.vertical, 10)
          .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
          .overlay {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
              .strokeBorder(Color.primary.opacity(0.10), lineWidth: 1)
          }
          .accessibilityLabel("Project code")

        TextField("Notes (optional)", text: $notes, axis: .vertical)
          .lineLimit(2...5)
          .padding(.horizontal, 12)
          .padding(.vertical, 10)
          .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
          .overlay {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
              .strokeBorder(Color.primary.opacity(0.10), lineWidth: 1)
          }
          .accessibilityLabel("Notes")

        Toggle(isOn: $isRoundTrip) {
          Text("Round trip")
            .font(.subheadline.weight(.semibold))
        }
        .tint(.accentColor)
        .accessibilityLabel("Round trip")
        .accessibilityHint("Optional; not yet stored.")

        Text("Round trip is a UI-only toggle for now (not stored).")
          .font(.footnote)
          .foregroundStyle(.secondary)
          .accessibilityHidden(true)
      }
    }
  }

  private var actionsCard: some View {
    GlassCard {
      VStack(alignment: .leading, spacing: 10) {
        Text("Actions")
          .font(.headline)

        PrimaryGlassButton(title: "Confirm", systemImage: "checkmark", isEnabled: canConfirm) {
          Haptics.success()
          confirm()
        }
        .accessibilityHint(canConfirm ? "Confirms this trip." : "Select a category to confirm.")

        Button(role: .destructive) {
          Haptics.warning()
          ignore()
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
        .accessibilityHint("Ignores this auto-detected item.")
      }
    }
  }

  private var canConfirm: Bool {
    resolvedCategory != nil && tripIndex != nil
  }

  private static let addNewSentinel = "__ADD_NEW_CATEGORY__"
  private static let addNewClientSentinel = "__ADD_NEW_CLIENT__"

  private var resolvedCategory: String? {
    let base = selectedCategory?.trimmingCharacters(in: .whitespacesAndNewlines)
    guard let base, !base.isEmpty else { return nil }
    return base
  }

  private var normalizedSelectedCategory: String? {
    selectedCategory?.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
  }

  private func hydrateFromTrip() {
    guard let trip else { return }
    let existing = trip.category?.trimmingCharacters(in: .whitespacesAndNewlines)
    if let existing, !existing.isEmpty {
      // Keep existing category even if not currently in the list.
      selectedCategory = existing
    } else {
      selectedCategory = nil
    }

    selectedClient = trip.clientOrOrg
    projectCodeText = trip.projectCode ?? ""
    notes = trip.notes ?? ""
    isRoundTrip = false
  }

  private func confirm() {
    guard let idx = tripIndex else { return }
    guard let category = resolvedCategory else { return }

    let trimmedProject = projectCodeText.trimmingCharacters(in: .whitespacesAndNewlines)
    let trimmedNotes = notes.trimmingCharacters(in: .whitespacesAndNewlines)

    tripStore.trips[idx].category = category
    tripStore.trips[idx].clientOrOrg = selectedClient
    tripStore.trips[idx].projectCode = trimmedProject.isEmpty ? nil : trimmedProject
    tripStore.trips[idx].notes = trimmedNotes.isEmpty ? nil : trimmedNotes
    tripStore.trips[idx].state = .confirmed

    dismiss()
  }

  private func ignore() {
    guard let idx = tripIndex else { return }
    tripStore.trips[idx].state = .ignored
    dismiss()
  }

  private func addCategory() {
    let trimmed = newCategoryName.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !trimmed.isEmpty else {
      addCategoryError = "Please enter a category name."
      return
    }

    if categoriesStore.add(trimmed) {
      selectedCategory = trimmed
      addCategoryError = nil
    } else {
      addCategoryError = "That category already exists."
    }
  }

  private func addClient() {
    let trimmed = newClientName.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !trimmed.isEmpty else {
      addClientError = "Please enter a client name."
      return
    }

    if clientStore.add(trimmed) {
      selectedClient = trimmed
      addClientError = nil
    } else {
      addClientError = "That client already exists."
    }
  }

  private func routeLabel(_ trip: Trip) -> String {
    let start = trip.startLabel?.trimmingCharacters(in: .whitespacesAndNewlines)
    let end = trip.endLabel?.trimmingCharacters(in: .whitespacesAndNewlines)
    if let start, !start.isEmpty, let end, !end.isEmpty { return "\(start) → \(end)" }
    if let start, !start.isEmpty { return start }
    if let end, !end.isEmpty { return end }
    return "Trip"
  }

  private func distanceLabel(_ trip: Trip) -> String {
    let number = trip.distanceMiles.formatted(.number.precision(.fractionLength(0...1)))
    return "\(number) mi"
  }

  private func durationLabel(_ seconds: Int) -> String {
    let minutes = max(0, seconds / 60)
    if minutes < 60 { return "\(minutes)m" }
    let hours = minutes / 60
    let rem = minutes % 60
    return rem == 0 ? "\(hours)h" : "\(hours)h \(rem)m"
  }
}

#Preview {
  let store = TripStore()
  return CategorizeTripSheet(tripID: store.pendingTrips.first?.id ?? store.trips.first!.id)
    .environmentObject(store)
    .environmentObject(CategoriesStore())
    .environmentObject(ClientStore())
}

