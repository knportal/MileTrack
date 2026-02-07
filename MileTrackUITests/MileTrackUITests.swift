import XCTest

final class MileTrackUITests: XCTestCase {
  override func setUpWithError() throws {
    continueAfterFailure = false
  }

  func testAppLaunch() throws {
    let app = XCUIApplication()
    app.launch()

    // Verify the main view loads
    XCTAssertTrue(app.navigationBars["MileTrack"].exists)
  }
}
