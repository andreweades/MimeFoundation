//
// ParserOptionsTests.swift
//

import Foundation
import Testing
@testable import SwiftMimeKit

private final class CustomTextHtmlPart: TextPart {
    override init(_ contentType: ContentType) {
        super.init(contentType)
    }
}

@Test("ParserOptions register MIME type validation")
func parserOptionsRegisterMimeTypeValidation() {
    var options = ParserOptions.default
    #expect(throws: ParserOptions.Error.nilMimeType) {
        try options.registerMimeType(nil) { _ in TextPart("plain") }
    }
    #expect(throws: ParserOptions.Error.invalidMimeType) {
        try options.registerMimeType("") { _ in TextPart("plain") }
    }
    #expect(throws: ParserOptions.Error.invalidMimeType) {
        try options.registerMimeType("not-a-mime") { _ in TextPart("plain") }
    }
}

@Test("ParserOptions parsing application/rtf")
func parserOptionsParsingApplicationRtf() throws {
    let raw = "Content-type: application/rtf\n\nThis is make-believe rtf data..."
    let stream = MemoryStream(Array(raw.utf8), writable: false)
    let part = try MimeEntity.load(stream)
    #expect(part is TextPart)
    if let text = part as? TextPart {
        #expect(text.isRichText)
    }
}

@Test("ParserOptions parsing message/global-headers")
func parserOptionsParsingMessageGlobalHeaders() throws {
    let raw = "Content-type: message/global-headers\n\nDate: Fri, 22 Jan 2016 8:44:05 -0500 (EST)\nFrom: MimeKit Unit Tests <unit.tests@mimekit.org>\nTo: MimeKit Unit Tests <unit.tests@mimekit.org>\nMIME-Version: 1.0\nContent-type: text/plain\n"
    let stream = MemoryStream(Array(raw.utf8), writable: false)
    let part = try MimeEntity.load(stream)
    #expect(part is TextRfc822Headers)
}

@Test("ParserOptions parsing custom MIME type")
func parserOptionsParsingCustomMimeType() throws {
    var options = ParserOptions.default
    try options.registerMimeType("text/html") { contentType in
        CustomTextHtmlPart(contentType)
    }

    options = options.clone()

    let text = TextPart("html")
    text.text = "<html>this is some html and stuff</html>"

    let stream = MemoryStream()
    try text.writeTo(stream)
    _ = try? stream.seek(0, origin: .begin)

    let html = try MimeEntity.load(options, stream)
    #expect(html is CustomTextHtmlPart)
}

@Test("ParserOptions parsing custom MIME type async")
func parserOptionsParsingCustomMimeTypeAsync() async throws {
    var options = ParserOptions.default
    try options.registerMimeType("text/html") { contentType in
        CustomTextHtmlPart(contentType)
    }

    options = options.clone()

    let text = TextPart("html")
    text.text = "<html>this is some html and stuff</html>"

    let stream = MemoryStream()
    try text.writeTo(stream)
    _ = try? stream.seek(0, origin: .begin)

    let html = try await MimeEntity.loadAsync(options, stream)
    #expect(html is CustomTextHtmlPart)
}
