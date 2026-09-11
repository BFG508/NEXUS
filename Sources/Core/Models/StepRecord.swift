import Foundation

public struct StepRecord: Codable, Equatable, Sendable, Identifiable {
    public var id: String { name }

    public let name: String
    public let status: RunStatus
    public let dependsOn: [String]
    public let command: String?
    public let args: [String]
    public let environmentOverrides: [String: String]
    public let startedAt: Date?
    public let finishedAt: Date?
    public let durationMS: Int64
    public let exitCode: Int?
    public let timedOut: Bool
    public let stdoutLog: String?
    public let stderrLog: String?
    public let artifacts: [ArtifactRecord]
    public let error: String?

    enum CodingKeys: String, CodingKey {
        case name, status, command, args, artifacts, error
        case dependsOn = "depends_on"
        case environmentOverrides = "environment_overrides"
        case startedAt = "started_at"
        case finishedAt = "finished_at"
        case durationMS = "duration_ms"
        case exitCode = "exit_code"
        case timedOut = "timed_out"
        case stdoutLog = "stdout_log"
        case stderrLog = "stderr_log"
    }

    public init(
        name: String,
        status: RunStatus,
        dependsOn: [String] = [],
        command: String? = nil,
        args: [String] = [],
        environmentOverrides: [String: String] = [:],
        startedAt: Date? = nil,
        finishedAt: Date? = nil,
        durationMS: Int64 = 0,
        exitCode: Int? = nil,
        timedOut: Bool = false,
        stdoutLog: String? = nil,
        stderrLog: String? = nil,
        artifacts: [ArtifactRecord] = [],
        error: String? = nil
    ) {
        self.name = name
        self.status = status
        self.dependsOn = dependsOn
        self.command = command
        self.args = args
        self.environmentOverrides = environmentOverrides
        self.startedAt = startedAt
        self.finishedAt = finishedAt
        self.durationMS = durationMS
        self.exitCode = exitCode
        self.timedOut = timedOut
        self.stdoutLog = stdoutLog
        self.stderrLog = stderrLog
        self.artifacts = artifacts
        self.error = error
    }

    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        name = try c.decode(String.self, forKey: .name)
        status = try c.decode(RunStatus.self, forKey: .status)
        dependsOn = try c.decodeIfPresent([String].self, forKey: .dependsOn) ?? []
        command = try c.decodeIfPresent(String.self, forKey: .command)
        args = try c.decodeIfPresent([String].self, forKey: .args) ?? []
        environmentOverrides = try c.decodeIfPresent([String: String].self, forKey: .environmentOverrides) ?? [:]
        startedAt = try c.decodeIfPresent(Date.self, forKey: .startedAt)
        finishedAt = try c.decodeIfPresent(Date.self, forKey: .finishedAt)
        durationMS = try c.decodeIfPresent(Int64.self, forKey: .durationMS) ?? 0
        exitCode = try c.decodeIfPresent(Int.self, forKey: .exitCode)
        timedOut = try c.decodeIfPresent(Bool.self, forKey: .timedOut) ?? false
        stdoutLog = try c.decodeIfPresent(String.self, forKey: .stdoutLog)
        stderrLog = try c.decodeIfPresent(String.self, forKey: .stderrLog)
        artifacts = try c.decodeIfPresent([ArtifactRecord].self, forKey: .artifacts) ?? []
        error = try c.decodeIfPresent(String.self, forKey: .error)
    }
}
