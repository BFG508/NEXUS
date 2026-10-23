import XCTest
@testable import ATLASCore

final class RunDiscoveryTests: XCTestCase {
    func testDiscoversNewestFirst() throws {
        let root = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: root) }

        for (name, offset) in [("old", 0.0), ("new", 100.0)] {
            let dir = root.appendingPathComponent(name)
            try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
            let base = fixtureManifest()
            let manifest = RunManifest(
                schema: base.schema, hermesVersion: base.hermesVersion, runID: name,
                runFingerprint: base.runFingerprint, status: base.status,
                scenario: base.scenario, workingDirectory: base.workingDirectory,
                runtime: base.runtime, startedAt: base.startedAt.addingTimeInterval(offset),
                finishedAt: base.finishedAt?.addingTimeInterval(offset),
                telemetryPath: base.telemetryPath, steps: base.steps
            )
            try encodeManifest(manifest).write(to: dir.appendingPathComponent("manifest.json"))
        }

        let runs = try RunDiscovery.discover(in: root)
        XCTAssertEqual(runs.map { $0.manifest.runID }, ["new", "old"])
    }
}
