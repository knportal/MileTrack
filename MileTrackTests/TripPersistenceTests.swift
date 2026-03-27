import XCTest
@testable import MileTrack

final class TripPersistenceTests: XCTestCase {

  private let testFilename = "test_trips_\(UUID().uuidString).json"
  private lazy var store = TripPersistenceStore(filename: testFilename)

  override func tearDown() {
    try? store.reset()
    super.tearDown()
  }

  // MARK: - Save and load round-trip

  func testSaveAndLoadTrips() throws {
    let trips = [
      Trip(date: Date(), distanceMiles: 5.0, source: .manual, state: .confirmed),
      Trip(date: Date(), distanceMiles: 10.0, source: .auto, state: .pendingCategory),
    ]

    try store.saveTrips(trips)
    let loaded = try store.loadTrips()

    XCTAssertEqual(loaded.count, 2)
    XCTAssertEqual(loaded[0].id, trips[0].id)
    XCTAssertEqual(loaded[1].id, trips[1].id)
    XCTAssertEqual(loaded[0].distanceMiles, 5.0)
    XCTAssertEqual(loaded[1].distanceMiles, 10.0)
  }

  // MARK: - Empty file

  func testLoadFromNonexistentFileReturnsEmpty() throws {
    let freshStore = TripPersistenceStore(filename: "nonexistent_\(UUID().uuidString).json")
    let trips = try freshStore.loadTrips()
    XCTAssertTrue(trips.isEmpty)
    XCTAssertEqual(freshStore.lastLoadSkippedCount, 0)
  }

  // MARK: - Preserves all fields

  func testAllFieldsPreservedAfterSaveLoad() throws {
    let vehicleID = UUID()
    let trip = Trip(
      date: Date(timeIntervalSince1970: 1_700_000_000),
      distanceMiles: 12.5,
      durationSeconds: 600,
      startLabel: "Home",
      endLabel: "Office",
      startAddress: "123 Oak St",
      endAddress: "456 Elm St",
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

    try store.saveTrips([trip])
    let loaded = try store.loadTrips()

    let t = loaded[0]
    XCTAssertEqual(t.startLabel, "Home")
    XCTAssertEqual(t.endLabel, "Office")
    XCTAssertEqual(t.startAddress, "123 Oak St")
    XCTAssertEqual(t.endAddress, "456 Elm St")
    XCTAssertEqual(t.startLatitude, 30.25)
    XCTAssertEqual(t.purpose, "Client meeting")
    XCTAssertEqual(t.vehicleID, vehicleID)
    XCTAssertEqual(t.waypoints, ["Coffee Shop"])
  }
}
