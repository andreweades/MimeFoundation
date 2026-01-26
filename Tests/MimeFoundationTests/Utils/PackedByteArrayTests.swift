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
struct PackedByteArrayTests {
    @Test func argumentExceptions() {
        let packed = PackedByteArray()
        var buffer = [UInt8](repeating: 0, count: 16)

        #expect(throws: PackedByteArrayError.self) {
            try packed.copy(to: &buffer, startIndex: -1)
        }
    }

    @Test func basicFunctionality() throws {
        let packed = PackedByteArray()
        var expected = [UInt8](repeating: 0, count: 1024)
        var buffer = [UInt8](repeating: 0, count: 1024)
        var index = 0

        let a = "A".utf8.first!
        let b = "B".utf8.first!

        for _ in 0..<257 {
            expected[index] = a
            packed.add(a)
            index += 1
        }

        for i in 1..<26 {
            let value = a + UInt8(i)
            expected[index] = value
            packed.add(value)
            index += 1
        }

        for _ in 0..<128 {
            expected[index] = b
            packed.add(b)
            index += 1
        }

        for i in 0..<26 {
            let value = a + UInt8(i)
            expected[index] = value
            packed.add(value)
            index += 1
        }

        for i in 0..<26 {
            let value = a + UInt8(i)
            expected[index] = value
            packed.add(value)
            index += 1
        }

        #expect(packed.count == index)

        try packed.copy(to: &buffer, startIndex: 0)

        for i in 0..<index {
            #expect(buffer[i] == expected[i], "buffer[\(i)]")
        }
    }
}
