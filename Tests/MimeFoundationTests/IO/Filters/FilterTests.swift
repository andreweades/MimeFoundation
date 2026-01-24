//
// FilterTests.swift
//

import Foundation
import Testing
@testable import MimeFoundation

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

    private static func applyOpenPgpBlockFilter(_ filter: OpenPgpBlockFilter, input: String, increment: Int) throws -> String {
        let buffer = Array(input.utf8)
        let output = MemoryStream([], writable: true)
        let filtered = try FilteredStream(output)
        try filtered.add(filter)

        var index = 0
        while index < buffer.count {
            let count = min(increment, buffer.count - index)
            try filtered.write(buffer, offset: index, count: count)
            index += count
        }

        try filtered.flush()
        return String(decoding: output.toByteArray(), as: UTF8.self)
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

    @Test("BestEncodingFilter")
    func bestEncodingFilter() throws {
        let fromLines = "This text is meant to test that the filter will armor lines beginning with\nFrom (like mbox).\n"
        let ascii = "This is some ascii text to make sure that\nthe filter returns 7bit encoding...\n"
        let french = "Wikipédia est un projet d’encyclopédie collective en ligne, universelle, multilingue et fonctionnant sur le principe du wiki. Wikipédia a pour objectif d’offrir un contenu librement réutilisable, objectif et vérifiable, que chacun peut modifier et améliorer.\n\nTous les rédacteurs des articles de Wikipédia sont bénévoles. Ils coordonnent leurs efforts au sein d'une communauté collaborative, sans dirigeant."
        let filter = BestEncodingFilter()

        #expect(throws: BestEncodingFilterError.invalidMaxLineLength) {
            _ = try filter.getBestEncoding(.sevenBit, maxLineLength: 10)
        }

        do {
            let stream = MemoryStream([], writable: true)
            let filtered = try FilteredStream(stream)
            try filtered.add(filter)

            let buffer = Array(ascii.utf8)
            try filtered.write(buffer, offset: 0, count: buffer.count)
            try filtered.flush()

            #expect(try filter.getBestEncoding(.sevenBit) == .sevenBit)
            #expect(try filter.getBestEncoding(.eightBit) == .sevenBit)
            #expect(try filter.getBestEncoding(.none) == .sevenBit)

            _ = try filtered.remove(filter)
        }

        filter.reset()

        do {
            let stream = MemoryStream([], writable: true)
            let filtered = try FilteredStream(stream)
            try filtered.add(filter)

            let buffer = Array(fromLines.utf8)
            let marker = Array("\nFrom ".utf8)
            let fromIndex = Self.indexOf(buffer, pattern: marker) ?? 0
            let split = fromIndex + 3
            try filtered.write(buffer, offset: 0, count: split)
            try filtered.write(buffer, offset: split, count: buffer.count - split)
            try filtered.flush()

            #expect(try filter.getBestEncoding(.sevenBit) == .quotedPrintable)
            #expect(try filter.getBestEncoding(.eightBit) == .quotedPrintable)
            #expect(try filter.getBestEncoding(.none) == .quotedPrintable)
        }

        filter.reset()

        do {
            let stream = MemoryStream([], writable: true)
            let filtered = try FilteredStream(stream)
            try filtered.add(filter)

            let buffer = Array(french.utf8)
            let shortCount = min(60, buffer.count)
            try filtered.write(buffer, offset: 0, count: shortCount)
            try filtered.flush()

            #expect(try filter.getBestEncoding(.sevenBit) == .quotedPrintable)
            #expect(try filter.getBestEncoding(.eightBit) == .eightBit)
            #expect(try filter.getBestEncoding(.none) == .eightBit)
        }

        filter.reset()

        do {
            let stream = MemoryStream([], writable: true)
            let filtered = try FilteredStream(stream)
            try filtered.add(filter)

            let buffer = Array(french.utf8)
            try filtered.write(buffer, offset: 0, count: buffer.count)
            try filtered.flush()

            #expect(try filter.getBestEncoding(.sevenBit) == .quotedPrintable)
            #expect(try filter.getBestEncoding(.eightBit) == .quotedPrintable)
            #expect(try filter.getBestEncoding(.none) == .quotedPrintable)
        }

        filter.reset()

        do {
            let stream = MemoryStream([], writable: true)
            let filtered = try FilteredStream(stream)
            try filtered.add(filter)

            let buffer = Array("abcdefghijklmnopqrstuvwxyzabcdefghijklmnopqrstuvwxyzabcdefghijklmnopqrstuvwxyz\r\nabc\r\n".utf8)
            try filtered.write(buffer, offset: 0, count: buffer.count)
            try filtered.flush()

            #expect(try filter.getBestEncoding(.sevenBit, maxLineLength: 78) == .sevenBit)
            #expect(try filter.getBestEncoding(.eightBit, maxLineLength: 78) == .sevenBit)
            #expect(try filter.getBestEncoding(.none, maxLineLength: 78) == .sevenBit)
        }
    }

    @Test("CharsetFilter")
    func charsetFilter() throws {
        let french = "Wikipédia est un projet d’encyclopédie collective en ligne, universelle, multilingue et fonctionnant sur le principe du wiki. Wikipédia a pour objectif d’offrir un contenu librement réutilisable, objectif et vérifiable, que chacun peut modifier et améliorer.\n\nTous les rédacteurs des articles de Wikipédia sont bénévoles. Ils coordonnent leurs efforts au sein d'une communauté collaborative, sans dirigeant."

        #expect(throws: CharsetFilterError.unsupportedEncoding) { _ = try CharsetFilter("bogus charset", "iso-8859-1") }
        #expect(throws: CharsetFilterError.unsupportedEncoding) { _ = try CharsetFilter("iso-8859-1", "bogus charset") }
        #expect(throws: CharsetFilterError.invalidArgument) { _ = try CharsetFilter(sourceCodepage: -1, targetCodepage: 28591) }
        #expect(throws: CharsetFilterError.invalidArgument) { _ = try CharsetFilter(sourceCodepage: 28591, targetCodepage: -1) }

        _ = CharsetFilter(.utf8, .isoLatin1)

        if let iso8859_15 = CharsetUtils.getEncoding("iso-8859-15") {
            let expected = french.data(using: iso8859_15, allowLossyConversion: true) ?? Data()
            let source = MemoryStream(Array(french.utf8), writable: false)
            let filtered = try FilteredStream(source)
            try filtered.add(try CharsetFilter("utf-8", "iso-8859-15"))

            var buffer = [UInt8](repeating: 0, count: expected.count)
            var length = try filtered.read(&buffer, offset: 0, count: expected.count / 2)
            length += try filtered.read(&buffer, offset: expected.count / 2, count: buffer.count - expected.count / 2)
            try filtered.flush()

            #expect(length == expected.count)
        }

        do {
            let expected = french.data(using: .isoLatin1, allowLossyConversion: true) ?? Data()
            let source = MemoryStream(Array(french.utf8), writable: false)
            let filtered = try FilteredStream(source)
            try filtered.add(CharsetFilter(.utf8, .isoLatin1))

            var buffer = [UInt8](repeating: 0, count: expected.count)
            var length = try filtered.read(&buffer, offset: 0, count: expected.count / 2)
            length += try filtered.read(&buffer, offset: expected.count / 2, count: buffer.count - expected.count / 2)
            try filtered.flush()

            #expect(length == expected.count)
        }
    }

    @Test("OpenPgpBlockFilter")
    func openPgpBlockFilter() throws {
        let input = """
% cat sample
This is a sample.

This is a sample text file.  I created it with an editor.  If it were
an actual message, it would contain some useful information.

This has been a sample.
% pgp -eat sample john
Pretty Good Privacy(tm) 2.6.2 - Public-key encryption for the masses.
(c) 1990-1994 Philip Zimmermann, Phil's Pretty Good Software. 11 Oct 94
Uses the RSAREF(tm) Toolkit, which is copyright RSA Data Security, Inc.
Distributed by the Massachusetts Institute of Technology.
Export of this software may be restricted by the U.S. government.
Current time: 1996/11/09 13:10 GMT


Recipients' public key(s) will be used to encrypt. 
Key for user ID: John E Doe <jd@somewhere.net>
1024-bit key, Key ID F4DD25F1, created 1996/11/07

WARNING:  Because this public key is not certified with a trusted
signature, it is not known with high confidence that this public key
actually belongs to: "John E Doe <jd@somewhere.net>".

Are you sure you want to use this public key (y/N)? y
.
Transport armor file: sample.asc
% cat sample.asc
-----BEGIN PGP MESSAGE-----
Version: 2.6.2

hIwD1vwet/TdJfEBBACdcCPkNI3kRwYqtHUyfpvVAY5rt+Lb9P6EztNd4sYq9egV
CZjfqcCn36XZmYPbbO6nZbl992kPRFzTgCRszKNPtlk6Wa93AqXs3KCZp+4emXQh
7moE+XTf4QUGJZ2L3w/sSNs5WFkZRIbto0ivK1aRlX1XTqhPqo9HbgEfElBVUaYA
AACQEWaOS3/h6BVLHTfXaK20vmLcg9BUisB5RDvYGLZv9XFwHMMjctFJJQYnWIOp
+7LLkmNO5fE48rWh0EOAwjAeduGzJGQb4yiE7OlxoESmmTJQ+qO1K2nDz8Stk3a6
WvAQJrpEUY7Og8QGlQQRPKl2F++j6XbIhZ27OeYqJp+vgylUd874KDMCcTrzF3ph
/Qfi
=xTV9
-----END PGP MESSAGE-----
%
"""
        let expected = """
-----BEGIN PGP MESSAGE-----
Version: 2.6.2

hIwD1vwet/TdJfEBBACdcCPkNI3kRwYqtHUyfpvVAY5rt+Lb9P6EztNd4sYq9egV
CZjfqcCn36XZmYPbbO6nZbl992kPRFzTgCRszKNPtlk6Wa93AqXs3KCZp+4emXQh
7moE+XTf4QUGJZ2L3w/sSNs5WFkZRIbto0ivK1aRlX1XTqhPqo9HbgEfElBVUaYA
AACQEWaOS3/h6BVLHTfXaK20vmLcg9BUisB5RDvYGLZv9XFwHMMjctFJJQYnWIOp
+7LLkmNO5fE48rWh0EOAwjAeduGzJGQb4yiE7OlxoESmmTJQ+qO1K2nDz8Stk3a6
WvAQJrpEUY7Og8QGlQQRPKl2F++j6XbIhZ27OeYqJp+vgylUd874KDMCcTrzF3ph
/Qfi
=xTV9
-----END PGP MESSAGE-----
""" + "\n"
        let filter = OpenPgpBlockFilter("-----BEGIN PGP MESSAGE-----", "-----END PGP MESSAGE-----")
        let actual20 = try Self.applyOpenPgpBlockFilter(filter, input: input, increment: 20)
        #expect(actual20 == expected)

        filter.reset()
        let actual21 = try Self.applyOpenPgpBlockFilter(filter, input: input, increment: 21)
        #expect(actual21 == expected)
    }
}
