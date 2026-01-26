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
// EncoderFilterTests.swift
//

import Testing
@testable import MimeFoundation

@Suite
struct EncoderFilterTests {
    private static func assertIsEncoderFilter(_ encoding: ContentEncoding, expected: ContentEncoding) {
        let filter = EncoderFilter.create(encoding)
        #expect(filter is EncoderFilter)
        if let encoder = filter as? EncoderFilter {
            #expect(encoder.encoding == expected)
        }
    }

    private static func assertIsEncoderFilter(_ encoding: String, expected: ContentEncoding) {
        let filter = EncoderFilter.create(encoding)
        #expect(filter is EncoderFilter)
        if let encoder = filter as? EncoderFilter {
            #expect(encoder.encoding == expected)
        }
    }

    @Test("EncoderFilter create")
    func encoderFilterCreate() {
        #expect(EncoderFilter.create(nil as ContentEncoding?) is PassThroughFilter)
        #expect(EncoderFilter.create(nil as String?) is PassThroughFilter)

        Self.assertIsEncoderFilter(.base64, expected: .base64)
        Self.assertIsEncoderFilter("base64", expected: .base64)

        #expect(EncoderFilter.create(.binary) is PassThroughFilter)
        #expect(EncoderFilter.create("binary") is PassThroughFilter)

        #expect(EncoderFilter.create(.default) is PassThroughFilter)
        #expect(EncoderFilter.create("x-invalid") is PassThroughFilter)

        #expect(EncoderFilter.create(.eightBit) is PassThroughFilter)
        #expect(EncoderFilter.create("8bit") is PassThroughFilter)

        Self.assertIsEncoderFilter(.quotedPrintable, expected: .quotedPrintable)
        Self.assertIsEncoderFilter("quoted-printable", expected: .quotedPrintable)

        #expect(EncoderFilter.create(.sevenBit) is PassThroughFilter)
        #expect(EncoderFilter.create("7bit") is PassThroughFilter)

        Self.assertIsEncoderFilter(.uuEncode, expected: .uuEncode)
        Self.assertIsEncoderFilter("x-uuencode", expected: .uuEncode)
        Self.assertIsEncoderFilter("uuencode", expected: .uuEncode)
    }
}
