import Foundation
import ATLASCore

private func fail(_ message: String, code: Int32 = 1) -> Never {
    fputs("ATLAS: \(message)\n", stderr)
    exit(code)
}

private func usage() {
    print("""
    ATLAS - offline run inspection and visualization client

    Usage:
      atlas version
      atlas validate <run-directory|manifest.json>
      atlas inspect <run-directory|manifest.json>
      atlas timeline <run-directory|manifest.json>
      atlas artifacts [--verify] <run-directory|manifest.json>
      atlas discover <runs-directory>
    """)
}

private func load(_ path: String) throws -> LoadedRun {
    try RunLoader.load(URL(fileURLWithPath: path))
}

private func statusMarker(_ status: RunStatus) -> String {
    switch status {
    case .succeeded: "✓"
    case .failed: "✗"
    case .blocked: "-"
    case .running: "→"
    case .pending: "·"
    }
}

private func validateCommand(_ path: String) throws {
    let run = try load(path)
    let report = ManifestValidator.validate(run.manifest)
    if report.issues.isEmpty {
        print("[OK] \(run.manifest.runID): \(run.manifest.schema), \(run.manifest.steps.count) steps")
        return
    }
    for issue in report.issues {
        print("[\(issue.severity.rawValue.uppercased())] \(issue.path): \(issue.message)")
    }
    if !report.isValid {
        fail("manifest validation failed with \(report.errors.count) error(s)")
    }
}

private func inspectCommand(_ path: String) throws {
    let run = try load(path)
    let report = ManifestValidator.validate(run.manifest)
    guard report.isValid else {
        fail("manifest is invalid; run 'atlas validate' for details")
    }
    let summary = RunSummary(manifest: run.manifest)
    print("ATLAS \(ATLASCore.version)")
    print("run: \(summary.runID)")
    print("schema: \(run.manifest.schema)")
    print("HERMES: \(run.manifest.hermesVersion)")
    print("scenario: \(summary.scenario)")
    print("seed: \(run.manifest.scenario.seed)")
    print("fingerprint: \(run.manifest.runFingerprint)")
    print("status: \(summary.status.rawValue)")
    print("steps: \(summary.stepCount)")
    print("artifacts: \(summary.artifactCount)")
    print("started: \(ISO8601Coding.format(summary.startedAt))")
    if let finish = summary.finishedAt { print("finished: \(ISO8601Coding.format(finish))") }
    print("")
    for step in run.manifest.steps {
        print(String(format: "%@ %-24@ %-10@ %8lld ms", statusMarker(step.status), step.name as NSString, step.status.rawValue as NSString, step.durationMS))
    }
}

private func timelineCommand(_ path: String) throws {
    let run = try load(path)
    for entry in TimelineBuilder.build(from: run.manifest) {
        let subject = entry.step ?? run.manifest.runID
        let duration = entry.durationMS.map { " (\($0) ms)" } ?? ""
        print("\(ISO8601Coding.format(entry.timestamp))  \(entry.kind.rawValue)  \(subject)  \(entry.status.rawValue)\(duration)")
    }
}

private func artifactsCommand(_ args: [String]) throws {
    let verify = args.contains("--verify")
    let paths = args.filter { $0 != "--verify" }
    guard paths.count == 1 else { fail("usage: atlas artifacts [--verify] <run-directory|manifest.json>", code: 2) }
    let run = try load(paths[0])
    if verify {
        let results = ArtifactVerifier.verifyAll(in: run)
        var failures = 0
        for item in results {
            if item.status != .verified { failures += 1 }
            print("\(item.status.rawValue)\t\(item.step)\t\(item.artifact.path)")
        }
        if failures > 0 { fail("\(failures) artifact verification(s) did not pass") }
    } else {
        for step in run.manifest.steps {
            for artifact in step.artifacts.sorted(by: { $0.path < $1.path }) {
                print("\(step.name)\t\(artifact.sizeBytes)\t\(artifact.sha256)\t\(artifact.path)")
            }
        }
    }
}

private func discoverCommand(_ path: String) throws {
    let runs = try RunDiscovery.discover(in: URL(fileURLWithPath: path))
    for run in runs {
        print("\(ISO8601Coding.format(run.manifest.startedAt))\t\(run.manifest.status.rawValue)\t\(run.manifest.runID)\t\(run.manifest.scenario.name)")
    }
    print("runs: \(runs.count)")
}

let args = Array(CommandLine.arguments.dropFirst())
guard let command = args.first else {
    usage()
    exit(2)
}

do {
    switch command {
    case "version":
        print(ATLASCore.version)
    case "validate":
        guard args.count == 2 else { fail("usage: atlas validate <run-directory|manifest.json>", code: 2) }
        try validateCommand(args[1])
    case "inspect":
        guard args.count == 2 else { fail("usage: atlas inspect <run-directory|manifest.json>", code: 2) }
        try inspectCommand(args[1])
    case "timeline":
        guard args.count == 2 else { fail("usage: atlas timeline <run-directory|manifest.json>", code: 2) }
        try timelineCommand(args[1])
    case "artifacts":
        try artifactsCommand(Array(args.dropFirst()))
    case "discover":
        guard args.count == 2 else { fail("usage: atlas discover <runs-directory>", code: 2) }
        try discoverCommand(args[1])
    case "help", "-h", "--help":
        usage()
    default:
        usage()
        fail("unknown command \"\(command)\"", code: 2)
    }
} catch {
    fail(error.localizedDescription)
}
