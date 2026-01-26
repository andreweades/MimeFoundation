//
// Author: Jeffrey Stedfast <jestedfa@microsoft.com>
//
// Copyright (c) 2013-2026 .NET Foundation and Contributors
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.
//

//
// ParserOptionsTests.swift
//

import Foundation
import Testing
@testable import MimeFoundation

private final class CustomTextHtmlPart: TextPart {
    override init(_ contentType: ContentType) {
        super.init(contentType)
    }
}

@Test("ParserOptions register MIME type validation")
func parserOptionsRegisterMimeTypeValidation() {
    var options = ParserOptions.default
    #expect(throws: ParserOptions.Error.emptyMimeType) {
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

    options = options.copy()

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

    options = options.copy()

    let text = TextPart("html")
    text.text = "<html>this is some html and stuff</html>"

    let stream = MemoryStream()
    try text.writeTo(stream)
    _ = try? stream.seek(0, origin: .begin)

    let html = try await MimeEntity.loadAsync(options, stream)
    #expect(html is CustomTextHtmlPart)
}
