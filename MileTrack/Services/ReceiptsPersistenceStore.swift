import Foundation

final class ReceiptsPersistenceStore {
  private let fileManager: FileManager
  private let encoder: JSONEncoder
  private let decoder: JSONDecoder
  private let metadataURL: URL
  private let imagesDirectory: URL
  
  init(
    fileManager: FileManager = .default,
    encoder: JSONEncoder = JSONEncoder(),
    decoder: JSONDecoder = JSONDecoder()
  ) {
    self.fileManager = fileManager
    self.encoder = encoder
    self.decoder = decoder
    encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
    
    let base = Self.applicationSupportDirectory(fileManager: fileManager)
    self.metadataURL = base.appendingPathComponent("receipts.json", isDirectory: false)
    self.imagesDirectory = base.appendingPathComponent("Receipts", isDirectory: true)
  }
  
  func loadReceipts() throws -> [TripReceipt] {
    guard fileManager.fileExists(atPath: metadataURL.path) else { return [] }
    let data = try Data(contentsOf: metadataURL)
    return try decoder.decode([TripReceipt].self, from: data)
  }
  
  func saveReceipts(_ receipts: [TripReceipt]) throws {
    try ensureDirectoriesExist()
    let data = try encoder.encode(receipts)
    try data.write(to: metadataURL, options: [.atomic, .completeFileProtection])
  }
  
  func saveImage(_ imageData: Data, fileName: String) throws -> String {
    try ensureDirectoriesExist()
    let sanitizedFileName = sanitizeFileName(fileName)
    let fileURL = imagesDirectory.appendingPathComponent(sanitizedFileName)
    try imageData.write(to: fileURL, options: [.atomic, .completeFileProtection])
    return sanitizedFileName
  }
  
  func loadImage(fileName: String) throws -> Data {
    let fileURL = imagesDirectory.appendingPathComponent(fileName)
    return try Data(contentsOf: fileURL)
  }
  
  func deleteImage(fileName: String) throws {
    let fileURL = imagesDirectory.appendingPathComponent(fileName)
    guard fileManager.fileExists(atPath: fileURL.path) else { return }
    try fileManager.removeItem(at: fileURL)
  }
  
  func reset() throws {
    // Remove metadata file
    if fileManager.fileExists(atPath: metadataURL.path) {
      try fileManager.removeItem(at: metadataURL)
    }
    
    // Remove images directory
    if fileManager.fileExists(atPath: imagesDirectory.path) {
      try fileManager.removeItem(at: imagesDirectory)
    }
  }
  
  private func ensureDirectoriesExist() throws {
    // Create app support directory
    let appSupportDir = metadataURL.deletingLastPathComponent()
    if !fileManager.fileExists(atPath: appSupportDir.path) {
      try fileManager.createDirectory(at: appSupportDir, withIntermediateDirectories: true)
    }
    
    // Create images directory
    if !fileManager.fileExists(atPath: imagesDirectory.path) {
      try fileManager.createDirectory(at: imagesDirectory, withIntermediateDirectories: true)
    }
  }
  
  private func sanitizeFileName(_ fileName: String) -> String {
    // Remove or replace problematic characters
    let invalidCharacters = CharacterSet(charactersIn: "/\\:*?\"<>|")
    let components = fileName.components(separatedBy: invalidCharacters)
    var sanitized = components.joined(separator: "_")
    
    // Ensure file name isn't empty
    if sanitized.isEmpty {
      sanitized = UUID().uuidString
    }
    
    return sanitized
  }
  
  private static func applicationSupportDirectory(fileManager: FileManager) -> URL {
    let base = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
      ?? URL(fileURLWithPath: NSHomeDirectory()).appendingPathComponent("Library/Application Support")
    let bundleID = Bundle.main.bundleIdentifier ?? "MileTrack"
    return base.appendingPathComponent(bundleID, isDirectory: true)
  }
}
