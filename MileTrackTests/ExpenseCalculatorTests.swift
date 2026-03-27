import XCTest
@testable import MileTrack

final class ExpenseCalculatorTests: XCTestCase {

  private let calculator = ExpenseCalculator()

  private func makeTrip(miles: Double, category: String? = "Business", date: Date = Date()) -> Trip {
    Trip(date: date, distanceMiles: miles, source: .auto, state: .confirmed, category: category)
  }

  private func makeRate(
    ratePerMile: Decimal = Decimal(string: "0.70")!,
    category: String? = nil,
    effectiveFrom: Date = Date(timeIntervalSince1970: 0),
    effectiveTo: Date? = nil
  ) -> MileageRate {
    MileageRate(
      name: "Standard",
      ratePerMile: ratePerMile,
      effectiveFrom: effectiveFrom,
      effectiveTo: effectiveTo,
      category: category
    )
  }

  // MARK: - Single trip calculation

  func testBasicMileageCalculation() {
    let trip = makeTrip(miles: 10.0)
    let rate = makeRate(ratePerMile: Decimal(string: "0.70")!)

    let result = calculator.calculateExpense(for: trip, rates: [rate], receipts: [])

    XCTAssertNotNil(result)
    XCTAssertEqual(result!.totalMiles, 10.0)
    XCTAssertEqual(result!.mileageRate, Decimal(string: "0.70"))
    XCTAssertEqual(result!.mileageAmount, Decimal(7)) // 10 * 0.70
    XCTAssertEqual(result!.totalAmount, Decimal(7))
  }

  func testMileageCalculationWithReceipts() {
    let trip = makeTrip(miles: 10.0)
    let rate = makeRate(ratePerMile: Decimal(string: "0.70")!)
    let receipt = TripReceipt(tripId: trip.id, type: .parking, amount: Decimal(5))

    let result = calculator.calculateExpense(for: trip, rates: [rate], receipts: [receipt])

    XCTAssertNotNil(result)
    XCTAssertEqual(result!.mileageAmount, Decimal(7))
    XCTAssertEqual(result!.receiptsAmount, Decimal(5))
    XCTAssertEqual(result!.totalAmount, Decimal(12)) // 7 + 5
  }

  func testNoRateReturnsNil() {
    let trip = makeTrip(miles: 10.0)
    let result = calculator.calculateExpense(for: trip, rates: [], receipts: [])
    // With no rates, should still return using first rate fallback — but no rates at all means nil
    // Actually the code returns rates.first which is nil, so calculateExpense returns nil
    XCTAssertNil(result)
  }

  // MARK: - Zero miles

  func testZeroMilesReturnsZeroAmount() {
    let trip = makeTrip(miles: 0)
    let rate = makeRate()

    let result = calculator.calculateExpense(for: trip, rates: [rate], receipts: [])

    XCTAssertNotNil(result)
    XCTAssertEqual(result!.mileageAmount, Decimal(0))
  }

  // MARK: - ExpenseCalculation formatting

  func testFormattedTotal() {
    let calc = ExpenseCalculation(totalMiles: 10, mileageRate: Decimal(string: "0.70")!)
    let formatted = calc.formattedTotal()
    XCTAssertTrue(formatted.contains("7"), "Should contain the dollar amount 7")
  }

  func testMileageFormula() {
    let calc = ExpenseCalculation(totalMiles: 10, mileageRate: Decimal(string: "0.70")!)
    let formula = calc.mileageFormula
    XCTAssertTrue(formula.contains("10"), "Formula should contain miles")
    XCTAssertTrue(formula.contains("0.70") || formula.contains("$0.70"), "Formula should contain rate")
  }
}
