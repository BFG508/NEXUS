import Foundation

public enum RunStatus: String, Codable, CaseIterable, Sendable {
    case pending
    case running
    case succeeded
    case failed
    case blocked

    public var isTerminal: Bool {
        switch self {
        case .succeeded, .failed, .blocked: true
        case .pending, .running: false
        }
    }
}
