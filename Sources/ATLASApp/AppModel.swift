import Foundation
import SwiftUI
import ATLASCore

@MainActor
final class AppModel: ObservableObject {
    @Published var loadedRun: LoadedRun?
    @Published var validation = ValidationReport(issues: [])
    @Published var artifactVerification: [ArtifactVerification] = []
    @Published var errorMessage: String?

    func load(url: URL) {
        do {
            let run = try RunLoader.load(url)
            loadedRun = run
            validation = ManifestValidator.validate(run.manifest)
            artifactVerification = []
            errorMessage = nil
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func verifyArtifacts() {
        guard let loadedRun else { return }
        artifactVerification = ArtifactVerifier.verifyAll(in: loadedRun)
    }
}
