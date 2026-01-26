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
struct Rfc2047Base64EncoderTests {
    @Test func argumentExceptions() {
        let encoder = Rfc2047Base64Encoder()
        var output = [UInt8]()

        #expect(throws: (any Error).self) {
            try encoder.encode([], startIndex: -1, length: 0, output: &output)
        }
        output = []
        #expect(throws: (any Error).self) {
            try encoder.encode([UInt8](repeating: 0, count: 1), startIndex: 0, length: 10, output: &output)
        }
        output = []
        #expect(throws: (any Error).self) {
            try encoder.encode([UInt8](repeating: 0, count: 1), startIndex: 0, length: 1, output: &output)
        }
    }
}
