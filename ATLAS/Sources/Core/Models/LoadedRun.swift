import Foundation

public struct LoadedRun: Sendable {
    public let manifest: RunManifest
    public let manifestURL: URL
    public let runDirectory: URL

    public init(manifest: RunManifest, manifestURL: URL, runDirectory: URL) {
        self.manifest = manifest
        self.manifestURL = manifestURL
        self.runDirectory = runDirectory
    }
}
