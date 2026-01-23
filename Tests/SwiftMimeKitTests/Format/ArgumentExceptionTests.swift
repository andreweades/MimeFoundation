//
// ArgumentExceptionTests.swift
//

import Testing
@testable import SwiftMimeKit

@Test("Argument exceptions: MimeEntity accept nil visitor")
func argumentExceptionsAcceptNilVisitor() {
    let part = TextPart("plain")
    #expect(throws: MimeEntityError.nilVisitor) {
        try part.accept(nil)
    }
}

@Test("Argument exceptions: Crc32 update invalid range")
func argumentExceptionsCrc32UpdateInvalidRange() {
    let crc = Crc32(initialValue: 0)
    let buffer = [UInt8](repeating: 0x2A, count: 4)
    let initial = crc.checksum

    _ = crc.update(buffer, offset: -1, count: 2)
    #expect(crc.checksum == initial)

    _ = crc.update(buffer, offset: 0, count: -1)
    #expect(crc.checksum == initial)

    _ = crc.update(buffer, offset: 3, count: 4)
    #expect(crc.checksum == initial)
}

@Test("Argument exceptions: ContentType tryParse invalid indices")
func argumentExceptionsContentTypeTryParseInvalidIndices() {
    let buffer = Array("text/plain".utf8)
    var parsed: ContentType? = nil

    #expect(ContentType.tryParse(buffer, startIndex: -1, length: buffer.count, contentType: &parsed) == false)
    #expect(parsed == nil)

    parsed = nil
    #expect(ContentType.tryParse(buffer, startIndex: 0, length: buffer.count + 1, contentType: &parsed) == false)
    #expect(parsed == nil)
}
