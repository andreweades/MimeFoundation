//
// ArgumentExceptionTests.swift
//

import Testing
@testable import MimeFoundation

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

@Test("Argument exceptions: ContentDisposition tryParse invalid indices")
func argumentExceptionsContentDispositionTryParseInvalidIndices() {
    let buffer = Array("attachment; filename=test.txt".utf8)
    var parsed: ContentDisposition? = nil

    #expect(ContentDisposition.tryParse(buffer, startIndex: -1, length: buffer.count, disposition: &parsed) == false)
    #expect(parsed == nil)

    parsed = nil
    #expect(ContentDisposition.tryParse(buffer, startIndex: 0, length: buffer.count + 1, disposition: &parsed) == false)
    #expect(parsed == nil)
}

@Test("Argument exceptions: Address tryParse invalid indices")
func argumentExceptionsAddressTryParseInvalidIndices() {
    let buffer = Array("mimekit@example.com".utf8)

    var group: GroupAddress? = nil
    #expect(GroupAddress.tryParse(buffer, startIndex: -1, length: buffer.count, group: &group) == false)
    #expect(group == nil)

    group = nil
    #expect(GroupAddress.tryParse(buffer, startIndex: 0, length: buffer.count + 1, group: &group) == false)
    #expect(group == nil)

    var mailbox: MailboxAddress? = nil
    #expect(MailboxAddress.tryParse(buffer, startIndex: -1, length: buffer.count, mailbox: &mailbox) == false)
    #expect(mailbox == nil)

    mailbox = nil
    #expect(MailboxAddress.tryParse(buffer, startIndex: 0, length: buffer.count + 1, mailbox: &mailbox) == false)
    #expect(mailbox == nil)

    var address: InternetAddress? = nil
    #expect(InternetAddress.tryParse(buffer, startIndex: -1, length: buffer.count, address: &address) == false)
    #expect(address == nil)

    address = nil
    #expect(InternetAddress.tryParse(buffer, startIndex: 0, length: buffer.count + 1, address: &address) == false)
    #expect(address == nil)

    var list: InternetAddressList? = nil
    #expect(InternetAddressList.tryParse(buffer, startIndex: -1, length: buffer.count, addresses: &list) == false)
    #expect(list == nil)

    list = nil
    #expect(InternetAddressList.tryParse(buffer, startIndex: 0, length: buffer.count + 1, addresses: &list) == false)
    #expect(list == nil)
}

@Test("Argument exceptions: Header tryParse invalid indices")
func argumentExceptionsHeaderTryParseInvalidIndices() {
    let buffer = Array("Subject: Test".utf8)
    var header: Header? = nil

    #expect(Header.tryParse(buffer, startIndex: -1, length: buffer.count, header: &header) == false)
    #expect(header == nil)

    header = nil
    #expect(Header.tryParse(buffer, startIndex: 0, length: buffer.count + 1, header: &header) == false)
    #expect(header == nil)
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
