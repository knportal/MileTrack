import Foundation
import Combine
import CoreLocation

/// In-memory trip store used for SwiftUI previews and UI state only.
@MainActor
final class TripStore: ObservableObject {
  @Published var trips: [Trip]
  private let persistence: TripPersistenceStore
  private let geocoder = ReverseGeocodeService()
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
    } else {
      let result = persistenceStore.loadTripsWithFallback()
      self.trips = result.trips
      #if DEBUG
      if result.restoredFromBackup {
        print("[TripStore] restored \(result.trips.count) trips from backup")
      }
      if persistenceStore.lastLoadSkippedCount > 0 {
        print("[TripStore] skipped \(persistenceStore.lastLoadSkippedCount) corrupted trips")
      }
      #endif
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

  // MARK: - Debug / Preview helpers

  #if DEBUG
  /// Mock trips for SwiftUI previews only. Never loaded for real users.
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

  func resetDemoData() {
    trips = Self.makeMockTrips()
    do { try persistence.reset() } catch { /* best-effort */ }
  }
  #endif

  /// Immediately persists current trips to disk, bypassing the debounce timer.
  /// Call this when the app enters the background to prevent data loss.
  func saveNow() {
    persist(trips)
  }

  /// Retry geocoding for trips with placeholder labels and stored coordinates.
  /// Call this on app launch to resolve addresses that failed while offline.
  func retryFailedGeocoding() {
    Task {
      for (index, trip) in trips.enumerated() {
        // Only retry if we have placeholder labels and stored coordinates
        let hasPlaceholderStart = trip.startLabel == "Trip start"
        let hasPlaceholderEnd = trip.endLabel == "Trip end"
        
        if hasPlaceholderStart, let lat = trip.startLatitude, let lon = trip.startLongitude {
          let location = CLLocation(latitude: lat, longitude: lon)
          if let result = await geocoder.addresses(for: location) {
            await MainActor.run {
              if index < trips.count && trips[index].id == trip.id {
                trips[index].startLabel = result.shortLabel
                trips[index].startAddress = result.fullAddress
              }
            }
          }
        }
        
        if hasPlaceholderEnd, let lat = trip.endLatitude, let lon = trip.endLongitude {
          let location = CLLocation(latitude: lat, longitude: lon)
          if let result = await geocoder.addresses(for: location) {
            await MainActor.run {
              if index < trips.count && trips[index].id == trip.id {
                trips[index].endLabel = result.shortLabel
                trips[index].endAddress = result.fullAddress
              }
            }
          }
        }
      }
    }
  }

  private func persist(_ value: [Trip]) {
    do {
      try persistence.saveTrips(value)
    } catch {
      // Best-effort persistence: ignore write failures in UI-only store.
    }
  }
}

