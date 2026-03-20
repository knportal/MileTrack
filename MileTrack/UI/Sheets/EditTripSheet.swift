import SwiftUI

/// Sheet for editing confirmed trips - allows changing addresses, category, client, etc.
struct EditTripSheet: View {
  @Environment(\.dismiss) private var dismiss
  @EnvironmentObject private var tripStore: TripStore
  @EnvironmentObject private var categoriesStore: CategoriesStore
  @EnvironmentObject private var clientStore: ClientsStore
  @EnvironmentObject private var mileageRatesStore: MileageRatesStore
  @EnvironmentObject private var receiptsStore: ReceiptsStore
  @EnvironmentObject private var vehiclesStore: VehiclesStore

  let tripID: UUID

  @AppStorage("useMetricUnits") private var useMetricUnits = false

  @State private var startLabel: String = ""
  @State private var endLabel: String = ""
  @State private var startAddress: String = ""
  @State private var endAddress: String = ""
  @State private var selectedCategory: String?
  @State private var selectedClient: String?
  @State private var purposeText: String = ""
  @State private var selectedVehicleID: UUID?
  @State private var projectCodeText: String = ""
  @State private var notes: String = ""

  @State private var isPresentingAddCategory: Bool = false
  @State private var newCategoryName: String = ""
  @State private var addCategoryError: String?

  @State private var isPresentingAddClient: Bool = false
  @State private var newClientName: String = ""
  @State private var addClientError: String?
  
  @State private var isPresentingDeleteConfirm: Bool = false
  @State private var isPresentingMergeSheet: Bool = false

  private let calculator = ExpenseCalculator()

  var body: some View {
    NavigationStack {
      ScrollView {
        VStack(alignment: .leading, spacing: 14) {
          tripInfoCard
          expenseCard
          addressesCard
          categoryCard
          optionalDetailsCard
          receiptsCard
        }
        .frame(maxWidth: DesignConstants.iPadMaxContentWidth)
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .frame(maxWidth: .infinity)
      }
      .background(.background)
      .navigationTitle("Edit Trip")
      .navigationBarTitleDisplayMode(.inline)
      .toolbar {
        ToolbarItem(placement: .cancellationAction) {
          Button("Cancel") { dismiss() }
        }
        ToolbarItem(placement: .confirmationAction) {
          Button("Save") {
            Haptics.success()
            saveChanges()
          }
          .fontWeight(.semibold)
          .disabled(!canSave)
        }
        ToolbarItem(placement: .bottomBar) {
          Button(role: .destructive) {
            isPresentingDeleteConfirm = true
          } label: {
            Label("Delete", systemImage: "trash")
              .font(.caption.weight(.semibold))
          }
        }
        if !nearbyConfirmedTrips.isEmpty {
          ToolbarItem(placement: .bottomBar) {
            Spacer()
          }
          ToolbarItem(placement: .bottomBar) {
            Button {
              isPresentingMergeSheet = true
            } label: {
              Label("Merge with trip…", systemImage: "arrow.triangle.merge")
                .font(.caption.weight(.semibold))
            }
            .accessibilityLabel("Merge with another trip")
            .accessibilityHint("Combine this trip with a nearby trip from the same day.")
          }
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
      Text("Names can't be empty or duplicates.")
    }
    .alert("Add New Client", isPresented: $isPresentingAddClient) {
      TextField("Client name", text: $newClientName)
      Button("Add") { addClient() }
      Button("Cancel", role: .cancel) {}
    } message: {
      Text("Names can't be empty or duplicates.")
    }
    .alert("Delete Trip?", isPresented: $isPresentingDeleteConfirm) {
      Button("Cancel", role: .cancel) {}
      Button("Delete", role: .destructive) {
        Haptics.warning()
        deleteTrip()
      }
    } message: {
      Text("This trip will be removed from your records. This action cannot be undone.")
    }
    .sheet(isPresented: $isPresentingMergeSheet, onDismiss: {
      // Dismiss EditTripSheet too if the trip was merged (no longer exists)
      if tripIndex == nil {
        dismiss()
      }
    }) {
      if let trip {
        MergeTripsSheet(anchorTrip: trip)
          .environmentObject(tripStore)
      }
    }
  }

  private var tripIndex: Int? {
    tripStore.trips.firstIndex(where: { $0.id == tripID })
  }

  private var trip: Trip? {
    guard let idx = tripIndex else { return nil }
    return tripStore.trips[idx]
  }

  // MARK: - Trip Info Card

  private var tripInfoCard: some View {
    GlassCard {
      VStack(alignment: .leading, spacing: 10) {
        Text("Trip Details")
          .font(.headline)

        if let trip {
          HStack(alignment: .firstTextBaseline) {
            Text(trip.date, format: .dateTime.month().day().year())
              .font(.subheadline)
            Spacer(minLength: 0)
            Text(distanceLabel(trip))
              .font(.subheadline.weight(.semibold))
          }

          if let seconds = trip.durationSeconds, seconds > 0 {
            Text(durationLabel(seconds))
              .font(.footnote)
              .foregroundStyle(.secondary)
          }
        } else {
          Text("This trip is no longer available.")
            .foregroundStyle(.secondary)
            .font(.footnote)
        }
      }
    }
    .accessibilityElement(children: .contain)
  }
  
  // MARK: - Expense Card
  
  private var expenseCard: some View {
    Group {
      if let trip = trip,
         let calculation = calculator.calculateExpense(
          for: trip,
          rates: mileageRatesStore.rates,
          receipts: receiptsStore.receipts
         ) {
        GlassCard {
          VStack(alignment: .leading, spacing: 12) {
            Text("Expense Estimate")
              .font(.headline)
            
            ExpenseCalculationView(calculation: calculation, showBreakdown: true)
          }
        }
      }
    }
  }

  // MARK: - Addresses Card

  private var addressesCard: some View {
    GlassCard {
      VStack(alignment: .leading, spacing: 12) {
        Text("Addresses")
          .font(.headline)

        VStack(alignment: .leading, spacing: 8) {
          Text("Start Location")
            .font(.caption)
            .foregroundStyle(.secondary)
          TextField("Start location name", text: $startLabel)
            .textInputAutocapitalization(.words)
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
            .overlay {
              RoundedRectangle(cornerRadius: 14, style: .continuous)
                .strokeBorder(Color.primary.opacity(0.10), lineWidth: 1)
            }
            .accessibilityLabel("Start location name")
          TextField("Start street address", text: $startAddress)
            .font(.subheadline)
            .textInputAutocapitalization(.words)
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
            .overlay {
              RoundedRectangle(cornerRadius: 14, style: .continuous)
                .strokeBorder(Color.primary.opacity(0.10), lineWidth: 1)
            }
            .accessibilityLabel("Start street address")
        }

        VStack(alignment: .leading, spacing: 8) {
          Text("End Location")
            .font(.caption)
            .foregroundStyle(.secondary)
          TextField("End location name", text: $endLabel)
            .textInputAutocapitalization(.words)
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
            .overlay {
              RoundedRectangle(cornerRadius: 14, style: .continuous)
                .strokeBorder(Color.primary.opacity(0.10), lineWidth: 1)
            }
            .accessibilityLabel("End location name")
          TextField("End street address", text: $endAddress)
            .font(.subheadline)
            .textInputAutocapitalization(.words)
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
            .overlay {
              RoundedRectangle(cornerRadius: 14, style: .continuous)
                .strokeBorder(Color.primary.opacity(0.10), lineWidth: 1)
            }
            .accessibilityLabel("End street address")
        }

        if let stops = trip?.waypoints, !stops.isEmpty {
          Divider()
          VStack(alignment: .leading, spacing: 4) {
            Text("Intermediate Stops")
              .font(.caption)
              .foregroundStyle(.secondary)
            ForEach(Array(stops.enumerated()), id: \.offset) { _, stop in
              Text("· \(stop)")
                .font(.subheadline)
                .foregroundStyle(.primary)
            }
          }
        }
      }
    }
  }

  // MARK: - Category Card

  private var categoryCard: some View {
    GlassCard {
      VStack(alignment: .leading, spacing: 12) {
        Text("Category")
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

  // MARK: - Optional Details Card

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

          TextField("Describe the business purpose…", text: $purposeText.max(DesignConstants.TextLimits.notes))
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

        TextField("Project / Job code (optional)", text: $projectCodeText.max(DesignConstants.TextLimits.shortName))
          .textInputAutocapitalization(.characters)
          .padding(.horizontal, 12)
          .padding(.vertical, 10)
          .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
          .overlay {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
              .strokeBorder(Color.primary.opacity(0.10), lineWidth: 1)
          }
          .accessibilityLabel("Project code")

        TextField("Notes (optional)", text: $notes.max(DesignConstants.TextLimits.notes), axis: .vertical)
          .lineLimit(2...5)
          .padding(.horizontal, 12)
          .padding(.vertical, 10)
          .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
          .overlay {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
              .strokeBorder(Color.primary.opacity(0.10), lineWidth: 1)
          }
          .accessibilityLabel("Notes")
      }
    }
  }
  
  // MARK: - Receipts Card
  
  private var receiptsCard: some View {
    Group {
      if let trip = trip {
        GlassCard {
          VStack(alignment: .leading, spacing: 12) {
            HStack {
              Text("Receipts")
                .font(.headline)
              
              Spacer()
              
              let receiptCount = receiptsStore.receipts(for: trip).count
              if receiptCount > 0 {
                Text("\(receiptCount)")
                  .font(.caption)
                  .foregroundStyle(.secondary)
                  .padding(.horizontal, 8)
                  .padding(.vertical, 4)
                  .background(.secondary.opacity(0.2), in: Capsule())
              }
            }
            
            NavigationLink {
              TripReceiptsView(trip: trip, receiptsStore: receiptsStore)
            } label: {
              HStack {
                Image(systemName: "doc.text")
                  .foregroundStyle(.secondary)
                Text("Manage Receipts")
                  .font(.body)
                Spacer()
                Image(systemName: "chevron.right")
                  .font(.caption.weight(.semibold))
                  .foregroundStyle(.tertiary)
              }
              .padding(.horizontal, 12)
              .padding(.vertical, 10)
              .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
              .overlay {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                  .strokeBorder(Color.primary.opacity(0.10), lineWidth: 1)
              }
            }
            .buttonStyle(.plain)
            
            let totalAmount = receiptsStore.totalAmount(for: trip)
            if totalAmount > 0 {
              HStack {
                Text("Total")
                  .font(.subheadline)
                  .foregroundStyle(.secondary)
                Spacer()
                let formatter = NumberFormatter()
                let _ = { formatter.numberStyle = .currency; formatter.currencyCode = "USD" }()
                Text(formatter.string(from: totalAmount as NSNumber) ?? "$0.00")
                  .font(.subheadline.bold())
                  .foregroundStyle(.green)
              }
            }
          }
        }
      }
    }
  }



  private var canSave: Bool {
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

  private var nearbyConfirmedTrips: [Trip] {
    guard let trip else { return [] }
    let window: TimeInterval = 24 * 60 * 60
    return tripStore.confirmedTrips.filter { other in
      other.id != trip.id && abs(other.date.timeIntervalSince(trip.date)) <= window
    }
  }

  // MARK: - Actions

  private func hydrateFromTrip() {
    guard let trip else { return }
    startLabel = trip.startLabel ?? ""
    endLabel = trip.endLabel ?? ""
    startAddress = trip.startAddress ?? ""
    endAddress = trip.endAddress ?? ""
    
    let existing = trip.category?.trimmingCharacters(in: .whitespacesAndNewlines)
    if let existing, !existing.isEmpty {
      selectedCategory = existing
    } else {
      selectedCategory = nil
    }

    selectedClient = trip.clientOrOrg
    selectedVehicleID = trip.vehicleID
    purposeText = trip.purpose ?? ""
    projectCodeText = trip.projectCode ?? ""
    notes = trip.notes ?? ""
  }

  private func saveChanges() {
    guard let idx = tripIndex else { return }
    guard let category = resolvedCategory else { return }

    let trimmedStart = startLabel.trimmingCharacters(in: .whitespacesAndNewlines)
    let trimmedEnd = endLabel.trimmingCharacters(in: .whitespacesAndNewlines)
    let trimmedStartAddr = startAddress.trimmingCharacters(in: .whitespacesAndNewlines)
    let trimmedEndAddr = endAddress.trimmingCharacters(in: .whitespacesAndNewlines)
    let trimmedPurpose = purposeText.trimmingCharacters(in: .whitespacesAndNewlines)
    let trimmedProject = projectCodeText.trimmingCharacters(in: .whitespacesAndNewlines)
    let trimmedNotes = notes.trimmingCharacters(in: .whitespacesAndNewlines)

    tripStore.trips[idx].startLabel = trimmedStart.isEmpty ? nil : trimmedStart
    tripStore.trips[idx].endLabel = trimmedEnd.isEmpty ? nil : trimmedEnd
    tripStore.trips[idx].startAddress = trimmedStartAddr.isEmpty ? nil : trimmedStartAddr
    tripStore.trips[idx].endAddress = trimmedEndAddr.isEmpty ? nil : trimmedEndAddr
    tripStore.trips[idx].category = category
    tripStore.trips[idx].vehicleID = selectedVehicleID
    tripStore.trips[idx].clientOrOrg = selectedClient
    tripStore.trips[idx].purpose = trimmedPurpose.isEmpty ? nil : trimmedPurpose
    tripStore.trips[idx].projectCode = trimmedProject.isEmpty ? nil : trimmedProject
    tripStore.trips[idx].notes = trimmedNotes.isEmpty ? nil : trimmedNotes

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
  
  private func deleteTrip() {
    guard let idx = tripIndex else { return }
    tripStore.trips[idx].state = .ignored
    dismiss()
  }

  // MARK: - Formatting Helpers

  private func distanceLabel(_ trip: Trip) -> String {
    DistanceFormatter.format(trip.distanceMiles)
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
  return EditTripSheet(tripID: store.confirmedTrips.first?.id ?? store.trips.first!.id)
    .environmentObject(store)
    .environmentObject(CategoriesStore())
    .environmentObject(ClientsStore())
    .environmentObject(MileageRatesStore())
    .environmentObject(ReceiptsStore())
    .environmentObject(VehiclesStore())
}
