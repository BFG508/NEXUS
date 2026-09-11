import SwiftUI
import ATLASCore

struct OverviewView: View {
    let run: LoadedRun
    let validation: ValidationReport

    var body: some View {
        let summary = RunSummary(manifest: run.manifest)
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                HStack {
                    VStack(alignment: .leading) {
                        Text(summary.runID).font(.title.bold())
                        Text(summary.scenario).foregroundStyle(.secondary)
                    }
                    Spacer()
                    StatusBadge(status: summary.status)
                }

                HStack(spacing: 12) {
                    MetricCard(title: "Steps", value: "\(summary.stepCount)")
                    MetricCard(title: "Artifacts", value: "\(summary.artifactCount)")
                    MetricCard(title: "Recorded step time", value: "\(summary.totalRecordedDurationMS) ms")
                    MetricCard(title: "Validation", value: validation.isValid ? "Valid" : "\(validation.errors.count) errors")
                }

                Text("Steps").font(.headline)
                ForEach(run.manifest.steps) { step in
                    HStack {
                        StatusBadge(status: step.status)
                        Text(step.name).font(.system(.body, design: .monospaced))
                        Spacer()
                        Text("\(step.durationMS) ms").foregroundStyle(.secondary)
                    }
                    Divider()
                }

                if !validation.issues.isEmpty {
                    Text("Validation").font(.headline)
                    ForEach(validation.issues) { issue in
                        Text("[\(issue.severity.rawValue.uppercased())] \(issue.path): \(issue.message)")
                            .font(.system(.caption, design: .monospaced))
                    }
                }
            }
            .padding(24)
        }
    }
}

private struct MetricCard: View {
    let title: String
    let value: String
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title).font(.caption).foregroundStyle(.secondary)
            Text(value).font(.headline)
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.quaternary, in: RoundedRectangle(cornerRadius: 10))
    }
}

struct StatusBadge: View {
    let status: RunStatus
    var body: some View {
        Text(status.rawValue.uppercased())
            .font(.caption.bold())
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(.quaternary, in: Capsule())
    }
}
