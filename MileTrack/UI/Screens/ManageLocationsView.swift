import SwiftUI

struct ManageLocationsView: View {
  @EnvironmentObject private var locationsStore: LocationsStore

  @State private var isPresentingAdd: Bool = false
  @State private var addName: String = ""
  @State private var addAddress: String = ""
  @State private var addLatitude: Double?
  @State private var addLongitude: Double?

  @State private var editingLocation: NamedLocation?
  @State private var editName: String = ""
  @State private var editAddress: String = ""
  @State private var editLatitude: Double?
  @State private var editLongitude: Double?

  @State private var deletingLocation: NamedLocation?

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
    .navigationTitle("Locations")
    .toolbar {
      ToolbarItem(placement: .topBarTrailing) {
        Button {
          addName = ""
          addAddress = ""
          isPresentingAdd = true
        } label: {
          Image(systemName: "plus")
        }
        .accessibilityLabel("Add location")
      }
    }
    .sheet(isPresented: $isPresentingAdd) {
      addLocationSheet
    }
    .sheet(item: $editingLocation) { location in
      editLocationSheet(location)
    }
    .confirmationDialog(
      "Delete Location?",
      isPresented: Binding(
        get: { deletingLocation != nil },
        set: { if !$0 { deletingLocation = nil } }
      ),
      titleVisibility: .visible
    ) {
      Button("Delete", role: .destructive) {
        deleteLocation()
      }
      Button("Cancel", role: .cancel) {
        deletingLocation = nil
      }
    } message: {
      Text("This location will be removed. Rules using it will no longer match.")
    }
  }

  private var headerCard: some View {
    GlassCard {
      VStack(alignment: .leading, spacing: 8) {
        Text("Named Locations")
          .font(.headline)
        Text("Save addresses with friendly names like \"Home\" or \"Work\" to use in rules.")
          .font(.footnote)
          .foregroundStyle(.secondary)
      }
    }
  }

  private var listCard: some View {
    GlassCard {
      VStack(alignment: .leading, spacing: 10) {
        HStack {
          Text("Locations")
            .font(.headline)
          Spacer(minLength: 0)
          Text("\(locationsStore.locations.count)")
            .foregroundStyle(.secondary)
            .font(.subheadline)
            .accessibilityHidden(true)
        }

        if locationsStore.locations.isEmpty {
          EmptyStateView(
            systemImage: "mappin.and.ellipse",
            title: "No locations yet",
            subtitle: "Add locations like Home or Work to use in rules.",
            actionTitle: "Add Location",
            action: {
              addName = ""
              addAddress = ""
              isPresentingAdd = true
            }
          )
        } else {
          VStack(spacing: 10) {
            ForEach(locationsStore.locations) { location in
              locationRow(location)
            }
          }
        }
      }
    }
  }

  private func locationRow(_ location: NamedLocation) -> some View {
    HStack(spacing: 10) {
      VStack(alignment: .leading, spacing: 2) {
        Text(location.name)
          .font(.subheadline.weight(.semibold))
          .lineLimit(1)
        if !location.address.isEmpty {
          Text(location.address)
            .font(.caption)
            .foregroundStyle(.secondary)
            .lineLimit(1)
        } else {
          Text("No address set")
            .font(.caption)
            .foregroundStyle(.tertiary)
            .italic()
        }
      }

      Spacer(minLength: 0)

      Button {
        editingLocation = location
        editName = location.name
        editAddress = location.address
        editLatitude = location.latitude
        editLongitude = location.longitude
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
      .accessibilityLabel("Edit \(location.name)")

      Button(role: .destructive) {
        deletingLocation = location
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
      .accessibilityLabel("Delete \(location.name)")
    }
    .accessibilityElement(children: .combine)
  }

  private var addLocationSheet: some View {
    NavigationStack {
      ScrollView {
        VStack(alignment: .leading, spacing: 14) {
          GlassCard {
            VStack(alignment: .leading, spacing: 12) {
              Text("New Location")
                .font(.headline)

              VStack(alignment: .leading, spacing: 6) {
                Text("Name")
                  .font(.caption)
                  .foregroundStyle(.secondary)
                TextField("e.g. Home, Work, Gym", text: $addName)
                  .textInputAutocapitalization(.words)
                  .padding(.horizontal, 14)
                  .padding(.vertical, 12)
                  .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                  .overlay {
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                      .strokeBorder(Color.primary.opacity(0.08), lineWidth: 1)
                  }
                  .accessibilityLabel("Location name")
              }

              VStack(alignment: .leading, spacing: 6) {
                Text("Address")
                  .font(.caption)
                  .foregroundStyle(.secondary)
                AddressAutocompleteField(
                  placeholder: "e.g. 123 Main Street",
                  text: $addAddress,
                  accessibilityLabel: "Location address",
                  onCoordinatesResolved: { lat, lon in
                    addLatitude = lat
                    addLongitude = lon
                  }
                )
                if addLatitude != nil {
                  Label("Coordinates captured", systemImage: "checkmark.circle.fill")
                    .font(.caption2)
                    .foregroundStyle(.green)
                } else {
                  Text("Select an address from suggestions to enable location snapping.")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
                }
              }
            }
          }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
      }
      .background(.background)
      .navigationTitle("Add Location")
      .navigationBarTitleDisplayMode(.inline)
      .toolbar {
        ToolbarItem(placement: .cancellationAction) {
          Button("Cancel") { isPresentingAdd = false }
        }
        ToolbarItem(placement: .confirmationAction) {
          Button("Add") { addLocation() }
            .disabled(addName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
        }
      }
    }
    .presentationBackground(.ultraThinMaterial)
  }

  private func editLocationSheet(_ location: NamedLocation) -> some View {
    NavigationStack {
      ScrollView {
        VStack(alignment: .leading, spacing: 14) {
          GlassCard {
            VStack(alignment: .leading, spacing: 12) {
              Text("Edit Location")
                .font(.headline)

              VStack(alignment: .leading, spacing: 6) {
                Text("Name")
                  .font(.caption)
                  .foregroundStyle(.secondary)
                TextField("e.g. Home, Work, Gym", text: $editName)
                  .textInputAutocapitalization(.words)
                  .padding(.horizontal, 14)
                  .padding(.vertical, 12)
                  .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                  .overlay {
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                      .strokeBorder(Color.primary.opacity(0.08), lineWidth: 1)
                  }
                  .accessibilityLabel("Location name")
              }

              VStack(alignment: .leading, spacing: 6) {
                Text("Address")
                  .font(.caption)
                  .foregroundStyle(.secondary)
                AddressAutocompleteField(
                  placeholder: "e.g. 123 Main Street",
                  text: $editAddress,
                  accessibilityLabel: "Location address",
                  onCoordinatesResolved: { lat, lon in
                    editLatitude = lat
                    editLongitude = lon
                  }
                )
                if editLatitude != nil {
                  Label("Coordinates captured", systemImage: "checkmark.circle.fill")
                    .font(.caption2)
                    .foregroundStyle(.green)
                } else {
                  Text("Select an address from suggestions to enable location snapping.")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
                }
              }
            }
          }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
      }
      .background(.background)
      .navigationTitle("Edit Location")
      .navigationBarTitleDisplayMode(.inline)
      .toolbar {
        ToolbarItem(placement: .cancellationAction) {
          Button("Cancel") { editingLocation = nil }
        }
        ToolbarItem(placement: .confirmationAction) {
          Button("Save") { saveEditedLocation(location) }
            .disabled(editName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
        }
      }
    }
    .presentationBackground(.ultraThinMaterial)
  }

  private func addLocation() {
    let trimmedName = addName.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !trimmedName.isEmpty else {
      message = "Please enter a location name."
      return
    }
    if locationsStore.add(name: trimmedName, address: addAddress, latitude: addLatitude, longitude: addLongitude) {
      message = nil
      addLatitude = nil
      addLongitude = nil
      isPresentingAdd = false
    } else {
      message = "A location with that name already exists."
    }
  }

  private func saveEditedLocation(_ original: NamedLocation) {
    let updated = NamedLocation(
      id: original.id,
      name: editName,
      address: editAddress,
      latitude: editLatitude ?? original.latitude,
      longitude: editLongitude ?? original.longitude
    )
    if locationsStore.update(updated) {
      message = nil
      editLatitude = nil
      editLongitude = nil
      editingLocation = nil
    } else {
      message = "Could not save. Name may be empty or duplicate."
    }
  }

  private func deleteLocation() {
    guard let toDelete = deletingLocation else { return }
    deletingLocation = nil

    if locationsStore.remove(toDelete) {
      message = nil
    } else {
      message = "Delete failed."
    }
  }
}

#Preview {
  NavigationStack {
    ManageLocationsView()
  }
  .environmentObject(LocationsStore())
}
