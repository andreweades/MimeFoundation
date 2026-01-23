import Testing
@testable import SwiftMimeKit

@Suite
struct Rfc2047Base64EncoderTests {
    @Test func argumentExceptions() {
        let encoder = Rfc2047Base64Encoder()
        var output: [UInt8]? = []

        #expect(throws: (any Error).self) {
            try encoder.encode(nil, startIndex: 0, length: 0, output: &output)
        }
        output = []
        #expect(throws: (any Error).self) {
            try encoder.encode([], startIndex: -1, length: 0, output: &output)
        }
        output = []
        #expect(throws: (any Error).self) {
            try encoder.encode([UInt8](repeating: 0, count: 1), startIndex: 0, length: 10, output: &output)
        }
        var nilOutput: [UInt8]? = nil
        #expect(throws: (any Error).self) {
            try encoder.encode([UInt8](repeating: 0, count: 1), startIndex: 0, length: 1, output: &nilOutput)
        }
        output = []
        #expect(throws: (any Error).self) {
            try encoder.encode([UInt8](repeating: 0, count: 1), startIndex: 0, length: 1, output: &output)
        }
    }
}
