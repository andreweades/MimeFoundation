import Foundation
import Testing
@testable import MimeFoundation

@Suite
struct QEncoderTests {
    @Test func argumentExceptions() {
        MimeEncoderTestsBase.assertArgumentExceptions(QEncoder(mode: .text))
    }

    @Test func encoding() {
        let encoder = QEncoder(mode: .text)
        #expect(encoder.encoding == .quotedPrintable)
    }

    @Test func clone() {
        MimeEncoderTestsBase.cloneAndAssert(QEncoder(mode: .text), sample: MimeEncoderTestsBase.wikipediaUnix)
        MimeEncoderTestsBase.cloneAndAssert(QEncoder(mode: .phrase), sample: MimeEncoderTestsBase.wikipediaUnix)
    }

    @Test func reset() {
        MimeEncoderTestsBase.resetAndAssert(QEncoder(mode: .text), sample: MimeEncoderTestsBase.wikipediaUnix)
        MimeEncoderTestsBase.resetAndAssert(QEncoder(mode: .phrase), sample: MimeEncoderTestsBase.wikipediaUnix)
    }

    @Test func encodeText() {
        let expected = "_=09=0D=0AABCabc123!=40#$%^&*=28=29=5F+`-=3D=5B=5D\\{}|=3B=3A'=22=2C=2E=2F=3C=3E=3F"
        let input = " \t\r\nABCabc123!@#$%^&*()_+`-=[]\\{}|;:'\",./<>?"
        let encoder = QEncoder(mode: .text)
        var output = [UInt8](repeating: 0, count: 256)
        let buf = Array(input.data(using: TestHelper.isoLatinHebrew) ?? Data())
        let n = try! encoder.encode(buf, startIndex: 0, length: buf.count, output: &output)
        let actual = String(decoding: output.prefix(n), as: UTF8.self)
        #expect(actual == expected)

        encoder.reset()
        let n2 = try! encoder.flush(buf, startIndex: 0, length: buf.count, output: &output)
        let actual2 = String(decoding: output.prefix(n2), as: UTF8.self)
        #expect(actual2 == expected)
    }

    @Test func encodePhrase() {
        let expected = "_=09=0D=0AABCabc123!=40=23=24=25=5E=26*=28=29=5F+=60-=3D=5B=5D=5C=7B=7D=7C=3B=3A=27=22=2C=2E/=3C=3E=3F"
        let input = " \t\r\nABCabc123!@#$%^&*()_+`-=[]\\{}|;:'\",./<>?"
        let encoder = QEncoder(mode: .phrase)
        var output = [UInt8](repeating: 0, count: 256)
        let buf = Array(input.data(using: TestHelper.isoLatinHebrew) ?? Data())
        let n = try! encoder.encode(buf, startIndex: 0, length: buf.count, output: &output)
        let actual = String(decoding: output.prefix(n), as: UTF8.self)
        #expect(actual == expected)

        encoder.reset()
        let n2 = try! encoder.flush(buf, startIndex: 0, length: buf.count, output: &output)
        let actual2 = String(decoding: output.prefix(n2), as: UTF8.self)
        #expect(actual2 == expected)
    }
}
