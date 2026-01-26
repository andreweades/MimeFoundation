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
// MimeReaderTests.swift
//
import os
import Foundation
import Testing
@testable import MimeFoundation

private final class MimeOffsets: Codable {
    var mimeType: String?
    var mboxMarkerOffset: Int?
    var lineNumber: Int
    var beginOffset: Int
    var headersEndOffset: Int
    var endOffset: Int
    var message: MimeOffsets?
    var body: MimeOffsets?
    var children: [MimeOffsets]?
    var octets: Int
    var lines: Int?

    init(
        mimeType: String? = nil,
        mboxMarkerOffset: Int? = nil,
        lineNumber: Int = 0,
        beginOffset: Int = 0,
        headersEndOffset: Int = 0,
        endOffset: Int = 0,
        message: MimeOffsets? = nil,
        body: MimeOffsets? = nil,
        children: [MimeOffsets]? = nil,
        octets: Int = 0,
        lines: Int? = nil
    ) {
        self.mimeType = mimeType
        self.mboxMarkerOffset = mboxMarkerOffset
        self.lineNumber = lineNumber
        self.beginOffset = beginOffset
        self.headersEndOffset = headersEndOffset
        self.endOffset = endOffset
        self.message = message
        self.body = body
        self.children = children
        self.octets = octets
        self.lines = lines
    }

    enum CodingKeys: String, CodingKey {
        case mimeType
        case mboxMarkerOffset
        case lineNumber
        case beginOffset
        case headersEndOffset
        case endOffset
        case message
        case body
        case children
        case octets
        case lines
    }
}

private enum ReaderMimeType {
    case message
    case messagePart
    case multipart
    case mimePart
}

private struct MimeItem {
    let type: ReaderMimeType
    let offsets: MimeOffsets
}

private func assertMimeOffsets(_ expected: MimeOffsets, _ actual: MimeOffsets, messageIndex: Int, partSpecifier: String) {
    #expect(actual.mimeType == expected.mimeType, "mime-type differs for message #\(messageIndex)\(partSpecifier)")
    #expect(actual.mboxMarkerOffset == expected.mboxMarkerOffset, "mbox marker begin offset differs for message #\(messageIndex)\(partSpecifier)")
    #expect(actual.beginOffset == expected.beginOffset, "begin offset differs for message #\(messageIndex)\(partSpecifier)")
    #expect(actual.lineNumber == expected.lineNumber, "begin line differs for message #\(messageIndex)\(partSpecifier)")
    #expect(actual.headersEndOffset == expected.headersEndOffset, "headers end offset differs for message #\(messageIndex)\(partSpecifier)")
    #expect(actual.endOffset == expected.endOffset, "end offset differs for message #\(messageIndex)\(partSpecifier)")
    #expect(actual.octets == expected.octets, "octets differs for message #\(messageIndex)\(partSpecifier)")
    #expect(actual.lines == expected.lines, "lines differs for message #\(messageIndex)\(partSpecifier)")

    if let expectedMessage = expected.message {
        #expect(actual.message != nil, "message content is null for message #\(messageIndex)\(partSpecifier)")
        if let actualMessage = actual.message {
            assertMimeOffsets(expectedMessage, actualMessage, messageIndex: messageIndex, partSpecifier: "\(partSpecifier)/message")
        }
    } else if let expectedBody = expected.body {
        #expect(actual.body != nil, "body content is null for message #\(messageIndex)\(partSpecifier)")
        if let actualBody = actual.body {
            assertMimeOffsets(expectedBody, actualBody, messageIndex: messageIndex, partSpecifier: "\(partSpecifier)/0")
        }
    } else if let expectedChildren = expected.children {
        let actualChildren = actual.children ?? []
        #expect(actualChildren.count == expectedChildren.count, "children count differs for message #\(messageIndex)\(partSpecifier)")
        for index in 0..<min(actualChildren.count, expectedChildren.count) {
            assertMimeOffsets(expectedChildren[index], actualChildren[index], messageIndex: messageIndex, partSpecifier: "\(partSpecifier).\(index)")
        }
    }
}

private final class CustomMimeReader: MimeReader {
    var offsets: [MimeOffsets] = []
    private var stack: [MimeItem] = []
    private var mboxMarkerBeginOffset: Int = -1

    override func onMboxMarkerRead(_ marker: [UInt8], startIndex: Int, count: Int, beginOffset: Int, lineNumber: Int) {
        mboxMarkerBeginOffset = beginOffset
        super.onMboxMarkerRead(marker, startIndex: startIndex, count: count, beginOffset: beginOffset, lineNumber: lineNumber)
    }

    override func onMimeMessageBegin(_ beginOffset: Int, _ beginLineNumber: Int) {
        let record = MimeOffsets(
            mimeType: nil,
            mboxMarkerOffset: nil,
            lineNumber: beginLineNumber,
            beginOffset: beginOffset,
            headersEndOffset: 0,
            endOffset: 0,
            message: nil,
            body: nil,
            children: nil,
            octets: 0,
            lines: nil
        )

        if let parent = stack.last {
            if parent.type == .messagePart {
                let updatedParent = parent
                updatedParent.offsets.message = record
                stack[stack.count - 1] = updatedParent
            }
        } else {
            record.mboxMarkerOffset = mboxMarkerBeginOffset >= 0 ? mboxMarkerBeginOffset : nil
            offsets.append(record)
        }

        stack.append(MimeItem(type: .message, offsets: record))
        super.onMimeMessageBegin(beginOffset, beginLineNumber)
    }

    override func onMimeMessageEnd(_ beginOffset: Int, _ beginLineNumber: Int, _ headersEndOffset: Int, _ endOffset: Int, _ lines: Int) {
        guard let current = stack.popLast(), current.type == .message else {
            super.onMimeMessageEnd(beginOffset, beginLineNumber, headersEndOffset, endOffset, lines)
            return
        }

        let updated = current.offsets
        updated.headersEndOffset = headersEndOffset
        updated.endOffset = endOffset
        updated.octets = endOffset - headersEndOffset
        updated.lines = nil

        if let parent = stack.last {
            if parent.type == .messagePart {
                let updatedParent = parent
                updatedParent.offsets.message = updated
                stack[stack.count - 1] = updatedParent
            }
        } else if let index = offsets.firstIndex(where: { $0.beginOffset == beginOffset && $0.lineNumber == beginLineNumber }) {
            offsets[index] = updated
        }

        super.onMimeMessageEnd(beginOffset, beginLineNumber, headersEndOffset, endOffset, lines)
    }

    override func onMessagePartBegin(_ contentType: ContentType, _ beginOffset: Int, _ beginLineNumber: Int) {
        push(type: .messagePart, contentType: contentType, beginOffset: beginOffset, beginLineNumber: beginLineNumber)
        super.onMessagePartBegin(contentType, beginOffset, beginLineNumber)
    }

    override func onMessagePartEnd(_ contentType: ContentType, _ beginOffset: Int, _ beginLineNumber: Int, _ headersEndOffset: Int, _ endOffset: Int, _ lines: Int) {
        pop(type: .messagePart, contentType: contentType, beginOffset: beginOffset, beginLineNumber: beginLineNumber, headersEndOffset: headersEndOffset, endOffset: endOffset, lines: lines)
        super.onMessagePartEnd(contentType, beginOffset, beginLineNumber, headersEndOffset, endOffset, lines)
    }

    override func onMimePartBegin(_ contentType: ContentType, _ beginOffset: Int, _ beginLineNumber: Int) {
        push(type: .mimePart, contentType: contentType, beginOffset: beginOffset, beginLineNumber: beginLineNumber)
        super.onMimePartBegin(contentType, beginOffset, beginLineNumber)
    }

    override func onMimePartEnd(_ contentType: ContentType, _ beginOffset: Int, _ beginLineNumber: Int, _ headersEndOffset: Int, _ endOffset: Int, _ lines: Int) {
        pop(type: .mimePart, contentType: contentType, beginOffset: beginOffset, beginLineNumber: beginLineNumber, headersEndOffset: headersEndOffset, endOffset: endOffset, lines: lines)
        super.onMimePartEnd(contentType, beginOffset, beginLineNumber, headersEndOffset, endOffset, lines)
    }

    override func onMultipartBegin(_ contentType: ContentType, _ beginOffset: Int, _ beginLineNumber: Int) {
        push(type: .multipart, contentType: contentType, beginOffset: beginOffset, beginLineNumber: beginLineNumber)
        super.onMultipartBegin(contentType, beginOffset, beginLineNumber)
    }

    override func onMultipartEnd(_ contentType: ContentType, _ beginOffset: Int, _ beginLineNumber: Int, _ headersEndOffset: Int, _ endOffset: Int, _ lines: Int) {
        pop(type: .multipart, contentType: contentType, beginOffset: beginOffset, beginLineNumber: beginLineNumber, headersEndOffset: headersEndOffset, endOffset: endOffset, lines: lines)
        super.onMultipartEnd(contentType, beginOffset, beginLineNumber, headersEndOffset, endOffset, lines)
    }

    private func push(type: ReaderMimeType, contentType: ContentType, beginOffset: Int, beginLineNumber: Int) {
        let record = MimeOffsets(
            mimeType: contentType.mimeType,
            mboxMarkerOffset: nil,
            lineNumber: beginLineNumber,
            beginOffset: beginOffset,
            headersEndOffset: 0,
            endOffset: 0,
            message: nil,
            body: nil,
            children: nil,
            octets: 0,
            lines: nil
        )

        if let parent = stack.last {
            switch parent.type {
            case .message:
                let updatedParent = parent
                updatedParent.offsets.body = record
                stack[stack.count - 1] = updatedParent
            case .multipart:
                let updatedParent = parent
                var children = updatedParent.offsets.children ?? []
                children.append(record)
                updatedParent.offsets.children = children
                stack[stack.count - 1] = updatedParent
            default:
                break
            }
        } else {
            offsets.append(record)
        }

        stack.append(MimeItem(type: type, offsets: record))
    }

    private func pop(type: ReaderMimeType, contentType: ContentType, beginOffset: Int, beginLineNumber: Int, headersEndOffset: Int, endOffset: Int, lines: Int) {
        guard let current = stack.popLast(), current.type == type else {
            return
        }

        let updated = current.offsets
        updated.headersEndOffset = headersEndOffset
        updated.endOffset = endOffset
        updated.octets = endOffset - headersEndOffset
        updated.lines = lines

        if let parentIndex = stack.indices.last {
            let parent = stack[parentIndex]
            switch parent.type {
            case .message:
                parent.offsets.body = updated
                stack[parentIndex] = parent
            case .multipart:
                var children = parent.offsets.children ?? []
                if let lastIndex = children.indices.last {
                    children[lastIndex] = updated
                }
                parent.offsets.children = children
                stack[parentIndex] = parent
            default:
                break
            }
        } else if let index = offsets.firstIndex(where: { $0.beginOffset == beginOffset && $0.lineNumber == beginLineNumber }) {
            offsets[index] = updated
        }
    }
}

private func detectNewLineFormat(url: URL) -> NewLineFormat {
    if let data = try? Data(contentsOf: url) {
        for index in 0..<min(1024, data.count) {
            if data[index] == 0x0A {
                if index > 0 && data[index - 1] == 0x0D {
                    return .dos
                }
                return .unix
            }
        }
    }
    return .dos
}

private func assertMboxResults(baseName: String, offsets: [MimeOffsets], newLineFormat: NewLineFormat) throws {
    let jsonName = "\(baseName).\(newLineFormat == .unix ? "unix" : "dos")-offsets.json"
    let url = TestHelper.dataURL(for: "mbox/\(jsonName)")
    let data = try Data(contentsOf: url)
    let expectedOffsets = try JSONDecoder().decode([MimeOffsets].self, from: data)
    #expect(offsets.count == expectedOffsets.count, "message count")
    for index in 0..<min(offsets.count, expectedOffsets.count) {
        assertMimeOffsets(expectedOffsets[index], offsets[index], messageIndex: index, partSpecifier: "")
    }
}

private func testMbox(options: ParserOptions?, baseName: String) throws {
    let url = TestHelper.dataURL(for: "mbox/\(baseName).mbox.txt")
    let data = try Data(contentsOf: url)
    let stream = MemoryStream(Array(data), writable: false)
    let reader = try (options != nil ? CustomMimeReader(options!, stream, .mbox) : CustomMimeReader(stream, .mbox))
    while !reader.isEndOfStream {
        try reader.readMessage()
    }
    let newLineFormat = detectNewLineFormat(url: url)
    try assertMboxResults(baseName: baseName, offsets: reader.offsets, newLineFormat: newLineFormat)
}

private func testMboxAsync(options: ParserOptions?, baseName: String) async throws {
    let url = TestHelper.dataURL(for: "mbox/\(baseName).mbox.txt")
    let data = try Data(contentsOf: url)
    let stream = MemoryStream(Array(data), writable: false)
    let reader = try (options != nil ? CustomMimeReader(options!, stream, .mbox) : CustomMimeReader(stream, .mbox))
    while !reader.isEndOfStream {
        try await reader.readMessageAsync()
    }
    let newLineFormat = detectNewLineFormat(url: url)
    try assertMboxResults(baseName: baseName, offsets: reader.offsets, newLineFormat: newLineFormat)
}

@Test("MimeReader content-length mbox")
func mimeReaderContentLengthMbox() throws {
    var options = ParserOptions.default
    options.respectContentLength = true
    try testMbox(options: options, baseName: "content-length")
}

@Test("MimeReader Performance content-length mbox")
func perfMimeReaderContentLengthMbox() throws {
    let signposter = OSSignposter(subsystem: "MimeFoundationTest", category: .pointsOfInterest)

    let duration = Duration(secondsComponent: 10, attosecondsComponent: 0)
    var options = ParserOptions.default
    options.respectContentLength = true

    var now = ContinuousClock.now
    var outerIterations = 0
    let start = ContinuousClock.now

    let interval = signposter.beginInterval("perfMimeReaderContentLengthMbox")
    repeat {
        try testMbox(options: options, baseName: "content-length")
        outerIterations += 1
        now = .now
    } while (start.duration(to: now) < duration)
    let elapsed = start.duration(to: now)
    let attoseconds = Double(elapsed.components.attoseconds)
    let seconds = Double(elapsed.components.seconds)
    let throughput = Double(outerIterations) / (seconds + attoseconds / 1e18)
    signposter.endInterval("perfMimeReaderContentLengthMbox", interval, "\(throughput) throughput calls/s")

}

@Test("MimeReader content-length mbox async")
func mimeReaderContentLengthMboxAsync() async throws {
    var options = ParserOptions.default
    options.respectContentLength = true
    try await testMboxAsync(options: options, baseName: "content-length")
}

@Test("MimeReader issue1189 mbox")
func mimeReaderIssue1189Mbox() throws {
    try testMbox(options: nil, baseName: "issue1189")
}

@Test("MimeReader issue1189 mbox async")
func mimeReaderIssue1189MboxAsync() async throws {
    try await testMboxAsync(options: nil, baseName: "issue1189")
}

@Test("MimeReader jwz mbox")
func mimeReaderJwzMbox() throws {
    try testMbox(options: nil, baseName: "jwz")
}

@Test("MimeReader jwz mbox async")
func mimeReaderJwzMboxAsync() async throws {
    try await testMboxAsync(options: nil, baseName: "jwz")
}

@Test("MimeReader line count single line")
func mimeReaderLineCountSingleLine() throws {
    let text = """
From: mimekit@example.org
To: mimekit@example.org
Subject: This is a message with a single line of text
Message-Id: <123@example.org>
MIME-Version: 1.0
Content-Type: text/plain; charset=us-ascii

This is a single line of text
"""
    let stream = MemoryStream(Array(text.utf8), writable: false)
    let reader = try CustomMimeReader(stream, .entity)
    try reader.readMessage()
    let lines = reader.offsets.first?.body?.lines
    #expect(lines == 1)
}

@Test("MimeReader line count single line async")
func mimeReaderLineCountSingleLineAsync() async throws {
    let text = """
From: mimekit@example.org
To: mimekit@example.org
Subject: This is a message with a single line of text
Message-Id: <123@example.org>
MIME-Version: 1.0
Content-Type: text/plain; charset=us-ascii

This is a single line of text
"""
    let stream = MemoryStream(Array(text.utf8), writable: false)
    let reader = try CustomMimeReader(stream, .entity)
    try await reader.readMessageAsync()
    let lines = reader.offsets.first?.body?.lines
    #expect(lines == 1)
}

@Test("MimeReader line count single line CRLF")
func mimeReaderLineCountSingleLineCRLF() throws {
    let text = """
From: mimekit@example.org
To: mimekit@example.org
Subject: This is a message with a single line of text
Message-Id: <123@example.org>
MIME-Version: 1.0
Content-Type: text/plain; charset=us-ascii

This is a single line of text

"""
    let stream = MemoryStream(Array(text.utf8), writable: false)
    let reader = try CustomMimeReader(stream, .entity)
    try reader.readMessage()
    let lines = reader.offsets.first?.body?.lines
    #expect(lines == 1)
}

@Test("MimeReader line count single line CRLF async")
func mimeReaderLineCountSingleLineCRLFAsync() async throws {
    let text = """
From: mimekit@example.org
To: mimekit@example.org
Subject: This is a message with a single line of text
Message-Id: <123@example.org>
MIME-Version: 1.0
Content-Type: text/plain; charset=us-ascii

This is a single line of text

"""
    let stream = MemoryStream(Array(text.utf8), writable: false)
    let reader = try CustomMimeReader(stream, .entity)
    try await reader.readMessageAsync()
    let lines = reader.offsets.first?.body?.lines
    #expect(lines == 1)
}

@Test("MimeReader line count single line in multipart")
func mimeReaderLineCountSingleLineInMultipart() throws {
    let text = """
From: mimekit@example.org
To: mimekit@example.org
Subject: This is a message with a single line of text
Message-Id: <123@example.org>
MIME-Version: 1.0
Content-Type: multipart/mixed; boundary="boundary-marker"

--boundary-marker
Content-Type: text/plain; charset=us-ascii

This is a single line of text
--boundary-marker
Content-Type: application/octet-stream; name="attachment.dat"
Content-DIsposition: attachment; filename="attachment.dat"

ABC
--boundary-marker--
"""
    let stream = MemoryStream(Array(text.utf8), writable: false)
    let reader = try CustomMimeReader(stream, .entity)
    try reader.readMessage()
    let lines = reader.offsets.first?.body?.children?.first?.lines
    #expect(lines == 1)
}

@Test("MimeReader line count single line in multipart async")
func mimeReaderLineCountSingleLineInMultipartAsync() async throws {
    let text = """
From: mimekit@example.org
To: mimekit@example.org
Subject: This is a message with a single line of text
Message-Id: <123@example.org>
MIME-Version: 1.0
Content-Type: multipart/mixed; boundary="boundary-marker"

--boundary-marker
Content-Type: text/plain; charset=us-ascii

This is a single line of text
--boundary-marker
Content-Type: application/octet-stream; name="attachment.dat"
Content-DIsposition: attachment; filename="attachment.dat"

ABC
--boundary-marker--
"""
    let stream = MemoryStream(Array(text.utf8), writable: false)
    let reader = try CustomMimeReader(stream, .entity)
    try await reader.readMessageAsync()
    let lines = reader.offsets.first?.body?.children?.first?.lines
    #expect(lines == 1)
}

@Test("MimeReader line count one line then blank line in multipart")
func mimeReaderLineCountOneLineThenBlankInMultipart() throws {
    let text = """
From: mimekit@example.org
To: mimekit@example.org
Subject: This is a message with a single line of text
Message-Id: <123@example.org>
MIME-Version: 1.0
Content-Type: multipart/mixed; boundary="boundary-marker"

--boundary-marker
Content-Type: text/plain; charset=us-ascii

This is a single line of text followed by a blank line

--boundary-marker
Content-Type: application/octet-stream; name="attachment.dat"
Content-DIsposition: attachment; filename="attachment.dat"

ABC
--boundary-marker--
"""
    let stream = MemoryStream(Array(text.utf8), writable: false)
    let reader = try CustomMimeReader(stream, .entity)
    try reader.readMessage()
    let lines = reader.offsets.first?.body?.children?.first?.lines
    #expect(lines == 1)
}

@Test("MimeReader line count one line then blank line in multipart async")
func mimeReaderLineCountOneLineThenBlankInMultipartAsync() async throws {
    let text = """
From: mimekit@example.org
To: mimekit@example.org
Subject: This is a message with a single line of text
Message-Id: <123@example.org>
MIME-Version: 1.0
Content-Type: multipart/mixed; boundary="boundary-marker"

--boundary-marker
Content-Type: text/plain; charset=us-ascii

This is a single line of text followed by a blank line

--boundary-marker
Content-Type: application/octet-stream; name="attachment.dat"
Content-DIsposition: attachment; filename="attachment.dat"

ABC
--boundary-marker--
"""
    let stream = MemoryStream(Array(text.utf8), writable: false)
    let reader = try CustomMimeReader(stream, .entity)
    try await reader.readMessageAsync()
    let lines = reader.offsets.first?.body?.children?.first?.lines
    #expect(lines == 1)
}

@Test("MimeReader line count non-terminated single header")
func mimeReaderLineCountNonTerminatedSingleHeader() throws {
    let text = "From: mimekit@example.org"
    let stream = MemoryStream(Array(text.utf8), writable: false)
    let reader = try CustomMimeReader(stream, .entity)
    try reader.readMessage()
    let lines = reader.offsets.first?.body?.lines
    #expect(lines == 0)
}

@Test("MimeReader line count non-terminated single header async")
func mimeReaderLineCountNonTerminatedSingleHeaderAsync() async throws {
    let text = "From: mimekit@example.org"
    let stream = MemoryStream(Array(text.utf8), writable: false)
    let reader = try CustomMimeReader(stream, .entity)
    try await reader.readMessageAsync()
    let lines = reader.offsets.first?.body?.lines
    #expect(lines == 0)
}

@Test("MimeReader line count terminated single header")
func mimeReaderLineCountTerminatedSingleHeader() throws {
    let text = "From: mimekit@example.org\r\n"
    let stream = MemoryStream(Array(text.utf8), writable: false)
    let reader = try CustomMimeReader(stream, .entity)
    try reader.readMessage()
    let lines = reader.offsets.first?.body?.lines
    #expect(lines == 0)
}

@Test("MimeReader line count terminated single header async")
func mimeReaderLineCountTerminatedSingleHeaderAsync() async throws {
    let text = "From: mimekit@example.org\r\n"
    let stream = MemoryStream(Array(text.utf8), writable: false)
    let reader = try CustomMimeReader(stream, .entity)
    try await reader.readMessageAsync()
    let lines = reader.offsets.first?.body?.lines
    #expect(lines == 0)
}
