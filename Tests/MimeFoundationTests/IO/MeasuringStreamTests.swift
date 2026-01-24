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
