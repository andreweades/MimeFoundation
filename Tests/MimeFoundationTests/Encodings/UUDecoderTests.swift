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
@testable import MimeFoundation

@Suite
struct UUDecoderTests {
    @Test func argumentExceptions() {
        MimeDecoderTestsBase.assertArgumentExceptions(UUDecoder())
    }

    @Test func encoding() {
        let decoder = UUDecoder()
        #expect(decoder.encoding == .uuEncode)
    }

    @Test func clone() {
        MimeDecoderTestsBase.cloneAndAssert(UUDecoder(payloadOnly: true), sample: MimeDecoderTestsBase.photo)
        MimeDecoderTestsBase.cloneAndAssert(UUDecoder(payloadOnly: false), sample: MimeDecoderTestsBase.photo)
    }

    @Test func reset() {
        MimeDecoderTestsBase.resetAndAssert(UUDecoder(payloadOnly: true), sample: MimeDecoderTestsBase.photo)
        MimeDecoderTestsBase.resetAndAssert(UUDecoder(payloadOnly: false), sample: MimeDecoderTestsBase.photo)
    }

    @Test func decode() {
        for bufferSize in [4096, 1024, 16, 1] {
            MimeDecoderTestsBase.testDecoder(UUDecoder(), rawData: MimeDecoderTestsBase.photo, encodedFile: "photo.uu", bufferSize: bufferSize)
        }
    }

    @Test func decodeBeginStateChanges() {
        for bufferSize in [4096, 1024, 16, 1] {
            MimeDecoderTestsBase.testDecoder(UUDecoder(), rawData: MimeDecoderTestsBase.photo, encodedFile: "photo.uu-states", bufferSize: bufferSize)
        }
    }
}
