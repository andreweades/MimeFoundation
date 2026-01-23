import Testing
@testable import SwiftMimeKit

@Suite
struct UUDecoderTests {
    @Test func argumentExceptions() {
        MimeDecoderTestsBase.assertArgumentExceptions(UUDecoder())
    }

    @Test func encoding() {
        let decoder = UUDecoder()
        #expect(decoder.encoding == .uuEncode)
    }

    @Test func clone() {
        MimeDecoderTestsBase.cloneAndAssert(UUDecoder(payloadOnly: true), sample: MimeDecoderTestsBase.photo)
        MimeDecoderTestsBase.cloneAndAssert(UUDecoder(payloadOnly: false), sample: MimeDecoderTestsBase.photo)
    }

    @Test func reset() {
        MimeDecoderTestsBase.resetAndAssert(UUDecoder(payloadOnly: true), sample: MimeDecoderTestsBase.photo)
        MimeDecoderTestsBase.resetAndAssert(UUDecoder(payloadOnly: false), sample: MimeDecoderTestsBase.photo)
    }

    @Test func decode() {
        for bufferSize in [4096, 1024, 16, 1] {
            MimeDecoderTestsBase.testDecoder(UUDecoder(), rawData: MimeDecoderTestsBase.photo, encodedFile: "photo.uu", bufferSize: bufferSize)
        }
    }

    @Test func decodeBeginStateChanges() {
        for bufferSize in [4096, 1024, 16, 1] {
            MimeDecoderTestsBase.testDecoder(UUDecoder(), rawData: MimeDecoderTestsBase.photo, encodedFile: "photo.uu-states", bufferSize: bufferSize)
        }
    }
}
