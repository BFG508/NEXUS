import Foundation

public struct ArtifactRecord: Codable, Equatable, Sendable {
    public let path: String
    public let sizeBytes: Int64
    public let sha256: String

    enum CodingKeys: String, CodingKey {
        case path
        case sizeBytes = "size_bytes"
        case sha256
    }

    public init(path: String, sizeBytes: Int64, sha256: String) {
        self.path = path
        self.sizeBytes = sizeBytes
        self.sha256 = sha256
    }
}
