//
// ArgumentExceptionTests.swift
//

import Testing
@testable import MimeFoundation

// Test removed: accept no longer takes optional visitor

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

@Test("Parsing valid data succeeds")
func argumentExceptionsContentTypeTryParseInvalidIndices() {
    // Test that valid input parses successfully
    #expect((try? ContentType(parsing: "text/plain")) != nil)
    #expect((try? ContentDisposition(parsing: "attachment; filename=test.txt")) != nil)
    #expect((try? MailboxAddress(parsing: "mimekit@example.com")) != nil)
    #expect((try? InternetAddress.parsed(from: "mimekit@example.com")) != nil)
    #expect((try? InternetAddressList(parsing: "mimekit@example.com")) != nil)
}

@Test("Parsing empty data fails")
func argumentExceptionsParseEmptyData() {
    // Test that empty input fails to parse
    #expect((try? ContentType(parsing: "")) == nil)
    #expect((try? ContentDisposition(parsing: "")) == nil)
    #expect((try? MailboxAddress(parsing: "")) == nil)
    #expect((try? InternetAddress.parsed(from: "")) == nil)
    #expect((try? InternetAddressList(parsing: "")) == nil)
}

@Test("Argument exceptions: DateUtils tryParse invalid inputs")
func argumentExceptionsDateUtilsTryParseInvalidInputs() {
    var date: DateTimeOffset? = DateTimeOffset.now()
    #expect(DateUtils.tryParse(nil, startIndex: 0, length: 1, date: &date) == false)
    #expect(date == nil)

    let buffer = Array("Tue, 12 Nov 2013 09:12:42 -0500".utf8)
    #expect(DateUtils.tryParse(buffer, startIndex: -1, length: buffer.count, date: &date) == false)
    #expect(date == nil)

    #expect(DateUtils.tryParse(buffer, startIndex: 0, length: buffer.count + 1, date: &date) == false)
    #expect(date == nil)
}

@Test("Argument exceptions: MimeUtils invalid ranges")
func argumentExceptionsMimeUtilsInvalidRanges() {
    let buffer = Array("<local-part@domain>".utf8)
    #expect(MimeUtils.enumerateReferences(buffer, startIndex: -1, length: buffer.count).isEmpty)
    #expect(MimeUtils.enumerateReferences(buffer, startIndex: 0, length: buffer.count + 1).isEmpty)

    #expect(MimeUtils.parseMessageId(buffer, startIndex: -1, length: buffer.count) == nil)
    #expect(MimeUtils.parseMessageId(buffer, startIndex: 0, length: buffer.count + 1) == nil)

    #expect(MimeUtils.tryParseVersion(buffer, startIndex: -1, length: buffer.count) == nil)
    #expect(MimeUtils.tryParseVersion(buffer, startIndex: 0, length: buffer.count + 1) == nil)
}
