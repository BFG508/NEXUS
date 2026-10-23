import Foundation

public enum ManifestValidator {
    public static func validate(_ manifest: RunManifest) -> ValidationReport {
        var issues: [ValidationIssue] = []
        func error(_ path: String, _ message: String) {
            issues.append(.init(severity: .error, path: path, message: message))
        }
        func warning(_ path: String, _ message: String) {
            issues.append(.init(severity: .warning, path: path, message: message))
        }

        if manifest.schema != ATLASContract.supportedManifestSchema {
            error("schema", "unsupported schema \(manifest.schema)")
        }
        if manifest.runID.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            error("run_id", "run ID must not be empty")
        }
        if !isSHA256(manifest.runFingerprint) {
            error("run_fingerprint", "run fingerprint must be a 64-character hexadecimal SHA-256 value")
        }
        if manifest.scenario.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            error("scenario.name", "scenario name must not be empty")
        }
        if !isSHA256(manifest.scenario.sha256) {
            error("scenario.sha256", "scenario hash must be a 64-character hexadecimal SHA-256 value")
        }
        if manifest.finishedAt != nil && manifest.finishedAt! < manifest.startedAt {
            error("finished_at", "run finished_at precedes started_at")
        }
        if manifest.status.isTerminal && manifest.finishedAt == nil {
            error("finished_at", "terminal run status requires finished_at")
        }
        if manifest.status == .running && manifest.finishedAt != nil {
            warning("finished_at", "running run unexpectedly has finished_at")
        }

        var names = Set<String>()
        for (index, step) in manifest.steps.enumerated() {
            let base = "steps[\(index)]"
            if step.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                error("\(base).name", "step name must not be empty")
            }
            if !names.insert(step.name).inserted {
                error("\(base).name", "duplicate step name \(step.name)")
            }
            if step.dependsOn.contains(step.name) {
                error("\(base).depends_on", "step must not depend on itself")
            }
            if step.durationMS < 0 {
                error("\(base).duration_ms", "duration must be non-negative")
            }
            if let start = step.startedAt, let finish = step.finishedAt, finish < start {
                error("\(base).finished_at", "step finished_at precedes started_at")
            }
            if step.status == .succeeded || step.status == .failed {
                if step.startedAt == nil {
                    error("\(base).started_at", "executed terminal step requires started_at")
                }
                if step.finishedAt == nil {
                    error("\(base).finished_at", "executed terminal step requires finished_at")
                }
            }
            if step.status == .succeeded, step.exitCode != 0 {
                error("\(base).exit_code", "succeeded step must have exit code 0")
            }
            if step.timedOut && step.status != .failed {
                error("\(base).timed_out", "timed-out step must be failed")
            }
            for (artifactIndex, artifact) in step.artifacts.enumerated() {
                let artifactBase = "\(base).artifacts[\(artifactIndex)]"
                if artifact.path.isEmpty {
                    error("\(artifactBase).path", "artifact path must not be empty")
                }
                if artifact.sizeBytes < 0 {
                    error("\(artifactBase).size_bytes", "artifact size must be non-negative")
                }
                if !isSHA256(artifact.sha256) {
                    error("\(artifactBase).sha256", "artifact hash must be a 64-character hexadecimal SHA-256 value")
                }
            }
        }

        let known = Set(manifest.steps.map(\.name))
        for (index, step) in manifest.steps.enumerated() {
            for dependency in step.dependsOn where !known.contains(dependency) {
                error("steps[\(index)].depends_on", "unknown dependency \(dependency)")
            }
        }
        if hasCycle(manifest.steps) {
            error("steps", "dependency graph contains a cycle")
        }

        return ValidationReport(issues: issues)
    }

    public static func isSHA256(_ value: String) -> Bool {
        value.count == 64 && value.unicodeScalars.allSatisfy { scalar in
            switch scalar.value {
            case 48...57, 65...70, 97...102: true
            default: false
            }
        }
    }

    private static func hasCycle(_ steps: [StepRecord]) -> Bool {
        // Duplicate names are reported above. Merge their edges so malformed
        // input cannot trap here or hide a cycle in either occurrence.
        let dependencies = Dictionary(steps.map { ($0.name, $0.dependsOn) }, uniquingKeysWith: +)
        var visiting = Set<String>()
        var visited = Set<String>()

        func visit(_ node: String) -> Bool {
            if visiting.contains(node) { return true }
            if visited.contains(node) { return false }
            visiting.insert(node)
            for dependency in dependencies[node] ?? [] {
                if dependencies[dependency] != nil && visit(dependency) { return true }
            }
            visiting.remove(node)
            visited.insert(node)
            return false
        }

        return dependencies.keys.sorted().contains(where: visit)
    }
}
