import XCTest
@testable import ATLASCore

final class TimelineTests: XCTestCase {
    func testTimelineIsChronological() {
        let entries = TimelineBuilder.build(from: fixtureManifest())
        XCTAssertEqual(entries.first?.kind, .runStarted)
        XCTAssertEqual(entries.last?.kind, .runFinished)
        XCTAssertEqual(entries.map(\.timestamp), entries.map(\.timestamp).sorted())
    }
}
