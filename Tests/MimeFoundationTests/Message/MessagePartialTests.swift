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
