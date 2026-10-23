import SwiftUI
import UniformTypeIdentifiers
import ATLASCore

struct ContentView: View {
    @StateObject private var model = AppModel()
    @State private var showImporter = false
    @State private var selection: SidebarItem = .overview

    enum SidebarItem: String, CaseIterable, Identifiable {
        case overview = "Overview"
        case timeline = "Timeline"
        case artifacts = "Artifacts"
        case provenance = "Provenance"
        var id: String { rawValue }
        var icon: String {
            switch self {
            case .overview: "rectangle.grid.2x2"
            case .timeline: "clock"
            case .artifacts: "shippingbox"
            case .provenance: "doc.text.magnifyingglass"
            }
        }
    }

    var body: some View {
        NavigationSplitView {
            List(SidebarItem.allCases, selection: $selection) { item in
                Label(item.rawValue, systemImage: item.icon).tag(item)
            }
            .navigationTitle("ATLAS")
            .toolbar {
                Button("Open Run") { showImporter = true }
            }
        } detail: {
            if let run = model.loadedRun {
                switch selection {
                case .overview: OverviewView(run: run, validation: model.validation)
                case .timeline: TimelineView(run: run)
                case .artifacts: ArtifactsView(run: run, results: model.artifactVerification, verify: model.verifyArtifacts)
                case .provenance: ProvenanceView(run: run)
                }
            } else {
                VStack(spacing: 16) {
                    Image(systemName: "point.3.connected.trianglepath.dotted")
                        .font(.system(size: 56))
                    Text("ATLAS").font(.largeTitle.bold())
                    Text("Open a HERMES run manifest to inspect its results and provenance.")
                        .foregroundStyle(.secondary)
                    Button("Open Run") { showImporter = true }
                }
                .padding(40)
            }
        }
        .frame(minWidth: 980, minHeight: 650)
        .fileImporter(isPresented: $showImporter, allowedContentTypes: [.json]) { result in
            switch result {
            case .success(let url): model.load(url: url)
            case .failure(let error): model.errorMessage = error.localizedDescription
            }
        }
        .alert("ATLAS", isPresented: Binding(
            get: { model.errorMessage != nil },
            set: { if !$0 { model.errorMessage = nil } }
        )) {
            Button("OK", role: .cancel) { model.errorMessage = nil }
        } message: {
            Text(model.errorMessage ?? "")
        }
    }
}
