#if canImport(Testing)
import Testing
import Foundation
@testable import MileTrack

@Suite("Expense Calculator Tests")
struct ExpenseCalculatorTests {
  
  let calculator = ExpenseCalculator()
  
  // MARK: - Basic Expense Calculation
  
  @Test("Calculate simple mileage expense")
  func calculateSimpleMileageExpense() {
    let trip = Trip(
      date: Date(),
      distanceMiles: 50.0,
      source: .manual,
      state: .confirmed,
      category: "Business"
    )
    
    let rate = MileageRate(
      name: "Test Rate",
      ratePerMile: 0.70,
      effectiveFrom: Date().addingTimeInterval(-86400) // Yesterday
    )
    
    let calculation = calculator.calculateExpense(
      for: trip,
      rates: [rate],
      receipts: []
    )
    
    #expect(calculation != nil)
    #expect(calculation?.totalMiles == 50.0)
    #expect(calculation?.mileageRate == 0.70)
    #expect(calculation?.mileageAmount == 35.0)
    #expect(calculation?.receiptsAmount == 0)
    #expect(calculation?.totalAmount == 35.0)
  }
  
  @Test("Calculate expense with receipts")
  func calculateExpenseWithReceipts() {
    let tripId = UUID()
    let trip = Trip(
      id: tripId,
      date: Date(),
      distanceMiles: 50.0,
      source: .manual,
      state: .confirmed,
      category: "Business"
    )
    
    let rate = MileageRate(
      name: "Test Rate",
      ratePerMile: 0.70,
      effectiveFrom: Date().addingTimeInterval(-86400)
    )
    
    let receipts = [
      TripReceipt(tripId: tripId, type: .parking, amount: 10.00),
      TripReceipt(tripId: tripId, type: .toll, amount: 5.50)
    ]
    
    let calculation = calculator.calculateExpense(
      for: trip,
      rates: [rate],
      receipts: receipts
    )
    
    #expect(calculation != nil)
    #expect(calculation?.mileageAmount == 35.0)
    #expect(calculation?.receiptsAmount == 15.5)
    #expect(calculation?.totalAmount == 50.5)
  }
  
  // MARK: - Rate Matching
  
  @Test("Match rate by category and date")
  func matchRateByCategoryAndDate() {
    let trip = Trip(
      date: Date(),
      distanceMiles: 50.0,
      source: .manual,
      state: .confirmed,
      category: "Business"
    )
    
    let businessRate = MileageRate(
      name: "Business Rate",
      ratePerMile: 0.70,
      effectiveFrom: Date().addingTimeInterval(-86400),
      category: "Business"
    )
    
    let medicalRate = MileageRate(
      name: "Medical Rate",
      ratePerMile: 0.21,
      effectiveFrom: Date().addingTimeInterval(-86400),
      category: "Medical"
    )
    
    let calculation = calculator.calculateExpense(
      for: trip,
      rates: [businessRate, medicalRate],
      receipts: []
    )
    
    #expect(calculation?.mileageRate == 0.70) // Should use business rate
  }
  
  @Test("Fallback to any active rate when no category match")
  func fallbackToActiveRate() {
    let trip = Trip(
      date: Date(),
      distanceMiles: 50.0,
      source: .manual,
      state: .confirmed,
      category: "Personal"
    )
    
    let businessRate = MileageRate(
      name: "Business Rate",
      ratePerMile: 0.70,
      effectiveFrom: Date().addingTimeInterval(-86400),
      category: "Business"
    )
    
    let calculation = calculator.calculateExpense(
      for: trip,
      rates: [businessRate],
      receipts: []
    )
    
    #expect(calculation?.mileageRate == 0.70) // Should use available rate
  }
  
  @Test("Handle no matching rate")
  func handleNoMatchingRate() {
    let trip = Trip(
      date: Date(),
      distanceMiles: 50.0,
      source: .manual,
      state: .confirmed
    )
    
    let calculation = calculator.calculateExpense(
      for: trip,
      rates: [],
      receipts: []
    )
    
    #expect(calculation == nil) // No rate available
  }
  
  // MARK: - Multiple Trips
  
  @Test("Calculate total for multiple trips")
  func calculateTotalForMultipleTrips() {
    let trips = [
      Trip(date: Date(), distanceMiles: 50.0, source: .manual, state: .confirmed, category: "Business"),
      Trip(date: Date(), distanceMiles: 30.0, source: .manual, state: .confirmed, category: "Business"),
      Trip(date: Date(), distanceMiles: 20.0, source: .manual, state: .confirmed, category: "Business")
    ]
    
    let rate = MileageRate(
      name: "Business Rate",
      ratePerMile: 0.70,
      effectiveFrom: Date().addingTimeInterval(-86400),
      category: "Business"
    )
    
    let calculation = calculator.calculateTotalExpense(
      for: trips,
      rates: [rate],
      receipts: []
    )
    
    #expect(calculation.totalMiles == 100.0)
    #expect(calculation.mileageAmount == 70.0)
  }
  
  @Test("Group expenses by client")
  func groupExpensesByClient() {
    let trips = [
      Trip(date: Date(), distanceMiles: 50.0, source: .manual, state: .confirmed, clientOrOrg: "Client A"),
      Trip(date: Date(), distanceMiles: 30.0, source: .manual, state: .confirmed, clientOrOrg: "Client A"),
      Trip(date: Date(), distanceMiles: 20.0, source: .manual, state: .confirmed, clientOrOrg: "Client B")
    ]
    
    let rate = MileageRate(
      name: "Test Rate",
      ratePerMile: 0.70,
      effectiveFrom: Date().addingTimeInterval(-86400)
    )
    
    let byClient = calculator.calculateExpensesByClient(
      trips: trips,
      rates: [rate],
      receipts: []
    )
    
    #expect(byClient.count == 2)
    #expect(byClient["Client A"]?.totalMiles == 80.0)
    #expect(byClient["Client B"]?.totalMiles == 20.0)
    #expect(byClient["Client A"]?.mileageAmount == 56.0)
    #expect(byClient["Client B"]?.mileageAmount == 14.0)
  }
  
  @Test("Group expenses by category")
  func groupExpensesByCategory() {
    let trips = [
      Trip(date: Date(), distanceMiles: 50.0, source: .manual, state: .confirmed, category: "Business"),
      Trip(date: Date(), distanceMiles: 30.0, source: .manual, state: .confirmed, category: "Business"),
      Trip(date: Date(), distanceMiles: 20.0, source: .manual, state: .confirmed, category: "Medical")
    ]
    
    let businessRate = MileageRate(
      name: "Business Rate",
      ratePerMile: 0.70,
      effectiveFrom: Date().addingTimeInterval(-86400),
      category: "Business"
    )
    
    let medicalRate = MileageRate(
      name: "Medical Rate",
      ratePerMile: 0.21,
      effectiveFrom: Date().addingTimeInterval(-86400),
      category: "Medical"
    )
    
    let byCategory = calculator.calculateExpensesByCategory(
      trips: trips,
      rates: [businessRate, medicalRate],
      receipts: []
    )
    
    #expect(byCategory.count == 2)
    #expect(byCategory["Business"]?.totalMiles == 80.0)
    #expect(byCategory["Medical"]?.totalMiles == 20.0)
    #expect(byCategory["Business"]?.mileageAmount == 56.0)
    #expect(byCategory["Medical"]?.mileageAmount == 4.2)
  }
}

@Suite("Mileage Rate Tests")
struct MileageRateTests {
  
  @Test("Rate is active within date range")
  func rateIsActiveWithinDateRange() {
    let startDate = Calendar.current.date(from: DateComponents(year: 2026, month: 1, day: 1))!
    let endDate = Calendar.current.date(from: DateComponents(year: 2026, month: 12, day: 31))!
    let testDate = Calendar.current.date(from: DateComponents(year: 2026, month: 6, day: 15))!
    
    let rate = MileageRate(
      name: "Test Rate",
      ratePerMile: 0.70,
      effectiveFrom: startDate,
      effectiveTo: endDate
    )
    
    #expect(rate.isActive(on: testDate))
  }
  
  @Test("Rate is not active before start date")
  func rateIsNotActiveBeforeStartDate() {
    let startDate = Calendar.current.date(from: DateComponents(year: 2026, month: 1, day: 1))!
    let testDate = Calendar.current.date(from: DateComponents(year: 2025, month: 12, day: 31))!
    
    let rate = MileageRate(
      name: "Test Rate",
      ratePerMile: 0.70,
      effectiveFrom: startDate
    )
    
    #expect(!rate.isActive(on: testDate))
  }
  
  @Test("Rate is not active after end date")
  func rateIsNotActiveAfterEndDate() {
    let startDate = Calendar.current.date(from: DateComponents(year: 2026, month: 1, day: 1))!
    let endDate = Calendar.current.date(from: DateComponents(year: 2026, month: 12, day: 31))!
    let testDate = Calendar.current.date(from: DateComponents(year: 2027, month: 1, day: 1))!
    
    let rate = MileageRate(
      name: "Test Rate",
      ratePerMile: 0.70,
      effectiveFrom: startDate,
      effectiveTo: endDate
    )
    
    #expect(!rate.isActive(on: testDate))
  }
  
  @Test("Rate with no end date is always active after start")
  func rateWithNoEndDateIsActiveAfterStart() {
    let startDate = Calendar.current.date(from: DateComponents(year: 2026, month: 1, day: 1))!
    let testDate = Calendar.current.date(from: DateComponents(year: 2030, month: 1, day: 1))!
    
    let rate = MileageRate(
      name: "Test Rate",
      ratePerMile: 0.70,
      effectiveFrom: startDate
    )
    
    #expect(rate.isActive(on: testDate))
  }
}

@Suite("Expense Calculation Formatting Tests")
struct ExpenseCalculationFormattingTests {
  
  @Test("Format mileage formula correctly")
  func formatMileageFormula() {
    let calculation = ExpenseCalculation(
      totalMiles: 50.5,
      mileageRate: 0.70,
      receiptsAmount: 0,
      currency: "USD"
    )
    
    let formula = calculation.mileageFormula
    
    // Should contain rate, miles, and result
    #expect(formula.contains("$0.70"))
    #expect(formula.contains("50.5"))
    #expect(formula.contains("$35.35"))
  }
  
  @Test("Format total amount with currency")
  func formatTotalAmount() {
    let calculation = ExpenseCalculation(
      totalMiles: 50.0,
      mileageRate: 0.70,
      receiptsAmount: 10.0,
      currency: "USD"
    )
    
    let formatted = calculation.formattedTotal()
    
    #expect(formatted.contains("$45.00"))
  }
  
  @Test("Calculate correct decimal amounts")
  func calculateCorrectDecimalAmounts() {
    // Test precision with awkward numbers
    let calculation = ExpenseCalculation(
      totalMiles: 37.3,
      mileageRate: 0.67,
      receiptsAmount: 12.45
    )
    
    // 37.3 * 0.67 = 24.991
    let expectedMileage = Decimal(37.3) * Decimal(0.67)
    
    #expect(calculation.mileageAmount == expectedMileage)
    #expect(calculation.totalAmount == expectedMileage + 12.45)
  }
}

@Suite("Receipt Store Tests")
struct ReceiptStoreTests {
  
  @Test("Get receipts for specific trip", .bug("Ensure filtering works correctly"))
  func getReceiptsForTrip() async {
    let tripId1 = UUID()
    let tripId2 = UUID()
    
    let trip1 = Trip(
      id: tripId1,
      date: Date(),
      distanceMiles: 50.0,
      source: .manual,
      state: .confirmed
    )
    
    let receipts = [
      TripReceipt(tripId: tripId1, type: .parking, amount: 10.00),
      TripReceipt(tripId: tripId1, type: .toll, amount: 5.00),
      TripReceipt(tripId: tripId2, type: .parking, amount: 8.00)
    ]
    
    let store = await ReceiptsStore(receipts: receipts)
    
    await MainActor.run {
      let trip1Receipts = store.receipts(for: trip1)
      #expect(trip1Receipts.count == 2)
      #expect(trip1Receipts.allSatisfy { $0.tripId == tripId1 })
    }
  }
  
  @Test("Calculate total amount for trip")
  func calculateTotalAmountForTrip() async {
    let tripId = UUID()
    
    let trip = Trip(
      id: tripId,
      date: Date(),
      distanceMiles: 50.0,
      source: .manual,
      state: .confirmed
    )
    
    let receipts = [
      TripReceipt(tripId: tripId, type: .parking, amount: 10.00),
      TripReceipt(tripId: tripId, type: .toll, amount: 5.50),
      TripReceipt(tripId: tripId, type: .fuel, amount: 25.00)
    ]
    
    let store = await ReceiptsStore(receipts: receipts)
    
    await MainActor.run {
      let total = store.totalAmount(for: trip)
      #expect(total == 40.50)
    }
  }
}

@Suite("Mileage Rates Store Tests")
struct MileageRatesStoreTests {
  
  @Test("Find rate for trip by category")
  func findRateForTripByCategory() async {
    let trip = Trip(
      date: Date(),
      distanceMiles: 50.0,
      source: .manual,
      state: .confirmed,
      category: "Business"
    )
    
    let businessRate = MileageRate(
      name: "Business Rate",
      ratePerMile: 0.70,
      effectiveFrom: Date().addingTimeInterval(-86400),
      category: "Business"
    )
    
    let medicalRate = MileageRate(
      name: "Medical Rate",
      ratePerMile: 0.21,
      effectiveFrom: Date().addingTimeInterval(-86400),
      category: "Medical"
    )
    
    let store = await MileageRatesStore(rates: [businessRate, medicalRate])
    
    await MainActor.run {
      let rate = store.rate(for: trip)
      #expect(rate?.name == "Business Rate")
      #expect(rate?.ratePerMile == 0.70)
    }
  }
  
  @Test("Get active rates on date")
  func getActiveRatesOnDate() async {
    let now = Date()
    let yesterday = now.addingTimeInterval(-86400)
    let tomorrow = now.addingTimeInterval(86400)
    
    let currentRate = MileageRate(
      name: "Current Rate",
      ratePerMile: 0.70,
      effectiveFrom: yesterday
    )
    
    let futureRate = MileageRate(
      name: "Future Rate",
      ratePerMile: 0.75,
      effectiveFrom: tomorrow
    )
    
    let store = await MileageRatesStore(rates: [currentRate, futureRate])
    
    await MainActor.run {
      let activeRates = store.activeRates(on: now)
      #expect(activeRates.count == 1)
      #expect(activeRates.first?.name == "Current Rate")
    }
  }
}
#endif

