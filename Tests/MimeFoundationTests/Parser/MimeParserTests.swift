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
// MimeParserTests.swift
//

import Foundation
import Testing
@testable import MimeFoundation

private func assertSerialization(_ message: MimeMessage, _ format: NewLineFormat, _ expected: String) throws {
    var normalized = expected
    if normalized.hasPrefix("From -") {
        if let end = normalized.firstIndex(of: "\n") {
            normalized = String(normalized[normalized.index(after: end)...])
        }
    }

    var options = FormatOptions.default.copy()
    options.newLineFormat = format
    let memory = MemoryStream()
    try message.writeTo(options, memory)
    let actual = String(bytes: memory.toByteArray(), encoding: .ascii) ?? ""
    #expect(normalizeLineEndings(actual) == normalizeLineEndings(normalized))
}

private func assertSerialization(_ entity: MimeEntity, _ format: NewLineFormat, _ expected: String) throws {
    var options = FormatOptions.default.copy()
    options.newLineFormat = format
    let memory = MemoryStream()
    try entity.writeTo(options, memory)
    let actual = String(bytes: memory.toByteArray(), encoding: .ascii) ?? ""
    #expect(normalizeLineEndings(actual) == normalizeLineEndings(expected))
}

private func assertSerializationAsync(_ message: MimeMessage, _ format: NewLineFormat, _ expected: String) async throws {
    var normalized = expected
    if normalized.hasPrefix("From -") {
        if let end = normalized.firstIndex(of: "\n") {
            normalized = String(normalized[normalized.index(after: end)...])
        }
    }

    var options = FormatOptions.default.copy()
    options.newLineFormat = format
    let memory = MemoryStream()
    try message.writeTo(options, memory)
    let actual = String(bytes: memory.toByteArray(), encoding: .ascii) ?? ""
    #expect(normalizeLineEndings(actual) == normalizeLineEndings(normalized))
}

private func assertSerializationAsync(_ entity: MimeEntity, _ format: NewLineFormat, _ expected: String) async throws {
    var options = FormatOptions.default.copy()
    options.newLineFormat = format
    let memory = MemoryStream()
    try await entity.writeToAsync(options, memory)
    let actual = String(bytes: memory.toByteArray(), encoding: .ascii) ?? ""
    #expect(normalizeLineEndings(actual) == normalizeLineEndings(expected))
}

private func removingLastOccurrence(of needle: String, in text: String) -> String {
    guard let range = text.range(of: needle, options: .backwards) else {
        return text
    }
    var result = text
    result.removeSubrange(range)
    return result
}

private func replacingLastOccurrence(of needle: String, with replacement: String, in text: String) -> String {
    guard let range = text.range(of: needle, options: .backwards) else {
        return text
    }
    var result = text
    result.replaceSubrange(range, with: replacement)
    return result
}

private func normalizeLineEndings(_ text: String) -> String {
    text
        .replacingOccurrences(of: "\r\n", with: "\n")
        .replacingOccurrences(of: "\r", with: "\n")
}

private func ensureTrailingNewline(_ text: String, newline: String) -> String {
    var trimmed = text
    while trimmed.hasSuffix(newline) {
        trimmed.removeLast(newline.count)
    }
    return trimmed + newline
}

@Test("MimeParser header parser")
func mimeParserHeaderParser() throws {
    let bytes = Array("Header-1: value 1\r\nHeader-2: value 2\r\nHeader-3: value 3\r\n\r\n".utf8)
    let memory = MemoryStream(bytes, writable: false)
    let parser = try MimeParser(memory, .entity)
    let headers = try parser.parseHeaders()

    #expect(headers.count == 3)
    #expect(headers["Header-1"] == "value 1")
    #expect(headers["Header-2"] == "value 2")
    #expect(headers["Header-3"] == "value 3")
}

@Test("MimeParser header parser async")
func mimeParserHeaderParserAsync() async throws {
    let bytes = Array("Header-1: value 1\r\nHeader-2: value 2\r\nHeader-3: value 3\r\n\r\n".utf8)
    let memory = MemoryStream(bytes, writable: false)
    let parser = try MimeParser(memory, .entity)
    let headers = try await parser.parseHeadersAsync()

    #expect(headers.count == 3)
    #expect(headers["Header-1"] == "value 1")
    #expect(headers["Header-2"] == "value 2")
    #expect(headers["Header-3"] == "value 3")
}

@Test("MimeParser truncated header name")
func mimeParserTruncatedHeaderName() throws {
    let bytes = Array("Header-1".utf8)
    let memory = MemoryStream(bytes, writable: false)
    let parser = try MimeParser(memory, .entity)
    #expect(throws: ParseException.self) {
        _ = try parser.parseHeaders()
    }
}

@Test("MimeParser truncated header name async")
func mimeParserTruncatedHeaderNameAsync() async throws {
    let bytes = Array("Header-1".utf8)
    let memory = MemoryStream(bytes, writable: false)
    let parser = try MimeParser(memory, .entity)
    await #expect(throws: ParseException.self) {
        _ = try await parser.parseHeadersAsync()
    }
}

@Test("MimeParser truncated header")
func mimeParserTruncatedHeader() throws {
    let bytes = Array("Header-1: value 1".utf8)
    let memory = MemoryStream(bytes, writable: false)
    let parser = try MimeParser(memory, .entity)
    let headers = try parser.parseHeaders()

    #expect(headers.count == 1)
    #expect(headers["Header-1"] == "value 1")
}

@Test("MimeParser truncated header async")
func mimeParserTruncatedHeaderAsync() async throws {
    let bytes = Array("Header-1: value 1".utf8)
    let memory = MemoryStream(bytes, writable: false)
    let parser = try MimeParser(memory, .entity)
    let headers = try await parser.parseHeadersAsync()

    #expect(headers.count == 1)
    #expect(headers["Header-1"] == "value 1")
}

@Test("MimeParser single header no terminator")
func mimeParserSingleHeaderNoTerminator() throws {
    let bytes = Array("Header-1: value 1\r\n".utf8)
    let memory = MemoryStream(bytes, writable: false)
    let parser = try MimeParser(memory, .entity)
    let headers = try parser.parseHeaders()

    #expect(headers.count == 1)
    #expect(headers["Header-1"] == "value 1")
}

@Test("MimeParser single header no terminator async")
func mimeParserSingleHeaderNoTerminatorAsync() async throws {
    let bytes = Array("Header-1: value 1\r\n".utf8)
    let memory = MemoryStream(bytes, writable: false)
    let parser = try MimeParser(memory, .entity)
    let headers = try await parser.parseHeadersAsync()

    #expect(headers.count == 1)
    #expect(headers["Header-1"] == "value 1")
}

@Test("MimeParser empty headers")
func mimeParserEmptyHeaders() throws {
    let bytes = Array("\r\n".utf8)
    let memory = MemoryStream(bytes, writable: false)
    let parser = try MimeParser(memory, .entity)
    let headers = try parser.parseHeaders()
    #expect(headers.count == 0)
}

@Test("MimeParser empty headers async")
func mimeParserEmptyHeadersAsync() async throws {
    let bytes = Array("\r\n".utf8)
    let memory = MemoryStream(bytes, writable: false)
    let parser = try MimeParser(memory, .entity)
    let headers = try await parser.parseHeadersAsync()
    #expect(headers.count == 0)
}

@Test("MimeParser headers with bare carriage return")
func mimeParserHeadersWithBareCarriageReturn() throws {
    let text = "From: <mimekit@example.com>\r\nTo: <mimekit@example.com>\r\nSubject: Test of headers ending with bare carriage-return\r\n\rYou might expect this to be a body, but it's really an invalid header.\r\n"
    let bytes = Array(text.utf8)
    let memory = MemoryStream(bytes, writable: false)
    let parser = try MimeParser(memory, .entity)
    let headers = try parser.parseHeaders()

    #expect(headers.count == 4)
    #expect(headers[0].id == .from)
    #expect(headers[0].value == "<mimekit@example.com>")
    #expect(headers[1].id == .to)
    #expect(headers[1].value == "<mimekit@example.com>")
    #expect(headers[2].id == .subject)
    #expect(headers[2].value == "Test of headers ending with bare carriage-return")
    #expect(headers[3].isInvalid)
    #expect(headers[3].field == "\rYou might expect this to be a body, but it's really an invalid header.\r\n")
}

@Test("MimeParser headers with bare carriage return async")
func mimeParserHeadersWithBareCarriageReturnAsync() async throws {
    let text = "From: <mimekit@example.com>\r\nTo: <mimekit@example.com>\r\nSubject: Test of headers ending with bare carriage-return\r\n\rYou might expect this to be a body, but it's really an invalid header.\r\n"
    let bytes = Array(text.utf8)
    let memory = MemoryStream(bytes, writable: false)
    let parser = try MimeParser(memory, .entity)
    let headers = try await parser.parseHeadersAsync()

    #expect(headers.count == 4)
    #expect(headers[0].id == .from)
    #expect(headers[0].value == "<mimekit@example.com>")
    #expect(headers[1].id == .to)
    #expect(headers[1].value == "<mimekit@example.com>")
    #expect(headers[2].id == .subject)
    #expect(headers[2].value == "Test of headers ending with bare carriage-return")
    #expect(headers[3].isInvalid)
    #expect(headers[3].field == "\rYou might expect this to be a body, but it's really an invalid header.\r\n")
}

@Test("MimeParser partial byte order mark EOF")
func mimeParserPartialByteOrderMarkEOF() throws {
    let bytes: [UInt8] = [0xEF, 0xBB]
    let memory = MemoryStream(bytes, writable: false)
    let parser = try MimeParser(memory, .entity)
    #expect(throws: ParseException.self) {
        _ = try parser.parseMessage()
    }
}

@Test("MimeParser partial byte order mark EOF async")
func mimeParserPartialByteOrderMarkEOFAsync() async throws {
    let bytes: [UInt8] = [0xEF, 0xBB]
    let memory = MemoryStream(bytes, writable: false)
    let parser = try MimeParser(memory, .entity)
    await #expect(throws: ParseException.self) {
        _ = try await parser.parseMessageAsync()
    }
}

@Test("MimeParser byte order mark EOF")
func mimeParserByteOrderMarkEOF() throws {
    let bytes: [UInt8] = [0xEF, 0xBB, 0xBF]
    let memory = MemoryStream(bytes, writable: false)
    let parser = try MimeParser(memory, .entity)

    do {
        _ = try parser.parseMessage()
        #expect(Bool(false))
    } catch let error as ParseException {
        #expect(error.message == "End of stream.")
    } catch {
        #expect(Bool(false))
    }
}

@Test("MimeParser byte order mark EOF async")
func mimeParserByteOrderMarkEOFAsync() async throws {
    let bytes: [UInt8] = [0xEF, 0xBB, 0xBF]
    let memory = MemoryStream(bytes, writable: false)
    let parser = try MimeParser(memory, .entity)

    do {
        _ = try await parser.parseMessageAsync()
        #expect(Bool(false))
    } catch let error as ParseException {
        #expect(error.message == "End of stream.")
    } catch {
        #expect(Bool(false))
    }
}

@Test("MimeParser parsing garbage mbox")
func mimeParserParsingGarbageMbox() throws {
    var bytes: [UInt8] = []
    let line = Array("This is just a standard test file... nothing to see here. No MIME anywhere to be found\r\n".utf8)
    for _ in 0..<200 {
        bytes.append(contentsOf: line)
    }
    let memory = MemoryStream(bytes, writable: false)
    let parser = try MimeParser(memory, .mbox)
    do {
        _ = try parser.parseMessage()
        #expect(Bool(false))
    } catch let error as ParseException {
        #expect(error.message == "Failed to find mbox From marker.")
    } catch {
        #expect(Bool(false))
    }
}

@Test("MimeParser parsing garbage mbox async")
func mimeParserParsingGarbageMboxAsync() async throws {
    var bytes: [UInt8] = []
    let line = Array("This is just a standard test file... nothing to see here. No MIME anywhere to be found\r\n".utf8)
    for _ in 0..<200 {
        bytes.append(contentsOf: line)
    }
    let memory = MemoryStream(bytes, writable: false)
    let parser = try MimeParser(memory, .mbox)
    do {
        _ = try await parser.parseMessageAsync()
        #expect(Bool(false))
    } catch let error as ParseException {
        #expect(error.message == "Failed to find mbox From marker.")
    } catch {
        #expect(Bool(false))
    }
}

@Test("MimeParser parsing garbage entity")
func mimeParserParsingGarbageEntity() throws {
    var bytes: [UInt8] = []
    let line = Array("This is just a standard test file... nothing to see here. No MIME anywhere to be found\r\n".utf8)
    for _ in 0..<200 {
        bytes.append(contentsOf: line)
    }
    let memory = MemoryStream(bytes, writable: false)
    let parser = try MimeParser(memory, .entity)
    do {
        _ = try parser.parseEntity()
        #expect(Bool(false))
    } catch let error as ParseException {
        #expect(error.message == "Failed to parse entity headers.")
    } catch {
        #expect(Bool(false))
    }
}

@Test("MimeParser parsing garbage entity async")
func mimeParserParsingGarbageEntityAsync() async throws {
    var bytes: [UInt8] = []
    let line = Array("This is just a standard test file... nothing to see here. No MIME anywhere to be found\r\n".utf8)
    for _ in 0..<200 {
        bytes.append(contentsOf: line)
    }
    let memory = MemoryStream(bytes, writable: false)
    let parser = try MimeParser(memory, .entity)
    do {
        _ = try await parser.parseEntityAsync()
        #expect(Bool(false))
    } catch let error as ParseException {
        #expect(error.message == "Failed to parse entity headers.")
    } catch {
        #expect(Bool(false))
    }
}

@Test("MimeParser parsing garbage message")
func mimeParserParsingGarbageMessage() throws {
    var bytes: [UInt8] = []
    let line = Array("This is just a standard test file... nothing to see here. No MIME anywhere to be found\r\n".utf8)
    for _ in 0..<200 {
        bytes.append(contentsOf: line)
    }
    let memory = MemoryStream(bytes, writable: false)
    let parser = try MimeParser(memory, .entity)
    do {
        _ = try parser.parseMessage()
        #expect(Bool(false))
    } catch let error as ParseException {
        #expect(error.message == "Failed to parse message headers.")
    } catch {
        #expect(Bool(false))
    }
}

@Test("MimeParser parsing garbage message async")
func mimeParserParsingGarbageMessageAsync() async throws {
    var bytes: [UInt8] = []
    let line = Array("This is just a standard test file... nothing to see here. No MIME anywhere to be found\r\n".utf8)
    for _ in 0..<200 {
        bytes.append(contentsOf: line)
    }
    let memory = MemoryStream(bytes, writable: false)
    let parser = try MimeParser(memory, .entity)
    do {
        _ = try await parser.parseMessageAsync()
        #expect(Bool(false))
    } catch let error as ParseException {
        #expect(error.message == "Failed to parse message headers.")
    } catch {
        #expect(Bool(false))
    }
}

@Test("MimeParser double mbox marker")
func mimeParserDoubleMboxMarker() throws {
    let content = Array("From - \r\nFrom -\r\nFrom: sender@example.com\r\nTo: recipient@example.com\r\nSubject: test message\r\n\r\nBody text\r\n".utf8)
    let memory = MemoryStream(content, writable: false)
    let parser = try MimeParser(memory, .mbox)

    let first = try parser.parseMessage()
    #expect(first.headers.count == 0)

    let second = try parser.parseMessage()
    #expect(second.headers.count == 3)
}

@Test("MimeParser double mbox marker async")
func mimeParserDoubleMboxMarkerAsync() async throws {
    let content = Array("From - \r\nFrom -\r\nFrom: sender@example.com\r\nTo: recipient@example.com\r\nSubject: test message\r\n\r\nBody text\r\n".utf8)
    let memory = MemoryStream(content, writable: false)
    let parser = try MimeParser(memory, .mbox)

    let first = try await parser.parseMessageAsync()
    #expect(first.headers.count == 0)

    let second = try await parser.parseMessageAsync()
    #expect(second.headers.count == 3)
}

@Test("MimeParser truncated mbox marker")
func mimeParserTruncatedMboxMarker() throws {
    let bytes = Array("From <incomplete mbox marker>".utf8)
    let memory = MemoryStream(bytes, writable: false)
    let parser = try MimeParser(memory, .mbox)
    #expect(throws: ParseException.self) {
        _ = try parser.parseMessage()
    }
}

@Test("MimeParser truncated mbox marker async")
func mimeParserTruncatedMboxMarkerAsync() async throws {
    let bytes = Array("From <incomplete mbox marker>".utf8)
    let memory = MemoryStream(bytes, writable: false)
    let parser = try MimeParser(memory, .mbox)
    await #expect(throws: ParseException.self) {
        _ = try await parser.parseMessageAsync()
    }
}

@Test("MimeParser empty mbox stream")
func mimeParserEmptyMboxStream() throws {
    let memory = MemoryStream([], writable: false)
    let parser = try MimeParser(memory, .mbox)
    do {
        _ = try parser.parseMessage()
        #expect(Bool(false))
    } catch let error as ParseException {
        #expect(error.message == "End of stream.")
    } catch {
        #expect(Bool(false))
    }
}

@Test("MimeParser empty mbox stream async")
func mimeParserEmptyMboxStreamAsync() async throws {
    let memory = MemoryStream([], writable: false)
    let parser = try MimeParser(memory, .mbox)
    do {
        _ = try await parser.parseMessageAsync()
        #expect(Bool(false))
    } catch let error as ParseException {
        #expect(error.message == "End of stream.")
    } catch {
        #expect(Bool(false))
    }
}

@Test("MimeParser empty message stream")
func mimeParserEmptyMessageStream() throws {
    let memory = MemoryStream([], writable: false)
    let parser = try MimeParser(memory, .entity)
    do {
        _ = try parser.parseMessage()
        #expect(Bool(false))
    } catch let error as ParseException {
        #expect(error.message == "End of stream.")
    } catch {
        #expect(Bool(false))
    }
}

@Test("MimeParser empty message stream async")
func mimeParserEmptyMessageStreamAsync() async throws {
    let memory = MemoryStream([], writable: false)
    let parser = try MimeParser(memory, .entity)
    do {
        _ = try await parser.parseMessageAsync()
        #expect(Bool(false))
    } catch let error as ParseException {
        #expect(error.message == "End of stream.")
    } catch {
        #expect(Bool(false))
    }
}

@Test("MimeParser empty message")
func mimeParserEmptyMessage() throws {
    let bytes = Array("\r\n".utf8)
    let memory = MemoryStream(bytes, writable: false)
    let parser = try MimeParser(memory, .entity)
    let message = try parser.parseMessage()
    #expect(message.headers.count == 0)
}

@Test("MimeParser empty message async")
func mimeParserEmptyMessageAsync() async throws {
    let bytes = Array("\r\n".utf8)
    let memory = MemoryStream(bytes, writable: false)
    let parser = try MimeParser(memory, .entity)
    let message = try await parser.parseMessageAsync()
    #expect(message.headers.count == 0)
}

@Test("MimeParser header field name begins with colon")
func mimeParserHeaderFieldNameBeginsWithColon() throws {
    let text = """
From: mimekit@example.com
To: mimekit@example.com
Subject: test of a header line starting with ':'
Date: Tue, 12 Nov 2013 09:12:42 -0500
MIME-Version: 1.0
Message-ID: <54AD68C9E3B0184CAC6041320424FD1B5B81E74D@localhost.localdomain>
X-Mailer: Microsoft Office Outlook 12.0
Content-Type: text/plain; charset=utf-8
: What header is this?

This is the message body.
""".replacingOccurrences(of: "\r\n", with: "\n")

    let memory = MemoryStream(Array(text.utf8), writable: false)
    let parser = try MimeParser(memory, .entity)
    let message = try parser.parseMessage()

    #expect(message.body is TextPart)
    let header = message.headers[message.headers.count - 1]
    #expect(!header.isInvalid)
    #expect(header.field == "")
    #expect(header.value == "What header is this?")

    guard let body = message.body as? TextPart else {
        #expect(Bool(false))
        return
    }
    #expect(body.contentType.mimeType == "text/plain")
    #expect(body.contentType.charset == "utf-8")
    #expect(body.text == "This is the message body.")

    try assertSerialization(message, .unix, text)

    let dos = text.replacingOccurrences(of: "\n", with: "\r\n")
    let memoryDos = MemoryStream(Array(dos.utf8), writable: false)
    let parserDos = try MimeParser(memoryDos, .entity)
    let messageDos = try parserDos.parseMessage()
    try assertSerialization(messageDos, .dos, dos)
}

@Test("MimeParser header field name begins with colon async")
func mimeParserHeaderFieldNameBeginsWithColonAsync() async throws {
    let text = """
From: mimekit@example.com
To: mimekit@example.com
Subject: test of a header line starting with ':'
Date: Tue, 12 Nov 2013 09:12:42 -0500
MIME-Version: 1.0
Message-ID: <54AD68C9E3B0184CAC6041320424FD1B5B81E74D@localhost.localdomain>
X-Mailer: Microsoft Office Outlook 12.0
Content-Type: text/plain; charset=utf-8
: What header is this?

This is the message body.
""".replacingOccurrences(of: "\r\n", with: "\n")

    let memory = MemoryStream(Array(text.utf8), writable: false)
    let parser = try MimeParser(memory, .entity)
    let message = try await parser.parseMessageAsync()

    #expect(message.body is TextPart)
    let header = message.headers[message.headers.count - 1]
    #expect(!header.isInvalid)
    #expect(header.field == "")
    #expect(header.value == "What header is this?")

    guard let body = message.body as? TextPart else {
        #expect(Bool(false))
        return
    }
    #expect(body.contentType.mimeType == "text/plain")
    #expect(body.contentType.charset == "utf-8")
    #expect(body.text == "This is the message body.")

    try await assertSerializationAsync(message, .unix, text)

    let dos = text.replacingOccurrences(of: "\n", with: "\r\n")
    let memoryDos = MemoryStream(Array(dos.utf8), writable: false)
    let parserDos = try MimeParser(memoryDos, .entity)
    let messageDos = try await parserDos.parseMessageAsync()
    try await assertSerializationAsync(messageDos, .dos, dos)
}

@Test("MimeParser header field name colon colon")
func mimeParserHeaderFieldNameColonColon() throws {
    let text = """
From: mimekit@example.com
To: mimekit@example.com
Subject: test of a Content-Transfer-Encoding header with double ':'s
Date: Tue, 12 Nov 2013 09:12:42 -0500
MIME-Version: 1.0
Message-ID: <54AD68C9E3B0184CAC6041320424FD1B5B81E74D@localhost.localdomain>
X-Mailer: Microsoft Office Outlook 12.0
Content-Type: text/plain; charset=utf-8
Content-Transfer-Encoding:: base64
Content-Disposition: inline; name=body.txt

This is the message body.
""".replacingOccurrences(of: "\r\n", with: "\n")

    let memory = MemoryStream(Array(text.utf8), writable: false)
    let parser = try MimeParser(memory, .entity)
    let message = try parser.parseMessage()

    guard let body = message.body as? TextPart else {
        #expect(Bool(false))
        return
    }
    let header = body.headers[body.headers.count - 2]
    #expect(header.id == .contentTransferEncoding)
    #expect(!header.isInvalid)
    #expect(header.value == ": base64")
    #expect(body.contentTransferEncoding == .default)
    #expect(body.contentType.mimeType == "text/plain")
    #expect(body.contentType.charset == "utf-8")
    #expect(body.contentDisposition != nil)
    #expect(body.contentDisposition?.disposition == "inline")
    #expect(body.contentDisposition?.parameters["name"] == "body.txt")
    #expect(body.text == "This is the message body.")

    try assertSerialization(message, .unix, text)

    let dos = text.replacingOccurrences(of: "\n", with: "\r\n")
    let memoryDos = MemoryStream(Array(dos.utf8), writable: false)
    let parserDos = try MimeParser(memoryDos, .entity)
    let messageDos = try parserDos.parseMessage()
    try assertSerialization(messageDos, .dos, dos)
}

@Test("MimeParser header field name colon colon async")
func mimeParserHeaderFieldNameColonColonAsync() async throws {
    let text = """
From: mimekit@example.com
To: mimekit@example.com
Subject: test of a Content-Transfer-Encoding header with double ':'s
Date: Tue, 12 Nov 2013 09:12:42 -0500
MIME-Version: 1.0
Message-ID: <54AD68C9E3B0184CAC6041320424FD1B5B81E74D@localhost.localdomain>
X-Mailer: Microsoft Office Outlook 12.0
Content-Type: text/plain; charset=utf-8
Content-Transfer-Encoding:: base64
Content-Disposition: inline; name=body.txt

This is the message body.
""".replacingOccurrences(of: "\r\n", with: "\n")

    let memory = MemoryStream(Array(text.utf8), writable: false)
    let parser = try MimeParser(memory, .entity)
    let message = try await parser.parseMessageAsync()

    guard let body = message.body as? TextPart else {
        #expect(Bool(false))
        return
    }
    let header = body.headers[body.headers.count - 2]
    #expect(header.id == .contentTransferEncoding)
    #expect(!header.isInvalid)
    #expect(header.value == ": base64")
    #expect(body.contentTransferEncoding == .default)
    #expect(body.contentType.mimeType == "text/plain")
    #expect(body.contentType.charset == "utf-8")
    #expect(body.contentDisposition != nil)
    #expect(body.contentDisposition?.disposition == "inline")
    #expect(body.contentDisposition?.parameters["name"] == "body.txt")
    #expect(body.text == "This is the message body.")

    try await assertSerializationAsync(message, .unix, text)

    let dos = text.replacingOccurrences(of: "\n", with: "\r\n")
    let memoryDos = MemoryStream(Array(dos.utf8), writable: false)
    let parserDos = try MimeParser(memoryDos, .entity)
    let messageDos = try await parserDos.parseMessageAsync()
    try await assertSerializationAsync(messageDos, .dos, dos)
}

@Test("MimeParser multipart truncated at end of first boundary")
func mimeParserMultipartTruncatedAtEndOfFirstBoundary() throws {
    var text = """
From: mimekit@example.com
To: mimekit@example.com
Subject: test of multipart truncated at the end of the first boundary
Date: Tue, 12 Nov 2013 09:12:42 -0500
MIME-Version: 1.0
Message-ID: <54AD68C9E3B0184CAC6041320424FD1B5B81E74D@localhost.localdomain>
X-Mailer: Microsoft Office Outlook 12.0
Content-Type: multipart/mixed;
\tboundary=\"----=_NextPart_000_003F_01CE98CE.6E826F90\"


------=_NextPart_000_003F_01CE98CE.6E826F90
""".replacingOccurrences(of: "\r\n", with: "\n")

    let memory = MemoryStream(Array(text.utf8), writable: false)
    let parser = try MimeParser(memory, .entity)
    let message = try parser.parseMessage()

    guard let multipart = message.body as? Multipart else {
        #expect(Bool(false))
        return
    }
    #expect(multipart.count == 0)

    let boundary = "------=_NextPart_000_003F_01CE98CE.6E826F90"
    let expected = replacingLastOccurrence(of: boundary, with: boundary + "--", in: text)
    try assertSerialization(message, .unix, ensureTrailingNewline(expected, newline: "\n"))

    text = text.replacingOccurrences(of: "\n", with: "\r\n")
    let memoryDos = MemoryStream(Array(text.utf8), writable: false)
    let parserDos = try MimeParser(memoryDos, .entity)
    let messageDos = try parserDos.parseMessage()
    let expectedDos = replacingLastOccurrence(of: boundary, with: boundary + "--", in: text)
    try assertSerialization(messageDos, .dos, ensureTrailingNewline(expectedDos, newline: "\r\n"))
}

@Test("MimeParser multipart truncated at end of first boundary async")
func mimeParserMultipartTruncatedAtEndOfFirstBoundaryAsync() async throws {
    var text = """
From: mimekit@example.com
To: mimekit@example.com
Subject: test of multipart truncated at the end of the first boundary
Date: Tue, 12 Nov 2013 09:12:42 -0500
MIME-Version: 1.0
Message-ID: <54AD68C9E3B0184CAC6041320424FD1B5B81E74D@localhost.localdomain>
X-Mailer: Microsoft Office Outlook 12.0
Content-Type: multipart/mixed;
\tboundary=\"----=_NextPart_000_003F_01CE98CE.6E826F90\"


------=_NextPart_000_003F_01CE98CE.6E826F90
""".replacingOccurrences(of: "\r\n", with: "\n")

    let memory = MemoryStream(Array(text.utf8), writable: false)
    let parser = try MimeParser(memory, .entity)
    let message = try await parser.parseMessageAsync()

    guard let multipart = message.body as? Multipart else {
        #expect(Bool(false))
        return
    }
    #expect(multipart.count == 0)

    let boundary = "------=_NextPart_000_003F_01CE98CE.6E826F90"
    let expected = replacingLastOccurrence(of: boundary, with: boundary + "--", in: text)
    try await assertSerializationAsync(message, .unix, ensureTrailingNewline(expected, newline: "\n"))

    text = text.replacingOccurrences(of: "\n", with: "\r\n")
    let memoryDos = MemoryStream(Array(text.utf8), writable: false)
    let parserDos = try MimeParser(memoryDos, .entity)
    let messageDos = try await parserDos.parseMessageAsync()
    let expectedDos = replacingLastOccurrence(of: boundary, with: boundary + "--", in: text)
    try await assertSerializationAsync(messageDos, .dos, ensureTrailingNewline(expectedDos, newline: "\r\n"))
}

@Test("MimeParser invalid Content-Type")
func mimeParserInvalidContentType() throws {
    let mimeTypes = ["garbage", "!%^#&^!\t  "]
    for mimeType in mimeTypes {
        let template = """
From: mimekit@example.com
To: mimekit@example.com
Subject: test of recovery from invalid media-type in Content-Type header
Date: Tue, 12 Nov 2013 09:12:42 -0500
MIME-Version: 1.0
Message-ID: <54AD68C9E3B0184CAC6041320424FD1B5B81E74D@localhost.localdomain>
X-Mailer: Microsoft Office Outlook 12.0
Content-Type: \(mimeType); charset=utf-8

This is the message body.
""".replacingOccurrences(of: "\r\n", with: "\n")

        for text in [template, template.replacingOccurrences(of: "\n", with: "\r\n")] {
            let memory = MemoryStream(Array(text.utf8), writable: false)
            let parser = try MimeParser(memory, .entity)
            let message = try parser.parseMessage()

            guard let part = message.body as? MimePart else {
                #expect(Bool(false))
                continue
            }
            #expect(part.contentType.mimeType == "application/octet-stream")
            #expect(part.contentType.charset == "utf-8")

            let body = TextPart("plain")
            body.content = part.content
            #expect(body.text == "This is the message body.")
        }
    }
}

@Test("MimeParser invalid Content-Type async")
func mimeParserInvalidContentTypeAsync() async throws {
    let mimeTypes = ["garbage", "!%^#&^!\t  "]
    for mimeType in mimeTypes {
        let template = """
From: mimekit@example.com
To: mimekit@example.com
Subject: test of recovery from invalid media-type in Content-Type header
Date: Tue, 12 Nov 2013 09:12:42 -0500
MIME-Version: 1.0
Message-ID: <54AD68C9E3B0184CAC6041320424FD1B5B81E74D@localhost.localdomain>
X-Mailer: Microsoft Office Outlook 12.0
Content-Type: \(mimeType); charset=utf-8

This is the message body.
""".replacingOccurrences(of: "\r\n", with: "\n")

        for text in [template, template.replacingOccurrences(of: "\n", with: "\r\n")] {
            let memory = MemoryStream(Array(text.utf8), writable: false)
            let parser = try MimeParser(memory, .entity)
            let message = try await parser.parseMessageAsync()

            guard let part = message.body as? MimePart else {
                #expect(Bool(false))
                continue
            }
            #expect(part.contentType.mimeType == "application/octet-stream")
            #expect(part.contentType.charset == "utf-8")

            let body = TextPart("plain")
            body.content = part.content
            #expect(body.text == "This is the message body.")
        }
    }
}

@Test("MimeParser multipart truncated at end of second boundary")
func mimeParserMultipartTruncatedAtEndOfSecondBoundary() throws {
    var text = """
From: mimekit@example.com
To: mimekit@example.com
Subject: test of a multipart truncated at the end of the second boundary
Date: Tue, 12 Nov 2013 09:12:42 -0500
MIME-Version: 1.0
Message-ID: <54AD68C9E3B0184CAC6041320424FD1B5B81E74D@localhost.localdomain>
X-Mailer: Microsoft Office Outlook 12.0
Content-Type: multipart/mixed;
\tboundary=\"----=_NextPart_000_003F_01CE98CE.6E826F90\"


------=_NextPart_000_003F_01CE98CE.6E826F90
Content-Type: text/plain; charset=utf-8

This is the message body.

------=_NextPart_000_003F_01CE98CE.6E826F90
""".replacingOccurrences(of: "\r\n", with: "\n")

    let memory = MemoryStream(Array(text.utf8), writable: false)
    let parser = try MimeParser(memory, .entity)
    let message = try parser.parseMessage()

    guard let multipart = message.body as? Multipart else {
        #expect(Bool(false))
        return
    }
    #expect(multipart.count == 1)
    guard multipart.count >= 1, let body = multipart[0] as? TextPart else {
        #expect(Bool(false))
        return
    }
    #expect(body.headers[.contentType] == "text/plain; charset=utf-8")
    #expect(body.contentType.charset == "utf-8")
    #expect(body.text == "This is the message body.\n")

    let boundary = "------=_NextPart_000_003F_01CE98CE.6E826F90"
    let expected = replacingLastOccurrence(of: boundary, with: boundary + "--", in: text)
    try assertSerialization(message, .unix, ensureTrailingNewline(expected, newline: "\n"))

    text = text.replacingOccurrences(of: "\n", with: "\r\n")
    let memoryDos = MemoryStream(Array(text.utf8), writable: false)
    let parserDos = try MimeParser(memoryDos, .entity)
    let messageDos = try parserDos.parseMessage()
    let expectedDos = replacingLastOccurrence(of: boundary, with: boundary + "--", in: text)
    try assertSerialization(messageDos, .dos, ensureTrailingNewline(expectedDos, newline: "\r\n"))
}

@Test("MimeParser multipart truncated at end of second boundary async")
func mimeParserMultipartTruncatedAtEndOfSecondBoundaryAsync() async throws {
    var text = """
From: mimekit@example.com
To: mimekit@example.com
Subject: test of a multipart truncated at the end of the second boundary
Date: Tue, 12 Nov 2013 09:12:42 -0500
MIME-Version: 1.0
Message-ID: <54AD68C9E3B0184CAC6041320424FD1B5B81E74D@localhost.localdomain>
X-Mailer: Microsoft Office Outlook 12.0
Content-Type: multipart/mixed;
\tboundary=\"----=_NextPart_000_003F_01CE98CE.6E826F90\"


------=_NextPart_000_003F_01CE98CE.6E826F90
Content-Type: text/plain; charset=utf-8

This is the message body.

------=_NextPart_000_003F_01CE98CE.6E826F90
""".replacingOccurrences(of: "\r\n", with: "\n")

    let memory = MemoryStream(Array(text.utf8), writable: false)
    let parser = try MimeParser(memory, .entity)
    let message = try await parser.parseMessageAsync()

    guard let multipart = message.body as? Multipart else {
        #expect(Bool(false))
        return
    }
    #expect(multipart.count == 1)
    guard multipart.count >= 1, let body = multipart[0] as? TextPart else {
        #expect(Bool(false))
        return
    }
    #expect(body.headers[.contentType] == "text/plain; charset=utf-8")
    #expect(body.contentType.charset == "utf-8")
    #expect(body.text == "This is the message body.\n")

    let boundary = "------=_NextPart_000_003F_01CE98CE.6E826F90"
    let expected = replacingLastOccurrence(of: boundary, with: boundary + "--", in: text)
    try await assertSerializationAsync(message, .unix, ensureTrailingNewline(expected, newline: "\n"))

    text = text.replacingOccurrences(of: "\n", with: "\r\n")
    let memoryDos = MemoryStream(Array(text.utf8), writable: false)
    let parserDos = try MimeParser(memoryDos, .entity)
    let messageDos = try await parserDos.parseMessageAsync()
    let expectedDos = replacingLastOccurrence(of: boundary, with: boundary + "--", in: text)
    try await assertSerializationAsync(messageDos, .dos, ensureTrailingNewline(expectedDos, newline: "\r\n"))
}

@Test("MimeParser multipart truncated immediately after first boundary")
func mimeParserMultipartTruncatedImmediatelyAfterFirstBoundary() throws {
    var text = """
From: mimekit@example.com
To: mimekit@example.com
Subject: test of multipart truncated immedately after first boundary
Date: Tue, 12 Nov 2013 09:12:42 -0500
MIME-Version: 1.0
Message-ID: <54AD68C9E3B0184CAC6041320424FD1B5B81E74D@localhost.localdomain>
X-Mailer: Microsoft Office Outlook 12.0
Content-Type: multipart/mixed;
\tboundary=\"----=_NextPart_000_003F_01CE98CE.6E826F90\"


------=_NextPart_000_003F_01CE98CE.6E826F90
""".replacingOccurrences(of: "\r\n", with: "\n")

    let memory = MemoryStream(Array(text.utf8), writable: false)
    let parser = try MimeParser(memory, .entity)
    let message = try parser.parseMessage()

    guard let multipart = message.body as? Multipart else {
        #expect(Bool(false))
        return
    }
    #expect(multipart.count == 0)

    let boundary = "------=_NextPart_000_003F_01CE98CE.6E826F90"
    let expected = replacingLastOccurrence(of: boundary, with: boundary + "--", in: text)
    try assertSerialization(message, .unix, ensureTrailingNewline(expected, newline: "\n"))

    text = text.replacingOccurrences(of: "\n", with: "\r\n")
    let memoryDos = MemoryStream(Array(text.utf8), writable: false)
    let parserDos = try MimeParser(memoryDos, .entity)
    let messageDos = try parserDos.parseMessage()
    let expectedDos = replacingLastOccurrence(of: boundary, with: boundary + "--", in: text)
    try assertSerialization(messageDos, .dos, ensureTrailingNewline(expectedDos, newline: "\r\n"))
}

@Test("MimeParser multipart truncated immediately after first boundary async")
func mimeParserMultipartTruncatedImmediatelyAfterFirstBoundaryAsync() async throws {
    var text = """
From: mimekit@example.com
To: mimekit@example.com
Subject: test of multipart truncated immedately after first boundary
Date: Tue, 12 Nov 2013 09:12:42 -0500
MIME-Version: 1.0
Message-ID: <54AD68C9E3B0184CAC6041320424FD1B5B81E74D@localhost.localdomain>
X-Mailer: Microsoft Office Outlook 12.0
Content-Type: multipart/mixed;
\tboundary=\"----=_NextPart_000_003F_01CE98CE.6E826F90\"


------=_NextPart_000_003F_01CE98CE.6E826F90
""".replacingOccurrences(of: "\r\n", with: "\n")

    let memory = MemoryStream(Array(text.utf8), writable: false)
    let parser = try MimeParser(memory, .entity)
    let message = try await parser.parseMessageAsync()

    guard let multipart = message.body as? Multipart else {
        #expect(Bool(false))
        return
    }
    #expect(multipart.count == 0)

    let boundary = "------=_NextPart_000_003F_01CE98CE.6E826F90"
    let expected = replacingLastOccurrence(of: boundary, with: boundary + "--", in: text)
    try await assertSerializationAsync(message, .unix, ensureTrailingNewline(expected, newline: "\n"))

    text = text.replacingOccurrences(of: "\n", with: "\r\n")
    let memoryDos = MemoryStream(Array(text.utf8), writable: false)
    let parserDos = try MimeParser(memoryDos, .entity)
    let messageDos = try await parserDos.parseMessageAsync()
    let expectedDos = replacingLastOccurrence(of: boundary, with: boundary + "--", in: text)
    try await assertSerializationAsync(messageDos, .dos, ensureTrailingNewline(expectedDos, newline: "\r\n"))
}

@Test("MimeParser multipart truncated immediately after second boundary")
func mimeParserMultipartTruncatedImmediatelyAfterSecondBoundary() throws {
    var text = """
From: mimekit@example.com
To: mimekit@example.com
Subject: test of a multipart truncated immediately after the second boundary
Date: Tue, 12 Nov 2013 09:12:42 -0500
MIME-Version: 1.0
Message-ID: <54AD68C9E3B0184CAC6041320424FD1B5B81E74D@localhost.localdomain>
X-Mailer: Microsoft Office Outlook 12.0
Content-Type: multipart/mixed;
\tboundary=\"----=_NextPart_000_003F_01CE98CE.6E826F90\"


------=_NextPart_000_003F_01CE98CE.6E826F90
Content-Type: text/plain; charset=utf-8

This is the message body.

------=_NextPart_000_003F_01CE98CE.6E826F90
""".replacingOccurrences(of: "\r\n", with: "\n")

    let memory = MemoryStream(Array(text.utf8), writable: false)
    let parser = try MimeParser(memory, .entity)
    let message = try parser.parseMessage()

    guard let multipart = message.body as? Multipart else {
        #expect(Bool(false))
        return
    }
    #expect(multipart.count == 1)
    guard multipart.count >= 1, let body = multipart[0] as? TextPart else {
        #expect(Bool(false))
        return
    }
    #expect(body.headers[.contentType] == "text/plain; charset=utf-8")
    #expect(body.contentType.charset == "utf-8")
    #expect(body.text == "This is the message body.\n")

    let boundary = "------=_NextPart_000_003F_01CE98CE.6E826F90"
    let expected = replacingLastOccurrence(of: boundary, with: boundary + "--", in: text)
    try assertSerialization(message, .unix, ensureTrailingNewline(expected, newline: "\n"))

    text = text.replacingOccurrences(of: "\n", with: "\r\n")
    let memoryDos = MemoryStream(Array(text.utf8), writable: false)
    let parserDos = try MimeParser(memoryDos, .entity)
    let messageDos = try parserDos.parseMessage()
    let expectedDos = replacingLastOccurrence(of: boundary, with: boundary + "--", in: text)
    try assertSerialization(messageDos, .dos, ensureTrailingNewline(expectedDos, newline: "\r\n"))
}

@Test("MimeParser multipart truncated immediately after second boundary async")
func mimeParserMultipartTruncatedImmediatelyAfterSecondBoundaryAsync() async throws {
    var text = """
From: mimekit@example.com
To: mimekit@example.com
Subject: test of a multipart truncated immediately after the second boundary
Date: Tue, 12 Nov 2013 09:12:42 -0500
MIME-Version: 1.0
Message-ID: <54AD68C9E3B0184CAC6041320424FD1B5B81E74D@localhost.localdomain>
X-Mailer: Microsoft Office Outlook 12.0
Content-Type: multipart/mixed;
\tboundary=\"----=_NextPart_000_003F_01CE98CE.6E826F90\"


------=_NextPart_000_003F_01CE98CE.6E826F90
Content-Type: text/plain; charset=utf-8

This is the message body.

------=_NextPart_000_003F_01CE98CE.6E826F90
""".replacingOccurrences(of: "\r\n", with: "\n")

    let memory = MemoryStream(Array(text.utf8), writable: false)
    let parser = try MimeParser(memory, .entity)
    let message = try await parser.parseMessageAsync()

    guard let multipart = message.body as? Multipart else {
        #expect(Bool(false))
        return
    }
    #expect(multipart.count == 1)
    guard multipart.count >= 1, let body = multipart[0] as? TextPart else {
        #expect(Bool(false))
        return
    }
    #expect(body.headers[.contentType] == "text/plain; charset=utf-8")
    #expect(body.contentType.charset == "utf-8")
    #expect(body.text == "This is the message body.\n")

    let boundary = "------=_NextPart_000_003F_01CE98CE.6E826F90"
    let expected = replacingLastOccurrence(of: boundary, with: boundary + "--", in: text)
    try await assertSerializationAsync(message, .unix, ensureTrailingNewline(expected, newline: "\n"))

    text = text.replacingOccurrences(of: "\n", with: "\r\n")
    let memoryDos = MemoryStream(Array(text.utf8), writable: false)
    let parserDos = try MimeParser(memoryDos, .entity)
    let messageDos = try await parserDos.parseMessageAsync()
    let expectedDos = replacingLastOccurrence(of: boundary, with: boundary + "--", in: text)
    try await assertSerializationAsync(messageDos, .dos, ensureTrailingNewline(expectedDos, newline: "\r\n"))
}

@Test("MimeParser multipart boundary without trailing newline")
func mimeParserMultipartBoundaryWithoutTrailingNewline() throws {
    var text = """
From: mimekit@example.com
To: mimekit@example.com
Subject: test of multipart boundary w/o trailing newline
Date: Tue, 12 Nov 2013 09:12:42 -0500
MIME-Version: 1.0
Message-ID: <54AD68C9E3B0184CAC6041320424FD1B5B81E74D@localhost.localdomain>
X-Mailer: Microsoft Office Outlook 12.0
Content-Type: multipart/mixed;
\tboundary=\"----=_NextPart_000_003F_01CE98CE.6E826F90\"


------=_NextPart_000_003F_01CE98CE.6E826F90
Content-Type: text/plain; charset=utf-8

This is the message body.

------=_NextPart_000_003F_01CE98CE.6E826F90
""".replacingOccurrences(of: "\r\n", with: "\n")

    let memory = MemoryStream(Array(text.utf8), writable: false)
    let parser = try MimeParser(memory, .entity)
    let message = try parser.parseMessage()

    guard let multipart = message.body as? Multipart else {
        #expect(Bool(false))
        return
    }
    #expect(multipart.count == 1)
    guard multipart.count >= 1, let body = multipart[0] as? TextPart else {
        #expect(Bool(false))
        return
    }
    #expect(body.text == "This is the message body.\n")

    let boundary = "------=_NextPart_000_003F_01CE98CE.6E826F90"
    let expected = replacingLastOccurrence(of: boundary, with: boundary + "--", in: text)
    try assertSerialization(message, .unix, ensureTrailingNewline(expected, newline: "\n"))

    text = text.replacingOccurrences(of: "\n", with: "\r\n")
    let memoryDos = MemoryStream(Array(text.utf8), writable: false)
    let parserDos = try MimeParser(memoryDos, .entity)
    let messageDos = try parserDos.parseMessage()
    let expectedDos = replacingLastOccurrence(of: boundary, with: boundary + "--", in: text)
    try assertSerialization(messageDos, .dos, ensureTrailingNewline(expectedDos, newline: "\r\n"))
}

@Test("MimeParser multipart boundary without trailing newline async")
func mimeParserMultipartBoundaryWithoutTrailingNewlineAsync() async throws {
    var text = """
From: mimekit@example.com
To: mimekit@example.com
Subject: test of multipart boundary w/o trailing newline
Date: Tue, 12 Nov 2013 09:12:42 -0500
MIME-Version: 1.0
Message-ID: <54AD68C9E3B0184CAC6041320424FD1B5B81E74D@localhost.localdomain>
X-Mailer: Microsoft Office Outlook 12.0
Content-Type: multipart/mixed;
\tboundary=\"----=_NextPart_000_003F_01CE98CE.6E826F90\"


------=_NextPart_000_003F_01CE98CE.6E826F90
Content-Type: text/plain; charset=utf-8

This is the message body.

------=_NextPart_000_003F_01CE98CE.6E826F90
""".replacingOccurrences(of: "\r\n", with: "\n")

    let memory = MemoryStream(Array(text.utf8), writable: false)
    let parser = try MimeParser(memory, .entity)
    let message = try await parser.parseMessageAsync()

    guard let multipart = message.body as? Multipart else {
        #expect(Bool(false))
        return
    }
    #expect(multipart.count == 1)
    guard multipart.count >= 1, let body = multipart[0] as? TextPart else {
        #expect(Bool(false))
        return
    }
    #expect(body.text == "This is the message body.\n")

    let boundary = "------=_NextPart_000_003F_01CE98CE.6E826F90"
    let expected = replacingLastOccurrence(of: boundary, with: boundary + "--", in: text)
    try await assertSerializationAsync(message, .unix, ensureTrailingNewline(expected, newline: "\n"))

    text = text.replacingOccurrences(of: "\n", with: "\r\n")
    let memoryDos = MemoryStream(Array(text.utf8), writable: false)
    let parserDos = try MimeParser(memoryDos, .entity)
    let messageDos = try await parserDos.parseMessageAsync()
    let expectedDos = replacingLastOccurrence(of: boundary, with: boundary + "--", in: text)
    try await assertSerializationAsync(messageDos, .dos, ensureTrailingNewline(expectedDos, newline: "\r\n"))
}

@Test("MimeParser issue 991 mbox offsets")
func mimeParserIssue991() throws {
    let (memory, expectedOffsets) = createIssue991Mbox()
    let parser = try MimeParser(memory, .mbox)
    var index = 0

    while !parser.isEndOfStream {
        let message = try parser.parseMessage()
        #expect(parser.position == expectedOffsets[index])
        #expect(message.messageId == "1234567890.\(index)@example.org")
        index += 1
    }
}

@Test("MimeParser issue 991 mbox offsets async")
func mimeParserIssue991Async() async throws {
    let (memory, expectedOffsets) = createIssue991Mbox()
    let parser = try MimeParser(memory, .mbox)
    var index = 0

    while !parser.isEndOfStream {
        let message = try await parser.parseMessageAsync()
        #expect(parser.position == expectedOffsets[index])
        #expect(message.messageId == "1234567890.\(index)@example.org")
        index += 1
    }
}

@Test("MimeParser mbox with lines exceeding max SMTP line length")
func mimeParserMboxWithLinesExceedingMaxSmtpLineLength() throws {
    let (memory, expectedOffsets) = createMboxWithLinesExceedingMaxSmtpLineLength()
    let parser = try MimeParser(memory, .mbox)
    var index = 0

    while !parser.isEndOfStream {
        let message = try parser.parseMessage()
        #expect(parser.position == expectedOffsets[index])
        #expect(message.messageId == "1234567890.\(index)@example.org")
        index += 1
    }
}

@Test("MimeParser mbox with lines exceeding max SMTP line length async")
func mimeParserMboxWithLinesExceedingMaxSmtpLineLengthAsync() async throws {
    let (memory, expectedOffsets) = createMboxWithLinesExceedingMaxSmtpLineLength()
    let parser = try MimeParser(memory, .mbox)
    var index = 0

    while !parser.isEndOfStream {
        let message = try await parser.parseMessageAsync()
        #expect(parser.position == expectedOffsets[index])
        #expect(message.messageId == "1234567890.\(index)@example.org")
        index += 1
    }
}
