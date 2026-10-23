import Foundation

public enum RunLoader {
    public static func load(_ url: URL) throws -> LoadedRun {
        let fm = FileManager.default
        var isDirectory: ObjCBool = false
        guard fm.fileExists(atPath: url.path, isDirectory: &isDirectory) else {
            throw ATLASDecodingError.fileNotFound(url.path)
        }

        let manifestURL: URL
        let runDirectory: URL
        if isDirectory.boolValue {
            runDirectory = url.standardizedFileURL
            manifestURL = runDirectory.appendingPathComponent("manifest.json", isDirectory: false)
        } else {
            guard url.lastPathComponent == "manifest.json" || url.pathExtension.lowercased() == "json" else {
                throw ATLASDecodingError.notAFileOrDirectory(url.path)
            }
            manifestURL = url.standardizedFileURL
            runDirectory = manifestURL.deletingLastPathComponent()
        }

        guard fm.fileExists(atPath: manifestURL.path) else {
            throw ATLASDecodingError.fileNotFound(manifestURL.path)
        }
        let data = try Data(contentsOf: manifestURL)
        let manifest = try ManifestDecoder.decode(data)
        return LoadedRun(manifest: manifest, manifestURL: manifestURL, runDirectory: runDirectory)
    }
}
