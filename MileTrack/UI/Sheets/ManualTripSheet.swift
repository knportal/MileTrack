import SwiftUI

struct ManualTripSheet: View {
  @Environment(\.dismiss) private var dismiss
  @EnvironmentObject private var tripStore: TripStore
  @EnvironmentObject private var categoriesStore: CategoriesStore
  @EnvironmentObject private var clientStore: ClientStore

  @State private var selectedCategory: String?
  @State private var distanceText: String = ""
  @State private var date: Date = Date()

  @State private var startLabel: String = ""
  @State private var endLabel: String = ""
  @State private var selectedClient: String?
  @State private var projectCodeText: String = ""
  @State private var notes: String = ""
  @State private var showOptionalFields: Bool = false

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

          GlassCard {
            VStack(alignment: .leading, spacing: 12) {
              Text("Trip details")
                .font(.headline)

              VStack(alignment: .leading, spacing: 10) {
                Text("Distance (miles, required)")
                  .font(.subheadline.weight(.semibold))
                  .foregroundStyle(.secondary)
                  .accessibilityHidden(true)

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
                  .accessibilityLabel("Distance in miles")

                DatePicker("Date & Time", selection: $date, displayedComponents: [.date, .hourAndMinute])
                  .datePickerStyle(.compact)
                  .accessibilityLabel("Date and time")
              }

              DisclosureGroup(isExpanded: $showOptionalFields) {
                VStack(alignment: .leading, spacing: 10) {
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

                  TextField("Start (optional)", text: $startLabel)
                    .textInputAutocapitalization(.words)
                    .focused($focusedField, equals: .start)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 10)
                    .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                    .overlay {
                      RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .strokeBorder(Color.primary.opacity(0.10), lineWidth: 1)
                    }
                    .accessibilityLabel("Start location")

                  TextField("End (optional)", text: $endLabel)
                    .textInputAutocapitalization(.words)
                    .focused($focusedField, equals: .end)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 10)
                    .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                    .overlay {
                      RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .strokeBorder(Color.primary.opacity(0.10), lineWidth: 1)
                    }
                    .accessibilityLabel("End location")

                  TextField("Project / Job code (optional)", text: $projectCodeText)
                    .textInputAutocapitalization(.characters)
                    .focused($focusedField, equals: .project)
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
                    .focused($focusedField, equals: .notes)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 10)
                    .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                    .overlay {
                      RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .strokeBorder(Color.primary.opacity(0.10), lineWidth: 1)
                    }
                    .accessibilityLabel("Notes")
                }
                .padding(.top, 10)
              } label: {
                Text("Optional details")
                  .font(.subheadline.weight(.semibold))
                  .foregroundStyle(.secondary)
              }
            }
          }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
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
      TextField("Category name", text: $newCategoryName)
      Button("Add") {
        addCategory()
      }
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

  private var parsedDistanceMiles: Double? {
    let trimmed = distanceText.trimmingCharacters(in: .whitespacesAndNewlines)
      .replacingOccurrences(of: ",", with: ".")
    guard let miles = Double(trimmed), miles > 0 else { return nil }
    return miles
  }

  private var normalizedSelectedCategory: String? {
    selectedCategory?.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
  }

  private func save() {
    guard let category = resolvedCategory else { return }
    guard let miles = parsedDistanceMiles else { return }

    let trimmedStart = startLabel.trimmingCharacters(in: .whitespacesAndNewlines)
    let trimmedEnd = endLabel.trimmingCharacters(in: .whitespacesAndNewlines)
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
      notes: trimmedNotes.isEmpty ? nil : trimmedNotes
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
}

#Preview {
  ManualTripSheet()
    .environmentObject(TripStore())
    .environmentObject(CategoriesStore())
    .environmentObject(ClientStore())
}
