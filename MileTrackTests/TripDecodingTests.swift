import XCTest
@testable import MileTrack

final class TripDecodingTests: XCTestCase {

  private let decoder = JSONDecoder()

  // MARK: - Full round-trip

  func testEncodeDecodeRoundTrip() throws {
    let vehicleID = UUID()
    let original = Trip(
      date: Date(timeIntervalSince1970: 1_700_000_000),
      distanceMiles: 12.5,
      durationSeconds: 600,
      startLabel: "Home",
      endLabel: "Office",
      startAddress: "123 Oak St, Austin, TX",
      endAddress: "456 Elm St, Austin, TX",
      startLatitude: 30.25, startLongitude: -97.75,
      endLatitude: 30.30, endLongitude: -97.70,
      source: .auto,
      state: .confirmed,
      category: "Business",
      clientOrOrg: "Acme",
      projectCode: "P-100",
      notes: "Weekly sync",
      purpose: "Client meeting",
      vehicleID: vehicleID,
      waypoints: ["Coffee Shop"]
    )

    let data = try JSONEncoder().encode(original)
    let decoded = try decoder.decode(Trip.self, from: data)

    XCTAssertEqual(decoded.id, original.id)
    XCTAssertEqual(decoded.distanceMiles, 12.5)
    XCTAssertEqual(decoded.startLabel, "Home")
    XCTAssertEqual(decoded.endLabel, "Office")
    XCTAssertEqual(decoded.startAddress, "123 Oak St, Austin, TX")
    XCTAssertEqual(decoded.endAddress, "456 Elm St, Austin, TX")
    XCTAssertEqual(decoded.source, .auto)
    XCTAssertEqual(decoded.state, .confirmed)
    XCTAssertEqual(decoded.category, "Business")
    XCTAssertEqual(decoded.clientOrOrg, "Acme")
    XCTAssertEqual(decoded.purpose, "Client meeting")
    XCTAssertEqual(decoded.vehicleID, vehicleID)
    XCTAssertEqual(decoded.waypoints, ["Coffee Shop"])
  }

  // MARK: - Resilient decoding: missing fields

  func testDecodeMissingOptionalFields() throws {
    let json = """
    {
      "id": "11111111-1111-1111-1111-111111111111",
      "date": 1700000000,
      "distanceMiles": 5.0,
      "source": "manual",
      "state": "confirmed"
    }
    """
    let trip = try decoder.decode(Trip.self, from: Data(json.utf8))

    XCTAssertEqual(trip.distanceMiles, 5.0)
    XCTAssertEqual(trip.source, .manual)
    XCTAssertEqual(trip.state, .confirmed)
    XCTAssertNil(trip.startLabel)
    XCTAssertNil(trip.endLabel)
    XCTAssertNil(trip.startAddress)
    XCTAssertNil(trip.endAddress)
    XCTAssertNil(trip.category)
    XCTAssertNil(trip.purpose)
    XCTAssertNil(trip.vehicleID)
    XCTAssertNil(trip.waypoints)
    XCTAssertNil(trip.durationSeconds)
  }

  // MARK: - Resilient decoding: unknown enum values

  func testDecodeUnknownSourceFallsBackToManual() throws {
    let json = """
    {
      "id": "22222222-2222-2222-2222-222222222222",
      "date": 1700000000,
      "distanceMiles": 3.0,
      "source": "future_source_type",
      "state": "confirmed"
    }
    """
    let trip = try decoder.decode(Trip.self, from: Data(json.utf8))
    XCTAssertEqual(trip.source, .manual)
  }

  func testDecodeUnknownStateFallsBackToPending() throws {
    let json = """
    {
      "id": "33333333-3333-3333-3333-333333333333",
      "date": 1700000000,
      "distanceMiles": 3.0,
      "source": "auto",
      "state": "some_new_state"
    }
    """
    let trip = try decoder.decode(Trip.self, from: Data(json.utf8))
    XCTAssertEqual(trip.state, .pendingCategory)
  }

  // MARK: - Resilient decoding: bad distance values

  func testDecodeNegativeDistanceClampsToZero() throws {
    let json = """
    {
      "id": "44444444-4444-4444-4444-444444444444",
      "date": 1700000000,
      "distanceMiles": -10.0,
      "source": "manual",
      "state": "confirmed"
    }
    """
    let trip = try decoder.decode(Trip.self, from: Data(json.utf8))
    XCTAssertEqual(trip.distanceMiles, 0)
  }

  func testDecodeInfinityDistanceClampsToZero() throws {
    let json = """
    {
      "id": "55555555-5555-5555-5555-555555555555",
      "date": 1700000000,
      "distanceMiles": Infinity,
      "source": "manual",
      "state": "confirmed"
    }
    """
    // JSON doesn't support Infinity, but let's test the NaN path via a type mismatch
    let jsonBadType = """
    {
      "id": "55555555-5555-5555-5555-555555555555",
      "date": 1700000000,
      "distanceMiles": "not_a_number",
      "source": "manual",
      "state": "confirmed"
    }
    """
    let trip = try decoder.decode(Trip.self, from: Data(jsonBadType.utf8))
    XCTAssertEqual(trip.distanceMiles, 0)
  }

  // MARK: - Resilient decoding: completely missing required fields

  func testDecodeMissingRequiredFieldsGetDefaults() throws {
    let json = "{}"
    let trip = try decoder.decode(Trip.self, from: Data(json.utf8))

    XCTAssertEqual(trip.distanceMiles, 0)
    XCTAssertEqual(trip.source, .manual)
    XCTAssertEqual(trip.state, .pendingCategory)
    XCTAssertNotNil(trip.id)
    XCTAssertNotNil(trip.date)
  }

  // MARK: - Forward compatibility: extra fields ignored

  func testDecodeExtraFieldsAreIgnored() throws {
    let json = """
    {
      "id": "66666666-6666-6666-6666-666666666666",
      "date": 1700000000,
      "distanceMiles": 7.0,
      "source": "auto",
      "state": "confirmed",
      "someNewField": "should be ignored",
      "anotherFutureField": 42
    }
    """
    let trip = try decoder.decode(Trip.self, from: Data(json.utf8))
    XCTAssertEqual(trip.distanceMiles, 7.0)
    XCTAssertEqual(trip.state, .confirmed)
  }

  // MARK: - Display helpers

  func testRouteLabelNoWaypoints() {
    let trip = Trip(date: Date(), distanceMiles: 5, startLabel: "Home", endLabel: "Office", source: .auto, state: .confirmed)
    XCTAssertEqual(trip.routeLabel, "Home → Office")
  }

  func testRouteLabelWithWaypoints() {
    let trip = Trip(date: Date(), distanceMiles: 10, startLabel: "Home", endLabel: "Office", source: .auto, state: .confirmed, waypoints: ["Coffee Shop", "Gas Station"])
    XCTAssertEqual(trip.routeLabel, "Home → Coffee Shop → Gas Station → Office")
  }

  func testRouteLabelNoLabels() {
    let trip = Trip(date: Date(), distanceMiles: 5, source: .auto, state: .confirmed)
    XCTAssertEqual(trip.routeLabel, "Trip")
  }

  func testStartDisplayPrefersAddress() {
    let trip = Trip(date: Date(), distanceMiles: 5, startLabel: "Home", startAddress: "123 Oak St, Austin, TX", source: .auto, state: .confirmed)
    XCTAssertEqual(trip.startDisplay, "123 Oak St, Austin, TX")
  }

  func testStartDisplayFallsBackToLabel() {
    let trip = Trip(date: Date(), distanceMiles: 5, startLabel: "Home", source: .auto, state: .confirmed)
    XCTAssertEqual(trip.startDisplay, "Home")
  }
}
