import Foundation

public struct TelemetryEvent: Codable, Equatable, Sendable, Identifiable {
    public var id: String { "\(timestamp.timeIntervalSince1970)-\(runID)-\(step ?? "")-\(state)" }

    public let timestamp: Date
    public let runID: String
    public let step: String?
    public let state: String
    public let message: String?

    enum CodingKeys: String, CodingKey {
        case timestamp, step, state, message
        case runID = "run_id"
    }
}
