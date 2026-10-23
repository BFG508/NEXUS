import SwiftUI
import ATLASCore

struct ProvenanceView: View {
    let run: LoadedRun

    var body: some View {
        Form {
            LabeledContent("Schema", value: run.manifest.schema)
            LabeledContent("HERMES", value: run.manifest.hermesVersion)
            LabeledContent("Run fingerprint", value: run.manifest.runFingerprint)
            LabeledContent("Scenario SHA-256", value: run.manifest.scenario.sha256)
            LabeledContent("Seed", value: "\(run.manifest.scenario.seed)")
            LabeledContent("Go runtime", value: run.manifest.runtime.goVersion)
            LabeledContent("OS", value: run.manifest.runtime.os)
            LabeledContent("Architecture", value: run.manifest.runtime.arch)
            if let commit = run.manifest.runtime.gitCommit {
                LabeledContent("Git commit", value: commit)
            }
            if let dirty = run.manifest.runtime.gitDirty {
                LabeledContent("Git dirty", value: dirty ? "yes" : "no")
            }
            LabeledContent("Manifest", value: run.manifestURL.path)
        }
        .padding()
        .navigationTitle("Provenance")
    }
}
