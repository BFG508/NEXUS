import Foundation

public enum ATLASDecodingError: Error, LocalizedError, Equatable {
    case fileNotFound(String)
    case notAFileOrDirectory(String)
    case unsupportedSchema(String)
    case malformedManifest(String)
    case malformedTelemetry(line: Int, message: String)

    public var errorDescription: String? {
        switch self {
        case .fileNotFound(let path):
            "file not found: \(path)"
        case .notAFileOrDirectory(let path):
            "path is neither a regular file nor directory: \(path)"
        case .unsupportedSchema(let schema):
            "unsupported manifest schema \"\(schema)\""
        case .malformedManifest(let message):
            "malformed manifest: \(message)"
        case .malformedTelemetry(let line, let message):
            "malformed telemetry at line \(line): \(message)"
        }
    }
}
