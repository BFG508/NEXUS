import XCTest
@testable import ATLASCore

final class ManifestValidatorTests: XCTestCase {
    func testValidManifestPasses() {
        XCTAssertTrue(ManifestValidator.validate(fixtureManifest()).isValid)
    }

    func testUnknownDependencyFails() {
        let step = StepRecord(
            name: "b",
            status: .succeeded,
            dependsOn: ["missing"],
            startedAt: Date(timeIntervalSince1970: 1_001),
            finishedAt: Date(timeIntervalSince1970: 1_002),
            durationMS: 1,
            exitCode: 0
        )
        let report = ManifestValidator.validate(fixtureManifest(steps: [step]))
        XCTAssertFalse(report.isValid)
        XCTAssertTrue(report.errors.contains { $0.message.contains("unknown dependency") })
    }

    func testDuplicateNamesAreReportedWithoutCrashing() {
        let step = fixtureManifest().steps[0]
        let report = ManifestValidator.validate(fixtureManifest(steps: [step, step]))
        XCTAssertFalse(report.isValid)
        XCTAssertTrue(report.errors.contains { $0.message.contains("duplicate step name") })
    }

    func testDuplicateNamesDoNotHideCycles() {
        let a = StepRecord(name: "a", status: .pending)
        let duplicate = StepRecord(name: "a", status: .pending, dependsOn: ["b"])
        let b = StepRecord(name: "b", status: .pending, dependsOn: ["a"])
        let report = ManifestValidator.validate(fixtureManifest(steps: [a, duplicate, b]))
        XCTAssertFalse(report.isValid)
        XCTAssertTrue(report.errors.contains { $0.message.contains("duplicate step name") })
        XCTAssertTrue(report.errors.contains { $0.message.contains("cycle") })
    }

    func testPreparationFailureWithoutProcessExitCodeIsValid() {
        let step = StepRecord(
            name: "prepare", status: .failed,
            startedAt: Date(timeIntervalSince1970: 1_001),
            finishedAt: Date(timeIntervalSince1970: 1_002),
            durationMS: 1_000, error: "unknown variable ${UNKNOWN}"
        )
        XCTAssertTrue(ManifestValidator.validate(fixtureManifest(status: .failed, steps: [step])).isValid)
    }

    func testFailedStepStillRequiresTiming() {
        let step = StepRecord(name: "prepare", status: .failed, error: "preparation failed")
        let report = ManifestValidator.validate(fixtureManifest(status: .failed, steps: [step]))
        XCTAssertTrue(report.errors.contains { $0.path == "steps[0].started_at" })
        XCTAssertTrue(report.errors.contains { $0.path == "steps[0].finished_at" })
    }

    func testCycleFails() {
        let t0 = Date(timeIntervalSince1970: 1_001)
        let t1 = Date(timeIntervalSince1970: 1_002)
        let a = StepRecord(name: "a", status: .succeeded, dependsOn: ["b"], startedAt: t0, finishedAt: t1, durationMS: 1, exitCode: 0)
        let b = StepRecord(name: "b", status: .succeeded, dependsOn: ["a"], startedAt: t0, finishedAt: t1, durationMS: 1, exitCode: 0)
        let report = ManifestValidator.validate(fixtureManifest(steps: [a, b]))
        XCTAssertFalse(report.isValid)
        XCTAssertTrue(report.errors.contains { $0.message.contains("cycle") })
    }

    func testTerminalRunRequiresFinish() {
        let base = fixtureManifest()
        let invalid = RunManifest(
            schema: base.schema, hermesVersion: base.hermesVersion, runID: base.runID,
            runFingerprint: base.runFingerprint, status: .succeeded,
            scenario: base.scenario, workingDirectory: base.workingDirectory,
            runtime: base.runtime, startedAt: base.startedAt, finishedAt: nil,
            telemetryPath: base.telemetryPath, steps: base.steps
        )
        XCTAssertFalse(ManifestValidator.validate(invalid).isValid)
    }
}
