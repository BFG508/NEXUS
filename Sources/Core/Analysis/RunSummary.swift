import Foundation

public struct RunSummary: Equatable, Sendable {
    public let runID: String
    public let scenario: String
    public let status: RunStatus
    public let stepCount: Int
    public let artifactCount: Int
    public let totalRecordedDurationMS: Int64
    public let startedAt: Date
    public let finishedAt: Date?

    public init(manifest: RunManifest) {
        runID = manifest.runID
        scenario = manifest.scenario.name
        status = manifest.status
        stepCount = manifest.steps.count
        artifactCount = manifest.artifactCount
        totalRecordedDurationMS = manifest.steps.reduce(0) { $0 + $1.durationMS }
        startedAt = manifest.startedAt
        finishedAt = manifest.finishedAt
    }
}
