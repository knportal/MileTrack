import Foundation

/// Lightweight, thread-safe file logger for on-device diagnostics.
///
/// Writes newline-delimited lines to Application Support `diagnostics.log`:
/// `2026-02-02T20:10:33-0500 [tracking] started location updates`
/// Active in all builds (DEBUG + Release). Data is only shared when the user
/// explicitly exports from Settings → Diagnostics.
final class DiagnosticsLogger {
  static let shared = DiagnosticsLogger()

  private let queue: DispatchQueue
  private let queueKey = DispatchSpecificKey<UUID>()
  private let queueID = UUID()

  private let fileManager: FileManager
  private let fileURL: URL
  private let maxBytes: Int

  private let formatter: DateFormatter

  init(
    fileManager: FileManager = .default,
    filename: String = "diagnostics.log",
    maxBytes: Int = 1_000_000
  ) {
    self.fileManager = fileManager
    self.maxBytes = maxBytes

    self.queue = DispatchQueue(label: "DiagnosticsLoggerQueue", qos: .utility)
    self.queue.setSpecific(key: queueKey, value: queueID)

    let base = Self.applicationSupportDirectory(fileManager: fileManager)
    self.fileURL = base.appendingPathComponent(filename, isDirectory: false)

    let df = DateFormatter()
    df.locale = Locale(identifier: "en_US_POSIX")
    df.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZ"
    self.formatter = df

    ensureDirectoryExists()
  }

  func log(_ category: String, _ message: String) {
    let cat = category.trimmingCharacters(in: .whitespacesAndNewlines)
    let msg = message.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !cat.isEmpty, !msg.isEmpty else { return }

    let timestamp = formatter.string(from: Date())
    let line = "\(timestamp) [\(cat)] \(msg)\n"

    withQueue {
      self.append(line)
      self.enforceMaxSize()
    }
  }

  func readAll() -> String {
    withQueue {
      (try? String(contentsOf: self.fileURL, encoding: .utf8)) ?? ""
    }
  }

  func readLastLines(_ n: Int) -> String {
    let n = max(0, n)
    guard n > 0 else { return "" }

    return withQueue {
      let text = (try? String(contentsOf: self.fileURL, encoding: .utf8)) ?? ""
      guard !text.isEmpty else { return "" }
      let lines = text.split(separator: "\n", omittingEmptySubsequences: false)
      let tail = lines.suffix(n)
      return tail.joined(separator: "\n")
    }
  }

  func clear() {
    withQueue {
      self.ensureDirectoryExists()
      try? Data().write(to: self.fileURL, options: [.atomic])
    }
  }

  func logFileURL() -> URL {
    fileURL
  }

  // MARK: - Internals

  private func withQueue<T>(_ work: () -> T) -> T {
    if DispatchQueue.getSpecific(key: queueKey) == queueID {
      return work()
    }
    return queue.sync(execute: work)
  }

  private func ensureDirectoryExists() {
    let dir = fileURL.deletingLastPathComponent()
    if !fileManager.fileExists(atPath: dir.path) {
      try? fileManager.createDirectory(at: dir, withIntermediateDirectories: true)
    }
  }

  private func append(_ line: String) {
    ensureDirectoryExists()

    if !fileManager.fileExists(atPath: fileURL.path) {
      try? line.data(using: .utf8)?.write(to: fileURL, options: [.atomic])
      return
    }

    guard let data = line.data(using: .utf8) else { return }
    do {
      let handle = try FileHandle(forWritingTo: fileURL)
      try handle.seekToEnd()
      try handle.write(contentsOf: data)
      try handle.close()
    } catch {
      // best-effort
    }
  }

  private func enforceMaxSize() {
    guard maxBytes > 0 else { return }
    guard let attrs = try? fileManager.attributesOfItem(atPath: fileURL.path),
          let size = attrs[.size] as? NSNumber
    else { return }

    let bytes = size.intValue
    guard bytes > maxBytes else { return }

    // Keep the last ~75% of maxBytes and drop the oldest.
    let keepBytes = Int(Double(maxBytes) * 0.75)
    guard keepBytes > 0 else {
      clear()
      return
    }

    guard let data = try? Data(contentsOf: fileURL), data.count > keepBytes else { return }
    let start = data.count - keepBytes
    var tail = data.subdata(in: start..<data.count)

    // Align to a line boundary: drop partial first line if needed.
    if let firstNewline = tail.firstIndex(of: 0x0A) { // '\n'
      tail = tail.subdata(in: tail.index(after: firstNewline)..<tail.count)
    }

    let header = "\(formatter.string(from: Date())) [diagnostics] log truncated to last \(keepBytes) bytes\n"
    var out = Data(header.utf8)
    out.append(tail)
    try? out.write(to: fileURL, options: [.atomic])
  }

  private static func applicationSupportDirectory(fileManager: FileManager) -> URL {
    let base = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
      ?? URL(fileURLWithPath: NSHomeDirectory()).appendingPathComponent("Library/Application Support")
    let bundleID = Bundle.main.bundleIdentifier ?? "MileTrack"
    return base.appendingPathComponent(bundleID, isDirectory: true)
  }
}

