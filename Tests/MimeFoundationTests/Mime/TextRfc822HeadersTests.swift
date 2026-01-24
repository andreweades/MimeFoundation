//
// TextRfc822HeadersTests.swift
//

import Testing
import MimeFoundation

@Test("TextRfc822Headers argument exceptions")
func textRfc822HeadersArgumentExceptions() {
    let entity = TextRfc822Headers()

    #expect(throws: (any Error).self) {
        _ = try TextRfc822Headers(args: ["unknown-parameter"])
    }

    #expect(throws: (any Error).self) {
        _ = try TextRfc822Headers(MimeMessage(), MimeMessage())
    }

    #expect(throws: (any Error).self) {
        try entity.accept(nil)
    }
}

@Test("TextRfc822Headers serialization")
func textRfc822HeadersSerialization() throws {
    let inner = MimeMessage()
    inner.from.add(MailboxAddress(name: "Sender Name", address: "sender@example.com"))
    inner.to.add(MailboxAddress(name: "Recipient Name", address: "recipient@example.com"))
    inner.subject = "Content of a text/rfc822-headers part"

    let rfc822headers = try TextRfc822Headers(Header(.contentId, value: "<id@localhost>"), inner)

    let outer = MimeMessage()
    outer.from.add(MailboxAddress(name: "Postmaster", address: "postmaster@example.com"))
    outer.to.add(MailboxAddress(name: "Sender Name", address: "sender@example.com.com"))
    outer.subject = "Sorry, but your message bounced"
    outer.body = rfc822headers

    let stream = MemoryStream()
    try outer.writeTo(stream)
    _ = try stream.seek(0, origin: .begin)

    let loaded = try MimeMessage.load(stream)
    guard let part = loaded.body as? TextRfc822Headers else {
        Issue.record("Expected TextRfc822Headers body")
        return
    }
    #expect(part.contentId == "id@localhost")
}
