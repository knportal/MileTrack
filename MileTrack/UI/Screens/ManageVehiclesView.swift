import SwiftUI

struct ManageVehiclesView: View {
  @EnvironmentObject private var vehiclesStore: VehiclesStore

  @State private var isPresentingAdd: Bool = false
  @State private var addName: String = ""
  @State private var addLicensePlate: String = ""
  @State private var addNotes: String = ""

  @State private var editingVehicle: NamedVehicle?
  @State private var editName: String = ""
  @State private var editLicensePlate: String = ""
  @State private var editNotes: String = ""

  @State private var deletingVehicle: NamedVehicle?

  @State private var message: String?

  var body: some View {
    ScrollView {
      VStack(alignment: .leading, spacing: 14) {
        headerCard
        listCard
        if let message {
          Text(message)
            .font(.footnote)
            .foregroundStyle(.secondary)
            .padding(.horizontal, 4)
        }
      }
      .padding(.horizontal, 16)
      .padding(.vertical, 12)
    }
    .background(.background)
    .navigationTitle("Vehicles")
    .toolbar {
      ToolbarItem(placement: .topBarTrailing) {
        Button {
          addName = ""
          addLicensePlate = ""
          addNotes = ""
          isPresentingAdd = true
        } label: {
          Image(systemName: "plus")
        }
        .accessibilityLabel("Add vehicle")
      }
    }
    .sheet(isPresented: $isPresentingAdd) {
      addVehicleSheet
    }
    .sheet(item: $editingVehicle) { vehicle in
      editVehicleSheet(vehicle)
    }
    .confirmationDialog(
      "Delete Vehicle?",
      isPresented: Binding(
        get: { deletingVehicle != nil },
        set: { if !$0 { deletingVehicle = nil } }
      ),
      titleVisibility: .visible
    ) {
      Button("Delete", role: .destructive) {
        deleteVehicle()
      }
      Button("Cancel", role: .cancel) {
        deletingVehicle = nil
      }
    } message: {
      Text("This vehicle will be removed from your fleet.")
    }
  }

  private var headerCard: some View {
    GlassCard {
      VStack(alignment: .leading, spacing: 8) {
        Text("Fleet / Vehicles")
          .font(.headline)
        Text("Track the vehicles you use for business trips.")
          .font(.footnote)
          .foregroundStyle(.secondary)
      }
    }
  }

  private var listCard: some View {
    GlassCard {
      VStack(alignment: .leading, spacing: 10) {
        HStack {
          Text("Vehicles")
            .font(.headline)
          Spacer(minLength: 0)
          Text("\(vehiclesStore.vehicles.count)")
            .foregroundStyle(.secondary)
            .font(.subheadline)
            .accessibilityHidden(true)
        }

        if vehiclesStore.vehicles.isEmpty {
          EmptyStateView(
            systemImage: "car.fill",
            title: "No vehicles yet",
            subtitle: "Add vehicles to track which car you use for trips.",
            actionTitle: "Add Vehicle",
            action: {
              addName = ""
              addLicensePlate = ""
              addNotes = ""
              isPresentingAdd = true
            }
          )
        } else {
          VStack(spacing: 10) {
            ForEach(vehiclesStore.vehicles) { vehicle in
              vehicleRow(vehicle)
            }
          }
        }
      }
    }
  }

  private func vehicleRow(_ vehicle: NamedVehicle) -> some View {
    HStack(spacing: 10) {
      Image(systemName: "car.fill")
        .font(.title3)
        .foregroundStyle(.secondary)
        .frame(width: 32)

      VStack(alignment: .leading, spacing: 2) {
        Text(vehicle.name)
          .font(.subheadline.weight(.semibold))
          .lineLimit(1)
        if !vehicle.licensePlate.isEmpty {
          Text(vehicle.licensePlate)
            .font(.caption)
            .foregroundStyle(.secondary)
            .lineLimit(1)
        }
      }

      Spacer(minLength: 0)

      Button {
        editingVehicle = vehicle
        editName = vehicle.name
        editLicensePlate = vehicle.licensePlate
        editNotes = vehicle.notes
      } label: {
        Image(systemName: "pencil")
          .font(.footnote.weight(.semibold))
          .padding(8)
          .background(.thinMaterial, in: Circle())
          .overlay {
            Circle()
              .strokeBorder(Color.primary.opacity(0.10), lineWidth: 1)
          }
      }
      .buttonStyle(.plain)
      .accessibilityLabel("Edit \(vehicle.name)")

      Button(role: .destructive) {
        deletingVehicle = vehicle
      } label: {
        Image(systemName: "trash")
          .font(.footnote.weight(.semibold))
          .padding(8)
          .background(.thinMaterial, in: Circle())
          .overlay {
            Circle()
              .strokeBorder(Color.primary.opacity(0.10), lineWidth: 1)
          }
      }
      .buttonStyle(.plain)
      .accessibilityLabel("Delete \(vehicle.name)")
    }
    .accessibilityElement(children: .combine)
  }

  // MARK: - Add Sheet

  private var addVehicleSheet: some View {
    NavigationStack {
      ScrollView {
        VStack(alignment: .leading, spacing: 14) {
          GlassCard {
            VStack(alignment: .leading, spacing: 12) {
              Text("New Vehicle")
                .font(.headline)

              nameField(text: $addName)
              licensePlateField(text: $addLicensePlate)
              notesField(text: $addNotes)
            }
          }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
      }
      .background(.background)
      .navigationTitle("Add Vehicle")
      .navigationBarTitleDisplayMode(.inline)
      .toolbar {
        ToolbarItem(placement: .cancellationAction) {
          Button("Cancel") { isPresentingAdd = false }
        }
        ToolbarItem(placement: .confirmationAction) {
          Button("Add") { addVehicle() }
            .disabled(addName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
        }
      }
    }
    .presentationBackground(.ultraThinMaterial)
  }

  // MARK: - Edit Sheet

  private func editVehicleSheet(_ vehicle: NamedVehicle) -> some View {
    NavigationStack {
      ScrollView {
        VStack(alignment: .leading, spacing: 14) {
          GlassCard {
            VStack(alignment: .leading, spacing: 12) {
              Text("Edit Vehicle")
                .font(.headline)

              nameField(text: $editName)
              licensePlateField(text: $editLicensePlate)
              notesField(text: $editNotes)
            }
          }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
      }
      .background(.background)
      .navigationTitle("Edit Vehicle")
      .navigationBarTitleDisplayMode(.inline)
      .toolbar {
        ToolbarItem(placement: .cancellationAction) {
          Button("Cancel") { editingVehicle = nil }
        }
        ToolbarItem(placement: .confirmationAction) {
          Button("Save") { saveEditedVehicle(vehicle) }
            .disabled(editName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
        }
      }
    }
    .presentationBackground(.ultraThinMaterial)
  }

  // MARK: - Form Fields

  private func nameField(text: Binding<String>) -> some View {
    VStack(alignment: .leading, spacing: 6) {
      Text("Name")
        .font(.caption)
        .foregroundStyle(.secondary)
      TextField("e.g. Tesla Model 3, Company Van", text: text)
        .textInputAutocapitalization(.words)
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay {
          RoundedRectangle(cornerRadius: 12, style: .continuous)
            .strokeBorder(Color.primary.opacity(0.08), lineWidth: 1)
        }
        .accessibilityLabel("Vehicle name")
    }
  }

  private func licensePlateField(text: Binding<String>) -> some View {
    VStack(alignment: .leading, spacing: 6) {
      Text("License Plate")
        .font(.caption)
        .foregroundStyle(.secondary)
      TextField("Optional", text: text)
        .textInputAutocapitalization(.characters)
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay {
          RoundedRectangle(cornerRadius: 12, style: .continuous)
            .strokeBorder(Color.primary.opacity(0.08), lineWidth: 1)
        }
        .accessibilityLabel("License plate")
    }
  }

  private func notesField(text: Binding<String>) -> some View {
    VStack(alignment: .leading, spacing: 6) {
      Text("Notes")
        .font(.caption)
        .foregroundStyle(.secondary)
      TextField("Optional", text: text)
        .textInputAutocapitalization(.sentences)
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay {
          RoundedRectangle(cornerRadius: 12, style: .continuous)
            .strokeBorder(Color.primary.opacity(0.08), lineWidth: 1)
        }
        .accessibilityLabel("Notes")
    }
  }

  // MARK: - Actions

  private func addVehicle() {
    let trimmedName = addName.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !trimmedName.isEmpty else {
      message = "Please enter a vehicle name."
      return
    }
    if vehiclesStore.add(name: trimmedName, licensePlate: addLicensePlate, notes: addNotes) {
      message = nil
      isPresentingAdd = false
    } else {
      message = "A vehicle with that name already exists."
    }
  }

  private func saveEditedVehicle(_ original: NamedVehicle) {
    let updated = NamedVehicle(
      id: original.id,
      name: editName,
      licensePlate: editLicensePlate,
      notes: editNotes
    )
    if vehiclesStore.update(updated) {
      message = nil
      editingVehicle = nil
    } else {
      message = "Could not save. Name may be empty or duplicate."
    }
  }

  private func deleteVehicle() {
    guard let toDelete = deletingVehicle else { return }
    deletingVehicle = nil

    if vehiclesStore.remove(toDelete) {
      message = nil
    } else {
      message = "Delete failed."
    }
  }
}

#Preview {
  NavigationStack {
    ManageVehiclesView()
  }
  .environmentObject(VehiclesStore())
}
