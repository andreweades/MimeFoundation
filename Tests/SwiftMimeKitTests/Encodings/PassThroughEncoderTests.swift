import Testing
@testable import SwiftMimeKit

@Suite
struct PassThroughEncoderTests {
    @Test func argumentExceptions() {
        MimeEncoderTestsBase.assertArgumentExceptions(PassThroughEncoder(encoding: .default))
    }

    @Test func encoding() {
        let encoder = PassThroughEncoder(encoding: .default)
        #expect(encoder.encoding == .default)
    }

    @Test func clone() {
        MimeEncoderTestsBase.cloneAndAssert(PassThroughEncoder(encoding: .default), sample: MimeEncoderTestsBase.wikipediaUnix)
    }

    @Test func reset() {
        MimeEncoderTestsBase.resetAndAssert(PassThroughEncoder(encoding: .default), sample: MimeEncoderTestsBase.wikipediaUnix)
    }

    @Test func encode() {
        let bufferSize = 1024
        let encoder = PassThroughEncoder(encoding: .default)
        var input = [UInt8](repeating: 0, count: bufferSize)
        var output: [UInt8]? = [UInt8](repeating: 0, count: bufferSize)

        for i in 0..<bufferSize {
            input[i] = UInt8(i & 0xFF)
        }

        let n = try! encoder.encode(input, startIndex: 0, length: bufferSize, output: &output)
        #expect(n == bufferSize)
        #expect(Array(output!.prefix(n)) == input)
    }

    @Test func flush() {
        let bufferSize = 1024
        let encoder = PassThroughEncoder(encoding: .default)
        var input = [UInt8](repeating: 0, count: bufferSize)
        var output: [UInt8]? = [UInt8](repeating: 0, count: bufferSize)

        for i in 0..<bufferSize {
            input[i] = UInt8(i & 0xFF)
        }

        let n = try! encoder.flush(input, startIndex: 0, length: bufferSize, output: &output)
        #expect(n == bufferSize)
        #expect(Array(output!.prefix(n)) == input)
    }
}
