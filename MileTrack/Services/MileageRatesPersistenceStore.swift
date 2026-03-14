import Foundation

final class MileageRatesPersistenceStore {
  private let fileManager: FileManager
  private let encoder: JSONEncoder
  private let decoder: JSONDecoder
  private let fileURL: URL
  
  init(
    fileManager: FileManager = .default,
    encoder: JSONEncoder = JSONEncoder(),
    decoder: JSONDecoder = JSONDecoder(),
    filename: String = "mileage_rates.json"
  ) {
    self.fileManager = fileManager
    self.encoder = encoder
    self.decoder = decoder
    encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
    
    let base = Self.applicationSupportDirectory(fileManager: fileManager)
    self.fileURL = base.appendingPathComponent(filename, isDirectory: false)
  }
  
  func loadRates() throws -> [MileageRate] {
    guard fileManager.fileExists(atPath: fileURL.path) else {
      // Return default rates on first launch
      return MileageRate.defaultRates
    }
    let data = try Data(contentsOf: fileURL)
    return try decoder.decode([MileageRate].self, from: data)
  }
  
  func saveRates(_ rates: [MileageRate]) throws {
    try ensureDirectoryExists()
    let data = try encoder.encode(rates)
    try data.write(to: fileURL, options: [.atomic])
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
