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
// MessageFeedbackReportTests.swift
//

import Foundation
import Testing
@testable import MimeFoundation

// Test removed: accept no longer takes optional visitor

@Test("MessageFeedbackReport parse")
func messageFeedbackReportParse() throws {
    let data = try TestHelper.loadData(relativePath: "messages/feedback-report.txt")
    let message = try MimeMessage.load(MemoryStream(data, writable: false))

    guard let report = message.body as? MultipartReport else {
        Issue.record("Expected multipart/report")
        return
    }

    #expect(report.reportType == "feedback-report")
    guard let mfr = report[1] as? MessageFeedbackReport else {
        Issue.record("Expected message/feedback-report")
        return
    }

    let fields = mfr.fields
    #expect(fields.count == 12)
    #expect(fields["Feedback-Type"] == "abuse")
    #expect(fields["User-Agent"] == "SomeGenerator/1.0")
    #expect(fields["Version"] == "1")
    #expect(fields["Original-Mail-From"] == "<somespammer@example.net>")
    #expect(fields["Original-Rcpt-To"] == "<user@example.com>")
    #expect(fields["Received-Date"] == "Thu, 8 Mar 2005 14:00:00 EDT")
    #expect(fields["Source-IP"] == "192.0.2.2")
    #expect(fields["Authentication-Results"] == "mail.example.com;               spf=fail smtp.mail=somespammer@example.com")
    #expect(fields["Reported-Domain"] == "example.net")
    #expect(fields["Reported-Uri"] == "http://example.net/earn_money.html")
    #expect(fields["Removal-Recipient"] == "user@example.com")
}

@Test("MessageFeedbackReport serialized content")
func messageFeedbackReportSerializedContent() throws {
    let expected = """
Feedback-Type: abuse
User-Agent: SomeGenerator/1.0
Version: 1

"""

    let mfr = MessageFeedbackReport()
    mfr.fields.add(Header(field: "Feedback-Type", value: "abuse"))
    mfr.fields.add(Header(field: "User-Agent", value: "SomeGenerator/1.0"))
    mfr.fields.add(Header(field: "Version", value: "1"))

    let memory = MemoryStream()
    try mfr.content?.decodeTo(memory)
    let text = String(bytes: memory.toByteArray(), encoding: .ascii)?.replacingOccurrences(of: "\r\n", with: "\n")
    #expect(text == expected)
}
