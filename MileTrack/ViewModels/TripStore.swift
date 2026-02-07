import Foundation
import Combine

/// In-memory trip store used for SwiftUI previews and UI state only.
@MainActor
final class TripStore: ObservableObject {
  @Published var trips: [Trip]
  private let persistence: TripPersistenceStore
  private var cancellables: Set<AnyCancellable> = []

  init(
    trips: [Trip]? = nil,
    persistence: TripPersistenceStore? = nil
  ) {
    // Avoid evaluating a potentially `@MainActor` default argument at the call site.
    let persistenceStore = persistence ?? TripPersistenceStore()
    self.persistence = persistenceStore

    if let trips {
      self.trips = trips
    } else if let loaded = try? persistenceStore.loadTrips(), !loaded.isEmpty {
      self.trips = loaded
    } else {
      self.trips = Self.makeMockTrips()
    }

    $trips
      .dropFirst()
      .debounce(for: .milliseconds(450), scheduler: RunLoop.main)
      .sink { [weak self] newValue in
        self?.persist(newValue)
      }
      .store(in: &cancellables)
  }

  var pendingTrips: [Trip] {
    trips
      .filter { $0.state == .pendingCategory }
      .sorted { $0.date > $1.date }
  }

  var confirmedTrips: [Trip] {
    trips
      .filter { $0.state == .confirmed }
      .sorted { $0.date > $1.date }
  }

  /// Mock trips for previews and local UI state.
  /// Kept `@MainActor` because it’s used by `TripStore` initialization/SwiftUI previews.
  static func makeMockTrips(now: Date = Date()) -> [Trip] {
    [
      // Inbox (pending_category) — auto-detected, not "real" until categorized + confirmed
      Trip(
        date: now.addingTimeInterval(-1 * 60 * 60),
        distanceMiles: 5.2,
        durationSeconds: 18 * 60,
        startLabel: "Home",
        endLabel: "Downtown",
        source: .auto,
        state: .pendingCategory,
        category: nil,
        clientOrOrg: nil,
        notes: "Auto-detected"
      ),
      Trip(
        date: now.addingTimeInterval(-5 * 60 * 60),
        distanceMiles: 12.8,
        durationSeconds: 32 * 60,
        startLabel: "Warehouse",
        endLabel: "Client Site",
        source: .auto,
        state: .pendingCategory,
        category: nil,
        clientOrOrg: "Acme Co.",
        notes: nil
      ),
      Trip(
        date: now.addingTimeInterval(-28 * 60 * 60),
        distanceMiles: 2.4,
        durationSeconds: 9 * 60,
        startLabel: "Office",
        endLabel: "Coffee",
        source: .auto,
        state: .pendingCategory,
        category: nil,
        clientOrOrg: nil,
        notes: nil
      ),

      // Confirmed — appears in Home + Reports
      Trip(
        date: now.addingTimeInterval(-2 * 24 * 60 * 60),
        distanceMiles: 8.1,
        durationSeconds: 24 * 60,
        startLabel: "Office",
        endLabel: "Client",
        source: .manual,
        state: .confirmed,
        category: TripCategory.business.stringValue,
        clientOrOrg: "Globex",
        notes: "Meeting"
      ),
      Trip(
        date: now.addingTimeInterval(-4 * 24 * 60 * 60),
        distanceMiles: 16.0,
        durationSeconds: 44 * 60,
        startLabel: "Home",
        endLabel: "Airport",
        source: .manual,
        state: .confirmed,
        category: TripCategory.education.stringValue,
        clientOrOrg: nil,
        notes: nil
      ),
      Trip(
        date: now.addingTimeInterval(-7 * 24 * 60 * 60),
        distanceMiles: 3.6,
        durationSeconds: 14 * 60,
        startLabel: "Home",
        endLabel: "Volunteer Center",
        source: .manual,
        state: .confirmed,
        category: TripCategory.volunteer.stringValue,
        clientOrOrg: nil,
        notes: nil
      ),
    ]
  }

  func save() {
    persist(trips)
  }

  func resetDemoData() {
    trips = Self.makeMockTrips()
    do { try persistence.reset() } catch { /* best-effort */ }
  }

  private func persist(_ value: [Trip]) {
    do {
      try persistence.saveTrips(value)
    } catch {
      // Best-effort persistence: ignore write failures in UI-only store.
    }
  }
}

