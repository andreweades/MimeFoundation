//
// Author: Jeffrey Stedfast <jestedfa@microsoft.com>
//
// Copyright (c) 2013-2026 .NET Foundation and Contributors
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.
//

import Foundation
import Testing
@testable import MimeFoundation

@Suite
struct QuotedPrintableEncoderTests {
    @Test func argumentExceptions() {
        #expect(throws: (any Error).self) {
            _ = try QuotedPrintableEncoder(maxLineLength: 0)
        }
        MimeEncoderTestsBase.assertArgumentExceptions(QuotedPrintableEncoder())
    }

    @Test func encoding() {
        let encoder = QuotedPrintableEncoder()
        #expect(encoder.encoding == .quotedPrintable)
    }

    @Test func clone() {
        let encoder = try! QuotedPrintableEncoder(maxLineLength: 76)
        MimeEncoderTestsBase.cloneAndAssert(encoder, sample: MimeEncoderTestsBase.wikipediaUnix)
    }

    @Test func reset() {
        let encoder = QuotedPrintableEncoder()
        MimeEncoderTestsBase.resetAndAssert(encoder, sample: MimeEncoderTestsBase.wikipediaUnix)
    }

    @Test func encodeDos() {
        for bufferSize in [4096, 1024, 16, 1] {
            MimeEncoderTestsBase.testEncoder(QuotedPrintableEncoder(), fileName: "wikipedia.txt", rawData: MimeEncoderTestsBase.wikipediaDos, encodedFile: "wikipedia.qp", bufferSize: bufferSize)
        }
    }

    @Test func encodeUnix() {
        for bufferSize in [4096, 1024, 16, 1] {
            MimeEncoderTestsBase.testEncoder(QuotedPrintableEncoder(), fileName: "wikipedia.txt", rawData: MimeEncoderTestsBase.wikipediaUnix, encodedFile: "wikipedia.qp", bufferSize: bufferSize)
        }
    }

    @Test func flushDos() {
        MimeEncoderTestsBase.testEncoderFlush(QuotedPrintableEncoder(), fileName: "wikipedia.txt", rawData: MimeEncoderTestsBase.wikipediaDos, encodedFile: "wikipedia.qp")
    }

    @Test func flushUnix() {
        MimeEncoderTestsBase.testEncoderFlush(QuotedPrintableEncoder(), fileName: "wikipedia.txt", rawData: MimeEncoderTestsBase.wikipediaUnix, encodedFile: "wikipedia.qp")
    }

    @Test func encodeSpaceDosLineBreak() {
        let input = "This line ends with a space \r\nbefore a line break."
        let expected = "This line ends with a space=20\nbefore a line break.=\n"
        let encoder = QuotedPrintableEncoder()
        var output = [UInt8](repeating: 0, count: 1024)
        let buf = Array(input.utf8)
        let n = try! encoder.flush(buf, startIndex: 0, length: buf.count, output: &output)
        let actual = String(decoding: output.prefix(n), as: UTF8.self)
        #expect(actual == expected)
    }

    @Test func encodeSpaceUnixLineBreak() {
        let input = "This line ends with a space \nbefore a line break."
        let expected = "This line ends with a space=20\nbefore a line break.=\n"
        let encoder = QuotedPrintableEncoder()
        var output = [UInt8](repeating: 0, count: 1024)
        let buf = Array(input.utf8)
        let n = try! encoder.flush(buf, startIndex: 0, length: buf.count, output: &output)
        let actual = String(decoding: output.prefix(n), as: UTF8.self)
        #expect(actual == expected)
    }

    @Test func encodeEqualSignAt76() {
        let expected = "<table style=3D\"width:100%;\" cellpadding=3D\"0\" cellspacing=3D\"0\" border=3D\"=\n0\"><tr><td style=3D\"width:100%;text-align:center;background-color:;\" bgcolo=\nr=3D\"\">Test</td></tr><table>=\n"
        let text = "<table style=\"width:100%;\" cellpadding=\"0\" cellspacing=\"0\" border=\"0\"><tr><td style=\"width:100%;text-align:center;background-color:;\" bgcolor=\"\">Test</td></tr><table>"
        let input = Array(text.utf8)
        let encoder = try! QuotedPrintableEncoder(maxLineLength: 76)
        var output = [UInt8](repeating: 0, count: encoder.estimateOutputLength(input.count))
        let outputLength = try! encoder.flush(input, startIndex: 0, length: input.count, output: &output)
        let encoded = String(decoding: output.prefix(outputLength), as: UTF8.self)
        #expect(encoded == expected)
    }

    @Test func flush() {
        let input = "This line ends with a space "
        let expected = "This line ends with a space=20=\n"
        let encoder = QuotedPrintableEncoder()
        let decoder = QuotedPrintableDecoder()
        var output = [UInt8](repeating: 0, count: 1024)

        let buf = Array(input.utf8)
        let n = try! encoder.flush(buf, startIndex: 0, length: buf.count, output: &output)
        let actual = String(decoding: output.prefix(n), as: UTF8.self)
        #expect(actual == expected)

        let encodedBuf = Array(expected.utf8)
        let n2 = try! decoder.decode(encodedBuf, startIndex: 0, length: encodedBuf.count, output: &output)
        let actual2 = String(decoding: output.prefix(n2), as: UTF8.self)
        #expect(actual2 == input)
    }

    @Test func encodeHebrew() {
        let expected = "This is an ordinary text message in which my name (=ED=E5=EC=F9 =EF=E1 =\n=E9=EC=E8=F4=F0)\nis in Hebrew (=FA=E9=F8=E1=F2).\n"
        let input = "This is an ordinary text message in which my name (םולש ןב ילטפנ)\nis in Hebrew (תירבע).\n"
        let encoder = try! QuotedPrintableEncoder(maxLineLength: 72)
        var output = [UInt8](repeating: 0, count: 1024)

        let encoding = TestHelper.isoLatinHebrew
        let buf = Array(input.data(using: encoding) ?? Data())
        let n = try! encoder.flush(buf, startIndex: 0, length: buf.count, output: &output)
        let actual = String(decoding: output.prefix(n), as: UTF8.self)
        #expect(actual == expected)
    }
}
