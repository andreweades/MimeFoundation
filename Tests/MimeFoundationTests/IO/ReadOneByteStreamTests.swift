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
// ReadOneByteStreamTests.swift
//

import Testing
@testable import MimeFoundation

@Suite
struct ReadOneByteStreamTests {
    @Test("ReadOneByteStream reads one byte")
    func readOneByte() throws {
        let bytes = [UInt8](arrayLiteral: 1, 2, 3, 4)
        let memory = MemoryStream(bytes, writable: true)
        let stream = ReadOneByteStream(memory)

        var buffer = [UInt8](repeating: 0, count: 4)
        let first = try stream.read(&buffer, offset: 0, count: 4)
        #expect(first == 1)
        #expect(buffer[0] == 1)

        let second = try stream.read(&buffer, offset: 1, count: 4)
        #expect(second == 1)
        #expect(buffer[1] == 2)

        let third = try stream.read(&buffer, offset: 2, count: 0)
        #expect(third == 0)
    }

    @Test("ReadOneByteStream write delegates")
    func writeDelegates() throws {
        let memory = MemoryStream([], writable: true)
        let stream = ReadOneByteStream(memory)
        let bytes = [UInt8](arrayLiteral: 9, 8, 7)
        try stream.write(bytes, offset: 0, count: bytes.count)
        #expect(memory.toByteArray() == bytes)
    }
}
