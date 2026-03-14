import Combine
import Foundation

@MainActor
final class MileageRatesStore: ObservableObject {
  @Published var rates: [MileageRate]
  @Published var lastSaveError: String?
  
  private let persistence: MileageRatesPersistenceStore
  private var cancellables: Set<AnyCancellable> = []
  
  init(
    rates: [MileageRate]? = nil,
    persistence: MileageRatesPersistenceStore? = nil
  ) {
    let persistenceStore = persistence ?? MileageRatesPersistenceStore()
    self.persistence = persistenceStore
    
    if let rates {
      self.rates = rates
    } else if let loaded = try? persistenceStore.loadRates() {
      self.rates = loaded
    } else {
      self.rates = MileageRate.defaultRates
    }
    
    $rates
      .dropFirst()
      .debounce(for: .milliseconds(450), scheduler: RunLoop.main)
      .sink { [weak self] newValue in
        self?.persist(newValue)
      }
      .store(in: &cancellables)
  }
  
  /// Find the best matching rate for a given trip
  func rate(for trip: Trip) -> MileageRate? {
    // First, try to find a rate matching category and date
    let categoryMatches = rates.filter { rate in
      guard let rateCategory = rate.category, let tripCategory = trip.category else {
        return false
      }
      return rateCategory.caseInsensitiveCompare(tripCategory) == .orderedSame
    }
    
    if let rate = categoryMatches.first(where: { $0.isActive(on: trip.date) }) {
      return rate
    }
    
    // Fallback to any active rate for the date
    if let rate = rates.first(where: { $0.isActive(on: trip.date) }) {
      return rate
    }
    
    // Last resort: most recent rate
    return rates.sorted(by: { $0.effectiveFrom > $1.effectiveFrom }).first
  }
  
  /// Get all rates active on a specific date
  func activeRates(on date: Date) -> [MileageRate] {
    rates.filter { $0.isActive(on: date) }
  }
  
  /// Add a new rate
  func add(_ rate: MileageRate) {
    rates.append(rate)
  }
  
  /// Update an existing rate
  func update(_ rate: MileageRate) -> Bool {
    guard let idx = rates.firstIndex(where: { $0.id == rate.id }) else {
      return false
    }
    rates[idx] = rate
    return true
  }
  
  /// Remove a rate
  func remove(_ rate: MileageRate) -> Bool {
    let before = rates.count
    rates.removeAll { $0.id == rate.id }
    return rates.count != before
  }
  
  /// Reset to default rates
  func resetToDefaults() {
    rates = MileageRate.defaultRates
  }
  
  func saveNow() {
    persist(rates)
  }
  
  private func persist(_ value: [MileageRate]) {
    do {
      try persistence.saveRates(value)
      lastSaveError = nil
    } catch {
      lastSaveError = "Failed to save rates: \(error.localizedDescription)"
    }
  }
}
