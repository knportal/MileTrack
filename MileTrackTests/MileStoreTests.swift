import XCTest
@testable import MileTrack

final class MileStoreTests: XCTestCase {
  func testAddInsertsAtFrontAndNormalizesNote() {
    let store = MileStore()

    store.add(date: Date(timeIntervalSince1970: 0), miles: 1.25, note: "  ")
    XCTAssertEqual(store.entries.count, 1)
    XCTAssertNil(store.entries[0].note)

    store.add(date: Date(timeIntervalSince1970: 10), miles: 2.0, note: "  Trip  ")
    XCTAssertEqual(store.entries.count, 2)
    XCTAssertEqual(store.entries[0].miles, 2.0)
    XCTAssertEqual(store.entries[0].note, "Trip")
  }

  func testTotalMilesSumsEntries() {
    let store = MileStore()
    store.entries = [
      MileEntry(date: Date(), miles: 1.0, note: nil),
      MileEntry(date: Date(), miles: 2.5, note: nil),
    ]

    XCTAssertEqual(store.totalMiles, 3.5, accuracy: 0.000_1)
  }
}

