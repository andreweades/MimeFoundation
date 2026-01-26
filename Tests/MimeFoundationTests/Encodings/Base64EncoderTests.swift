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
struct Base64EncoderTests {
    @Test func argumentExceptions() {
        #expect(throws: (any Error).self) {
            try Base64Encoder(maxLineLength: 0)
        }
        let encoder = Base64Encoder()
        MimeEncoderTestsBase.assertArgumentExceptions(encoder)
    }

    @Test func encoding() {
        let encoder = Base64Encoder()
        #expect(encoder.encoding == .base64)
    }

    @Test func clone() {
        let encoder = Base64Encoder()
        MimeEncoderTestsBase.cloneAndAssert(encoder, sample: MimeEncoderTestsBase.wikipediaUnix)
    }

    @Test func reset() {
        let encoder = Base64Encoder()
        MimeEncoderTestsBase.resetAndAssert(encoder, sample: MimeEncoderTestsBase.wikipediaUnix)
    }

    @Test func encode() {
        let bufferSizes = [4096, 1024, 16, 1]
        for bufferSize in bufferSizes {
            let encoder = Base64Encoder()
            encoder.enableHardwareAcceleration = false
            MimeEncoderTestsBase.testEncoder(encoder, fileName: "photo.jpg", rawData: MimeEncoderTestsBase.photo, encodedFile: "photo.b64", bufferSize: bufferSize)
            let encoderAlt = Base64Encoder()
            encoderAlt.enableHardwareAcceleration = true
            MimeEncoderTestsBase.testEncoder(encoderAlt, fileName: "photo.jpg", rawData: MimeEncoderTestsBase.photo, encodedFile: "photo.b64", bufferSize: bufferSize)
        }
    }

    @Test func flush() {
        let encoder = Base64Encoder()
        encoder.enableHardwareAcceleration = false
        MimeEncoderTestsBase.testEncoderFlush(encoder, fileName: "photo.jpg", rawData: MimeEncoderTestsBase.photo, encodedFile: "photo.b64")
        let encoderAlt = Base64Encoder()
        encoderAlt.enableHardwareAcceleration = true
        MimeEncoderTestsBase.testEncoderFlush(encoderAlt, fileName: "photo.jpg", rawData: MimeEncoderTestsBase.photo, encodedFile: "photo.b64")
    }
}
