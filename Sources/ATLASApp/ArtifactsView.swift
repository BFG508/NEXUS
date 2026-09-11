import SwiftUI
import ATLASCore

struct ArtifactsView: View {
    let run: LoadedRun
    let results: [ArtifactVerification]
    let verify: () -> Void

    var body: some View {
        VStack(alignment: .leading) {
            HStack {
                Text("Declared artifacts").font(.title2.bold())
                Spacer()
                Button("Verify SHA-256", action: verify)
            }
            .padding()

            if results.isEmpty {
                List {
                    ForEach(run.manifest.steps) { step in
                        ForEach(step.artifacts, id: \.path) { artifact in
                            VStack(alignment: .leading) {
                                Text(step.name).font(.caption).foregroundStyle(.secondary)
                                Text(artifact.path).font(.system(.body, design: .monospaced))
                                Text("\(artifact.sizeBytes) bytes · \(artifact.sha256)")
                                    .font(.caption2).foregroundStyle(.secondary)
                            }
                        }
                    }
                }
            } else {
                List(results) { result in
                    VStack(alignment: .leading) {
                        HStack {
                            Text(result.step).font(.headline)
                            Spacer()
                            Text(result.status.rawValue).font(.caption.bold())
                        }
                        Text(result.resolvedURL?.path ?? result.artifact.path)
                            .font(.system(.caption, design: .monospaced))
                        if let message = result.message {
                            Text(message).font(.caption).foregroundStyle(.secondary)
                        }
                    }
                }
            }
        }
    }
}
