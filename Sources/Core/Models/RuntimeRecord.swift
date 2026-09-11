import Foundation

public struct RuntimeRecord: Codable, Equatable, Sendable {
    public let goVersion: String
    public let os: String
    public let arch: String
    public let gitCommit: String?
    public let gitDirty: Bool?

    enum CodingKeys: String, CodingKey {
        case goVersion = "go_version"
        case os
        case arch
        case gitCommit = "git_commit"
        case gitDirty = "git_dirty"
    }

    public init(goVersion: String, os: String, arch: String, gitCommit: String? = nil, gitDirty: Bool? = nil) {
        self.goVersion = goVersion
        self.os = os
        self.arch = arch
        self.gitCommit = gitCommit
        self.gitDirty = gitDirty
    }
}
