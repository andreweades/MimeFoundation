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
// ChainedStreamTests.swift
//

import Testing
@testable import MimeFoundation

@Suite
struct ChainedStreamTests {
    private static func makeBytes(count: Int) -> [UInt8] {
        (0..<count).map { UInt8($0 % 251) }
    }

    private static func makeChained(bytes: [UInt8]) throws -> (ChainedStream, MemoryStream, MemoryStream) {
        let master = MemoryStream(bytes, writable: false)
        let backing = MemoryStream(bytes, writable: true)
        let chained = ChainedStream()

        let chunkSizes = [1, 8, 64, 256, 512, 1024, 2048]
        var position = 0
        var index = 0

        while position < bytes.count {
            let size = min(chunkSizes[index % chunkSizes.count], bytes.count - position)
            let bound = try BoundStream(backing, startBoundary: position, endBoundary: position + size, leaveOpen: true)
            try chained.add(ReadOneByteStream(bound), leaveOpen: true)
            position += size
            index += 1
        }

        return (chained, master, backing)
    }

    private static func assertReadMatches(_ chained: ChainedStream, _ master: MemoryStream) throws {
        var cbuf = [UInt8](repeating: 0, count: 512)
        var mbuf = [UInt8](repeating: 0, count: 512)

        while true {
            let nread = try chained.read(&cbuf, offset: 0, count: cbuf.count)
            let mread = try master.read(&mbuf, offset: 0, count: mbuf.count)
            #expect(nread == mread)
            if nread == 0 {
                break
            }
            #expect(Array(cbuf[0..<nread]) == Array(mbuf[0..<mread]))
            #expect(chained.position == master.position)
        }
    }

    @Test("ChainedStream can read/write/seek")
    func chainedStreamCapabilities() throws {
        var buffer = [UInt8](repeating: 0, count: 8)

        do {
            let chained = ChainedStream()
            try chained.add(CanReadWriteSeekStream(true, false, false))
            #expect(chained.canRead)
            #expect(!chained.canWrite)
            #expect(!chained.canSeek)
            #expect(!chained.canTimeout)
            #expect(throws: StreamError.notSupported) { _ = try chained.read(&buffer, offset: 0, count: buffer.count) }
            #expect(throws: StreamError.notSupported) { try chained.write(buffer, offset: 0, count: buffer.count) }
            #expect(throws: StreamError.notSupported) { _ = try chained.seek(0, origin: .end) }
        }

        do {
            let chained = ChainedStream()
            try chained.add(CanReadWriteSeekStream(false, true, false))
            #expect(!chained.canRead)
            #expect(chained.canWrite)
            #expect(!chained.canSeek)
            #expect(!chained.canTimeout)
            #expect(throws: StreamError.notSupported) { _ = try chained.read(&buffer, offset: 0, count: buffer.count) }
            #expect(throws: StreamError.notSupported) { try chained.write(buffer, offset: 0, count: buffer.count) }
            #expect(throws: StreamError.notSupported) { _ = try chained.seek(0, origin: .end) }
        }

        do {
            let chained = ChainedStream()
            try chained.add(CanReadWriteSeekStream(false, false, true))
            #expect(!chained.canRead)
            #expect(!chained.canWrite)
            #expect(chained.canSeek)
            #expect(!chained.canTimeout)
            #expect(throws: StreamError.notSupported) { _ = try chained.read(&buffer, offset: 0, count: buffer.count) }
            #expect(throws: StreamError.notSupported) { try chained.write(buffer, offset: 0, count: buffer.count) }
            #expect(throws: StreamError.notSupported) { _ = try chained.seek(0, origin: .end) }
        }
    }

    @Test("ChainedStream read matches master")
    func chainedStreamRead() throws {
        let bytes = Self.makeBytes(count: 10_240)
        let (chained, master, _) = try Self.makeChained(bytes: bytes)
        try Self.assertReadMatches(chained, master)
    }

    @Test("ChainedStream read async matches master")
    func chainedStreamReadAsync() async throws {
        let bytes = Self.makeBytes(count: 10_240)
        let (chained, master, _) = try Self.makeChained(bytes: bytes)
        var cbuf = [UInt8](repeating: 0, count: 512)
        var mbuf = [UInt8](repeating: 0, count: 512)

        while true {
            let nread = try await chained.readAsync(&cbuf, offset: 0, count: cbuf.count)
            let mread = try await master.readAsync(&mbuf, offset: 0, count: mbuf.count)
            #expect(nread == mread)
            if nread == 0 {
                break
            }
            #expect(Array(cbuf[0..<nread]) == Array(mbuf[0..<mread]))
            #expect(chained.position == master.position)
        }
    }

    @Test("ChainedStream seeking")
    func chainedStreamSeeking() throws {
        let bytes = Self.makeBytes(count: 10_240)
        let (chained, master, _) = try Self.makeChained(bytes: bytes)

        #expect(throws: StreamError.outOfRange) { _ = try chained.seek(-1, origin: .begin) }
        #expect(throws: StreamError.outOfRange) { _ = try chained.seek(chained.length + 1, origin: .begin) }

        let positions = [0, 1, 64, 512, bytes.count / 2, bytes.count - 1, bytes.count]
        for position in positions {
            let expected = try master.seek(position, origin: .begin)
            let actual = try chained.seek(position, origin: .begin)
            #expect(actual == expected)
            try Self.assertReadMatches(chained, master)
        }

        _ = try master.seek(0, origin: .begin)
        _ = try chained.seek(0, origin: .begin)
        let currentOffset = 128
        let expectedCurrent = try master.seek(currentOffset, origin: .current)
        let actualCurrent = try chained.seek(currentOffset, origin: .current)
        #expect(actualCurrent == expectedCurrent)
        try Self.assertReadMatches(chained, master)

        _ = try master.seek(0, origin: .begin)
        _ = try chained.seek(0, origin: .begin)
        let endOffset = -256
        let expectedEnd = try master.seek(endOffset, origin: .end)
        let actualEnd = try chained.seek(endOffset, origin: .end)
        #expect(actualEnd == expectedEnd)
        try Self.assertReadMatches(chained, master)
    }

    @Test("ChainedStream write")
    func chainedStreamWrite() throws {
        let bytes = Self.makeBytes(count: 4096)
        let (chained, _, backing) = try Self.makeChained(bytes: bytes)
        var buffer = [UInt8](repeating: 0, count: chained.length)

        for i in 0..<buffer.count {
            buffer[i] = UInt8(i & 0xFF)
        }

        chained.position = 0
        try chained.write(buffer, offset: 0, count: buffer.count)
        try chained.flush()

        let updated = backing.toByteArray()
        #expect(Array(updated.prefix(buffer.count)) == buffer)
    }

    @Test("ChainedStream write async")
    func chainedStreamWriteAsync() async throws {
        let bytes = Self.makeBytes(count: 4096)
        let (chained, _, backing) = try Self.makeChained(bytes: bytes)
        var buffer = [UInt8](repeating: 0, count: chained.length)

        for i in 0..<buffer.count {
            buffer[i] = UInt8(i & 0xFF)
        }

        chained.position = 0
        try await chained.writeAsync(buffer, offset: 0, count: buffer.count)
        try await chained.flushAsync()

        let updated = backing.toByteArray()
        #expect(Array(updated.prefix(buffer.count)) == buffer)
    }

    @Test("ChainedStream setLength not supported")
    func chainedStreamSetLength() throws {
        let bytes = Self.makeBytes(count: 128)
        let (chained, _, _) = try Self.makeChained(bytes: bytes)
        #expect(throws: StreamError.notSupported) { try chained.setLength(32) }
    }
}
