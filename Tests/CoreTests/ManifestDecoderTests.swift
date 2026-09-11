import XCTest
@testable import ATLASCore

final class ManifestDecoderTests: XCTestCase {
    func testDecodesSupportedManifest() throws {
        let original = fixtureManifest()
        let decoded = try ManifestDecoder.decode(encodeManifest(original))
        XCTAssertEqual(decoded.runID, original.runID)
        XCTAssertEqual(decoded.steps.count, 1)
        XCTAssertEqual(decoded.steps[0].status, .succeeded)
    }

    func testRejectsUnsupportedSchema() throws {
        let data = Data(#"{"schema":"other.v1"}"#.utf8)
        XCTAssertThrowsError(try ManifestDecoder.decode(data)) { error in
            XCTAssertEqual(error as? ATLASDecodingError, .unsupportedSchema("other.v1"))
        }
    }

    func testFractionalNanosecondTimestamp() throws {
        let text = "2026-09-09T12:00:00.123456789Z"
        XCTAssertNotNil(ISO8601Coding.parse(text))
    }
}
