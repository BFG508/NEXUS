import Foundation

public enum ArtifactVerificationStatus: String, Sendable {
    case verified
    case missing
    case sizeMismatch = "size_mismatch"
    case hashMismatch = "hash_mismatch"
    case unreadable
}

public struct ArtifactVerification: Sendable, Identifiable {
    public var id: String { "\(step):\(artifact.path)" }

    public let step: String
    public let artifact: ArtifactRecord
    public let resolvedURL: URL?
    public let status: ArtifactVerificationStatus
    public let actualSizeBytes: Int64?
    public let actualSHA256: String?
    public let message: String?
}

public enum ArtifactVerifier {
    public static func verifyAll(in run: LoadedRun) -> [ArtifactVerification] {
        run.manifest.steps.flatMap { step in
            step.artifacts.map { verify($0, step: step.name, runDirectory: run.runDirectory) }
        }.sorted {
            if $0.step != $1.step { return $0.step < $1.step }
            return $0.artifact.path < $1.artifact.path
        }
    }

    public static func resolve(_ artifact: ArtifactRecord, runDirectory: URL) -> URL? {
        let fm = FileManager.default
        let recorded = URL(fileURLWithPath: artifact.path)
        if fm.fileExists(atPath: recorded.path) { return recorded }

        let components = recorded.pathComponents
        if let artifactsIndex = components.lastIndex(of: "artifacts"), artifactsIndex + 1 < components.count {
            let suffix = components[(artifactsIndex + 1)...]
            var candidate = runDirectory.appendingPathComponent("artifacts", isDirectory: true)
            for component in suffix {
                candidate.appendPathComponent(component)
            }
            if fm.fileExists(atPath: candidate.path) { return candidate }
        }
        return nil
    }

    public static func verify(_ artifact: ArtifactRecord, step: String, runDirectory: URL) -> ArtifactVerification {
        guard let url = resolve(artifact, runDirectory: runDirectory) else {
            return ArtifactVerification(
                step: step, artifact: artifact, resolvedURL: nil, status: .missing,
                actualSizeBytes: nil, actualSHA256: nil, message: "artifact file not found"
            )
        }
        do {
            let attrs = try FileManager.default.attributesOfItem(atPath: url.path)
            let size = (attrs[.size] as? NSNumber)?.int64Value
            guard size == artifact.sizeBytes else {
                return ArtifactVerification(
                    step: step, artifact: artifact, resolvedURL: url, status: .sizeMismatch,
                    actualSizeBytes: size, actualSHA256: nil,
                    message: "expected \(artifact.sizeBytes) bytes, got \(size ?? -1)"
                )
            }
            let hash = try SHA256.hexDigest(fileAt: url)
            guard hash.caseInsensitiveCompare(artifact.sha256) == .orderedSame else {
                return ArtifactVerification(
                    step: step, artifact: artifact, resolvedURL: url, status: .hashMismatch,
                    actualSizeBytes: size, actualSHA256: hash, message: "SHA-256 mismatch"
                )
            }
            return ArtifactVerification(
                step: step, artifact: artifact, resolvedURL: url, status: .verified,
                actualSizeBytes: size, actualSHA256: hash, message: nil
            )
        } catch {
            return ArtifactVerification(
                step: step, artifact: artifact, resolvedURL: url, status: .unreadable,
                actualSizeBytes: nil, actualSHA256: nil, message: error.localizedDescription
            )
        }
    }
}
