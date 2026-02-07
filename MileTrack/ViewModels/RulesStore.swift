import Combine
import Foundation

@MainActor
final class RulesStore: ObservableObject {
  @Published var rules: [TripRule]

  private let persistence: RulesPersistenceStore
  private var cancellables: Set<AnyCancellable> = []

  init(
    rules: [TripRule]? = nil,
    persistence: RulesPersistenceStore? = nil
  ) {
    // Avoid evaluating a potentially `@MainActor` default argument at the call site.
    let persistenceStore = persistence ?? RulesPersistenceStore()
    self.persistence = persistenceStore

    if let rules {
      self.rules = rules
    } else if let loaded = try? persistenceStore.loadRules() {
      self.rules = loaded
    } else {
      self.rules = []
    }

    $rules
      .dropFirst()
      .debounce(for: .milliseconds(450), scheduler: RunLoop.main)
      .sink { [weak self] newValue in
        self?.persist(newValue)
      }
      .store(in: &cancellables)
  }

  func add(_ rule: TripRule) {
    rules.append(rule)
  }

  func update(_ rule: TripRule) {
    guard let idx = rules.firstIndex(where: { $0.id == rule.id }) else { return }
    rules[idx] = rule
  }

  func remove(ruleID: UUID) {
    rules.removeAll { $0.id == ruleID }
  }

  func toggleEnabled(ruleID: UUID, isEnabled: Bool) {
    guard let idx = rules.firstIndex(where: { $0.id == ruleID }) else { return }
    rules[idx].isEnabled = isEnabled
  }

  func reset() {
    rules = []
    do { try persistence.reset() } catch { /* best-effort */ }
  }

  func saveNow() {
    persist(rules)
  }

  private func persist(_ value: [TripRule]) {
    do {
      try persistence.saveRules(value)
    } catch {
      // Best-effort persistence.
    }
  }
}

