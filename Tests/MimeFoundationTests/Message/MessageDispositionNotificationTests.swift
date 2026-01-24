//
// MessageDispositionNotificationTests.swift
//

import Foundation
import Testing
@testable import MimeFoundation

@Test("MessageDispositionNotification argument exceptions")
func messageDispositionNotificationArgumentExceptions() {
    let mdn = MessageDispositionNotification()
    #expect(throws: MimeEntityError.nilVisitor) {
        try mdn.accept(nil)
    }
}

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
