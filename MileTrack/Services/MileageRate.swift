import Foundation

/// Represents a mileage reimbursement rate for a specific time period.
struct MileageRate: Identifiable, Codable, Equatable {
  var id: UUID
  var name: String
  var ratePerMile: Decimal
  var effectiveFrom: Date
  var effectiveTo: Date?
  var category: String?
  var country: String
  var notes: String?
  
  init(
    id: UUID = UUID(),
    name: String,
    ratePerMile: Decimal,
    effectiveFrom: Date,
    effectiveTo: Date? = nil,
    category: String? = nil,
    country: String = "US",
    notes: String? = nil
  ) {
    self.id = id
    self.name = name
    self.ratePerMile = ratePerMile
    self.effectiveFrom = effectiveFrom
    self.effectiveTo = effectiveTo
    self.category = category
    self.country = country
    self.notes = notes
  }
  
  /// Check if this rate is active for a given date.
  func isActive(on date: Date) -> Bool {
    if date < effectiveFrom {
      return false
    }
    if let to = effectiveTo, date > to {
      return false
    }
    return true
  }
}

extension MileageRate {
  /// IRS standard mileage rate for 2026 business use
  static let irs2026Business = MileageRate(
    name: "IRS 2026 Business",
    ratePerMile: 0.70,
    effectiveFrom: Calendar.current.date(from: DateComponents(year: 2026, month: 1, day: 1))!,
    effectiveTo: Calendar.current.date(from: DateComponents(year: 2026, month: 12, day: 31))!,
    category: "Business",
    country: "US",
    notes: "Standard mileage rate for business use of a vehicle"
  )
  
  /// IRS standard mileage rate for 2026 medical/moving
  static let irs2026Medical = MileageRate(
    name: "IRS 2026 Medical",
    ratePerMile: 0.21,
    effectiveFrom: Calendar.current.date(from: DateComponents(year: 2026, month: 1, day: 1))!,
    effectiveTo: Calendar.current.date(from: DateComponents(year: 2026, month: 12, day: 31))!,
    category: "Medical",
    country: "US",
    notes: "Standard mileage rate for medical or moving purposes"
  )
  
  /// IRS standard mileage rate for 2026 charitable
  static let irs2026Charitable = MileageRate(
    name: "IRS 2026 Charitable",
    ratePerMile: 0.14,
    effectiveFrom: Calendar.current.date(from: DateComponents(year: 2026, month: 1, day: 1))!,
    effectiveTo: Calendar.current.date(from: DateComponents(year: 2026, month: 12, day: 31))!,
    category: "Volunteer",
    country: "US",
    notes: "Standard mileage rate for charitable organizations"
  )
  
  /// Default rates for quick setup
  static let defaultRates: [MileageRate] = [
    .irs2026Business,
    .irs2026Medical,
    .irs2026Charitable
  ]
}
