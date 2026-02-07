import Foundation

final class TripPersistenceStore {
  private let fileManager: FileManager
  private let encoder: JSONEncoder
  private let decoder: JSONDecoder
  private let fileURL: URL

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

  func loadTrips() throws -> [Trip] {
    guard fileManager.fileExists(atPath: fileURL.path) else { return [] }
    let data = try Data(contentsOf: fileURL)
    return try decoder.decode([Trip].self, from: data)
  }

  func saveTrips(_ trips: [Trip]) throws {
    try ensureDirectoryExists()
    let data = try encoder.encode(trips)
    try data.write(to: fileURL, options: [.atomic])
  }

  func reset() throws {
    guard fileManager.fileExists(atPath: fileURL.path) else { return }
    try fileManager.removeItem(at: fileURL)
  }

  // MARK: - Paths

  private func ensureDirectoryExists() throws {
    let dir = fileURL.deletingLastPathComponent()
    if !fileManager.fileExists(atPath: dir.path) {
      try fileManager.createDirectory(at: dir, withIntermediateDirectories: true)
    }
  }

  private static func applicationSupportDirectory(fileManager: FileManager) -> URL {
    let base = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
    let bundleID = Bundle.main.bundleIdentifier ?? "MileTrack"
    return base.appendingPathComponent(bundleID, isDirectory: true)
  }
}

