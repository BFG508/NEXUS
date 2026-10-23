import XCTest
@testable import ATLASCore

final class ArtifactVerifierTests: XCTestCase {
    func testRelocatedArtifactVerifies() throws {
        let root = URL(fileURLWithPath: NSTemporaryDirectory())
            .appendingPathComponent(UUID().uuidString)
        let artifactDir = root.appendingPathComponent("artifacts/prepare", isDirectory: true)
        try FileManager.default.createDirectory(at: artifactDir, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: root) }

        let file = artifactDir.appendingPathComponent("value.txt")
        let data = Data("hello\n".utf8)
        try data.write(to: file)
        let record = ArtifactRecord(
            path: "/old/machine/run/artifacts/prepare/value.txt",
            sizeBytes: Int64(data.count),
            sha256: SHA256.hexDigest(data: data)
        )
        let result = ArtifactVerifier.verify(record, step: "prepare", runDirectory: root)
        XCTAssertEqual(result.status, .verified)
        XCTAssertEqual(result.resolvedURL?.standardizedFileURL, file.standardizedFileURL)
    }

    func testHashMismatchIsReported() throws {
        let root = URL(fileURLWithPath: NSTemporaryDirectory())
            .appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: root) }
        let file = root.appendingPathComponent("value.txt")
        let data = Data("hello".utf8)
        try data.write(to: file)
        let record = ArtifactRecord(path: file.path, sizeBytes: Int64(data.count), sha256: String(repeating: "0", count: 64))
        XCTAssertEqual(ArtifactVerifier.verify(record, step: "x", runDirectory: root).status, .hashMismatch)
    }
}
