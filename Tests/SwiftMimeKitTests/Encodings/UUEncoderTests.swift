import Testing
@testable import SwiftMimeKit

@Suite
struct UUEncoderTests {
    @Test func argumentExceptions() {
        MimeEncoderTestsBase.assertArgumentExceptions(UUEncoder())
    }

    @Test func encoding() {
        let encoder = UUEncoder()
        #expect(encoder.encoding == .uuEncode)
    }

    @Test func clone() {
        MimeEncoderTestsBase.cloneAndAssert(UUEncoder(), sample: MimeEncoderTestsBase.photo)
    }

    @Test func reset() {
        MimeEncoderTestsBase.resetAndAssert(UUEncoder(), sample: MimeEncoderTestsBase.photo)
    }

    @Test func encode() {
        for bufferSize in [4096, 1024, 16, 1] {
            MimeEncoderTestsBase.testEncoder(UUEncoder(), fileName: "photo.jpg", rawData: MimeEncoderTestsBase.photo, encodedFile: "photo.uu", bufferSize: bufferSize)
        }
    }

    @Test func flush() {
        MimeEncoderTestsBase.testEncoderFlush(UUEncoder(), fileName: "photo.jpg", rawData: MimeEncoderTestsBase.photo, encodedFile: "photo.uu")
    }
}
