//
// FilterTests.swift
//

import Testing
@testable import SwiftMimeKit

@Suite
struct FilterTests {
    private static func applyFilter(_ filter: MimeFilter, to text: String, chunkSize: Int? = nil) throws -> String {
        let input = Array(text.utf8)
        let output = MemoryStream([], writable: true)
        let filtered = try FilteredStream(output)
        try filtered.add(filter)

        if let chunkSize {
            var offset = 0
            while offset < input.count {
                let count = min(chunkSize, input.count - offset)
                try filtered.write(input, offset: offset, count: count)
                offset += count
            }
        } else {
            try filtered.write(input, offset: 0, count: input.count)
        }

        try filtered.flush()
        try filtered.flush()
        let bytes = output.toByteArray()
        return String(decoding: bytes, as: UTF8.self)
    }

    private static func indexOf(_ bytes: [UInt8], pattern: [UInt8]) -> Int? {
        guard bytes.count >= pattern.count else { return nil }
        for i in 0...(bytes.count - pattern.count) {
            if bytes[i..<(i + pattern.count)].elementsEqual(pattern) {
                return i
            }
        }
        return nil
    }

    @Test("ArmoredFromFilter")
    func armoredFromFilter() throws {
        let text = "This text is meant to test that the filter will armor lines beginning with\nFrom (like mbox). And let's add another\nFrom line for good measure, shall we?\n"
        let expected = "This text is meant to test that the filter will armor lines beginning with\n=46rom (like mbox). And let's add another\n=46rom line for good measure, shall we?\n"
        let filter = ArmoredFromFilter()
        let bytes = Array(text.utf8)
        let marker = Array("\nFrom ".utf8)
        let fromIndex = Self.indexOf(bytes, pattern: marker) ?? 0
        let split = fromIndex + 3

        let output = MemoryStream([], writable: true)
        let filtered = try FilteredStream(output)
        try filtered.add(filter)
        try filtered.write(bytes, offset: 0, count: split)
        try filtered.write(bytes, offset: split, count: bytes.count - split)
        try filtered.flush()

        let actual = String(decoding: output.toByteArray(), as: UTF8.self)
        #expect(actual == expected)
    }

    @Test("ArmoredFromFilter repeated chunks")
    func armoredFromFilterRepeatedChunks() throws {
        let line = "From Russia with love is one of my favorite James Bond files.\n"
        let iterations = 1000
        let input = String(repeating: line, count: iterations)
        let expectedLine = "=46" + String(line.dropFirst())
        let expected = String(repeating: expectedLine, count: iterations)

        for size in [1, 8, 64, 1024] {
            let actual = try Self.applyFilter(ArmoredFromFilter(), to: input, chunkSize: size)
            #expect(actual == expected)
        }
    }

    @Test("MboxFromFilter")
    func mboxFromFilter() throws {
        let text = "This text is meant to test that the filter will armor lines beginning with\nFrom (like mbox). And let's add another\nFrom line for good measure, shall we?\n"
        let expected = "This text is meant to test that the filter will armor lines beginning with\n>From (like mbox). And let's add another\n>From line for good measure, shall we?\n"
        let filter = MboxFromFilter()
        let bytes = Array(text.utf8)
        let marker = Array("\nFrom ".utf8)
        let fromIndex = Self.indexOf(bytes, pattern: marker) ?? 0
        let split = fromIndex + 3

        let output = MemoryStream([], writable: true)
        let filtered = try FilteredStream(output)
        try filtered.add(filter)
        try filtered.write(bytes, offset: 0, count: split)
        try filtered.write(bytes, offset: split, count: bytes.count - split)
        try filtered.flush()

        let actual = String(decoding: output.toByteArray(), as: UTF8.self)
        #expect(actual == expected)
    }

    @Test("MboxFromFilter repeated chunks")
    func mboxFromFilterRepeatedChunks() throws {
        let line = "From Russia with love is one of my favorite James Bond files.\n"
        let iterations = 1000
        let input = String(repeating: line, count: iterations)
        let expected = String(repeating: ">" + line, count: iterations)

        for size in [1, 8, 64, 1024] {
            let actual = try Self.applyFilter(MboxFromFilter(), to: input, chunkSize: size)
            #expect(actual == expected)
        }
    }

    @Test("Unix2DosFilter")
    func unix2DosFilter() throws {
        let text = "This text is meant to test that the filter will convert unix line endings to dos.\nHere's a second line of text.\nAnd one more line for good measure, shall we?"
        let expected = "This text is meant to test that the filter will convert unix line endings to dos.\r\nHere's a second line of text.\r\nAnd one more line for good measure, shall we?"

        let actual = try Self.applyFilter(Unix2DosFilter(false), to: text)
        #expect(actual == expected)

        let ensured = try Self.applyFilter(Unix2DosFilter(true), to: text)
        #expect(ensured == expected + "\r\n")
    }

    @Test("Unix2DosFilter mixed line endings")
    func unix2DosFilterMixed() throws {
        let text = "This text is meant to test that the filter will convert unix line endings to dos.\nHere's a second line of text.\r\nAnd one more line for good measure, shall we?\r"
        let expected = "This text is meant to test that the filter will convert unix line endings to dos.\r\nHere's a second line of text.\r\nAnd one more line for good measure, shall we?\r"

        let actual = try Self.applyFilter(Unix2DosFilter(false), to: text)
        #expect(actual == expected)

        let ensured = try Self.applyFilter(Unix2DosFilter(true), to: text)
        #expect(ensured == expected + "\n")
    }

    @Test("Dos2UnixFilter")
    func dos2UnixFilter() throws {
        let text = "This text is meant to test that the filter will convert dos line endings to unix.\r\nHere's a second line of text.\r\nAnd one more line for good measure, shall we?"
        let expected = "This text is meant to test that the filter will convert dos line endings to unix.\nHere's a second line of text.\nAnd one more line for good measure, shall we?"

        let actual = try Self.applyFilter(Dos2UnixFilter(false), to: text)
        #expect(actual == expected)

        let ensured = try Self.applyFilter(Dos2UnixFilter(true), to: text)
        #expect(ensured == expected + "\n")
    }

    @Test("Dos2UnixFilter mixed line endings")
    func dos2UnixFilterMixed() throws {
        let text = "This text is meant to test that the filter will convert dos line endings to unix.\nHere's a second line of text.\r\nAnd one more line for good measure, shall we?\n"
        let expected = "This text is meant to test that the filter will convert dos line endings to unix.\nHere's a second line of text.\nAnd one more line for good measure, shall we?\n"

        let actual = try Self.applyFilter(Dos2UnixFilter(false), to: text)
        #expect(actual == expected)

        let ensured = try Self.applyFilter(Dos2UnixFilter(true), to: text)
        #expect(ensured == expected)
    }

    @Test("TrailingWhitespaceFilter")
    func trailingWhitespaceFilter() throws {
        let text = "Hello  \r\nWorld\t\t\nDone   "
        let expected = "Hello\r\nWorld\nDone"
        let actual = try Self.applyFilter(TrailingWhitespaceFilter(), to: text)
        #expect(actual == expected)
    }

    @Test("PassThroughFilter")
    func passThroughFilter() {
        let filter = PassThroughFilter()
        var outputIndex = 0
        var outputLength = 0
        let buffer = [UInt8](repeating: 0x2A, count: 10)

        let filtered = filter.filter(buffer, startIndex: 1, length: buffer.count - 2, outputIndex: &outputIndex, outputLength: &outputLength)
        #expect(filtered == buffer)
        #expect(outputIndex == 1)
        #expect(outputLength == buffer.count - 2)

        let flushed = filter.flush(buffer, startIndex: 1, length: buffer.count - 2, outputIndex: &outputIndex, outputLength: &outputLength)
        #expect(flushed == buffer)
        #expect(outputIndex == 1)
        #expect(outputLength == buffer.count - 2)
    }
}
