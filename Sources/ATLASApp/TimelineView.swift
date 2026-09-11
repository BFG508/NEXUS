import SwiftUI
import ATLASCore

struct TimelineView: View {
    let run: LoadedRun

    var body: some View {
        List(TimelineBuilder.build(from: run.manifest)) { entry in
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(entry.kind.rawValue.replacingOccurrences(of: "_", with: " ").capitalized)
                        .font(.headline)
                    Text(entry.step ?? run.manifest.runID)
                        .font(.system(.body, design: .monospaced))
                    Text(ISO8601Coding.format(entry.timestamp))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                StatusBadge(status: entry.status)
            }
            .padding(.vertical, 4)
        }
        .navigationTitle("Timeline")
    }
}
