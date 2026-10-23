import Foundation

public struct RunManifest: Codable, Equatable, Sendable, Identifiable {
    public var id: String { runID }

    public let schema: String
    public let hermesVersion: String
    public let runID: String
    public let runFingerprint: String
    public let status: RunStatus
    public let scenario: ScenarioRecord
    public let workingDirectory: String
    public let runtime: RuntimeRecord
    public let startedAt: Date
    public let finishedAt: Date?
    public let telemetryPath: String
    public let steps: [StepRecord]

    enum CodingKeys: String, CodingKey {
        case schema, status, scenario, runtime, steps
        case hermesVersion = "hermes_version"
        case runID = "run_id"
        case runFingerprint = "run_fingerprint"
        case workingDirectory = "working_directory"
        case startedAt = "started_at"
        case finishedAt = "finished_at"
        case telemetryPath = "telemetry_path"
    }

    public init(
        schema: String,
        hermesVersion: String,
        runID: String,
        runFingerprint: String,
        status: RunStatus,
        scenario: ScenarioRecord,
        workingDirectory: String,
        runtime: RuntimeRecord,
        startedAt: Date,
        finishedAt: Date? = nil,
        telemetryPath: String,
        steps: [StepRecord]
    ) {
        self.schema = schema
        self.hermesVersion = hermesVersion
        self.runID = runID
        self.runFingerprint = runFingerprint
        self.status = status
        self.scenario = scenario
        self.workingDirectory = workingDirectory
        self.runtime = runtime
        self.startedAt = startedAt
        self.finishedAt = finishedAt
        self.telemetryPath = telemetryPath
        self.steps = steps
    }

    public var artifactCount: Int {
        steps.reduce(0) { $0 + $1.artifacts.count }
    }
}
