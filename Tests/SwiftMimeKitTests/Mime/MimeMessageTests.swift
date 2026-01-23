//
// MimeMessageTests.swift
//

import Testing
import SwiftMimeKit

@Test("MimeMessage headers update")
func mimeMessageHeadersUpdate() {
    let message = MimeMessage()
    message.from.add(MailboxAddress(name: "Sender", address: "sender@example.com"))
    message.to.add(MailboxAddress(name: "Recipient", address: "recipient@example.com"))
    message.subject = "Hello"

    #expect(message.headers[.from] != nil)
    #expect(message.headers[.to] != nil)
    #expect(message.headers[.subject] == "Hello")
}

@Test("MimeMessage write/load roundtrip")
func mimeMessageWriteLoadRoundtrip() throws {
    let message = MimeMessage()
    message.from.add(MailboxAddress(name: "Sender", address: "sender@example.com"))
    message.to.add(MailboxAddress(name: "Recipient", address: "recipient@example.com"))
    message.subject = "Roundtrip"

    let textPart = TextPart("plain")
    textPart.text = "Hello, world!"
    message.body = textPart

    let stream = MemoryStream()
    try message.writeTo(stream)
    _ = try stream.seek(0, origin: .begin)

    let loaded = try MimeMessage.load(stream)
    #expect(loaded.headers[.subject] == "Roundtrip")

    guard let loadedText = loaded.body as? TextPart else {
        Issue.record("Expected TextPart body")
        return
    }
    #expect(loadedText.text == "Hello, world!")
}
