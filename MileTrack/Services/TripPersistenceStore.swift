import Foundation

final class TripPersistenceStore {
  private let fileManager: FileManager
  private let encoder: JSONEncoder
  private let decoder: JSONDecoder
  private let fileURL: URL
  private let maxBackups = 3

  /// Number of trips that were skipped during the last load due to corruption.
  private(set) var lastLoadSkippedCount: Int = 0

  init(
    fileManager: FileManager = .default,
    encoder: JSONEncoder = JSONEncoder(),
    decoder: JSONDecoder = JSONDecoder(),
    filename: String = "trips.json"
  ) {
    self.fileManager = fileManager
    self.encoder = encoder
    self.decoder = decoder

    encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
    decoder.dateDecodingStrategy = .deferredToDate
    encoder.dateEncodingStrategy = .deferredToDate

    let base = Self.applicationSupportDirectory(fileManager: fileManager)
    self.fileURL = base.appendingPathComponent(filename, isDirectory: false)
  }

  // MARK: - Load

  /// Loads trips with per-trip error recovery. Corrupted individual trips are
  /// skipped rather than losing the entire file. Returns an empty array only
  /// if the file does not exist or contains zero decodable trips.
  func loadTrips() throws -> [Trip] {
    guard fileManager.fileExists(atPath: fileURL.path) else {
      lastLoadSkippedCount = 0
      return []
    }
    let data = try Data(contentsOf: fileURL)
    return decodeTripsIndividually(from: data)
  }

  /// Attempts primary file first, then falls back through backups.
  /// Returns empty array only if all sources are exhausted.
  func loadTripsWithFallback() -> (trips: [Trip], restoredFromBackup: Bool) {
    // Try primary file
    if let trips = try? loadTrips(), !trips.isEmpty {
      return (trips, false)
    }

    // Try backups in order (most recent first)
    for i in 1...maxBackups {
      let backupURL = backupURL(index: i)
      guard fileManager.fileExists(atPath: backupURL.path),
            let data = try? Data(contentsOf: backupURL)
      else { continue }

      let trips = decodeTripsIndividually(from: data)
      guard !trips.isEmpty else { continue }

      // Restore the backup as the primary file
      try? ensureDirectoryExists()
      try? data.write(to: fileURL, options: [.atomic, .completeFileProtection])
      return (trips, true)
    }

    lastLoadSkippedCount = 0
    return ([], false)
  }

  // MARK: - Save

  func saveTrips(_ trips: [Trip]) throws {
    try ensureDirectoryExists()
    rotateBackups()
    let data = try encoder.encode(trips)
    try data.write(to: fileURL, options: [.atomic, .completeFileProtection])
  }

  func reset() throws {
    // Remove primary file
    if fileManager.fileExists(atPath: fileURL.path) {
      try fileManager.removeItem(at: fileURL)
    }
    // Remove all backups
    for i in 1...maxBackups {
      let backup = backupURL(index: i)
      if fileManager.fileExists(atPath: backup.path) {
        try? fileManager.removeItem(at: backup)
      }
    }
  }

  // MARK: - Per-Trip Decoding

  /// Decodes trips one at a time. If an individual trip fails to decode,
  /// it is skipped and the rest of the array is preserved.
  private func decodeTripsIndividually(from data: Data) -> [Trip] {
    // First, try the fast path: decode the entire array at once.
    if let trips = try? decoder.decode([Trip].self, from: data) {
      lastLoadSkippedCount = 0
      return trips
    }

    // Fast path failed — at least one trip is corrupted.
    // Decode each element individually to salvage what we can.
    guard let rawArray = try? JSONSerialization.jsonObject(with: data) as? [[String: Any]] else {
      lastLoadSkippedCount = 0
      return []
    }

    var trips: [Trip] = []
    var skipped = 0

    for element in rawArray {
      guard let elementData = try? JSONSerialization.data(withJSONObject: element),
            let trip = try? decoder.decode(Trip.self, from: elementData)
      else {
        skipped += 1
        continue
      }
      trips.append(trip)
    }

    lastLoadSkippedCount = skipped
    return trips
  }

  // MARK: - Backup Rotation

  private func rotateBackups() {
    guard fileManager.fileExists(atPath: fileURL.path) else { return }

    // Remove oldest backup
    let oldest = backupURL(index: maxBackups)
    try? fileManager.removeItem(at: oldest)

    // Shift existing backups: 2→3, 1→2
    for i in stride(from: maxBackups - 1, through: 1, by: -1) {
      let source = backupURL(index: i)
      let dest = backupURL(index: i + 1)
      if fileManager.fileExists(atPath: source.path) {
        try? fileManager.moveItem(at: source, to: dest)
      }
    }

    // Copy current file to backup_1
    try? fileManager.copyItem(at: fileURL, to: backupURL(index: 1))
  }

  private func backupURL(index: Int) -> URL {
    let dir = fileURL.deletingLastPathComponent()
    return dir.appendingPathComponent("trips_backup_\(index).json", isDirectory: false)
  }

  // MARK: - Paths

  private func ensureDirectoryExists() throws {
    let dir = fileURL.deletingLastPathComponent()
    if !fileManager.fileExists(atPath: dir.path) {
      try fileManager.createDirectory(at: dir, withIntermediateDirectories: true)
    }
  }

  private static func applicationSupportDirectory(fileManager: FileManager) -> URL {
    let base = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
      ?? URL(fileURLWithPath: NSHomeDirectory()).appendingPathComponent("Library/Application Support")
    let bundleID = Bundle.main.bundleIdentifier ?? "MileTrack"
    return base.appendingPathComponent(bundleID, isDirectory: true)
  }
}
