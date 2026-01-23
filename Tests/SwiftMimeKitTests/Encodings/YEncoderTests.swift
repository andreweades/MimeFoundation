import Testing
@testable import SwiftMimeKit

@Suite
struct YEncoderTests {
    @Test func argumentExceptions() {
        #expect(throws: (any Error).self) {
            _ = try YEncoder(maxLineLength: 59)
        }
        MimeEncoderTestsBase.assertArgumentExceptions(YEncoder())
    }

    @Test func encoding() {
        let encoder = YEncoder()
        #expect(encoder.encoding == .default)
    }

    @Test func clone() {
        MimeEncoderTestsBase.cloneAndAssert(YEncoder(), sample: MimeEncoderTestsBase.photo)
    }

    @Test func reset() {
        MimeEncoderTestsBase.resetAndAssert(YEncoder(), sample: MimeEncoderTestsBase.photo)
    }
}
