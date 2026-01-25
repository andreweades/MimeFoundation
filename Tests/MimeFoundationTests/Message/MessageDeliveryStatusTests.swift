//
// MessageDeliveryStatusTests.swift
//

import Foundation
import Testing
@testable import MimeFoundation

private func loadMessage(relativePath: String) throws -> MimeMessage {
    let data = try TestHelper.loadData(relativePath: relativePath)
    let stream = MemoryStream(data, writable: false)
    return try MimeMessage.load(stream)
}

// Test removed: accept no longer takes optional visitor

@Test("MessageDeliveryStatus status groups")
func messageDeliveryStatusStatusGroups() throws {
    let message = try loadMessage(relativePath: "messages/delivery-status.txt")
    guard let report = message.body as? MultipartReport else {
        Issue.record("Expected multipart/report")
        return
    }
    guard let delivery = report[0] as? MessageDeliveryStatus else {
        Issue.record("Expected message/delivery-status")
        return
    }

    let groups = delivery.statusGroups
    #expect(groups.count == 2)
    #expect(groups[0]["Reporting-MTA"] == "dns; mm1")
    #expect(groups[0]["Arrival-Date"] == "Mon, 29 Jul 1996 02:12:50 -0700")
    #expect(groups[1]["Final-Recipient"] == "RFC822; newsletter-request@imusic.com")
    #expect(groups[1]["Action"] == "failed")
    #expect(groups[1]["Diagnostic-Code"] == "X-LOCAL; 500 (err.nosuchuser)")
}

@Test("MessageDeliveryStatus status groups with content")
func messageDeliveryStatusStatusGroupsWithContent() throws {
    let message = try loadMessage(relativePath: "messages/bounce.txt")
    guard let report = message.body as? MultipartReport else {
        Issue.record("Expected multipart/report")
        return
    }
    guard let delivery = report[1] as? MessageDeliveryStatus else {
        Issue.record("Expected message/delivery-status")
        return
    }

    #expect(delivery.contentDescription == "Delivery report")
    #expect(delivery.headers[.contentLength] == "934")

    let groups = delivery.statusGroups
    #expect(groups.count == 2)
    #expect(groups[0]["Reporting-MTA"] == "dns; hmail.jitbit.com")
    #expect(groups[0]["X-Postfix-Queue-ID"] == "630A242E63")
    #expect(groups[0]["X-Postfix-Sender"] == "rfc822; helpdesk@netecgc.com")
    #expect(groups[0]["Arrival-Date"] == "Wed, 26 Jan 2022 04:06:46 -0500 (EST)")
    #expect(groups[0]["Content-Transfer-Encoding"] == "base64")
    #expect(groups[0]["Content-Length"] == "712")

    #expect(groups[1]["Final-Recipient"] == "rfc822; netec.test@netecgc.com")
    #expect(groups[1]["Original-Recipient"] == "rfc822;netec.test@netecgc.com")
    #expect(groups[1]["Action"] == "failed")
    #expect(groups[1]["Status"] == "5.1.1")
    #expect(groups[1]["Remote-MTA"] == "dns; https://urldefense.proofpoint.com/v2/url?u=http-3A__mx1-2Deu1.ppe-2Dhosted.com&d=DwICAQ&c=euGZstcaTDllvimEN8b7jXrwqOf-v5A_CdpgnVfiiMM&r=xGEu8UUVNHyj_BIRW7SVPK81Hnp-FSanq3-_T1am-Kg&m=RMniPmjTykiwdgbzUU7Cewy0BeD_osytuQLS6cflj30&s=0Q-rn8HZSqF10OISjAJdmdg7HT9iADG2jsaaaxtt7tE&e=")
    #expect(groups[1]["Diagnostic-Code"] == "smtp; 550 5.1.1 <netec.test@netecgc.com>: Recipient address    rejected: User unknown")
}

@Test("MessageDeliveryStatus serialized content")
func messageDeliveryStatusSerializedContent() throws {
    let expected = """
Reporting-MTA: dns; mm1
Arrival-Date: Mon, 29 Jul 1996 02:12:50 -0700

Final-Recipient: RFC822; newsletter-request@imusic.com
Action: failed
Diagnostic-Code: X-LOCAL; 500 (err.nosuchuser)

"""

    let mds = MessageDeliveryStatus()
    let status = HeaderList()
    status.add(Header(field: "Reporting-MTA", value: "dns; mm1"))
    status.add(Header(field: "Arrival-Date", value: "Mon, 29 Jul 1996 02:12:50 -0700"))

    let recipient = HeaderList()
    recipient.add(Header(field: "Final-Recipient", value: "RFC822; newsletter-request@imusic.com"))
    recipient.add(Header(field: "Action", value: "failed"))
    recipient.add(Header(field: "Diagnostic-Code", value: "X-LOCAL; 500 (err.nosuchuser)"))

    mds.statusGroups.add(status)
    mds.statusGroups.add(recipient)

    let memory = MemoryStream()
    try mds.content?.decodeTo(memory)
    let text = String(bytes: memory.toByteArray(), encoding: .ascii)?.replacingOccurrences(of: "\r\n", with: "\n")
    #expect(text == expected)
}
