import Foundation

public enum RunDiscovery {
    public static func discover(in directory: URL) throws -> [LoadedRun] {
        let fm = FileManager.default
        let children = try fm.contentsOfDirectory(
            at: directory,
            includingPropertiesForKeys: [.isDirectoryKey],
            options: [.skipsHiddenFiles]
        )
        var runs: [LoadedRun] = []
        for child in children.sorted(by: { $0.lastPathComponent < $1.lastPathComponent }) {
            let values = try child.resourceValues(forKeys: [.isDirectoryKey])
            guard values.isDirectory == true else { continue }
            let manifest = child.appendingPathComponent("manifest.json")
            guard fm.fileExists(atPath: manifest.path) else { continue }
            if let run = try? RunLoader.load(child) {
                runs.append(run)
            }
        }
        return runs.sorted {
            if $0.manifest.startedAt != $1.manifest.startedAt {
                return $0.manifest.startedAt > $1.manifest.startedAt
            }
            return $0.manifest.runID < $1.manifest.runID
        }
    }
}
