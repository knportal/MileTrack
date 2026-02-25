import Combine
import Foundation

@MainActor
final class ClientsStore: ObservableObject {
  @Published var clients: [String]

  private let persistence: ClientsPersistenceStore
  private var cancellables: Set<AnyCancellable> = []

  static let defaultSeed: [String] = [
    "Acme Co.",
    "Globex",
    "Initech",
  ]

  init(
    clients: [String]? = nil,
    persistence: ClientsPersistenceStore? = nil
  ) {
    // Avoid evaluating a potentially `@MainActor` default argument at the call site.
    let persistenceStore = persistence ?? ClientsPersistenceStore()
    self.persistence = persistenceStore

    if let clients {
      self.clients = Self.normalizedUnique(clients)
    } else if let loaded = try? persistenceStore.loadClients(), !loaded.isEmpty {
      self.clients = Self.normalizedUnique(loaded)
    } else {
      self.clients = Self.defaultSeed
    }

    $clients
      .dropFirst()
      .debounce(for: .milliseconds(450), scheduler: RunLoop.main)
      .sink { [weak self] newValue in
        self?.persist(newValue)
      }
      .store(in: &cancellables)
  }

  func add(_ name: String) -> Bool {
    let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !trimmed.isEmpty else { return false }
    guard !containsCaseInsensitive(trimmed) else { return false }
    clients.append(trimmed)
    clients = Self.normalizedUnique(clients)
    return true
  }

  func remove(_ name: String) -> Bool {
    let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !trimmed.isEmpty else { return false }
    let before = clients.count
    clients.removeAll { $0.caseInsensitiveCompare(trimmed) == .orderedSame }
    return clients.count != before
  }

  func rename(from oldName: String, to newName: String) -> Bool {
    let oldTrimmed = oldName.trimmingCharacters(in: .whitespacesAndNewlines)
    let newTrimmed = newName.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !oldTrimmed.isEmpty, !newTrimmed.isEmpty else { return false }
    guard !containsCaseInsensitive(newTrimmed) || oldTrimmed.caseInsensitiveCompare(newTrimmed) == .orderedSame else {
      return false
    }
    guard let idx = clients.firstIndex(where: { $0.caseInsensitiveCompare(oldTrimmed) == .orderedSame }) else {
      return false
    }
    clients[idx] = newTrimmed
    clients = Self.normalizedUnique(clients)
    return true
  }

  func resetToDefaults() {
    clients = Self.defaultSeed
    do { try persistence.reset() } catch { /* best-effort */ }
  }

  func saveNow() {
    persist(clients)
  }

  private func persist(_ value: [String]) {
    do {
      try persistence.saveClients(value)
    } catch {
      // Best-effort persistence.
    }
  }

  private func containsCaseInsensitive(_ value: String) -> Bool {
    clients.contains { $0.caseInsensitiveCompare(value) == .orderedSame }
  }

  private static func normalizedUnique(_ input: [String]) -> [String] {
    var seen: [String] = []
    for raw in input {
      let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
      guard !trimmed.isEmpty else { continue }
      if !seen.contains(where: { $0.caseInsensitiveCompare(trimmed) == .orderedSame }) {
        seen.append(trimmed)
      }
    }
    return seen
  }
}

