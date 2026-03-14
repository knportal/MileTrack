import Combine
import CoreLocation
import Foundation

@MainActor
final class LocationsStore: ObservableObject {
  @Published var locations: [NamedLocation]
  @Published var lastSaveError: String?

  private let persistence: LocationsPersistenceStore
  private var cancellables: Set<AnyCancellable> = []

  static let defaultSeed: [NamedLocation] = [
    NamedLocation(name: "Home", address: ""),
    NamedLocation(name: "Work", address: ""),
  ]

  init(
    locations: [NamedLocation]? = nil,
    persistence: LocationsPersistenceStore? = nil
  ) {
    let persistenceStore = persistence ?? LocationsPersistenceStore()
    self.persistence = persistenceStore

    if let locations {
      self.locations = locations
    } else if let loaded = try? persistenceStore.loadLocations(), !loaded.isEmpty {
      self.locations = loaded
    } else {
      self.locations = Self.defaultSeed
    }

    $locations
      .dropFirst()
      .debounce(for: .milliseconds(450), scheduler: RunLoop.main)
      .sink { [weak self] newValue in
        self?.persist(newValue)
      }
      .store(in: &cancellables)
  }

  func add(name: String, address: String, latitude: Double? = nil, longitude: Double? = nil) -> Bool {
    let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !trimmedName.isEmpty else { return false }
    guard !containsNameCaseInsensitive(trimmedName) else { return false }
    let location = NamedLocation(name: trimmedName, address: address.trimmingCharacters(in: .whitespacesAndNewlines), latitude: latitude, longitude: longitude)
    locations.append(location)
    return true
  }

  func update(_ location: NamedLocation) -> Bool {
    guard let idx = locations.firstIndex(where: { $0.id == location.id }) else { return false }
    let trimmedName = location.name.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !trimmedName.isEmpty else { return false }
    // Check for duplicate name (excluding current location)
    let isDuplicate = locations.contains { $0.id != location.id && $0.name.caseInsensitiveCompare(trimmedName) == .orderedSame }
    guard !isDuplicate else { return false }
    locations[idx] = NamedLocation(
      id: location.id,
      name: trimmedName,
      address: location.address.trimmingCharacters(in: .whitespacesAndNewlines)
    )
    return true
  }

  func remove(_ location: NamedLocation) -> Bool {
    let before = locations.count
    locations.removeAll { $0.id == location.id }
    return locations.count != before
  }

  func location(named name: String) -> NamedLocation? {
    locations.first { $0.name.caseInsensitiveCompare(name) == .orderedSame }
  }

  func resetToDefaults() {
    locations = Self.defaultSeed
    do { try persistence.reset() } catch { /* best-effort */ }
  }

  func saveNow() {
    persist(locations)
  }

  private func persist(_ value: [NamedLocation]) {
    do {
      try persistence.saveLocations(value)
      lastSaveError = nil
    } catch {
      lastSaveError = "Failed to save locations: \(error.localizedDescription)"
    }
  }

  /// Find the nearest saved location within a given radius (meters).
  /// Returns the location and distance, or nil if nothing is close enough.
  func nearest(to location: CLLocation, withinMeters radius: Double = 150) -> (location: NamedLocation, distance: Double)? {
    var best: (location: NamedLocation, distance: Double)?
    for saved in locations {
      guard let dist = saved.distance(from: location) else { continue }
      if dist <= radius {
        if best == nil || dist < best!.distance {
          best = (saved, dist)
        }
      }
    }
    return best
  }

  private func containsNameCaseInsensitive(_ name: String) -> Bool {
    locations.contains { $0.name.caseInsensitiveCompare(name) == .orderedSame }
  }
}
