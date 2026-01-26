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

//
// DecoderFilterTests.swift
//

import Testing
@testable import MimeFoundation

@Suite
struct DecoderFilterTests {
    private static func assertIsDecoderFilter(_ encoding: ContentEncoding, expected: ContentEncoding) {
        let filter = DecoderFilter.create(encoding)
        #expect(filter is DecoderFilter)
        if let decoder = filter as? DecoderFilter {
            #expect(decoder.encoding == expected)
        }
    }

    private static func assertIsDecoderFilter(_ encoding: String, expected: ContentEncoding) {
        let filter = DecoderFilter.create(encoding)
        #expect(filter is DecoderFilter)
        if let decoder = filter as? DecoderFilter {
            #expect(decoder.encoding == expected)
        }
    }

    @Test("DecoderFilter create")
    func decoderFilterCreate() {
        #expect(DecoderFilter.create(nil as ContentEncoding?) is PassThroughFilter)
        #expect(DecoderFilter.create(nil as String?) is PassThroughFilter)

        Self.assertIsDecoderFilter(.base64, expected: .base64)
        Self.assertIsDecoderFilter("base64", expected: .base64)

        #expect(DecoderFilter.create(.binary) is PassThroughFilter)
        #expect(DecoderFilter.create("binary") is PassThroughFilter)

        #expect(DecoderFilter.create(.default) is PassThroughFilter)
        #expect(DecoderFilter.create("x-invalid") is PassThroughFilter)

        #expect(DecoderFilter.create(.eightBit) is PassThroughFilter)
        #expect(DecoderFilter.create("8bit") is PassThroughFilter)

        Self.assertIsDecoderFilter(.quotedPrintable, expected: .quotedPrintable)
        Self.assertIsDecoderFilter("quoted-printable", expected: .quotedPrintable)

        #expect(DecoderFilter.create(.sevenBit) is PassThroughFilter)
        #expect(DecoderFilter.create("7bit") is PassThroughFilter)

        Self.assertIsDecoderFilter(.uuEncode, expected: .uuEncode)
        Self.assertIsDecoderFilter("x-uuencode", expected: .uuEncode)
        Self.assertIsDecoderFilter("uuencode", expected: .uuEncode)
    }
}
