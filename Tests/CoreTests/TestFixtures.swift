import Foundation
@testable import ATLASCore

func fixtureManifest(
    status: RunStatus = .succeeded,
    steps: [StepRecord]? = nil
) -> RunManifest {
    let start = Date(timeIntervalSince1970: 1_000)
    let stepStart = Date(timeIntervalSince1970: 1_001)
    let stepFinish = Date(timeIntervalSince1970: 1_002)
    let defaultSteps = [
        StepRecord(
            name: "prepare",
            status: .succeeded,
            startedAt: stepStart,
            finishedAt: stepFinish,
            durationMS: 1_000,
            exitCode: 0
        )
    ]
    return RunManifest(
        schema: ATLASContract.supportedManifestSchema,
        hermesVersion: "0.1.0",
        runID: "test-run",
        runFingerprint: String(repeating: "a", count: 64),
        status: status,
        scenario: ScenarioRecord(
            name: "test",
            path: "/tmp/scenario.yaml",
            sha256: String(repeating: "b", count: 64),
            seed: 42
        ),
        workingDirectory: "/tmp",
        runtime: RuntimeRecord(goVersion: "go1.22", os: "linux", arch: "amd64"),
        startedAt: start,
        finishedAt: status.isTerminal ? Date(timeIntervalSince1970: 1_003) : nil,
        telemetryPath: "/tmp/telemetry.jsonl",
        steps: steps ?? defaultSteps
    )
}

func encodeManifest(_ manifest: RunManifest) throws -> Data {
    let encoder = JSONEncoder()
    encoder.outputFormatting = [.sortedKeys]
    encoder.dateEncodingStrategy = .custom { date, encoder in
        var container = encoder.singleValueContainer()
        try container.encode(ISO8601Coding.format(date))
    }
    return try encoder.encode(manifest)
}
