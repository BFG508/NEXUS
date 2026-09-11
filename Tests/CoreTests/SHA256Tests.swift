import XCTest
@testable import ATLASCore

final class SHA256Tests: XCTestCase {
    func testKnownVector() {
        XCTAssertEqual(
            SHA256.hexDigest(data: Data("abc".utf8)),
            "ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad"
        )
    }
}
