import Testing
@testable import MimeFoundation

@Suite
struct PassThroughDecoderTests {
    @Test func argumentExceptions() {
        MimeDecoderTestsBase.assertArgumentExceptions(PassThroughDecoder(encoding: .default))
    }

    @Test func encoding() {
        let decoder = PassThroughDecoder(encoding: .default)
        #expect(decoder.encoding == .default)
    }

    @Test func clone() {
        MimeDecoderTestsBase.cloneAndAssert(PassThroughDecoder(encoding: .default), sample: MimeDecoderTestsBase.wikipediaUnix)
    }

    @Test func reset() {
        MimeDecoderTestsBase.resetAndAssert(PassThroughDecoder(encoding: .default), sample: MimeDecoderTestsBase.wikipediaUnix)
    }

    @Test func decode() {
        let bufferSize = 1024
        let decoder = PassThroughDecoder(encoding: .default)
        var input = [UInt8](repeating: 0, count: bufferSize)
        var output = [UInt8](repeating: 0, count: bufferSize)

        for i in 0..<bufferSize {
            input[i] = UInt8(i & 0xFF)
        }

        let n = try! decoder.decode(input, startIndex: 0, length: bufferSize, output: &output)
        #expect(n == bufferSize)
        #expect(Array(output.prefix(n)) == input)

        decoder.reset()

        let n2 = try! decoder.decode(input, startIndex: 0, length: bufferSize, output: &output)
        #expect(n2 == bufferSize)
        #expect(Array(output.prefix(n2)) == input)
    }
}
