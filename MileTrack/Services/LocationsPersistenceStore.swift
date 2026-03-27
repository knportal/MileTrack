import Foundation

final class LocationsPersistenceStore {
  private let fileManager: FileManager
  private let encoder: JSONEncoder
  private let decoder: JSONDecoder
  private let fileURL: URL

  init(
    fileManager: FileManager = .default,
    encoder: JSONEncoder = JSONEncoder(),
    decoder: JSONDecoder = JSONDecoder(),
    filename: String = "named_locations.json"
  ) {
    self.fileManager = fileManager
    self.encoder = encoder
    self.decoder = decoder
    encoder.outputFormatting = [.prettyPrinted, .sortedKeys]

    let base = Self.applicationSupportDirectory(fileManager: fileManager)
    self.fileURL = base.appendingPathComponent(filename, isDirectory: false)
  }

  func loadLocations() throws -> [NamedLocation] {
    guard fileManager.fileExists(atPath: fileURL.path) else { return [] }
    let data = try Data(contentsOf: fileURL)
    return try decoder.decode([NamedLocation].self, from: data)
  }

  func saveLocations(_ locations: [NamedLocation]) throws {
    try ensureDirectoryExists()
    let data = try encoder.encode(locations)
    try data.write(to: fileURL, options: [.atomic, .completeFileProtection])
  }

  func reset() throws {
    guard fileManager.fileExists(atPath: fileURL.path) else { return }
    try fileManager.removeItem(at: fileURL)
  }

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
