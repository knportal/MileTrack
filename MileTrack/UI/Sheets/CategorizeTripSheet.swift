import SwiftUI

struct CategorizeTripSheet: View {
  @Environment(\.dismiss) private var dismiss
  @EnvironmentObject private var tripStore: TripStore
  @EnvironmentObject private var categoriesStore: CategoriesStore
  @EnvironmentObject private var clientStore: ClientsStore
  @EnvironmentObject private var vehiclesStore: VehiclesStore

  let tripID: UUID

  @State private var selectedCategory: String?
  @State private var isPresentingAddCategory: Bool = false
  @State private var newCategoryName: String = ""
  @State private var addCategoryError: String?

  @State private var selectedClient: String?
  @State private var isPresentingAddClient: Bool = false
  @State private var newClientName: String = ""
  @State private var addClientError: String?

  @State private var purposeText: String = ""
  @State private var selectedVehicleID: UUID?
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
        ToolbarItem(placement: .confirmationAction) {
          Button("Save") {
            Haptics.success()
            confirm()
          }
          .disabled(!canConfirm)
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

        Menu {
          Button {
            selectedCategory = nil
          } label: {
            if selectedCategory == nil {
              Label("Select category", systemImage: "checkmark")
            } else {
              Text("Select category")
            }
          }
          
          Divider()
          
          ForEach(categoriesStore.categories, id: \.self) { category in
            Button {
              selectedCategory = category
            } label: {
              if selectedCategory == category {
                Label(category, systemImage: "checkmark")
              } else {
                Text(category)
              }
            }
          }
          
          Divider()
          
          Button {
            newCategoryName = ""
            addCategoryError = nil
            isPresentingAddCategory = true
          } label: {
            Label("Add New Category…", systemImage: "plus")
          }
        } label: {
          HStack {
            Text(selectedCategory ?? "Select category")
              .foregroundStyle(selectedCategory != nil ? .primary : .secondary)
            Spacer()
            Image(systemName: "chevron.up.chevron.down")
              .font(.caption)
              .foregroundStyle(.secondary)
          }
          .padding(.horizontal, 14)
          .padding(.vertical, 12)
          .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
          .overlay {
            RoundedRectangle(cornerRadius: 12, style: .continuous)
              .strokeBorder(Color.primary.opacity(0.08), lineWidth: 1)
          }
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Category")
        .accessibilityValue(selectedCategory ?? "Not selected")

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

        VStack(alignment: .leading, spacing: 8) {
          Text("Business Purpose")
            .font(.caption)
            .foregroundStyle(.secondary)

          ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
              ForEach(["Client meeting", "Site visit", "Delivery", "Medical appt", "Property visit", "Training"], id: \.self) { suggestion in
                Button {
                  purposeText = purposeText == suggestion ? "" : suggestion
                } label: {
                  Text(suggestion)
                    .font(.caption.weight(.semibold))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(purposeText == suggestion ? Color.accentColor.opacity(0.18) : Color(.secondarySystemGroupedBackground), in: Capsule())
                    .overlay {
                      Capsule()
                        .strokeBorder(purposeText == suggestion ? Color.accentColor.opacity(0.5) : Color.primary.opacity(0.08), lineWidth: 1)
                    }
                    .foregroundStyle(purposeText == suggestion ? Color.accentColor : Color.primary)
                }
                .buttonStyle(.plain)
              }
            }
            .padding(.horizontal, 1)
          }

          TextField("Describe the business purpose…", text: $purposeText)
            .textInputAutocapitalization(.sentences)
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
            .overlay {
              RoundedRectangle(cornerRadius: 14, style: .continuous)
                .strokeBorder(Color.primary.opacity(0.10), lineWidth: 1)
            }
            .accessibilityLabel("Business purpose")
        }

        VStack(alignment: .leading, spacing: 8) {
          Text("Vehicle")
            .font(.caption)
            .foregroundStyle(.secondary)

          if vehiclesStore.vehicles.isEmpty {
            Text("No vehicles saved — add one in Settings → Vehicles.")
              .font(.footnote)
              .foregroundStyle(.secondary)
          } else {
            Menu {
              Button {
                selectedVehicleID = nil
              } label: {
                if selectedVehicleID == nil {
                  Label("No vehicle", systemImage: "checkmark")
                } else {
                  Text("No vehicle")
                }
              }

              Divider()

              ForEach(vehiclesStore.vehicles) { vehicle in
                Button {
                  selectedVehicleID = vehicle.id
                } label: {
                  if selectedVehicleID == vehicle.id {
                    Label(vehicle.name, systemImage: "checkmark")
                  } else {
                    Text(vehicle.name)
                  }
                }
              }
            } label: {
              HStack {
                Text(selectedVehicleName)
                  .foregroundStyle(selectedVehicleID != nil ? .primary : .secondary)
                Spacer()
                Image(systemName: "chevron.up.chevron.down")
                  .font(.caption)
                  .foregroundStyle(.secondary)
              }
              .padding(.horizontal, 14)
              .padding(.vertical, 12)
              .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
              .overlay {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                  .strokeBorder(Color.primary.opacity(0.08), lineWidth: 1)
              }
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Vehicle")
            .accessibilityValue(selectedVehicleName)
          }
        }

        VStack(alignment: .leading, spacing: 8) {
          Text("Client / Organization")
            .font(.caption)
            .foregroundStyle(.secondary)

          Menu {
            Button {
              selectedClient = nil
            } label: {
              if selectedClient == nil {
                Label("No client", systemImage: "checkmark")
              } else {
                Text("No client")
              }
            }

            Divider()

            ForEach(clientStore.clients, id: \.self) { client in
              Button {
                selectedClient = client
              } label: {
                if selectedClient == client {
                  Label(client, systemImage: "checkmark")
                } else {
                  Text(client)
                }
              }
            }

            Divider()

            Button {
              newClientName = ""
              addClientError = nil
              isPresentingAddClient = true
            } label: {
              Label("Add New Client…", systemImage: "plus")
            }
          } label: {
            HStack {
              Text(selectedClient ?? "No client")
                .foregroundStyle(selectedClient != nil ? .primary : .secondary)
              Spacer()
              Image(systemName: "chevron.up.chevron.down")
                .font(.caption)
                .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
            .overlay {
              RoundedRectangle(cornerRadius: 12, style: .continuous)
                .strokeBorder(Color.primary.opacity(0.08), lineWidth: 1)
            }
          }
          .buttonStyle(.plain)
          .accessibilityLabel("Client or organization")
          .accessibilityValue(selectedClient ?? "No client")

          if let addClientError {
            Text(addClientError)
              .font(.footnote)
              .foregroundStyle(.red)
          }
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

  private var canConfirm: Bool {
    resolvedCategory != nil && tripIndex != nil
  }

  private var resolvedCategory: String? {
    let base = selectedCategory?.trimmingCharacters(in: .whitespacesAndNewlines)
    guard let base, !base.isEmpty else { return nil }
    return base
  }

  private var selectedVehicleName: String {
    guard let id = selectedVehicleID else { return "No vehicle" }
    return vehiclesStore.vehicles.first(where: { $0.id == id })?.name ?? "Unknown vehicle"
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
    selectedVehicleID = trip.vehicleID
    purposeText = trip.purpose ?? ""
    projectCodeText = trip.projectCode ?? ""
    notes = trip.notes ?? ""
    isRoundTrip = false
  }

  private func confirm() {
    guard let idx = tripIndex else { return }
    guard let category = resolvedCategory else { return }

    let trimmedPurpose = purposeText.trimmingCharacters(in: .whitespacesAndNewlines)
    let trimmedProject = projectCodeText.trimmingCharacters(in: .whitespacesAndNewlines)
    let trimmedNotes = notes.trimmingCharacters(in: .whitespacesAndNewlines)

    tripStore.trips[idx].category = category
    tripStore.trips[idx].vehicleID = selectedVehicleID
    tripStore.trips[idx].clientOrOrg = selectedClient
    tripStore.trips[idx].purpose = trimmedPurpose.isEmpty ? nil : trimmedPurpose
    tripStore.trips[idx].projectCode = trimmedProject.isEmpty ? nil : trimmedProject
    tripStore.trips[idx].notes = trimmedNotes.isEmpty ? nil : trimmedNotes
    tripStore.trips[idx].state = .confirmed

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
    .environmentObject(ClientsStore())
    .environmentObject(VehiclesStore())
}

