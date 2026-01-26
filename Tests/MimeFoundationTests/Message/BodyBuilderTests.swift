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
// BodyBuilderTests.swift
//

import Testing
import MimeFoundation

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
