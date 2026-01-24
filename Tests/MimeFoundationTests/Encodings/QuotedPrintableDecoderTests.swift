import Foundation
import Testing
@testable import MimeFoundation

@Suite
struct QuotedPrintableDecoderTests {
    private let qpEncodedPatterns = [
        "=e1=e2=E3=E4\r\n",
        "=e1=g2=E3=E4\r\n",
        "=e1=eg=E3=E4\r\n",
        "   =e1 =e2  =E3\t=E4  \t \t    \r\n",
        "Soft line=\r\n\tHard line\r\n",
        "width==\r\n340 height=3d200\r\n"
    ]
    private let qpDecodedPatterns = [
        "\u{00e1}\u{00e2}\u{00e3}\u{00e4}\r\n",
        "\u{00e1}=g2\u{00e3}\u{00e4}\r\n",
        "\u{00e1}=eg\u{00e3}\u{00e4}\r\n",
        "   \u{00e1} \u{00e2}  \u{00e3}\t\u{00e4}  \t \t    \r\n",
        "Soft line\tHard line\r\n",
        "width=340 height=200\r\n"
    ]

    @Test func argumentExceptions() {
        MimeDecoderTestsBase.assertArgumentExceptions(QuotedPrintableDecoder())
    }

    @Test func encoding() {
        let decoder = QuotedPrintableDecoder()
        #expect(decoder.encoding == .quotedPrintable)
    }

    @Test func clone() {
        MimeDecoderTestsBase.cloneAndAssert(QuotedPrintableDecoder(rfc2047: true), sample: MimeDecoderTestsBase.wikipediaUnix)
        MimeDecoderTestsBase.cloneAndAssert(QuotedPrintableDecoder(rfc2047: false), sample: MimeDecoderTestsBase.wikipediaUnix)
    }

    @Test func reset() {
        MimeDecoderTestsBase.resetAndAssert(QuotedPrintableDecoder(rfc2047: true), sample: MimeDecoderTestsBase.wikipediaUnix)
        MimeDecoderTestsBase.resetAndAssert(QuotedPrintableDecoder(rfc2047: false), sample: MimeDecoderTestsBase.wikipediaUnix)
    }

    @Test func decodePatterns() {
        let decoder = QuotedPrintableDecoder()
        let encoding = String.Encoding.isoLatin1
        var output: [UInt8]? = [UInt8](repeating: 0, count: 4096)

        for i in 0..<qpEncodedPatterns.count {
            decoder.reset()
            let buf = Array(qpEncodedPatterns[i].data(using: encoding) ?? Data())
            let n = try! decoder.decode(buf, startIndex: 0, length: buf.count, output: &output)
            let actual = String(data: Data(output!.prefix(n)), encoding: encoding) ?? ""
            #expect(actual == qpDecodedPatterns[i])
        }
    }

    @Test func decode() {
        for bufferSize in [4096, 1024, 16, 1] {
            MimeDecoderTestsBase.testDecoder(QuotedPrintableDecoder(), rawData: MimeDecoderTestsBase.wikipediaUnix, encodedFile: "wikipedia.qp", bufferSize: bufferSize, unix: true)
        }
    }

    @Test func decodeEqualSignAt76() {
        let encoded = "<table style=3D\"width:100%;\" cellpadding=3D\"0\" cellspacing=3D\"0\" border=3D\"=\n0\"><tr><td style=3D\"width:100%;text-align:center;background-color:;\" bgcolo=\nr=3D\"\">Test</td></tr><table>=\n"
        let expected = "<table style=\"width:100%;\" cellpadding=\"0\" cellspacing=\"0\" border=\"0\"><tr><td style=\"width:100%;text-align:center;background-color:;\" bgcolor=\"\">Test</td></tr><table>"
        let decoder = QuotedPrintableDecoder()
        var output: [UInt8]? = [UInt8](repeating: 0, count: decoder.estimateOutputLength(encoded.utf8.count))
        let buf = Array(encoded.utf8)
        let decodedLength = try! decoder.decode(buf, startIndex: 0, length: buf.count, output: &output)
        let decoded = String(decoding: output!.prefix(decodedLength), as: UTF8.self)
        #expect(decoded == expected)
    }

    @Test func decodeInvalidSoftBreak() {
        let input = "This is an invalid=\rsoft break."
        let decoder = QuotedPrintableDecoder()
        var output: [UInt8]? = [UInt8](repeating: 0, count: 1024)
        let buf = Array(input.utf8)
        let n = try! decoder.decode(buf, startIndex: 0, length: buf.count, output: &output)
        let actual = String(decoding: output!.prefix(n), as: UTF8.self)
        #expect(actual == input)
    }

    @Test func decodeHebrew() {
        let input = "This is an ordinary text message in which my name (=ED=E5=EC=F9 =EF=E1 =E9=EC=E8=F4=F0)\nis in Hebrew (=FA=E9=F8=E1=F2)."
        let expected = "This is an ordinary text message in which my name (םולש ןב ילטפנ)\nis in Hebrew (תירבע)."
        let decoder = QuotedPrintableDecoder()
        var output: [UInt8]? = [UInt8](repeating: 0, count: 4096)
        let buf = Array(input.utf8)
        let n = try! decoder.decode(buf, startIndex: 0, length: buf.count, output: &output)
        let actual = String(data: Data(output!.prefix(n)), encoding: TestHelper.isoLatinHebrew) ?? ""
        #expect(actual == expected)
    }
}
