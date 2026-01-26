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

import Testing
import Foundation
@testable import MimeFoundation

@Suite("RtfCompressedToRtf tests")
struct RtfCompressedToRtfTests {
    @Test("Test RtfCompressedToRtf unknown compression type")
    func testRtfCompressedToRtfUnknownCompressionType() {
        let input: [UInt8] = [0x10, 0x00, 0x00, 0x00, 0x11, 0x00, 0x00, 0x00, UInt8(ascii: "A"), UInt8(ascii: "B"), UInt8(ascii: "C"), UInt8(ascii: "D"), 0xff, 0xff, 0xff, 0xff]
        let filter = RtfCompressedToRtf()
        var outputIndex = 0
        var outputLength = 0
        
        _ = filter.flush(input, startIndex: 0, length: input.count, outputIndex: &outputIndex, outputLength: &outputLength)
        
        #expect(outputIndex == 16)
        #expect(outputLength == 0)
        #expect(filter.isValidCrc32 == false)
        #expect(filter.compressionMode == 1145258561)
    }

    @Test("Test RtfCompressedToRtf invalid CRC")
    func testRtfCompressedToRtfInvalidCrc() {
        let input: [UInt8] = [0x10, 0x00, 0x00, 0x00, 0x11, 0x00, 0x00, 0x00, UInt8(ascii: "L"), UInt8(ascii: "Z"), UInt8(ascii: "F"), UInt8(ascii: "u"), 0xff, 0xff, 0xff, 0xff]
        let filter = RtfCompressedToRtf()
        var outputIndex = 0
        var outputLength = 0
        
        _ = filter.flush(input, startIndex: 0, length: input.count, outputIndex: &outputIndex, outputLength: &outputLength)
        
        #expect(outputIndex == 0)
        #expect(outputLength == 0)
        #expect(filter.isValidCrc32 == false)
        #expect(filter.compressionMode == RtfCompressionMode.compressed.rawValue)
    }

    @Test("Test RtfCompressedToRtf")
    func testRtfCompressedToRtf() {
        let input: [UInt8] = [UInt8(ascii: "-"), 0x00, 0x00, 0x00, UInt8(ascii: "+"), 0x00, 0x00, 0x00, UInt8(ascii: "L"), UInt8(ascii: "Z"), UInt8(ascii: "F"), UInt8(ascii: "u"), 0xf1, 0xc5, 0xc7, 0xa7, 0x03, 0x00, UInt8(ascii: "\n"), 0x00, UInt8(ascii: "r"), UInt8(ascii: "c"), UInt8(ascii: "p"), UInt8(ascii: "g"), UInt8(ascii: "1"), UInt8(ascii: "2"), UInt8(ascii: "5"), UInt8(ascii: "B"), UInt8(ascii: "2"), UInt8(ascii: "\n"), 0xf3, UInt8(ascii: " "), UInt8(ascii: "h"), UInt8(ascii: "e"), UInt8(ascii: "l"), UInt8(ascii: "\t"), 0x00, UInt8(ascii: " "), UInt8(ascii: "b"), UInt8(ascii: "w"), 0x05, 0xb0, UInt8(ascii: "l"), UInt8(ascii: "d"), UInt8(ascii: "}"), UInt8(ascii: "\n"), 0x80, 0x0f, 0xa0]
                let expectedBytes: [UInt8] = [
                    123, 92, 114, 116, 102, 49, 92, 97, 110, 115, 105, 92, 97, 110, 115, 105,
                    99, 112, 103, 49, 50, 53, 50, 92, 112, 97, 114, 100, 32, 104, 101, 108,
                    108, 111, 32, 119, 111, 114, 108, 100, 125, 13, 10
                ]
        let filter = RtfCompressedToRtf()
        var outputIndex = 0
        var outputLength = 0
        
        let output = filter.flush(input, startIndex: 0, length: input.count, outputIndex: &outputIndex, outputLength: &outputLength)
        
        #expect(outputIndex == 0)
        #expect(outputLength == 43)
        #expect(filter.isValidCrc32 == true)
        #expect(filter.compressionMode == RtfCompressionMode.compressed.rawValue)
        
        let actualBytes = Array(output[outputIndex..<(outputIndex + outputLength)])
        #expect(actualBytes == expectedBytes)
    }

    @Test("Test RtfCompressedToRtf raw")
    func testRtfCompressedToRtfRaw() {
        let b: UInt8 = 92
        let l: UInt8 = 123
        let r: UInt8 = 125
        let input: [UInt8] = [UInt8(ascii: "."), 0x00, 0x00, 0x00, UInt8(ascii: "\""), 0x00, 0x00, 0x00, UInt8(ascii: "M"), UInt8(ascii: "E"), UInt8(ascii: "L"), UInt8(ascii: "A"), UInt8(ascii: " "), 0xdf, 0x12, 0xce, l, b, UInt8(ascii: "r"), UInt8(ascii: "t"), UInt8(ascii: "f"), UInt8(ascii: "1"), b, UInt8(ascii: "a"), UInt8(ascii: "n"), UInt8(ascii: "s"), UInt8(ascii: "i"), b, UInt8(ascii: "a"), UInt8(ascii: "n"), UInt8(ascii: "s"), UInt8(ascii: "i"), UInt8(ascii: "c"), UInt8(ascii: "p"), UInt8(ascii: "g"), UInt8(ascii: "1"), UInt8(ascii: "2"), UInt8(ascii: "5"), UInt8(ascii: "2"), b, UInt8(ascii: "p"), UInt8(ascii: "a"), UInt8(ascii: "r"), UInt8(ascii: "d"), UInt8(ascii: " "), UInt8(ascii: "t"), UInt8(ascii: "e"), UInt8(ascii: "s"), UInt8(ascii: "t"), r]
        let expected = "{\\rtf1\\ansi\\ansicpg1252\\pard test}"
        let filter = RtfCompressedToRtf()
        var outputIndex = 0
        var outputLength = 0
        
        let output = filter.flush(input, startIndex: 0, length: input.count, outputIndex: &outputIndex, outputLength: &outputLength)
        
        #expect(outputIndex == 16)
        #expect(outputLength == 34)
        #expect(filter.isValidCrc32 == true)
        #expect(filter.compressionMode == RtfCompressionMode.uncompressed.rawValue)
        
        let text = String(decoding: output[outputIndex..<(outputIndex + outputLength)], as: UTF8.self)
        #expect(text == expected)
    }
}
