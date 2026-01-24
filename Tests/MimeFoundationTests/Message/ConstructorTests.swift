//
// ConstructorTests.swift
//

import Testing
import MimeFoundation

@Test("Constructor argument exceptions")
func constructorArgumentExceptions() throws {
    let body = TextPart("plain")
    body.text = "This is the body..."
    let message = MimeMessage()

    #expect(throws: (any Error).self) {
        _ = try MimeMessage(args: nil)
    }

    #expect(throws: (any Error).self) {
        _ = try MimeMessage(body, nil, body)
    }

    #expect(throws: (any Error).self) {
        _ = try MimeMessage(5)
    }

    #expect(throws: (any Error).self) {
        _ = try MessagePart("rfc822", args: nil)
    }

    #expect(throws: (any Error).self) {
        _ = try MessagePart("rfc822", message, nil, message)
    }

    #expect(throws: (any Error).self) {
        _ = try MessagePart("rfc822", 5)
    }

    _ = try MessagePart("rfc822", message)

    #expect(throws: (any Error).self) {
        _ = try MimePart("text", "plain", args: nil)
    }
}

@Test("MimeMessage with headers")
func mimeMessageWithHeaders() throws {
    let timestamp = "Thu, 29 Sep 2022 08:55:19 +0400"
    let msg = try MimeMessage(
        Header(field: "From", value: "Federico Di Gregorio <fog@dndg.it>"),
        Header(field: "To", value: "jeff@xamarin.com"),
        [Header(field: "Cc", value: "fog@dndg.it"), Header(field: "Cc", value: "<gg@dndg.it>")],
        Header(field: "Subject", value: "Hello"),
        TextPart("plain", "Just a short message to say hello!"),
        Header(field: "Date", value: timestamp)
    )

    var date: DateTimeOffset? = nil
    _ = DateUtils.tryParse(timestamp, date: &date)

    #expect(msg.from.count == 1)
    #expect(msg.from[0].toString(encode: false) == "\"Federico Di Gregorio\" <fog@dndg.it>")
    #expect(msg.to.count == 1)
    #expect(msg.to[0].toString(encode: false) == "jeff@xamarin.com")
    #expect(msg.cc.count == 2)
    #expect(msg.cc[0].toString(encode: false) == "fog@dndg.it")
    #expect(msg.cc[1].toString(encode: false) == "gg@dndg.it")
    #expect(msg.subject == "Hello")
    #expect(msg.date == date)
}

@Test("Generate multiple messages")
func generateMultipleMessages() throws {
    let destinations = ["jeff@xamarin.com", "gg@dndg.it"]
    let msgs = try destinations.map { destination in
        try MimeMessage(
            Header(field: "From", value: "Federico Di Gregorio <fog@dndg.it>"),
            Header(field: "To", value: destination),
            Header(field: "Subject", value: "Hello"),
            TextPart("plain", "Just a short message to say hello!")
        )
    }

    #expect(msgs.count == 2)
    #expect(msgs[0].from[0].toString(encode: false) == "\"Federico Di Gregorio\" <fog@dndg.it>")
    #expect(msgs[1].from[0].toString(encode: false) == "\"Federico Di Gregorio\" <fog@dndg.it>")
    #expect(msgs[0].to[0].toString(encode: false) == "jeff@xamarin.com")
    #expect(msgs[1].to[0].toString(encode: false) == "gg@dndg.it")
}

@Test("Multipart alternative constructor")
func multipartAlternativeConstructor() throws {
    let multipart = try Multipart(
        "alternative",
        TextPart("plain", "Just a short message to say hello!"),
        TextPart("html", "<html><head></head><body><strong>Just a short message to say hello!</strong></body></html>")
    )

    #expect(multipart.count == 2)
    #expect(multipart[0].contentType.mediaSubtype == "plain")
    #expect(multipart[1].contentType.mediaSubtype == "html")
    #expect((multipart[0] as? TextPart)?.text == "Just a short message to say hello!")
    #expect((multipart[1] as? TextPart)?.text == "<html><head></head><body><strong>Just a short message to say hello!</strong></body></html>")
}

@Test("MimePart content object")
func mimePartContentObject() throws {
    let data = Array("abcd".utf8)

    let content = try MimeContent(MemoryStream(data, writable: false), encoding: .binary)
    let part = try MimePart("application", "octet-stream", content)

    let checksum = try part.computeContentMd5()
    #expect(checksum.isEmpty == false)
    #expect(part.content?.encoding == .binary)
}

@Test("MimePart stream")
func mimePartStream() throws {
    let data = Array("abcd".utf8)
    let part = try MimePart("application", "octet-stream", MemoryStream(data, writable: false))

    let buffer = MemoryStream()
    try part.content?.decodeTo(buffer)
    #expect(part.content?.encoding == .default)
    #expect(buffer.toByteArray() == data)
}
