import SwiftUI

struct ManageClientsView: View {
  @EnvironmentObject private var clientStore: ClientsStore
  @EnvironmentObject private var tripStore: TripStore

  @State private var isPresentingAdd: Bool = false
  @State private var addName: String = ""

  @State private var renamingClient: String?
  @State private var renameName: String = ""

  @State private var deletingClient: String?

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
    .navigationTitle("Clients")
    .toolbar {
      ToolbarItem(placement: .topBarTrailing) {
        Button {
          addName = ""
          isPresentingAdd = true
        } label: {
          Image(systemName: "plus")
        }
        .accessibilityLabel("Add client")
      }
    }
    .alert("Add Client", isPresented: $isPresentingAdd) {
      TextField("Client name", text: $addName.max(DesignConstants.TextLimits.shortName))
      Button("Add") { addClient() }
      Button("Cancel", role: .cancel) {}
    } message: {
      Text("Names can't be empty or duplicates.")
    }
    .alert("Rename Client", isPresented: Binding(
      get: { renamingClient != nil },
      set: { if !$0 { renamingClient = nil } }
    )) {
      TextField("New name", text: $renameName.max(DesignConstants.TextLimits.shortName))
      Button("Save") { renameClient() }
      Button("Cancel", role: .cancel) { renamingClient = nil }
    } message: {
      Text("Renaming updates existing trips that use the client.")
    }
    .confirmationDialog(
      "Delete Client?",
      isPresented: Binding(
        get: { deletingClient != nil },
        set: { if !$0 { deletingClient = nil } }
      ),
      titleVisibility: .visible
    ) {
      Button("Delete", role: .destructive) {
        deleteClient()
      }
      Button("Cancel", role: .cancel) {
        deletingClient = nil
      }
    } message: {
      Text("Trips using this client will have the client cleared.")
    }
  }

  private var headerCard: some View {
    GlassCard {
      VStack(alignment: .leading, spacing: 8) {
        Text("Manage Clients")
          .font(.headline)
        Text("Clients are optional and can be used for reporting.")
          .font(.footnote)
          .foregroundStyle(.secondary)
      }
    }
  }

  private var listCard: some View {
    GlassCard {
      VStack(alignment: .leading, spacing: 10) {
        HStack {
          Text("Clients")
            .font(.headline)
          Spacer(minLength: 0)
          Text("\(clientStore.clients.count)")
            .foregroundStyle(.secondary)
            .font(.subheadline)
            .accessibilityHidden(true)
        }

        if clientStore.clients.isEmpty {
          EmptyStateView(
            systemImage: "building.2",
            title: "No clients yet",
            subtitle: "Clients are optional and help with reporting.",
            actionTitle: "Add Client",
            action: {
              addName = ""
              isPresentingAdd = true
            }
          )
        } else {
          VStack(spacing: 10) {
            ForEach(clientStore.clients, id: \.self) { client in
              clientRow(client)
            }
          }
        }
      }
    }
  }

  private func clientRow(_ client: String) -> some View {
    HStack(spacing: 10) {
      Text(client)
        .font(.subheadline.weight(.semibold))
        .lineLimit(1)

      Spacer(minLength: 0)

      Button {
        renamingClient = client
        renameName = client
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
      .accessibilityLabel("Rename \(client)")

      Button(role: .destructive) {
        deletingClient = client
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
      .accessibilityLabel("Delete \(client)")
    }
    .accessibilityElement(children: .combine)
  }

  private func addClient() {
    let trimmed = addName.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !trimmed.isEmpty else {
      message = "Please enter a client name."
      return
    }
    if clientStore.add(trimmed) {
      message = nil
    } else {
      message = "That client already exists."
    }
  }

  private func renameClient() {
    guard let old = renamingClient else { return }
    let trimmed = renameName.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !trimmed.isEmpty else {
      message = "Name can’t be empty."
      return
    }

    if clientStore.rename(from: old, to: trimmed) {
      updateTripsRenamingClient(from: old, to: trimmed)
      message = nil
      renamingClient = nil
    } else {
      message = "Rename failed (duplicate or missing)."
    }
  }

  private func deleteClient() {
    guard let toDelete = deletingClient else { return }
    deletingClient = nil

    if clientStore.remove(toDelete) {
      updateTripsDeletingClient(toDelete)
      message = nil
    } else {
      message = "Delete failed."
    }
  }

  private func updateTripsRenamingClient(from old: String, to new: String) {
    for idx in tripStore.trips.indices {
      let current = tripStore.trips[idx].clientOrOrg?.trimmingCharacters(in: .whitespacesAndNewlines)
      guard let current, !current.isEmpty else { continue }
      if current.caseInsensitiveCompare(old) == .orderedSame {
        tripStore.trips[idx].clientOrOrg = new
      }
    }
  }

  private func updateTripsDeletingClient(_ name: String) {
    for idx in tripStore.trips.indices {
      let current = tripStore.trips[idx].clientOrOrg?.trimmingCharacters(in: .whitespacesAndNewlines)
      guard let current, !current.isEmpty else { continue }
      if current.caseInsensitiveCompare(name) == .orderedSame {
        tripStore.trips[idx].clientOrOrg = nil
      }
    }
  }
}

#Preview {
  NavigationStack {
    ManageClientsView()
  }
  .environmentObject(ClientsStore())
  .environmentObject(TripStore())
}

