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
struct PassThroughDecoderTests {
    @Test func argumentExceptions() {
        MimeDecoderTestsBase.assertArgumentExceptions(PassThroughDecoder(encoding: .default))
    }

    @Test func encoding() {
        let decoder = PassThroughDecoder(encoding: .default)
        #expect(decoder.encoding == .default)
    }

    @Test func clone() {
        MimeDecoderTestsBase.cloneAndAssert(PassThroughDecoder(encoding: .default), sample: MimeDecoderTestsBase.wikipediaUnix)
    }

    @Test func reset() {
        MimeDecoderTestsBase.resetAndAssert(PassThroughDecoder(encoding: .default), sample: MimeDecoderTestsBase.wikipediaUnix)
    }

    @Test func decode() {
        let bufferSize = 1024
        let decoder = PassThroughDecoder(encoding: .default)
        var input = [UInt8](repeating: 0, count: bufferSize)
        var output = [UInt8](repeating: 0, count: bufferSize)

        for i in 0..<bufferSize {
            input[i] = UInt8(i & 0xFF)
        }

        let n = try! decoder.decode(input, startIndex: 0, length: bufferSize, output: &output)
        #expect(n == bufferSize)
        #expect(Array(output.prefix(n)) == input)

        decoder.reset()

        let n2 = try! decoder.decode(input, startIndex: 0, length: bufferSize, output: &output)
        #expect(n2 == bufferSize)
        #expect(Array(output.prefix(n2)) == input)
    }
}
