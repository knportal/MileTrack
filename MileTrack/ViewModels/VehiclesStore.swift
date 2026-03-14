import Combine
import Foundation

@MainActor
final class VehiclesStore: ObservableObject {
  @Published var vehicles: [NamedVehicle]
  @Published var lastSaveError: String?

  private let persistence: VehiclesPersistenceStore
  private var cancellables: Set<AnyCancellable> = []

  init(
    vehicles: [NamedVehicle]? = nil,
    persistence: VehiclesPersistenceStore? = nil
  ) {
    let persistenceStore = persistence ?? VehiclesPersistenceStore()
    self.persistence = persistenceStore

    if let vehicles {
      self.vehicles = vehicles
    } else if let loaded = try? persistenceStore.loadVehicles(), !loaded.isEmpty {
      self.vehicles = loaded
    } else {
      self.vehicles = []
    }

    $vehicles
      .dropFirst()
      .debounce(for: .milliseconds(450), scheduler: RunLoop.main)
      .sink { [weak self] newValue in
        self?.persist(newValue)
      }
      .store(in: &cancellables)
  }

  func add(name: String, licensePlate: String = "", notes: String = "") -> Bool {
    let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !trimmedName.isEmpty else { return false }
    guard !containsNameCaseInsensitive(trimmedName) else { return false }
    let vehicle = NamedVehicle(
      name: trimmedName,
      licensePlate: licensePlate.trimmingCharacters(in: .whitespacesAndNewlines),
      notes: notes.trimmingCharacters(in: .whitespacesAndNewlines)
    )
    vehicles.append(vehicle)
    return true
  }

  func update(_ vehicle: NamedVehicle) -> Bool {
    guard let idx = vehicles.firstIndex(where: { $0.id == vehicle.id }) else { return false }
    let trimmedName = vehicle.name.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !trimmedName.isEmpty else { return false }
    // Check for duplicate name (excluding current vehicle)
    let isDuplicate = vehicles.contains { $0.id != vehicle.id && $0.name.caseInsensitiveCompare(trimmedName) == .orderedSame }
    guard !isDuplicate else { return false }
    vehicles[idx] = NamedVehicle(
      id: vehicle.id,
      name: trimmedName,
      licensePlate: vehicle.licensePlate.trimmingCharacters(in: .whitespacesAndNewlines),
      notes: vehicle.notes.trimmingCharacters(in: .whitespacesAndNewlines)
    )
    return true
  }

  func remove(_ vehicle: NamedVehicle) -> Bool {
    let before = vehicles.count
    vehicles.removeAll { $0.id == vehicle.id }
    return vehicles.count != before
  }

  func vehicle(named name: String) -> NamedVehicle? {
    vehicles.first { $0.name.caseInsensitiveCompare(name) == .orderedSame }
  }

  func saveNow() {
    persist(vehicles)
  }

  private func persist(_ value: [NamedVehicle]) {
    do {
      try persistence.saveVehicles(value)
      lastSaveError = nil
    } catch {
      lastSaveError = "Failed to save vehicles: \(error.localizedDescription)"
    }
  }

  private func containsNameCaseInsensitive(_ name: String) -> Bool {
    vehicles.contains { $0.name.caseInsensitiveCompare(name) == .orderedSame }
  }
}
