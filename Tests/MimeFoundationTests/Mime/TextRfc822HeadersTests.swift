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
// TextRfc822HeadersTests.swift
//

import Testing
import MimeFoundation

@Test("TextRfc822Headers argument exceptions")
func textRfc822HeadersArgumentExceptions() {
    // Tests with nil have been removed since accept no longer takes optional visitor

    #expect(throws: (any Error).self) {
        _ = try TextRfc822Headers(args: ["unknown-parameter"])
    }

    #expect(throws: (any Error).self) {
        _ = try TextRfc822Headers(MimeMessage(), MimeMessage())
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
