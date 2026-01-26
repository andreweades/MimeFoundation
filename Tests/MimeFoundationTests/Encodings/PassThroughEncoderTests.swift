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
struct PassThroughEncoderTests {
    @Test func argumentExceptions() {
        MimeEncoderTestsBase.assertArgumentExceptions(PassThroughEncoder(encoding: .default))
    }

    @Test func encoding() {
        let encoder = PassThroughEncoder(encoding: .default)
        #expect(encoder.encoding == .default)
    }

    @Test func clone() {
        MimeEncoderTestsBase.cloneAndAssert(PassThroughEncoder(encoding: .default), sample: MimeEncoderTestsBase.wikipediaUnix)
    }

    @Test func reset() {
        MimeEncoderTestsBase.resetAndAssert(PassThroughEncoder(encoding: .default), sample: MimeEncoderTestsBase.wikipediaUnix)
    }

    @Test func encode() {
        let bufferSize = 1024
        let encoder = PassThroughEncoder(encoding: .default)
        var input = [UInt8](repeating: 0, count: bufferSize)
        var output = [UInt8](repeating: 0, count: bufferSize)

        for i in 0..<bufferSize {
            input[i] = UInt8(i & 0xFF)
        }

        let n = try! encoder.encode(input, startIndex: 0, length: bufferSize, output: &output)
        #expect(n == bufferSize)
        #expect(Array(output.prefix(n)) == input)
    }

    @Test func flush() {
        let bufferSize = 1024
        let encoder = PassThroughEncoder(encoding: .default)
        var input = [UInt8](repeating: 0, count: bufferSize)
        var output = [UInt8](repeating: 0, count: bufferSize)

        for i in 0..<bufferSize {
            input[i] = UInt8(i & 0xFF)
        }

        let n = try! encoder.flush(input, startIndex: 0, length: bufferSize, output: &output)
        #expect(n == bufferSize)
        #expect(Array(output.prefix(n)) == input)
    }
}
