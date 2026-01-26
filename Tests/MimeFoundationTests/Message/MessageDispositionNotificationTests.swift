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
// MessageDispositionNotificationTests.swift
//

import Foundation
import Testing
@testable import MimeFoundation

// Test removed: accept no longer takes optional visitor

@Test("MessageDispositionNotification parse")
func messageDispositionNotificationParse() throws {
    let data = try TestHelper.loadData(relativePath: "messages/disposition-notification.txt")
    let message = try MimeMessage.load(MemoryStream(data, writable: false))

    guard let report = message.body as? MultipartReport else {
        Issue.record("Expected multipart/report")
        return
    }

    #expect(report.reportType == "disposition-notification")
    guard let mdn = report[1] as? MessageDispositionNotification else {
        Issue.record("Expected message/disposition-notification")
        return
    }

    let fields = mdn.fields
    #expect(fields.count == 5)
    #expect(fields["Reporting-UA"] == "joes-pc.cs.example.com; Foomail 97.1")
    #expect(fields["Original-Recipient"] == "rfc822;Joe_Recipient@example.com")
    #expect(fields["Final-Recipient"] == "rfc822;Joe_Recipient@example.com")
    #expect(fields["Original-Message-Id"] == "<199509192301.23456@example.org>")
    #expect(fields["Disposition"] == "manual-action/MDN-sent-manually; displayed")
}

@Test("MessageDispositionNotification serialized content")
func messageDispositionNotificationSerializedContent() throws {
    let expected = """
Reporting-UA: joes-pc.cs.example.com; Foomail 97.1
Original-Recipient: rfc822;Joe_Recipient@example.com
Final-Recipient: rfc822;Joe_Recipient@example.com
Original-Message-ID: <199509192301.23456@example.org>
Disposition: manual-action/MDN-sent-manually; displayed

"""

    let mdn = MessageDispositionNotification()
    mdn.fields.add(Header(field: "Reporting-UA", value: "joes-pc.cs.example.com; Foomail 97.1"))
    mdn.fields.add(Header(field: "Original-Recipient", value: "rfc822;Joe_Recipient@example.com"))
    mdn.fields.add(Header(field: "Final-Recipient", value: "rfc822;Joe_Recipient@example.com"))
    mdn.fields.add(Header(field: "Original-Message-ID", value: "<199509192301.23456@example.org>"))
    mdn.fields.add(Header(field: "Disposition", value: "manual-action/MDN-sent-manually; displayed"))

    let memory = MemoryStream()
    try mdn.content?.decodeTo(memory)
    let text = String(bytes: memory.toByteArray(), encoding: .ascii)?.replacingOccurrences(of: "\r\n", with: "\n")
    #expect(text == expected)
}
