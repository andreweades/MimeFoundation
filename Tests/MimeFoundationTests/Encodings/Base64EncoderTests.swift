import Testing
@testable import MimeFoundation

@Suite
struct Base64EncoderTests {
    @Test func argumentExceptions() {
        #expect(throws: (any Error).self) {
            try Base64Encoder(maxLineLength: 0)
        }
        let encoder = Base64Encoder()
        MimeEncoderTestsBase.assertArgumentExceptions(encoder)
    }

    @Test func encoding() {
        let encoder = Base64Encoder()
        #expect(encoder.encoding == .base64)
    }

    @Test func clone() {
        let encoder = Base64Encoder()
        MimeEncoderTestsBase.cloneAndAssert(encoder, sample: MimeEncoderTestsBase.wikipediaUnix)
    }

    @Test func reset() {
        let encoder = Base64Encoder()
        MimeEncoderTestsBase.resetAndAssert(encoder, sample: MimeEncoderTestsBase.wikipediaUnix)
    }

    @Test func encode() {
        let bufferSizes = [4096, 1024, 16, 1]
        for bufferSize in bufferSizes {
            let encoder = Base64Encoder()
            encoder.enableHardwareAcceleration = false
            MimeEncoderTestsBase.testEncoder(encoder, fileName: "photo.jpg", rawData: MimeEncoderTestsBase.photo, encodedFile: "photo.b64", bufferSize: bufferSize)
            let encoderAlt = Base64Encoder()
            encoderAlt.enableHardwareAcceleration = true
            MimeEncoderTestsBase.testEncoder(encoderAlt, fileName: "photo.jpg", rawData: MimeEncoderTestsBase.photo, encodedFile: "photo.b64", bufferSize: bufferSize)
        }
    }

    @Test func flush() {
        let encoder = Base64Encoder()
        encoder.enableHardwareAcceleration = false
        MimeEncoderTestsBase.testEncoderFlush(encoder, fileName: "photo.jpg", rawData: MimeEncoderTestsBase.photo, encodedFile: "photo.b64")
        let encoderAlt = Base64Encoder()
        encoderAlt.enableHardwareAcceleration = true
        MimeEncoderTestsBase.testEncoderFlush(encoderAlt, fileName: "photo.jpg", rawData: MimeEncoderTestsBase.photo, encodedFile: "photo.b64")
    }
}
