//
// MessagePartTests.swift
//

import Testing
import SwiftMimeKit

@Test("MessagePart prepare")
func messagePartPrepare() throws {
    let content = MemoryStream([UInt8](repeating: 0, count: 64), writable: false)
    let part = try MimePart("application", "octet-stream")
    part.content = try MimeContent(content)

    let message = MimeMessage()
    message.body = part

    let rfc822 = MessagePart()
    rfc822.message = message

    let encoding = try part.getBestEncoding(.sevenBit)
    #expect(encoding == .base64)

    try rfc822.prepare(.sevenBit)
    #expect(part.contentTransferEncoding == .base64)

    try rfc822.prepare(.sevenBit)
    #expect(part.contentTransferEncoding == .base64)

    part.contentTransferEncoding = .binary
    try rfc822.prepare(.none)
    #expect(part.contentTransferEncoding == .binary)

    try rfc822.prepare(.sevenBit)
    #expect(part.contentTransferEncoding == .base64)
}
