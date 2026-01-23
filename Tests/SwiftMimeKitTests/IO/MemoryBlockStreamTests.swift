//
// MemoryBlockStreamTests.swift
//

import Testing
@testable import SwiftMimeKit

@Suite
struct MemoryBlockStreamTests {
    private static func makeBytes(count: Int) -> [UInt8] {
        (0..<count).map { UInt8($0 % 253) }
    }

    @Test("MemoryBlockStream capabilities")
    func memoryBlockStreamCapabilities() {
        let stream = MemoryBlockStream()
        #expect(stream.canRead)
        #expect(stream.canWrite)
        #expect(stream.canSeek)
        #expect(!stream.canTimeout)
        #expect(stream.readTimeout == 0)
        #expect(stream.writeTimeout == 0)
    }

    @Test("MemoryBlockStream read/write")
    func memoryBlockStreamReadWrite() throws {
        let bytes = Self.makeBytes(count: 8192)
        let stream = MemoryBlockStream()

        var position = 0
        let chunkSize = 777
        while position < bytes.count {
            let count = min(chunkSize, bytes.count - position)
            try stream.write(bytes, offset: position, count: count)
            position += count
        }

        _ = try stream.seek(0, origin: .begin)
        var buffer = [UInt8](repeating: 0, count: bytes.count)
        let nread = try stream.read(&buffer, offset: 0, count: buffer.count)
        #expect(nread == bytes.count)
        #expect(buffer == bytes)
    }

    @Test("MemoryBlockStream read async")
    func memoryBlockStreamReadAsync() async throws {
        let bytes = Self.makeBytes(count: 4096)
        let stream = MemoryBlockStream()
        try stream.write(bytes, offset: 0, count: bytes.count)
        _ = try stream.seek(0, origin: .begin)

        var buffer = [UInt8](repeating: 0, count: bytes.count)
        let nread = try await stream.readAsync(&buffer, offset: 0, count: buffer.count)
        #expect(nread == bytes.count)
        #expect(buffer == bytes)
    }

    @Test("MemoryBlockStream write async")
    func memoryBlockStreamWriteAsync() async throws {
        let bytes = Self.makeBytes(count: 4096)
        let stream = MemoryBlockStream()
        try await stream.writeAsync(bytes, offset: 0, count: bytes.count)
        try await stream.flushAsync()
        #expect(stream.length == bytes.count)
        #expect(try stream.toArray() == bytes)
    }

    @Test("MemoryBlockStream seek/setLength")
    func memoryBlockStreamSeekSetLength() throws {
        let stream = MemoryBlockStream()
        try stream.write([1, 2, 3, 4], offset: 0, count: 4)
        _ = try stream.seek(2, origin: .begin)
        #expect(stream.position == 2)
        #expect(throws: StreamError.outOfRange) { _ = try stream.seek(-1, origin: .begin) }

        try stream.setLength(2)
        #expect(stream.length == 2)
        try stream.setLength(5)
        #expect(stream.length == 5)
    }

    @Test("MemoryBlockStream close")
    func memoryBlockStreamClose() {
        let stream = MemoryBlockStream()
        stream.close()
        var buffer = [UInt8](repeating: 0, count: 4)
        #expect(throws: StreamError.closed) { _ = try stream.read(&buffer, offset: 0, count: buffer.count) }
        #expect(throws: StreamError.closed) { try stream.write(buffer, offset: 0, count: buffer.count) }
        #expect(throws: StreamError.closed) { _ = try stream.seek(0, origin: .begin) }
        #expect(throws: StreamError.closed) { try stream.setLength(1) }
        #expect(throws: StreamError.closed) { _ = try stream.toArray() }
    }
}
