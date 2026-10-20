import XCTest

/// Snapshot UI tests. Run via `fastlane screenshots` on a Mac with iOS 26 simulators.
/// These tests drive the app with a mock/demo server so screenshots are deterministic.
final class AmpSnapshotTests: XCTestCase {
    var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments = ["-UITestDemoMode", "1"]
        setupSnapshot(app)
        app.launch()
    }

    func testCaptureLoginAndLibrary() {
        snapshot("01-Login")

        // In demo mode the app skips real sign-in and loads sample data.
        let artists = app.staticTexts["Artists"]
        XCTAssertTrue(artists.waitForExistence(timeout: 10))
        snapshot("02-Artists")

        app.staticTexts.firstMatch.tap()
        snapshot("03-Albums")

        app.images.firstMatch.tap()
        snapshot("04-Tracks")

        app.buttons["play.fill"].firstMatch.tap()
        snapshot("05-NowPlaying")
    }
}
