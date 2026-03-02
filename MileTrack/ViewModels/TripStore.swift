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

  /// iCloud sync service. Observe this for live status in UI.
  let iCloudSync = iCloudSyncService()

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

    // Forward iCloud status changes so any view observing TripStore re-renders.
    iCloudSync.objectWillChange
      .sink { [weak self] in self?.objectWillChange.send() }
      .store(in: &cancellables)

    // On real launches (not preview injection), check iCloud for any trips
    // from other devices or restored after device loss.
    // The container URL resolves asynchronously (url(forUbiquityContainerIdentifier:) can
    // return nil if called too early). We observe $containerURL and react once it resolves.
    if trips == nil {
      iCloudSync.$containerURL
        .compactMap { $0 }          // skip nil values
        .prefix(1)                   // only trigger once per launch
        .sink { [weak self] (_: URL) in
          Task { [weak self] in
            guard let self else { return }
            // 1. Pull any trips from other devices / restored after device loss.
            await self.syncFromCloudOnLaunch()
            // 2. Always push current trips on first resolve — this creates the
            //    iCloud folder and trips.json even if nothing changed locally.
            await self.iCloudSync.backup(trips: self.trips)
          }
        }
        .store(in: &cancellables)
    }
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
    Task { [weak self] in
      guard let self else { return }
      await self.iCloudSync.backup(trips: self.trips)
    }
  }

  // MARK: - iCloud sync

  /// Check iCloud for any trips not in the local store (added on another device,
  /// or restored after device loss). Silently no-ops if iCloud is unavailable.
  private func syncFromCloudOnLaunch() async {
    guard let merged = await iCloudSync.fetchAndMerge(localTrips: trips) else { return }
    // fetchAndMerge returns nil when nothing changed — only update if there are new UUIDs.
    trips = merged
  }

  // MARK: - Merge

  /// Merges two or more trips into one. Source trips are marked .ignored (audit trail preserved).
  /// The merged state is .confirmed if all sources are confirmed, otherwise .pendingCategory.
  /// Returns the merged trip, or nil if fewer than 2 trips are provided.
  @discardableResult
  func merge(trips: [Trip]) -> Trip? {
    guard trips.count >= 2 else { return nil }

    let sorted = trips.sorted { $0.date < $1.date }
    let earliest = sorted.first!
    let latest = sorted.last!

    let totalMiles = trips.reduce(0.0) { $0 + $1.distanceMiles }
    let totalDuration = trips.reduce(0) { $0 + ($1.durationSeconds ?? 0) }

    func commonValue(_ values: [String?]) -> String? {
      let trimmed = values.map { $0?.trimmingCharacters(in: .whitespacesAndNewlines) }
        .map { ($0?.isEmpty ?? true) ? nil : $0 }
      guard let first = trimmed.first, let unwrapped = first else { return nil }
      return trimmed.allSatisfy { ($0 ?? "").caseInsensitiveCompare(unwrapped) == .orderedSame } ? unwrapped : nil
    }

    let notesParts = trips
      .compactMap { $0.notes?.trimmingCharacters(in: .whitespacesAndNewlines) }
      .filter { !$0.isEmpty }

    let allConfirmed = trips.allSatisfy { $0.state == .confirmed }
    let vehicleUUIDs = trips.compactMap(\.vehicleID)
    let sharedVehicle: UUID? = vehicleUUIDs.count == trips.count && Set(vehicleUUIDs).count == 1 ? vehicleUUIDs.first : nil

    let merged = Trip(
      date: earliest.date,
      distanceMiles: totalMiles,
      durationSeconds: totalDuration > 0 ? totalDuration : nil,
      startLabel: earliest.startLabel,
      endLabel: latest.endLabel,
      startAddress: earliest.startAddress,
      endAddress: latest.endAddress,
      startLatitude: earliest.startLatitude,
      startLongitude: earliest.startLongitude,
      endLatitude: latest.endLatitude,
      endLongitude: latest.endLongitude,
      source: .auto,
      state: allConfirmed ? .confirmed : .pendingCategory,
      category: commonValue(trips.map(\.category)),
      clientOrOrg: commonValue(trips.map(\.clientOrOrg)),
      projectCode: commonValue(trips.map(\.projectCode)),
      notes: notesParts.isEmpty ? nil : notesParts.joined(separator: " | "),
      purpose: commonValue(trips.map(\.purpose)),
      vehicleID: sharedVehicle
    )

    let sourceIDs = Set(trips.map(\.id))
    for idx in self.trips.indices where sourceIDs.contains(self.trips[idx].id) {
      self.trips[idx].state = .ignored
    }
    self.trips.insert(merged, at: 0)
    return merged
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
    // Mirror every local save to iCloud — runs off the main actor in a background task.
    Task { [weak self] in
      guard let self else { return }
      await self.iCloudSync.backup(trips: value)
    }
  }
}

