import XCTest
@testable import MileTrack

/// Tests for TripStore.merge() logic.
/// Uses @MainActor since TripStore is @MainActor-isolated.
@MainActor
final class TripMergeTests: XCTestCase {

  private func makeTrip(
    date: Date = Date(),
    miles: Double = 5.0,
    duration: Int? = 300,
    startLabel: String? = nil,
    endLabel: String? = nil,
    startAddress: String? = nil,
    endAddress: String? = nil,
    state: TripState = .pendingCategory,
    category: String? = nil,
    clientOrOrg: String? = nil,
    purpose: String? = nil,
    vehicleID: UUID? = nil,
    notes: String? = nil
  ) -> Trip {
    Trip(
      date: date,
      distanceMiles: miles,
      durationSeconds: duration,
      startLabel: startLabel,
      endLabel: endLabel,
      startAddress: startAddress,
      endAddress: endAddress,
      source: .auto,
      state: state,
      category: category,
      clientOrOrg: clientOrOrg,
      notes: notes,
      purpose: purpose,
      vehicleID: vehicleID
    )
  }

  // MARK: - Basic merge

  func testMergeTwoTrips() {
    let t1 = makeTrip(date: Date(timeIntervalSince1970: 1000), miles: 5, startLabel: "Home", endLabel: "Shop")
    let t2 = makeTrip(date: Date(timeIntervalSince1970: 2000), miles: 3, startLabel: "Shop", endLabel: "Office")
    let store = TripStore(trips: [t1, t2])

    let merged = store.merge(trips: [t1, t2])

    XCTAssertNotNil(merged)
    XCTAssertEqual(merged!.distanceMiles, 8.0, accuracy: 0.001)
    XCTAssertEqual(merged!.startLabel, "Home")
    XCTAssertEqual(merged!.endLabel, "Office")
  }

  func testMergeSumsDuration() {
    let t1 = makeTrip(date: Date(timeIntervalSince1970: 1000), miles: 5, duration: 300)
    let t2 = makeTrip(date: Date(timeIntervalSince1970: 2000), miles: 3, duration: 200)
    let store = TripStore(trips: [t1, t2])

    let merged = store.merge(trips: [t1, t2])!
    XCTAssertEqual(merged.durationSeconds, 500)
  }

  func testMergeUsesEarliestDate() {
    let early = Date(timeIntervalSince1970: 1000)
    let late = Date(timeIntervalSince1970: 2000)
    let t1 = makeTrip(date: late, miles: 5)
    let t2 = makeTrip(date: early, miles: 3)
    let store = TripStore(trips: [t1, t2])

    let merged = store.merge(trips: [t1, t2])!
    XCTAssertEqual(merged.date, early)
  }

  // MARK: - Single trip rejection

  func testMergeSingleTripReturnsNil() {
    let t1 = makeTrip()
    let store = TripStore(trips: [t1])

    let merged = store.merge(trips: [t1])
    XCTAssertNil(merged)
  }

  // MARK: - State logic

  func testMergeAllConfirmedProducesConfirmed() {
    let t1 = makeTrip(state: .confirmed)
    let t2 = makeTrip(state: .confirmed)
    let store = TripStore(trips: [t1, t2])

    let merged = store.merge(trips: [t1, t2])!
    XCTAssertEqual(merged.state, .confirmed)
  }

  func testMergeMixedStateProducesPending() {
    let t1 = makeTrip(state: .confirmed)
    let t2 = makeTrip(state: .pendingCategory)
    let store = TripStore(trips: [t1, t2])

    let merged = store.merge(trips: [t1, t2])!
    XCTAssertEqual(merged.state, .pendingCategory)
  }

  // MARK: - Common value resolution

  func testMergeKeepsCategoryWhenAllMatch() {
    let t1 = makeTrip(category: "Business")
    let t2 = makeTrip(category: "Business")
    let store = TripStore(trips: [t1, t2])

    let merged = store.merge(trips: [t1, t2])!
    XCTAssertEqual(merged.category, "Business")
  }

  func testMergeDropsCategoryWhenDifferent() {
    let t1 = makeTrip(category: "Business")
    let t2 = makeTrip(category: "Personal")
    let store = TripStore(trips: [t1, t2])

    let merged = store.merge(trips: [t1, t2])!
    XCTAssertNil(merged.category)
  }

  func testMergeKeepsSharedVehicle() {
    let vid = UUID()
    let t1 = makeTrip(vehicleID: vid)
    let t2 = makeTrip(vehicleID: vid)
    let store = TripStore(trips: [t1, t2])

    let merged = store.merge(trips: [t1, t2])!
    XCTAssertEqual(merged.vehicleID, vid)
  }

  func testMergeDropsVehicleWhenDifferent() {
    let t1 = makeTrip(vehicleID: UUID())
    let t2 = makeTrip(vehicleID: UUID())
    let store = TripStore(trips: [t1, t2])

    let merged = store.merge(trips: [t1, t2])!
    XCTAssertNil(merged.vehicleID)
  }

  func testMergeJoinsNotes() {
    let t1 = makeTrip(notes: "Note A")
    let t2 = makeTrip(notes: "Note B")
    let store = TripStore(trips: [t1, t2])

    let merged = store.merge(trips: [t1, t2])!
    XCTAssertEqual(merged.notes, "Note A | Note B")
  }

  // MARK: - Waypoints

  func testMergeCreatesWaypointsFromIntermediateStops() {
    let t1 = makeTrip(date: Date(timeIntervalSince1970: 1000), endLabel: "Coffee Shop", endAddress: "123 Main St")
    let t2 = makeTrip(date: Date(timeIntervalSince1970: 2000), endLabel: "Office")
    let store = TripStore(trips: [t1, t2])

    let merged = store.merge(trips: [t1, t2])!
    XCTAssertNotNil(merged.waypoints)
    XCTAssertEqual(merged.waypoints?.count, 1)
    XCTAssertTrue(merged.waypoints![0].contains("123 Main St"))
  }

  func testMergeThreeTripsCreatesTwoWaypoints() {
    let t1 = makeTrip(date: Date(timeIntervalSince1970: 1000), endLabel: "Stop A")
    let t2 = makeTrip(date: Date(timeIntervalSince1970: 2000), endLabel: "Stop B")
    let t3 = makeTrip(date: Date(timeIntervalSince1970: 3000), endLabel: "End")
    let store = TripStore(trips: [t1, t2, t3])

    let merged = store.merge(trips: [t1, t2, t3])!
    XCTAssertEqual(merged.waypoints?.count, 2)
    XCTAssertEqual(merged.waypoints?[0], "Stop A")
    XCTAssertEqual(merged.waypoints?[1], "Stop B")
  }

  // MARK: - Source trips marked ignored

  func testMergeMarksSourceTripsAsIgnored() {
    let t1 = makeTrip(state: .pendingCategory)
    let t2 = makeTrip(state: .pendingCategory)
    let store = TripStore(trips: [t1, t2])

    store.merge(trips: [t1, t2])

    let source1 = store.trips.first(where: { $0.id == t1.id })
    let source2 = store.trips.first(where: { $0.id == t2.id })
    XCTAssertEqual(source1?.state, .ignored)
    XCTAssertEqual(source2?.state, .ignored)
  }
}
