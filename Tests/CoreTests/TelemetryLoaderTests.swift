import XCTest
@testable import ATLASCore

final class TelemetryLoaderTests: XCTestCase {
    func testLoadsRelocatedTelemetry() throws {
        let root = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: root) }

        let base = fixtureManifest()
        try encodeManifest(base).write(to: root.appendingPathComponent("manifest.json"))
        let telemetry = #"{"timestamp":"2026-09-09T12:00:00.1Z","run_id":"test-run","state":"running"}"# + "\n"
        try telemetry.write(to: root.appendingPathComponent("telemetry.jsonl"), atomically: true, encoding: .utf8)

        let run = try RunLoader.load(root)
        let events = try TelemetryLoader.load(for: run)
        XCTAssertEqual(events.count, 1)
        XCTAssertEqual(events[0].runID, "test-run")
        XCTAssertTrue(TelemetryLoader.validateRunIDs(events, expectedRunID: "test-run").isEmpty)
    }
}
