import Testing
@testable import MimeFoundation

@Suite
struct YDecoderTests {
    @Test func argumentExceptions() {
        MimeDecoderTestsBase.assertArgumentExceptions(YDecoder())
    }

    @Test func encoding() {
        let decoder = YDecoder()
        #expect(decoder.encoding == .default)
    }

    @Test func clone() {
        MimeDecoderTestsBase.cloneAndAssert(YDecoder(payloadOnly: true), sample: MimeDecoderTestsBase.photo)
        MimeDecoderTestsBase.cloneAndAssert(YDecoder(payloadOnly: false), sample: MimeDecoderTestsBase.photo)
    }

    @Test func reset() {
        MimeDecoderTestsBase.resetAndAssert(YDecoder(payloadOnly: true), sample: MimeDecoderTestsBase.photo)
        MimeDecoderTestsBase.resetAndAssert(YDecoder(payloadOnly: false), sample: MimeDecoderTestsBase.photo)
    }
}
