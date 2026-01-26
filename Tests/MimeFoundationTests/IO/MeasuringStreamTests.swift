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
// MeasuringStreamTests.swift
//

import Testing
@testable import MimeFoundation

@Suite
struct MeasuringStreamTests {
    @Test("MeasuringStream capabilities")
    func measuringStreamCapabilities() {
        let stream = MeasuringStream()
        #expect(!stream.canRead)
        #expect(stream.canWrite)
        #expect(stream.canSeek)
        #expect(!stream.canTimeout)
        #expect(stream.readTimeout == 0)
        #expect(stream.writeTimeout == 0)
    }

    @Test("MeasuringStream write updates length")
    func measuringStreamWrite() throws {
        let stream = MeasuringStream()
        let buffer = Array(repeating: UInt8(0x5A), count: 1024)
        try stream.write(buffer, offset: 0, count: buffer.count)
        try stream.flush()
        #expect(stream.length == buffer.count)
    }

    @Test("MeasuringStream write async updates length")
    func measuringStreamWriteAsync() async throws {
        let stream = MeasuringStream()
        let buffer = Array(repeating: UInt8(0xA5), count: 1024)
        try await stream.writeAsync(buffer, offset: 0, count: buffer.count)
        try await stream.flushAsync()
        #expect(stream.length == buffer.count)
    }

    @Test("MeasuringStream seek")
    func measuringStreamSeek() throws {
        let stream = MeasuringStream()
        try stream.setLength(2048)
        #expect(stream.length == 2048)

        let offsets = [0, 1, 128, 1024, 2048]
        for offset in offsets {
            let pos = try stream.seek(offset, origin: .begin)
            #expect(pos == offset)
            #expect(stream.position == offset)
        }

        let current = try stream.seek(-256, origin: .current)
        #expect(current == stream.position)

        let end = try stream.seek(-128, origin: .end)
        #expect(end == stream.position)

        #expect(throws: StreamError.outOfRange) { _ = try stream.seek(-1, origin: .begin) }
    }

    @Test("MeasuringStream setLength")
    func measuringStreamSetLength() throws {
        let stream = MeasuringStream()
        #expect(throws: StreamError.outOfRange) { try stream.setLength(-1) }
        try stream.setLength(512)
        #expect(stream.length == 512)
    }
}
