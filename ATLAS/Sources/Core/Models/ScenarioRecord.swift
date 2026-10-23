import Foundation

public struct ScenarioRecord: Codable, Equatable, Sendable {
    public let name: String
    public let path: String
    public let sha256: String
    public let seed: Int64

    public init(name: String, path: String, sha256: String, seed: Int64) {
        self.name = name
        self.path = path
        self.sha256 = sha256
        self.seed = seed
    }
}
