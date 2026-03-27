import Foundation
import Combine

/// Backs up and syncs trip data to/from the user's private iCloud Drive container.
///
/// **Required Xcode setup (one-time):**
/// 1. Select the MileTrack target → Signing & Capabilities → + Capability → iCloud
/// 2. Under Services, enable "iCloud Documents"
/// 3. Under Containers, add or generate a container identifier (format: iCloud.{bundle-id})
///
/// The service degrades gracefully when iCloud is unavailable (not signed in,
/// not configured, airplane mode, etc.). All sync operations are no-ops in that case.
@MainActor
final class iCloudSyncService: ObservableObject {

  enum SyncStatus: Equatable {
    case unavailable    // iCloud not configured or user not signed in
    case idle           // Ready; last sync succeeded (or never run)
    case syncing        // Upload/download in progress
    case error(String)  // Last operation failed

    var displayLabel: String {
      switch self {
      case .unavailable: return "Not available"
      case .idle: return "On"
      case .syncing: return "Syncing…"
      case .error: return "Error"
      }
    }

    var systemImage: String {
      switch self {
      case .unavailable: return "icloud.slash"
      case .idle: return "checkmark.icloud"
      case .syncing: return "arrow.triangle.2.circlepath.icloud"
      case .error: return "exclamationmark.icloud"
      }
    }

    var isError: Bool {
      if case .error = self { return true }
      return false
    }
  }

  @Published private(set) var status: SyncStatus = .unavailable
  @Published private(set) var lastSyncDate: Date?

  private static let fileName = "trips.json"
  private static let containerID = "iCloud.\(Bundle.main.bundleIdentifier ?? "ai.plenitudo.MileTrack")"
  // Max seconds to wait for iCloud to download a file before giving up.
  private nonisolated static let downloadTimeoutSeconds: Double = 6

  // Published so UI reacts when iCloud becomes available after a brief delay.
  @Published private(set) var containerURL: URL?

  // Queued backup waiting for the container URL to resolve.
  private var pendingBackupTrips: [Trip]?

  init() {
    // url(forUbiquityContainerIdentifier:) must NOT be called on the main thread —
    // it can block and will return nil if iCloud isn't ready yet at launch.
    // Fetch it on a background thread and retry until available (up to ~10s).
    Task {
      await self.resolveContainerURL()
    }
  }

  var isAvailable: Bool { containerURL != nil }

  // MARK: - Container resolution (async, with retry)

  private func resolveContainerURL() async {
    let id = Self.containerID
    // Retry up to 10 times, 1 second apart (covers iCloud warm-up on launch).
    for attempt in 1...10 {
      let url = await Task.detached(priority: .utility) {
        FileManager.default.url(forUbiquityContainerIdentifier: id)
      }.value

      if let ubiquityURL = url {
        containerURL = ubiquityURL.appendingPathComponent("Documents", isDirectory: true)
        status = .idle
        #if DEBUG
        print("[iCloudSync] container resolved on attempt \(attempt): \(containerURL!.path)")
        #endif
        // If a backup was attempted before the URL resolved, flush it now.
        if let queued = pendingBackupTrips {
          pendingBackupTrips = nil
          await backup(trips: queued)
        }
        return
      }

      #if DEBUG
      print("[iCloudSync] attempt \(attempt): container URL nil, retrying in 1s…")
      #endif
      try? await Task.sleep(nanoseconds: 1_000_000_000)
    }

    // After 10 attempts, iCloud is genuinely unavailable (not signed in, no capability, etc.)
    status = .unavailable
    #if DEBUG
    print("[iCloudSync] container URL could not be resolved after 10 attempts — iCloud unavailable")
    #endif
  }

  // MARK: - Backup (upload)

  /// Encode and upload the full trip list to iCloud Drive.
  /// Called after every debounced local save.
  func backup(trips: [Trip]) async {
    guard let dir = containerURL else {
      // Container URL not yet resolved — queue for when it becomes available.
      pendingBackupTrips = trips
      #if DEBUG
      print("[iCloudSync] backup queued (\(trips.count) trips) — container URL not yet ready")
      #endif
      return
    }
    status = .syncing

    let fileURL = dir.appendingPathComponent(Self.fileName)
    #if DEBUG
    print("[iCloudSync] backup starting — \(trips.count) trips → \(fileURL.path)")
    #endif

    do {
      let encoder = makeEncoder()
      let data = try encoder.encode(trips)
      try await coordinatedWrite(data: data, to: fileURL, creatingDirectory: dir)
      status = .idle
      lastSyncDate = Date()
      #if DEBUG
      print("[iCloudSync] backup succeeded ✓ (\(data.count) bytes)")
      #endif
    } catch {
      status = .error(error.localizedDescription)
      #if DEBUG
      print("[iCloudSync] backup FAILED: \(error)")
      #endif
    }
  }

  // MARK: - Restore / Merge (download)

  /// Fetch trips from iCloud and merge with the provided local trips.
  /// Returns the merged set only if iCloud contributed at least one new UUID;
  /// returns nil if nothing changed or iCloud was unavailable.
  func fetchAndMerge(localTrips: [Trip]) async -> [Trip]? {
    guard let dir = containerURL else { return nil }
    status = .syncing

    let fileURL = dir.appendingPathComponent(Self.fileName)

    do {
      let cloudTrips = try await coordinatedRead(from: fileURL)
      let merged = mergeTrips(local: localTrips, remote: cloudTrips)

      // Only signal a change if the merge actually added new UUIDs.
      let localIDs = Set(localTrips.map(\.id))
      let mergedIDs = Set(merged.map(\.id))
      status = .idle
      lastSyncDate = Date()
      return mergedIDs == localIDs ? nil : merged
    } catch {
      // Not an error if the cloud file simply doesn't exist yet (first backup pending).
      let isNoSuchFile = (error as? CocoaError)?.code == .fileNoSuchFile
        || (error as NSError).code == NSFileNoSuchFileError
      status = isNoSuchFile ? .idle : .error(error.localizedDescription)
      return nil
    }
  }

  // MARK: - Merge logic

  /// Union merge: keep all unique trips from both sets.
  /// For the same UUID, pick the version with higher state priority:
  /// confirmed (2) > pendingCategory (1) > ignored (0).
  /// If states are equal, local wins.
  func mergeTrips(local: [Trip], remote: [Trip]) -> [Trip] {
    var byID = Dictionary(uniqueKeysWithValues: local.map { ($0.id, $0) })
    for remoteTrip in remote {
      if let localTrip = byID[remoteTrip.id] {
        byID[remoteTrip.id] = preferredVersion(local: localTrip, remote: remoteTrip)
      } else {
        byID[remoteTrip.id] = remoteTrip   // New trip from another device
      }
    }
    return byID.values.sorted { $0.date > $1.date }
  }

  private func preferredVersion(local: Trip, remote: Trip) -> Trip {
    let priority: [TripState: Int] = [.confirmed: 2, .pendingCategory: 1, .ignored: 0]
    let lp = priority[local.state] ?? 0
    let rp = priority[remote.state] ?? 0
    if lp != rp { return lp > rp ? local : remote }
    return local   // Same state: local is authoritative
  }

  // MARK: - NSFileCoordinator helpers (run off main actor)

  private func coordinatedWrite(data: Data, to fileURL: URL, creatingDirectory dir: URL) async throws {
    try await Task.detached(priority: .utility) {
      let fm = FileManager.default
      if !fm.fileExists(atPath: dir.path) {
        try fm.createDirectory(at: dir, withIntermediateDirectories: true)
      }
      var coordinatorError: NSError?
      var writeError: Error?
      NSFileCoordinator().coordinate(
        writingItemAt: fileURL, options: .forReplacing,
        error: &coordinatorError
      ) { url in
        do { try data.write(to: url, options: [.atomic, .completeFileProtection]) }
        catch { writeError = error }
      }
      if let err = coordinatorError ?? writeError { throw err }
    }.value
  }

  private func coordinatedRead(from fileURL: URL) async throws -> [Trip] {
    // File I/O on a background thread — returns raw Data so we avoid calling
    // @MainActor-isolated Trip.Decodable from a nonisolated context (Swift 6).
    let rawData: Data = try await Task.detached(priority: .utility) { () async throws -> Data in
      let fm = FileManager.default
      guard fm.fileExists(atPath: fileURL.path) else {
        throw CocoaError(.fileNoSuchFile)
      }

      // Tell iCloud to download the file if it's metadata-only (cloud-resident).
      try? fm.startDownloadingUbiquitousItem(at: fileURL)

      // Poll until downloaded or timeout.
      let deadline = Date().addingTimeInterval(iCloudSyncService.downloadTimeoutSeconds)
      while Date() < deadline {
        let values = try? fileURL.resourceValues(forKeys: [.ubiquitousItemDownloadingStatusKey])
        if values?.ubiquitousItemDownloadingStatus == .current { break }
        try await Task.sleep(nanoseconds: 300_000_000)
      }

      var coordinatorError: NSError?
      var cloudData: Data?
      NSFileCoordinator().coordinate(
        readingItemAt: fileURL, options: .withoutChanges,
        error: &coordinatorError
      ) { url in
        cloudData = try? Data(contentsOf: url)
      }
      if let err = coordinatorError { throw err }
      guard let data = cloudData else { throw CocoaError(.fileReadNoPermission) }
      return data
    }.value

    // Decode on the main actor where Trip.Decodable conformance is accessible.
    return Self.decodeTrips(from: rawData)
  }

  // MARK: - Resilient decoding

  /// Mirrors TripPersistenceStore's per-trip fallback decoding strategy.
  private static func decodeTrips(from data: Data) -> [Trip] {
    let decoder = JSONDecoder()
    decoder.dateDecodingStrategy = .deferredToDate
    if let trips = try? decoder.decode([Trip].self, from: data) { return trips }
    guard let raw = try? JSONSerialization.jsonObject(with: data) as? [[String: Any]] else { return [] }
    return raw.compactMap { element in
      guard let d = try? JSONSerialization.data(withJSONObject: element) else { return nil }
      return try? decoder.decode(Trip.self, from: d)
    }
  }

  private func makeEncoder() -> JSONEncoder {
    let enc = JSONEncoder()
    enc.outputFormatting = [.prettyPrinted, .sortedKeys]
    enc.dateEncodingStrategy = .deferredToDate
    return enc
  }
}
