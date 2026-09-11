import Foundation

public enum TimelineKind: String, Sendable {
    case runStarted = "run_started"
    case stepStarted = "step_started"
    case stepFinished = "step_finished"
    case runFinished = "run_finished"
}

public struct TimelineEntry: Equatable, Sendable, Identifiable {
    public var id: String { "\(timestamp.timeIntervalSince1970)-\(kind.rawValue)-\(step ?? "")" }

    public let timestamp: Date
    public let kind: TimelineKind
    public let step: String?
    public let status: RunStatus
    public let durationMS: Int64?

    public init(timestamp: Date, kind: TimelineKind, step: String?, status: RunStatus, durationMS: Int64? = nil) {
        self.timestamp = timestamp
        self.kind = kind
        self.step = step
        self.status = status
        self.durationMS = durationMS
    }
}

public enum TimelineBuilder {
    public static func build(from manifest: RunManifest) -> [TimelineEntry] {
        var entries: [TimelineEntry] = [
            TimelineEntry(timestamp: manifest.startedAt, kind: .runStarted, step: nil, status: .running)
        ]
        for step in manifest.steps {
            if let start = step.startedAt {
                entries.append(.init(timestamp: start, kind: .stepStarted, step: step.name, status: .running))
            }
            if let finish = step.finishedAt {
                entries.append(.init(timestamp: finish, kind: .stepFinished, step: step.name, status: step.status, durationMS: step.durationMS))
            }
        }
        if let finish = manifest.finishedAt {
            entries.append(.init(timestamp: finish, kind: .runFinished, step: nil, status: manifest.status))
        }
        let rank: [TimelineKind: Int] = [.runStarted: 0, .stepStarted: 1, .stepFinished: 2, .runFinished: 3]
        return entries.sorted {
            if $0.timestamp != $1.timestamp { return $0.timestamp < $1.timestamp }
            if rank[$0.kind, default: 99] != rank[$1.kind, default: 99] {
                return rank[$0.kind, default: 99] < rank[$1.kind, default: 99]
            }
            return ($0.step ?? "") < ($1.step ?? "")
        }
    }
}
