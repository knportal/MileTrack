import SwiftUI
import MapKit

struct ManualTripSheet: View {
  @Environment(\.dismiss) private var dismiss
  @EnvironmentObject private var tripStore: TripStore
  @EnvironmentObject private var categoriesStore: CategoriesStore
  @EnvironmentObject private var clientStore: ClientsStore
  @EnvironmentObject private var vehiclesStore: VehiclesStore

  @State private var selectedCategory: String?
  @State private var distanceText: String = ""
  @State private var date: Date = Date()

  @State private var startLabel: String = ""
  @State private var endLabel: String = ""
  @State private var selectedClient: String?
  @State private var selectedVehicleID: UUID?
  @State private var purposeText: String = ""
  @State private var projectCodeText: String = ""
  @State private var notes: String = ""
  @AppStorage("useMetricUnits") private var useMetricUnits = false

  @State private var showOptionalFields: Bool = false
  @State private var isCalculatingDistance: Bool = false

  @FocusState private var focusedField: Field?

  @State private var isPresentingAddCategory: Bool = false
  @State private var newCategoryName: String = ""
  @State private var addCategoryError: String?

  @State private var isPresentingAddClient: Bool = false
  @State private var newClientName: String = ""
  @State private var addClientError: String?

  private enum Field: Hashable {
    case distance
    case start
    case end
    case purpose
    case project
    case notes
  }

  var body: some View {
    NavigationStack {
      ScrollView {
        VStack(alignment: .leading, spacing: 14) {
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

          GlassCard {
            VStack(alignment: .leading, spacing: 12) {
              Text("Trip details")
                .font(.headline)

              VStack(alignment: .leading, spacing: 10) {
                AddressAutocompleteField(
                  placeholder: "Start location",
                  text: $startLabel,
                  accessibilityLabel: "Start location"
                )
                .onChange(of: startLabel) { _, _ in
                  calculateDistanceIfPossible()
                }

                AddressAutocompleteField(
                  placeholder: "End location",
                  text: $endLabel,
                  accessibilityLabel: "End location"
                )
                .onChange(of: endLabel) { _, _ in
                  calculateDistanceIfPossible()
                }

                HStack {
                  Text("Distance (\(DistanceFormatter.unitLabel), required)")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .accessibilityHidden(true)
                  
                  if isCalculatingDistance {
                    Spacer()
                    ProgressView()
                      .controlSize(.small)
                  }
                }

                TextField("0.0", text: $distanceText)
                  .keyboardType(.decimalPad)
                  .focused($focusedField, equals: .distance)
                  .padding(.horizontal, 12)
                  .padding(.vertical, 10)
                  .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                  .overlay {
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                      .strokeBorder(Color.primary.opacity(0.10), lineWidth: 1)
                  }
                  .accessibilityLabel("Distance in \(DistanceFormatter.unitName)")

                DatePicker("Date & Time", selection: $date, displayedComponents: [.date, .hourAndMinute])
                  .datePickerStyle(.compact)
                  .accessibilityLabel("Date and time")
              }

              // Optional details toggle button
              Button {
                withAnimation(.easeInOut(duration: 0.2)) {
                  showOptionalFields.toggle()
                }
              } label: {
                HStack {
                  Text("Optional details")
                    .font(.subheadline.weight(.medium))
                  Spacer()
                  Image(systemName: showOptionalFields ? "chevron.up" : "chevron.down")
                    .font(.caption.weight(.semibold))
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
              .accessibilityLabel("Optional details")
              .accessibilityHint(showOptionalFields ? "Tap to hide optional fields" : "Tap to show optional fields")
              
              if showOptionalFields {
                VStack(alignment: .leading, spacing: 10) {
                  // Purpose field
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
                    .focused($focusedField, equals: .purpose)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 10)
                    .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                    .overlay {
                      RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .strokeBorder(Color.primary.opacity(0.08), lineWidth: 1)
                    }
                    .accessibilityLabel("Business purpose")

                  // Vehicle picker
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

                  // Client picker with filled button style
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

                  TextField("Project / Job code", text: $projectCodeText.max(DesignConstants.TextLimits.shortName))
                    .textInputAutocapitalization(.characters)
                    .focused($focusedField, equals: .project)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 10)
                    .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                    .overlay {
                      RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .strokeBorder(Color.primary.opacity(0.08), lineWidth: 1)
                    }
                    .accessibilityLabel("Project code")

                  TextField("Notes", text: $notes.max(DesignConstants.TextLimits.notes), axis: .vertical)
                    .lineLimit(2...5)
                    .focused($focusedField, equals: .notes)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 10)
                    .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                    .overlay {
                      RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .strokeBorder(Color.primary.opacity(0.08), lineWidth: 1)
                    }
                    .accessibilityLabel("Notes")
                }
                .transition(.opacity.combined(with: .move(edge: .top)))
              }
            }
          }
        }
        .frame(maxWidth: DesignConstants.iPadMaxContentWidth)
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .frame(maxWidth: .infinity)
      }
      .background(.background)
      .navigationTitle("Add Trip")
      .navigationBarTitleDisplayMode(.inline)
      .toolbar {
        ToolbarItem(placement: .cancellationAction) {
          Button("Cancel") {
            dismiss()
          }
        }
        ToolbarItem(placement: .confirmationAction) {
          Button("Save") {
            Haptics.success()
            save()
          }
          .disabled(!canSave)
          .accessibilityLabel("Save trip")
          .accessibilityHint(canSave ? "Saves the trip." : "Select a category and enter a valid distance.")
        }
      }
    }
    .presentationBackground(.ultraThinMaterial)
    .alert("Add New Category", isPresented: $isPresentingAddCategory) {
      TextField("Category name", text: $newCategoryName.max(DesignConstants.TextLimits.shortName))
      Button("Add") {
        addCategory()
      }
      Button("Cancel", role: .cancel) {}
    } message: {
      Text("Names can't be empty or duplicates.")
    }
    .alert("Add New Client", isPresented: $isPresentingAddClient) {
      TextField("Client name", text: $newClientName.max(DesignConstants.TextLimits.shortName))
      Button("Add") { addClient() }
      Button("Cancel", role: .cancel) {}
    } message: {
      Text("Names can't be empty or duplicates.")
    }
  }

  private static let addNewSentinel = "__ADD_NEW_CATEGORY__"
  private static let addNewClientSentinel = "__ADD_NEW_CLIENT__"

  private var canSave: Bool {
    resolvedCategory != nil && parsedDistanceMiles != nil
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

  private var parsedDistanceMiles: Double? {
    let trimmed = distanceText.trimmingCharacters(in: .whitespacesAndNewlines)
      .replacingOccurrences(of: ",", with: ".")
    guard let value = Double(trimmed), value > 0 else { return nil }
    // Convert from display units (mi or km) to miles for storage
    return DistanceFormatter.toMiles(value)
  }

  private var normalizedSelectedCategory: String? {
    selectedCategory?.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
  }

  private func save() {
    guard let category = resolvedCategory else { return }
    guard let miles = parsedDistanceMiles else { return }

    let trimmedStart = startLabel.trimmingCharacters(in: .whitespacesAndNewlines)
    let trimmedEnd = endLabel.trimmingCharacters(in: .whitespacesAndNewlines)
    let trimmedPurpose = purposeText.trimmingCharacters(in: .whitespacesAndNewlines)
    let trimmedProject = projectCodeText.trimmingCharacters(in: .whitespacesAndNewlines)
    let trimmedNotes = notes.trimmingCharacters(in: .whitespacesAndNewlines)

    let trip = Trip(
      date: date,
      distanceMiles: miles,
      durationSeconds: nil,
      startLabel: trimmedStart.isEmpty ? nil : trimmedStart,
      endLabel: trimmedEnd.isEmpty ? nil : trimmedEnd,
      source: .manual,
      state: .confirmed,
      category: category,
      clientOrOrg: selectedClient,
      projectCode: trimmedProject.isEmpty ? nil : trimmedProject,
      notes: trimmedNotes.isEmpty ? nil : trimmedNotes,
      purpose: trimmedPurpose.isEmpty ? nil : trimmedPurpose,
      vehicleID: selectedVehicleID
    )

    tripStore.trips.insert(trip, at: 0)
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

  private func calculateDistanceIfPossible() {
    let trimmedStart = startLabel.trimmingCharacters(in: .whitespacesAndNewlines)
    let trimmedEnd = endLabel.trimmingCharacters(in: .whitespacesAndNewlines)

    // Only calculate if both addresses are filled
    guard !trimmedStart.isEmpty && !trimmedEnd.isEmpty else {
      return
    }

    // Cancel any existing calculation
    isCalculatingDistance = true

    Task {
      do {
        // Geocode start address
        let startRequest = MKLocalSearch.Request()
        startRequest.naturalLanguageQuery = trimmedStart
        let startSearch = MKLocalSearch(request: startRequest)
        let startResponse = try await startSearch.start()

        guard let startItem = startResponse.mapItems.first else {
          isCalculatingDistance = false
          return
        }

        // Geocode end address
        let endRequest = MKLocalSearch.Request()
        endRequest.naturalLanguageQuery = trimmedEnd
        let endSearch = MKLocalSearch(request: endRequest)
        let endResponse = try await endSearch.start()

        guard let endItem = endResponse.mapItems.first else {
          isCalculatingDistance = false
          return
        }

        // Calculate driving distance using MKDirections
        let directionsRequest = MKDirections.Request()
        directionsRequest.source = startItem
        directionsRequest.destination = endItem
        directionsRequest.transportType = .automobile

        let directions = MKDirections(request: directionsRequest)
        let directionsResponse = try await directions.calculate()

        if let route = directionsResponse.routes.first {
          // Convert meters to miles, then to display units
          let miles = route.distance / 1609.34
          let displayValue = DistanceFormatter.toDisplayUnits(miles)
          distanceText = String(format: "%.1f", displayValue)
        }

        isCalculatingDistance = false
      } catch {
        // Silently fail - user can enter distance manually
        isCalculatingDistance = false
      }
    }
  }
}

#Preview {
  ManualTripSheet()
    .environmentObject(TripStore())
    .environmentObject(CategoriesStore())
    .environmentObject(ClientsStore())
    .environmentObject(VehiclesStore())
}
