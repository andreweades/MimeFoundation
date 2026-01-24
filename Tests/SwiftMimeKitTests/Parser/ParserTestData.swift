//
// ParserTestData.swift
//

import Foundation
@testable import SwiftMimeKit

func createIssue991Mbox() -> (stream: MemoryStream, expectedOffsets: [Int]) {
    let template = """
From: mimekit@example.org
To: mimekit@example.org
Subject: %@
Message-Id: <1234567890.%d@example.org>
MIME-Version: 1.0
Content-Type: text/plain; charset=utf-8

"""
    let alphabet = Array("ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789".utf8)
    let lineLength = 255
    let mboxMarker = Array("From -\n".utf8)
    var bytes: [UInt8] = []
    var expectedOffsets = [Int](repeating: 0, count: 2)

    func append(_ buffer: [UInt8]) {
        bytes.append(contentsOf: buffer)
    }

    func appendByte(_ byte: UInt8) {
        bytes.append(byte)
    }

    append(mboxMarker)

    let headers0 = String(format: template, "This message contains long lines that will cause ScanContent() to require a buffer refill", 0)
    append(Array(headers0.utf8))

    var index = 0
    while bytes.count <= 4096 {
        let c = alphabet[index % alphabet.count]
        var i = 0
        while i < lineLength && bytes.count < 4096 {
            appendByte(c)
            i += 1
        }
        if bytes.count < 4096 {
            appendByte(0x0A)
        } else {
            append(mboxMarker)
        }
        index += 1
    }

    appendByte(0x0A)
    expectedOffsets[0] = max(0, bytes.count - 1)

    append(mboxMarker)
    let headers1 = String(format: template, "This message contains long lines that will cause ScanContent() to require a buffer refill", 1)
    append(Array(headers1.utf8))

    while bytes.count <= expectedOffsets[0] + 4096 {
        let c = alphabet[index % alphabet.count]
        for _ in 0..<lineLength {
            appendByte(c)
        }
        appendByte(0x0A)
        index += 1
    }

    appendByte(0x0A)
    expectedOffsets[1] = bytes.count

    return (MemoryStream(bytes, writable: false), expectedOffsets)
}

func createMboxWithLinesExceedingMaxSmtpLineLength() -> (stream: MemoryStream, expectedOffsets: [Int]) {
    let template = """
From: mimekit@example.org
To: mimekit@example.org
Subject: %@
Message-Id: <1234567890.%d@example.org>
MIME-Version: 1.0
Content-Type: text/plain; charset=utf-8

"""
    let alphabet = Array("ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789".utf8)
    let lineLength = 255
    let mboxMarker = Array("From -\n".utf8)
    var bytes: [UInt8] = []
    var expectedOffsets = [Int](repeating: 0, count: 2)

    func append(_ buffer: [UInt8]) {
        bytes.append(contentsOf: buffer)
    }

    func appendByte(_ byte: UInt8) {
        bytes.append(byte)
    }

    append(mboxMarker)

    let headers0 = String(format: template, "This message contains long lines that will cause ScanContent() to require a buffer refill", 0)
    append(Array(headers0.utf8))

    var index = 0
    while bytes.count <= 4096 - 1001 {
        let c = alphabet[index % alphabet.count]
        var i = 0
        while i < lineLength && bytes.count < 4096 - 1001 {
            appendByte(c)
            i += 1
        }
        appendByte(0x0A)
        index += 1
    }

    var c = alphabet[index % alphabet.count]
    while bytes.count < 4096 {
        appendByte(c)
    }
    append(mboxMarker)
    index += 1

    c = alphabet[index % alphabet.count]
    for _ in 0..<lineLength {
        appendByte(c)
    }
    append(mboxMarker)
    index += 1

    appendByte(0x0A)
    expectedOffsets[0] = max(0, bytes.count - 1)

    append(mboxMarker)
    let headers1 = String(format: template, "This message contains long lines that will cause ScanContent() to require a buffer refill", 1)
    append(Array(headers1.utf8))

    while bytes.count <= expectedOffsets[0] + 4096 {
        c = alphabet[index % alphabet.count]
        for _ in 0..<lineLength {
            appendByte(c)
        }
        appendByte(0x0A)
        index += 1
    }

    appendByte(0x0A)
    expectedOffsets[1] = bytes.count

    return (MemoryStream(bytes, writable: false), expectedOffsets)
}
