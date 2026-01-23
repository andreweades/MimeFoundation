//
// BodyBuilderTests.swift
//

import Testing
import SwiftMimeKit

@Test("BodyBuilder argument exceptions")
func bodyBuilderArgumentExceptions() {
    let builder = BodyBuilder()
    #expect(throws: (any Error).self) {
        try builder.setBodyEncoding(nil)
    }
}

@Test("BodyBuilder default message body")
func bodyBuilderToMessageBodyDefault() throws {
    let builder = BodyBuilder()

    #expect(builder.bodyEncoding == .utf8)

    let body = try builder.toMessageBody()
    let textBody = body as? TextPart
    #expect(textBody != nil)
    #expect(textBody?.contentType.mimeType == "text/plain")
    #expect(textBody?.contentType.charset == "utf-8")
    #expect(textBody?.text == "")
}

@Test("BodyBuilder body encoding text/plain")
func bodyBuilderBodyEncodingTextPlain() throws {
    let builder = BodyBuilder()
    builder.bodyEncoding = CharsetUtils.latin1
    builder.textBody = "This is the text body."

    let body = try builder.toMessageBody()
    let textBody = body as? TextPart
    #expect(textBody != nil)
    #expect(textBody?.contentType.mimeType == "text/plain")
    #expect(textBody?.contentType.charset == "iso-8859-1")
    #expect(textBody?.text == builder.textBody)
}

@Test("BodyBuilder body encoding text/html")
func bodyBuilderBodyEncodingTextHtml() throws {
    let builder = BodyBuilder()
    builder.bodyEncoding = CharsetUtils.latin1
    builder.htmlBody = "This is the html body."

    let body = try builder.toMessageBody()
    let textBody = body as? TextPart
    #expect(textBody != nil)
    #expect(textBody?.contentType.mimeType == "text/html")
    #expect(textBody?.contentType.charset == "iso-8859-1")
    #expect(textBody?.text == builder.htmlBody)
}

@Test("BodyBuilder body encoding multipart alternative")
func bodyBuilderBodyEncodingMultipartAlternative() throws {
    let builder = BodyBuilder()
    builder.bodyEncoding = CharsetUtils.latin1
    builder.textBody = "This is the text body."
    builder.htmlBody = "This is the html body."

    let body = try builder.toMessageBody()
    let alternative = body as? MultipartAlternative
    #expect(alternative != nil)
    #expect(alternative?.count == 2)

    let textBody = alternative?[0] as? TextPart
    let htmlBody = alternative?[1] as? TextPart

    #expect(textBody != nil)
    #expect(htmlBody != nil)
    #expect(textBody?.contentType.mimeType == "text/plain")
    #expect(textBody?.contentType.charset == "iso-8859-1")
    #expect(textBody?.text == builder.textBody)

    #expect(htmlBody?.contentType.mimeType == "text/html")
    #expect(htmlBody?.contentType.charset == "iso-8859-1")
    #expect(htmlBody?.text == builder.htmlBody)
}
