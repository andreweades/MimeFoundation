//
// ReadOneByteStreamTests.swift
//

import Testing
@testable import SwiftMimeKit

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
