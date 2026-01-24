import Foundation
import Testing
@testable import MimeFoundation

@Suite
struct Rfc2047QuotedPrintableEncoderTests {
    @Test func argumentExceptions() {
        let encoder = Rfc2047QuotedPrintableEncoder(mode: .text)
        var output = [UInt8]()

        #expect(throws: (any Error).self) {
            try encoder.encode([], startIndex: -1, length: 0, output: &output)
        }
        output = []
        #expect(throws: (any Error).self) {
            try encoder.encode([UInt8](repeating: 0, count: 1), startIndex: 0, length: 10, output: &output)
        }
        output = []
        #expect(throws: (any Error).self) {
            try encoder.encode([UInt8](repeating: 0, count: 1), startIndex: 0, length: 1, output: &output)
        }
    }

    @Test func encodeText() {
        let expected = "_=09=0D=0AABCabc123!=40#$%^&*=28=29=5F+`-=3D=5B=5D\\{}|=3B=3A'=22=2C=2E=2F=3C=3E=3F"
        let input = " \t\r\nABCabc123!@#$%^&*()_+`-=[]\\{}|;:'\",./<>?"
        let encoder = Rfc2047QuotedPrintableEncoder(mode: .text)
        var output = [UInt8](repeating: 0, count: 256)
        let buf = Array(input.data(using: TestHelper.isoLatinHebrew) ?? Data())
        let n = try! encoder.encode(buf, startIndex: 0, length: buf.count, output: &output)
        let actual = String(decoding: output.prefix(n), as: UTF8.self)
        #expect(actual == expected)
    }

    @Test func encodePhrase() {
        let expected = "_=09=0D=0AABCabc123!=40=23=24=25=5E=26*=28=29=5F+=60-=3D=5B=5D=5C=7B=7D=7C=3B=3A=27=22=2C=2E/=3C=3E=3F"
        let input = " \t\r\nABCabc123!@#$%^&*()_+`-=[]\\{}|;:'\",./<>?"
        let encoder = Rfc2047QuotedPrintableEncoder(mode: .phrase)
        var output = [UInt8](repeating: 0, count: 256)
        let buf = Array(input.data(using: TestHelper.isoLatinHebrew) ?? Data())
        let n = try! encoder.encode(buf, startIndex: 0, length: buf.count, output: &output)
        let actual = String(decoding: output.prefix(n), as: UTF8.self)
        #expect(actual == expected)
    }
}
