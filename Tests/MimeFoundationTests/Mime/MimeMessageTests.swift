//
// MimeMessageTests.swift
//

import Testing
import MimeFoundation

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

@Test("MimeMessage getRecipients")
func mimeMessageGetRecipients() {
    let message = MimeMessage()
    message.sender = MailboxAddress(name: "Example Sender", address: "sender@example.com")
    message.from.add(MailboxAddress(name: "Example From", address: "from@example.com"))
    message.replyTo.add(MailboxAddress(name: "Example Reply-To", address: "reply-to@example.com"))
    message.to.add(MailboxAddress(name: "Example To", address: "to@example.com"))
    message.to.add(MailboxAddress(name: "Example To Duplicate", address: "to@example.com"))
    message.cc.add(MailboxAddress(name: "Example Cc", address: "cc@example.com"))
    message.cc.add(MailboxAddress(name: "Example Cc Duplicate", address: "cc@example.com"))
    message.bcc.add(MailboxAddress(name: "Example Bcc", address: "bcc@example.com"))
    message.bcc.add(MailboxAddress(name: "Example Bcc Duplicate", address: "bcc@example.com"))

    var recipients = message.getRecipients()
    #expect(recipients.count == 6)
    #expect(recipients[0] == message.to[0])
    #expect(recipients[1] == message.to[1])
    #expect(recipients[2] == message.cc[0])
    #expect(recipients[3] == message.cc[1])
    #expect(recipients[4] == message.bcc[0])
    #expect(recipients[5] == message.bcc[1])

    recipients = message.getRecipients(true)
    #expect(recipients.count == 3)
    #expect(recipients[0] == message.to.mailboxes.first)
    #expect(recipients[1] == message.cc.mailboxes.first)
    #expect(recipients[2] == message.bcc.mailboxes.first)

    message.resentSender = MailboxAddress(name: "Example Resent-Sender", address: "resent-sender@example.com")
    message.resentFrom.add(MailboxAddress(name: "Example Resent-From", address: "resent-from@example.com"))
    message.resentReplyTo.add(MailboxAddress(name: "Example Resent-Reply-To", address: "resent-reply-to@example.com"))
    message.resentTo.add(MailboxAddress(name: "Example Resent-To", address: "resent-to@example.com"))
    message.resentTo.add(MailboxAddress(name: "Example Resent-To Duplicate", address: "resent-to@example.com"))
    message.resentCc.add(MailboxAddress(name: "Example Resent-Cc", address: "resent-cc@example.com"))
    message.resentCc.add(MailboxAddress(name: "Example Resent-Cc Duplicate", address: "resent-cc@example.com"))
    message.resentBcc.add(MailboxAddress(name: "Example Resent-Bcc", address: "resent-bcc@example.com"))
    message.resentBcc.add(MailboxAddress(name: "Example Resent-Bcc Duplicate", address: "resent-bcc@example.com"))

    recipients = message.getRecipients()
    #expect(recipients.count == 6)
    #expect(recipients[0] == message.resentTo[0])
    #expect(recipients[1] == message.resentTo[1])
    #expect(recipients[2] == message.resentCc[0])
    #expect(recipients[3] == message.resentCc[1])
    #expect(recipients[4] == message.resentBcc[0])
    #expect(recipients[5] == message.resentBcc[1])

    recipients = message.getRecipients(true)
    #expect(recipients.count == 3)
    #expect(recipients[0] == message.resentTo.mailboxes.first)
    #expect(recipients[1] == message.resentCc.mailboxes.first)
    #expect(recipients[2] == message.resentBcc.mailboxes.first)
}

@Test("MimeMessage allows bracketed message ids")
func mimeMessageAllowsBracketedMessageIds() throws {
    let msgid = "[d7e8bc604f797c18ba8120250cbd8c04-JFBVALKQOJXWILKCJQZFA7CDNRQXE2LUPF6EIYLUMFGG643TPRCXQ32TNV2HA===@microsoft.com]"
    let message = MimeMessage()

    try message.setMessageId(msgid)
    #expect(message.messageId == msgid)

    try message.setResentMessageId(msgid)
    #expect(message.resentMessageId == msgid)

    try message.setInReplyTo(msgid)
    #expect(message.inReplyTo == msgid)
}
