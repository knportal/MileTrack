import Foundation

/// Expense calculation result for a trip or group of trips.
struct ExpenseCalculation {
  var totalMiles: Double
  var mileageRate: Decimal
  var mileageAmount: Decimal
  var receiptsAmount: Decimal
  var totalAmount: Decimal
  var currency: String
  
  init(
    totalMiles: Double,
    mileageRate: Decimal,
    receiptsAmount: Decimal = 0,
    currency: String = "USD"
  ) {
    self.totalMiles = totalMiles
    self.mileageRate = mileageRate
    self.currency = currency
    
    // Calculate mileage amount
    let milesDecimal = Decimal(totalMiles)
    self.mileageAmount = milesDecimal * mileageRate
    
    self.receiptsAmount = receiptsAmount
    self.totalAmount = mileageAmount + receiptsAmount
  }
  
  /// Format the mileage calculation as a display string
  var mileageFormula: String {
    let formatter = NumberFormatter()
    formatter.numberStyle = .decimal
    formatter.minimumFractionDigits = 1
    formatter.maximumFractionDigits = 1
    
    let currencyFormatter = NumberFormatter()
    currencyFormatter.numberStyle = .currency
    currencyFormatter.currencyCode = currency
    
    let milesStr = formatter.string(from: NSNumber(value: totalMiles)) ?? "0.0"
    let rateStr = currencyFormatter.string(from: mileageRate as NSNumber) ?? "$0.00"
    let amountStr = currencyFormatter.string(from: mileageAmount as NSNumber) ?? "$0.00"
    
    return "\(rateStr)/mi × \(milesStr) mi = \(amountStr)"
  }
  
  /// Format the total amount with currency
  func formattedTotal() -> String {
    let formatter = NumberFormatter()
    formatter.numberStyle = .currency
    formatter.currencyCode = currency
    return formatter.string(from: totalAmount as NSNumber) ?? "$0.00"
  }
  
  /// Format the mileage amount with currency
  func formattedMileageAmount() -> String {
    let formatter = NumberFormatter()
    formatter.numberStyle = .currency
    formatter.currencyCode = currency
    return formatter.string(from: mileageAmount as NSNumber) ?? "$0.00"
  }
  
  /// Format the receipts amount with currency
  func formattedReceiptsAmount() -> String {
    let formatter = NumberFormatter()
    formatter.numberStyle = .currency
    formatter.currencyCode = currency
    return formatter.string(from: receiptsAmount as NSNumber) ?? "$0.00"
  }
}

/// Service for calculating trip expenses
struct ExpenseCalculator {
  
  /// Calculate expense for a single trip using the appropriate rate
  func calculateExpense(
    for trip: Trip,
    rates: [MileageRate],
    receipts: [TripReceipt]
  ) -> ExpenseCalculation? {
    guard let rate = findApplicableRate(for: trip, in: rates) else {
      return nil
    }
    
    let tripReceipts = receipts.filter { $0.tripId == trip.id }
    let receiptsTotal = tripReceipts.reduce(Decimal(0)) { sum, receipt in
      sum + (receipt.amount ?? 0)
    }
    
    return ExpenseCalculation(
      totalMiles: trip.distanceMiles,
      mileageRate: rate.ratePerMile,
      receiptsAmount: receiptsTotal
    )
  }
  
  /// Calculate total expenses for multiple trips
  func calculateTotalExpense(
    for trips: [Trip],
    rates: [MileageRate],
    receipts: [TripReceipt]
  ) -> ExpenseCalculation {
    let totalMiles = trips.reduce(0.0) { $0 + $1.distanceMiles }
    
    // Use weighted average rate based on applicable rate for each trip
    var totalWeightedRate = Decimal(0)
    var totalWeightedMiles = 0.0
    
    for trip in trips {
      if let rate = findApplicableRate(for: trip, in: rates) {
        totalWeightedRate += rate.ratePerMile * Decimal(trip.distanceMiles)
        totalWeightedMiles += trip.distanceMiles
      }
    }
    
    let averageRate = totalWeightedMiles > 0 ? totalWeightedRate / Decimal(totalWeightedMiles) : Decimal(0)
    
    let tripIds = Set(trips.map { $0.id })
    let relevantReceipts = receipts.filter { tripIds.contains($0.tripId) }
    let receiptsTotal = relevantReceipts.reduce(Decimal(0)) { sum, receipt in
      sum + (receipt.amount ?? 0)
    }
    
    return ExpenseCalculation(
      totalMiles: totalMiles,
      mileageRate: averageRate,
      receiptsAmount: receiptsTotal
    )
  }
  
  /// Calculate expenses grouped by client/organization
  func calculateExpensesByClient(
    trips: [Trip],
    rates: [MileageRate],
    receipts: [TripReceipt]
  ) -> [String: ExpenseCalculation] {
    var result: [String: ExpenseCalculation] = [:]
    
    // Group trips by client
    let groupedTrips = Dictionary(grouping: trips) { trip in
      trip.clientOrOrg ?? "Unassigned"
    }
    
    for (client, clientTrips) in groupedTrips {
      result[client] = calculateTotalExpense(
        for: clientTrips,
        rates: rates,
        receipts: receipts
      )
    }
    
    return result
  }
  
  /// Calculate expenses grouped by category
  func calculateExpensesByCategory(
    trips: [Trip],
    rates: [MileageRate],
    receipts: [TripReceipt]
  ) -> [String: ExpenseCalculation] {
    var result: [String: ExpenseCalculation] = [:]
    
    // Group trips by category
    let groupedTrips = Dictionary(grouping: trips) { trip in
      trip.category ?? "Uncategorized"
    }
    
    for (category, categoryTrips) in groupedTrips {
      result[category] = calculateTotalExpense(
        for: categoryTrips,
        rates: rates,
        receipts: receipts
      )
    }
    
    return result
  }
  
  // MARK: - Private Helpers
  
  private func findApplicableRate(for trip: Trip, in rates: [MileageRate]) -> MileageRate? {
    // First, try to find a rate that matches the trip's category and date
    let categoryRates = rates.filter { rate in
      if let rateCategory = rate.category, let tripCategory = trip.category {
        return rateCategory.caseInsensitiveCompare(tripCategory) == .orderedSame
      }
      return false
    }
    
    if let rate = categoryRates.first(where: { $0.isActive(on: trip.date) }) {
      return rate
    }
    
    // Fallback to any rate active on the trip date
    if let rate = rates.first(where: { $0.isActive(on: trip.date) }) {
      return rate
    }
    
    // Last resort: return the first rate
    return rates.first
  }
}
