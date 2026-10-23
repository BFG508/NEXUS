import Foundation

public enum TelemetryLoader {
    public static func load(for run: LoadedRun) throws -> [TelemetryEvent] {
        guard let url = resolveTelemetryURL(for: run) else { return [] }
        let text = try String(contentsOf: url, encoding: .utf8)
        var events: [TelemetryEvent] = []
        for (index, rawLine) in text.split(whereSeparator: \.isNewline).enumerated() {
            let line = String(rawLine)
            guard !line.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { continue }
            do {
                let event = try ISO8601Coding.makeDecoder().decode(TelemetryEvent.self, from: Data(line.utf8))
                events.append(event)
            } catch {
                throw ATLASDecodingError.malformedTelemetry(line: index + 1, message: error.localizedDescription)
            }
        }
        return events.sorted {
            if $0.timestamp != $1.timestamp { return $0.timestamp < $1.timestamp }
            if ($0.step ?? "") != ($1.step ?? "") { return ($0.step ?? "") < ($1.step ?? "") }
            return $0.state < $1.state
        }
    }

    public static func validateRunIDs(_ events: [TelemetryEvent], expectedRunID: String) -> [ValidationIssue] {
        events.enumerated().compactMap { index, event in
            guard event.runID != expectedRunID else { return nil }
            return ValidationIssue(
                severity: .error,
                path: "telemetry[\(index)].run_id",
                message: "expected \(expectedRunID), got \(event.runID)"
            )
        }
    }

    public static func resolveTelemetryURL(for run: LoadedRun) -> URL? {
        let fm = FileManager.default
        let recorded = URL(fileURLWithPath: run.manifest.telemetryPath)
        if fm.fileExists(atPath: recorded.path) { return recorded }
        let local = run.runDirectory.appendingPathComponent(recorded.lastPathComponent)
        if fm.fileExists(atPath: local.path) { return local }
        let canonical = run.runDirectory.appendingPathComponent("telemetry.jsonl")
        if fm.fileExists(atPath: canonical.path) { return canonical }
        return nil
    }
}
