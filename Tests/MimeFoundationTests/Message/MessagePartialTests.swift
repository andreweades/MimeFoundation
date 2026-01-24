//
// MessagePartialTests.swift
//

import Testing
@testable import MimeFoundation

@Test("MessagePartial number/total parameters")
func messagePartialNumberTotalParameters() throws {
    let partial = try MessagePartial("abc@example.com", 1, 5)
    partial.contentType.parameters["number"] = "invalid"
    partial.contentType.parameters["total"] = "invalid"
    #expect(partial.number == nil)
    #expect(partial.total == nil)

    partial.contentType.parameters.remove("number")
    partial.contentType.parameters.remove("total")
    #expect(partial.number == nil)
    #expect(partial.total == nil)

    partial.contentType.parameters["number"] = "1"
    partial.contentType.parameters["total"] = "5"
    #expect(partial.number == 1)
    #expect(partial.total == 5)
}

@Test("MessagePartial split and join")
func messagePartialSplitAndJoin() throws {
    let message = MimeMessage()
    message.subject = "Hello"
    let body = TextPart("plain")
    body.text = "This is a message body used for splitting."
    message.body = body

    let parts = try MessagePartial.split(message, maxSize: 32)
    #expect(!parts.isEmpty)

    let partials: [MessagePartial] = parts.compactMap { $0.body as? MessagePartial }
    #expect(partials.count == parts.count)

    let joined = try MessagePartial.join(message, partials)
    #expect(joined.subject == "Hello")
    let joinedText = (joined.body as? TextPart)?.text
    #expect(joinedText == "This is a message body used for splitting.")
}
