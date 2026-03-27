import XCTest
@testable import MileTrack

final class ExportServiceTests: XCTestCase {

  private let service = ExportService()

  private func makeTrip(
    date: Date = Date(timeIntervalSince1970: 1_700_000_000),
    miles: Double = 10.0,
    startLabel: String? = "Home",
    endLabel: String? = "Office",
    startAddress: String? = "123 Oak St, Austin, TX",
    endAddress: String? = "456 Elm St, Austin, TX",
    category: String? = "Business",
    state: TripState = .confirmed,
    purpose: String? = nil,
    clientOrOrg: String? = nil,
    notes: String? = nil
  ) -> Trip {
    Trip(
      date: date,
      distanceMiles: miles,
      startLabel: startLabel,
      endLabel: endLabel,
      startAddress: startAddress,
      endAddress: endAddress,
      source: .auto,
      state: state,
      category: category,
      clientOrOrg: clientOrOrg,
      notes: notes,
      purpose: purpose
    )
  }

  // MARK: - CSV header

  func testCSVHeaderColumns() {
    let csv = service.makeCSV(trips: [])
    let header = csv.components(separatedBy: "\n").first!
    let columns = header.components(separatedBy: ",")

    XCTAssertEqual(columns[0], "Date")
    XCTAssertEqual(columns[1], "From")
    XCTAssertEqual(columns[2], "To")
    XCTAssertEqual(columns[3], "Miles")
    XCTAssertEqual(columns[4], "Category")
    XCTAssertEqual(columns[5], "Purpose")
    XCTAssertEqual(columns[13], "Total Reimbursement")
    XCTAssertEqual(columns.count, 15)
  }

  // MARK: - Date format

  func testCSVDateFormatIsReadable() {
    let trip = makeTrip(date: Date(timeIntervalSince1970: 1_700_000_000))
    let csv = service.makeCSV(trips: [trip])
    let dataLine = csv.components(separatedBy: "\n")[1]

    // Date should be yyyy-MM-dd format (exact date depends on timezone)
    let dateField = dataLine.components(separatedBy: ",").first ?? ""
    XCTAssertTrue(dateField.count == 10, "Date should be 10 chars (yyyy-MM-dd), got: \(dateField)")
    XCTAssertFalse(dateField.contains("T"), "Date should not contain ISO 8601 time separator")
  }

  // MARK: - From/To columns combine address + label

  func testCSVFromColumnCombinesLabelAndAddress() {
    let trip = makeTrip(startLabel: "Home", startAddress: "123 Oak St, Austin, TX")
    let csv = service.makeCSV(trips: [trip])
    let dataLine = csv.components(separatedBy: "\n")[1]

    // "Home" is not contained in the address, so should be "Home — 123 Oak St, Austin, TX"
    XCTAssertTrue(dataLine.contains("Home"), "From should contain label")
    XCTAssertTrue(dataLine.contains("123 Oak St"), "From should contain address")
  }

  func testCSVFromColumnSkipsLabelWhenAddressContainsIt() {
    let trip = makeTrip(startLabel: "Austin", startAddress: "123 Oak St, Austin, TX")
    let csv = service.makeCSV(trips: [trip])
    let dataLine = csv.components(separatedBy: "\n")[1]

    // "Austin" is in the address, so label should be skipped
    XCTAssertFalse(dataLine.contains("Austin —"), "Should not duplicate label when address contains it")
  }

  func testCSVFromColumnFallsBackToLabel() {
    let trip = makeTrip(startLabel: "Home", startAddress: nil)
    let csv = service.makeCSV(trips: [trip])
    let dataLine = csv.components(separatedBy: "\n")[1]

    XCTAssertTrue(dataLine.contains("Home"))
  }

  // MARK: - Totals row

  func testCSVHasTotalsRow() {
    let t1 = makeTrip(miles: 10.0)
    let t2 = makeTrip(miles: 5.5)
    let csv = service.makeCSV(trips: [t1, t2])
    let lines = csv.components(separatedBy: "\n")

    // Find the TOTALS row (should be near the end)
    let totalsLine = lines.first(where: { $0.hasPrefix("TOTALS") })
    XCTAssertNotNil(totalsLine, "CSV should contain a TOTALS row")
    XCTAssertTrue(totalsLine!.contains("15.50"), "Totals should contain sum of miles (15.50)")
  }

  func testCSVEmptyTripsHasTotalsWithZero() {
    let csv = service.makeCSV(trips: [])
    let lines = csv.components(separatedBy: "\n")
    let totalsLine = lines.first(where: { $0.hasPrefix("TOTALS") })
    XCTAssertNotNil(totalsLine)
    XCTAssertTrue(totalsLine!.contains("0.00"))
  }

  // MARK: - CSV escaping

  func testCSVEscapesCommasInFields() {
    let trip = makeTrip(notes: "Meeting, lunch, and travel")
    let csv = service.makeCSV(trips: [trip])

    // Field with comma should be quoted
    XCTAssertTrue(csv.contains("\"Meeting, lunch, and travel\""))
  }

  func testCSVEscapesQuotesInFields() {
    let trip = makeTrip(notes: "Said \"hello\"")
    let csv = service.makeCSV(trips: [trip])

    // Quotes inside field should be doubled
    XCTAssertTrue(csv.contains("\"Said \"\"hello\"\"\""))
  }

  // MARK: - Filter logic

  func testConfirmedTripsFiltersOutPending() {
    let confirmed = makeTrip(state: .confirmed)
    let pending = makeTrip(state: .pendingCategory)
    let ignored = makeTrip(state: .ignored)

    let range = ExportDateRange(
      start: Date(timeIntervalSince1970: 0),
      end: Date(timeIntervalSince1970: 2_000_000_000)
    )
    let result = service.confirmedTrips(in: range, from: [confirmed, pending, ignored])

    XCTAssertEqual(result.count, 1)
    XCTAssertEqual(result.first?.id, confirmed.id)
  }

  func testConfirmedTripsFiltersByDateRange() {
    let inRange = makeTrip(date: Date(timeIntervalSince1970: 1_700_000_000))
    let outOfRange = makeTrip(date: Date(timeIntervalSince1970: 1_600_000_000))

    let range = ExportDateRange(
      start: Date(timeIntervalSince1970: 1_699_000_000),
      end: Date(timeIntervalSince1970: 1_701_000_000)
    )
    let result = service.confirmedTrips(in: range, from: [inRange, outOfRange])

    XCTAssertEqual(result.count, 1)
    XCTAssertEqual(result.first?.id, inRange.id)
  }

  // MARK: - File writing

  func testWriteCSVToTemporaryFile() throws {
    let csv = "Date,From,To\n2024-01-01,Home,Office\n"
    let url = try service.writeCSVToTemporaryFile(csv: csv, filename: "test_report")

    XCTAssertTrue(FileManager.default.fileExists(atPath: url.path))
    XCTAssertTrue(url.lastPathComponent.hasSuffix(".csv"))

    let contents = try String(contentsOf: url, encoding: .utf8)
    XCTAssertEqual(contents, csv)

    try? FileManager.default.removeItem(at: url)
  }
}
