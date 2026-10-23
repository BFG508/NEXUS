import Foundation

public enum ValidationSeverity: String, Codable, Sendable {
    case warning
    case error
}

public struct ValidationIssue: Equatable, Sendable, Identifiable {
    public let severity: ValidationSeverity
    public let path: String
    public let message: String

    public var id: String { "\(severity.rawValue):\(path):\(message)" }

    public init(severity: ValidationSeverity, path: String, message: String) {
        self.severity = severity
        self.path = path
        self.message = message
    }
}

public struct ValidationReport: Sendable {
    public let issues: [ValidationIssue]

    public var errors: [ValidationIssue] { issues.filter { $0.severity == .error } }
    public var warnings: [ValidationIssue] { issues.filter { $0.severity == .warning } }
    public var isValid: Bool { errors.isEmpty }

    public init(issues: [ValidationIssue]) {
        self.issues = issues
    }
}
