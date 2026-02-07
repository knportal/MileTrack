import Combine
import Foundation

@MainActor
final class CategoriesStore: ObservableObject {
  @Published var categories: [String]

  private let persistence: CategoriesPersistenceStore
  private var cancellables: Set<AnyCancellable> = []

  static let defaultSeed: [String] = [
    TripCategory.business.stringValue,
    TripCategory.volunteer.stringValue,
    TripCategory.medical.stringValue,
    TripCategory.education.stringValue,
    TripCategory.personal.stringValue,
  ]

  init(
    categories: [String]? = nil,
    persistence: CategoriesPersistenceStore? = nil
  ) {
    // Avoid evaluating a potentially `@MainActor` default argument at the call site.
    let persistenceStore = persistence ?? CategoriesPersistenceStore()
    self.persistence = persistenceStore

    if let categories {
      self.categories = Self.normalizedUnique(categories)
    } else if let loaded = try? persistenceStore.loadCategories(), !loaded.isEmpty {
      self.categories = Self.normalizedUnique(loaded)
    } else {
      self.categories = Self.defaultSeed
    }

    $categories
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
    categories.append(trimmed)
    categories = Self.normalizedUnique(categories)
    return true
  }

  func remove(_ name: String) -> Bool {
    let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !trimmed.isEmpty else { return false }
    let before = categories.count
    categories.removeAll { $0.caseInsensitiveCompare(trimmed) == .orderedSame }
    return categories.count != before
  }

  func rename(from oldName: String, to newName: String) -> Bool {
    let oldTrimmed = oldName.trimmingCharacters(in: .whitespacesAndNewlines)
    let newTrimmed = newName.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !oldTrimmed.isEmpty, !newTrimmed.isEmpty else { return false }
    guard !containsCaseInsensitive(newTrimmed) || oldTrimmed.caseInsensitiveCompare(newTrimmed) == .orderedSame else {
      return false
    }
    guard let idx = categories.firstIndex(where: { $0.caseInsensitiveCompare(oldTrimmed) == .orderedSame }) else {
      return false
    }
    categories[idx] = newTrimmed
    categories = Self.normalizedUnique(categories)
    return true
  }

  func resetToDefaults() {
    categories = Self.defaultSeed
    do { try persistence.reset() } catch { /* best-effort */ }
  }

  // MARK: - Persistence

  func saveNow() {
    persist(categories)
  }

  private func persist(_ value: [String]) {
    do {
      try persistence.saveCategories(value)
    } catch {
      // Best-effort persistence: ignore write failures in UI-only store.
    }
  }

  private func containsCaseInsensitive(_ value: String) -> Bool {
    categories.contains { $0.caseInsensitiveCompare(value) == .orderedSame }
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

