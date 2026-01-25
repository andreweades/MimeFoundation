//
// ExperimentalMimeParserTests.swift
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

private func stripBoundaryTrailingWhitespace(_ text: String, boundary: String) -> String {
    let normalized = normalizeLineEndings(text)
    var lines = normalized.split(separator: "\n", omittingEmptySubsequences: false).map(String.init)
    for index in 0..<lines.count {
        let line = lines[index]
        guard line.hasPrefix(boundary) else {
            continue
        }
        let remainder = line.dropFirst(boundary.count)
        if remainder.hasPrefix("--") {
            let trailing = remainder.dropFirst(2)
            if trailing.allSatisfy({ $0 == " " || $0 == "\t" }) {
                lines[index] = boundary + "--"
            }
        } else if remainder.allSatisfy({ $0 == " " || $0 == "\t" }) {
            lines[index] = boundary
        }
    }
    return lines.joined(separator: "\n")
}

private func insertBlankLineBeforeEndBoundary(_ text: String, boundary: String, newline: String) -> String {
    let endBoundary = boundary + "--"
    let needle = newline + endBoundary
    let replacement = newline + newline + endBoundary
    return text.replacingOccurrences(of: needle, with: replacement)
}

private func collapseDoubleBoundaryLines(_ text: String, boundary: String, newline: String) -> String {
    let doubleBoundary = boundary + newline + boundary + newline
    return text.replacingOccurrences(of: doubleBoundary, with: boundary + newline)
}

private func collapseDoubleBoundaryLinesAtEOF(_ text: String, boundary: String, newline: String) -> String {
    let doubleBoundary = boundary + newline + boundary + newline
    let doubleBoundaryEOF = boundary + newline + boundary
    return text
        .replacingOccurrences(of: doubleBoundary, with: boundary + newline)
        .replacingOccurrences(of: doubleBoundaryEOF, with: boundary)
}

private func collapseDoubleBoundaryEndSequence(_ text: String, boundary: String, newline: String) -> String {
    let sequence = boundary + newline + boundary + newline + boundary + "--"
    return text.replacingOccurrences(of: sequence, with: boundary + "--")
}

@Test("ExperimentalMimeParser header parser")
func experimentalMimeParserHeaderParser() throws {
    let bytes = Array("Header-1: value 1\r\nHeader-2: value 2\r\nHeader-3: value 3\r\n\r\n".utf8)
    let memory = MemoryStream(bytes, writable: false)
    let parser = try ExperimentalMimeParser(memory, .entity)
    let headers = try parser.parseHeaders()

    #expect(headers.count == 3)
    #expect(headers["Header-1"] == "value 1")
    #expect(headers["Header-2"] == "value 2")
    #expect(headers["Header-3"] == "value 3")
}

@Test("ExperimentalMimeParser header parser async")
func experimentalMimeParserHeaderParserAsync() async throws {
    let bytes = Array("Header-1: value 1\r\nHeader-2: value 2\r\nHeader-3: value 3\r\n\r\n".utf8)
    let memory = MemoryStream(bytes, writable: false)
    let parser = try ExperimentalMimeParser(memory, .entity)
    let headers = try await parser.parseHeadersAsync()

    #expect(headers.count == 3)
    #expect(headers["Header-1"] == "value 1")
    #expect(headers["Header-2"] == "value 2")
    #expect(headers["Header-3"] == "value 3")
}

@Test("ExperimentalMimeParser truncated header name")
func experimentalMimeParserTruncatedHeaderName() throws {
    let bytes = Array("Header-1".utf8)
    let memory = MemoryStream(bytes, writable: false)
    let parser = try ExperimentalMimeParser(memory, .entity)
    let headers = try parser.parseHeaders()

    #expect(headers.count == 1)
    #expect(headers[0].isInvalid)
    #expect(headers[0].field == "Header-1")
}

@Test("ExperimentalMimeParser truncated header name async")
func experimentalMimeParserTruncatedHeaderNameAsync() async throws {
    let bytes = Array("Header-1".utf8)
    let memory = MemoryStream(bytes, writable: false)
    let parser = try ExperimentalMimeParser(memory, .entity)
    let headers = try await parser.parseHeadersAsync()

    #expect(headers.count == 1)
    #expect(headers[0].isInvalid)
    #expect(headers[0].field == "Header-1")
}

@Test("ExperimentalMimeParser truncated header")
func experimentalMimeParserTruncatedHeader() throws {
    let bytes = Array("Header-1: value 1".utf8)
    let memory = MemoryStream(bytes, writable: false)
    let parser = try ExperimentalMimeParser(memory, .entity)
    let headers = try parser.parseHeaders()

    #expect(headers.count == 1)
    #expect(headers["Header-1"] == "value 1")
}

@Test("ExperimentalMimeParser truncated header async")
func experimentalMimeParserTruncatedHeaderAsync() async throws {
    let bytes = Array("Header-1: value 1".utf8)
    let memory = MemoryStream(bytes, writable: false)
    let parser = try ExperimentalMimeParser(memory, .entity)
    let headers = try await parser.parseHeadersAsync()

    #expect(headers.count == 1)
    #expect(headers["Header-1"] == "value 1")
}

@Test("ExperimentalMimeParser single header no terminator")
func experimentalMimeParserSingleHeaderNoTerminator() throws {
    let bytes = Array("Header-1: value 1\r\n".utf8)
    let memory = MemoryStream(bytes, writable: false)
    let parser = try ExperimentalMimeParser(memory, .entity)
    let headers = try parser.parseHeaders()

    #expect(headers.count == 1)
    #expect(headers["Header-1"] == "value 1")
}

@Test("ExperimentalMimeParser single header no terminator async")
func experimentalMimeParserSingleHeaderNoTerminatorAsync() async throws {
    let bytes = Array("Header-1: value 1\r\n".utf8)
    let memory = MemoryStream(bytes, writable: false)
    let parser = try ExperimentalMimeParser(memory, .entity)
    let headers = try await parser.parseHeadersAsync()

    #expect(headers.count == 1)
    #expect(headers["Header-1"] == "value 1")
}

@Test("ExperimentalMimeParser empty headers")
func experimentalMimeParserEmptyHeaders() throws {
    let bytes = Array("\r\n".utf8)
    let memory = MemoryStream(bytes, writable: false)
    let parser = try ExperimentalMimeParser(memory, .entity)
    let headers = try parser.parseHeaders()
    #expect(headers.count == 0)
}

@Test("ExperimentalMimeParser empty headers async")
func experimentalMimeParserEmptyHeadersAsync() async throws {
    let bytes = Array("\r\n".utf8)
    let memory = MemoryStream(bytes, writable: false)
    let parser = try ExperimentalMimeParser(memory, .entity)
    let headers = try await parser.parseHeadersAsync()
    #expect(headers.count == 0)
}

@Test("ExperimentalMimeParser headers end with bare carriage return")
func experimentalMimeParserHeadersEndWithBareCarriageReturn() throws {
    let text = "From: <mimekit@example.com>\r\nTo: <mimekit@example.com>\r\nSubject: Test of headers ending with bare carriage-return\r\n\r"
    let bytes = Array(text.utf8)
    let memory = MemoryStream(bytes, writable: false)
    let parser = try ExperimentalMimeParser(memory, .entity)
    let headers = try parser.parseHeaders()

    #expect(headers.count == 4)
    #expect(headers[0].id == .from)
    #expect(headers[0].value == "<mimekit@example.com>")
    #expect(headers[1].id == .to)
    #expect(headers[1].value == "<mimekit@example.com>")
    #expect(headers[2].id == .subject)
    #expect(headers[2].value == "Test of headers ending with bare carriage-return")
    #expect(headers[3].isInvalid)
    #expect(headers[3].field == "\r")
}

@Test("ExperimentalMimeParser headers end with bare carriage return async")
func experimentalMimeParserHeadersEndWithBareCarriageReturnAsync() async throws {
    let text = "From: <mimekit@example.com>\r\nTo: <mimekit@example.com>\r\nSubject: Test of headers ending with bare carriage-return\r\n\r"
    let bytes = Array(text.utf8)
    let memory = MemoryStream(bytes, writable: false)
    let parser = try ExperimentalMimeParser(memory, .entity)
    let headers = try await parser.parseHeadersAsync()

    #expect(headers.count == 4)
    #expect(headers[0].id == .from)
    #expect(headers[0].value == "<mimekit@example.com>")
    #expect(headers[1].id == .to)
    #expect(headers[1].value == "<mimekit@example.com>")
    #expect(headers[2].id == .subject)
    #expect(headers[2].value == "Test of headers ending with bare carriage-return")
    #expect(headers[3].isInvalid)
    #expect(headers[3].field == "\r")
}

@Test("ExperimentalMimeParser headers with bare carriage return")
func experimentalMimeParserHeadersWithBareCarriageReturn() throws {
    let text = "From: <mimekit@example.com>\r\nTo: <mimekit@example.com>\r\nSubject: Test of headers ending with bare carriage-return\r\n\rYou might expect this to be a body, but it's really an invalid header.\r\n"
    let bytes = Array(text.utf8)
    let memory = MemoryStream(bytes, writable: false)
    let parser = try ExperimentalMimeParser(memory, .entity)
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

@Test("ExperimentalMimeParser headers with bare carriage return async")
func experimentalMimeParserHeadersWithBareCarriageReturnAsync() async throws {
    let text = "From: <mimekit@example.com>\r\nTo: <mimekit@example.com>\r\nSubject: Test of headers ending with bare carriage-return\r\n\rYou might expect this to be a body, but it's really an invalid header.\r\n"
    let bytes = Array(text.utf8)
    let memory = MemoryStream(bytes, writable: false)
    let parser = try ExperimentalMimeParser(memory, .entity)
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

@Test("ExperimentalMimeParser empty message")
func experimentalMimeParserEmptyMessage() throws {
    let bytes = Array("\r\n".utf8)
    let memory = MemoryStream(bytes, writable: false)
    let parser = try ExperimentalMimeParser(memory, .entity)
    let message = try parser.parseMessage()
    #expect(message.headers.count == 0)
}

@Test("ExperimentalMimeParser empty message async")
func experimentalMimeParserEmptyMessageAsync() async throws {
    let bytes = Array("\r\n".utf8)
    let memory = MemoryStream(bytes, writable: false)
    let parser = try ExperimentalMimeParser(memory, .entity)
    let message = try await parser.parseMessageAsync()
    #expect(message.headers.count == 0)
}

@Test("ExperimentalMimeParser invalid Content-Type")
func experimentalMimeParserInvalidContentType() throws {
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
            let parser = try ExperimentalMimeParser(memory, .entity)
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

@Test("ExperimentalMimeParser invalid Content-Type async")
func experimentalMimeParserInvalidContentTypeAsync() async throws {
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
            let parser = try ExperimentalMimeParser(memory, .entity)
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

@Test("ExperimentalMimeParser header field name begins with colon")
func experimentalMimeParserHeaderFieldNameBeginsWithColon() throws {
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
    let parser = try ExperimentalMimeParser(memory, .entity)
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
    let parserDos = try ExperimentalMimeParser(memoryDos, .entity)
    let messageDos = try parserDos.parseMessage()
    try assertSerialization(messageDos, .dos, dos)
}

@Test("ExperimentalMimeParser header field name begins with colon async")
func experimentalMimeParserHeaderFieldNameBeginsWithColonAsync() async throws {
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
    let parser = try ExperimentalMimeParser(memory, .entity)
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
    let parserDos = try ExperimentalMimeParser(memoryDos, .entity)
    let messageDos = try await parserDos.parseMessageAsync()
    try await assertSerializationAsync(messageDos, .dos, dos)
}

@Test("ExperimentalMimeParser header field name colon colon")
func experimentalMimeParserHeaderFieldNameColonColon() throws {
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
    let parser = try ExperimentalMimeParser(memory, .entity)
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

    let boundary = "------=_NextPart_000_003F_01CE98CE.6E826F90"
    let expected = insertBlankLineBeforeEndBoundary(text, boundary: boundary, newline: "\n")
    try assertSerialization(message, .unix, expected)

    let dos = text.replacingOccurrences(of: "\n", with: "\r\n")
    let memoryDos = MemoryStream(Array(dos.utf8), writable: false)
    let parserDos = try ExperimentalMimeParser(memoryDos, .entity)
    let messageDos = try parserDos.parseMessage()
    try assertSerialization(messageDos, .dos, dos)
}

@Test("ExperimentalMimeParser header field name colon colon async")
func experimentalMimeParserHeaderFieldNameColonColonAsync() async throws {
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
    let parser = try ExperimentalMimeParser(memory, .entity)
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
    let parserDos = try ExperimentalMimeParser(memoryDos, .entity)
    let messageDos = try await parserDos.parseMessageAsync()
    try await assertSerializationAsync(messageDos, .dos, dos)
}

@Test("ExperimentalMimeParser multipart truncated at end of first boundary")
func experimentalMimeParserMultipartTruncatedAtEndOfFirstBoundary() throws {
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
    let parser = try ExperimentalMimeParser(memory, .entity)
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
    let parserDos = try ExperimentalMimeParser(memoryDos, .entity)
    let messageDos = try parserDos.parseMessage()
    let expectedDos = replacingLastOccurrence(of: boundary, with: boundary + "--", in: text)
    try assertSerialization(messageDos, .dos, ensureTrailingNewline(expectedDos, newline: "\r\n"))
}

@Test("ExperimentalMimeParser multipart truncated at end of first boundary async")
func experimentalMimeParserMultipartTruncatedAtEndOfFirstBoundaryAsync() async throws {
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
    let parser = try ExperimentalMimeParser(memory, .entity)
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
    let parserDos = try ExperimentalMimeParser(memoryDos, .entity)
    let messageDos = try await parserDos.parseMessageAsync()
    let expectedDos = replacingLastOccurrence(of: boundary, with: boundary + "--", in: text)
    try await assertSerializationAsync(messageDos, .dos, ensureTrailingNewline(expectedDos, newline: "\r\n"))
}

@Test("ExperimentalMimeParser multipart truncated at end of second boundary")
func experimentalMimeParserMultipartTruncatedAtEndOfSecondBoundary() throws {
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
    let parser = try ExperimentalMimeParser(memory, .entity)
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
    let parserDos = try ExperimentalMimeParser(memoryDos, .entity)
    let messageDos = try parserDos.parseMessage()
    let expectedDos = replacingLastOccurrence(of: boundary, with: boundary + "--", in: text)
    try assertSerialization(messageDos, .dos, ensureTrailingNewline(expectedDos, newline: "\r\n"))
}

@Test("ExperimentalMimeParser multipart truncated at end of second boundary async")
func experimentalMimeParserMultipartTruncatedAtEndOfSecondBoundaryAsync() async throws {
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
    let parser = try ExperimentalMimeParser(memory, .entity)
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
    let parserDos = try ExperimentalMimeParser(memoryDos, .entity)
    let messageDos = try await parserDos.parseMessageAsync()
    let expectedDos = replacingLastOccurrence(of: boundary, with: boundary + "--", in: text)
    try await assertSerializationAsync(messageDos, .dos, ensureTrailingNewline(expectedDos, newline: "\r\n"))
}

@Test("ExperimentalMimeParser multipart truncated immediately after first boundary")
func experimentalMimeParserMultipartTruncatedImmediatelyAfterFirstBoundary() throws {
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
    let parser = try ExperimentalMimeParser(memory, .entity)
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
    let parserDos = try ExperimentalMimeParser(memoryDos, .entity)
    let messageDos = try parserDos.parseMessage()
    let expectedDos = replacingLastOccurrence(of: boundary, with: boundary + "--", in: text)
    try assertSerialization(messageDos, .dos, ensureTrailingNewline(expectedDos, newline: "\r\n"))
}

@Test("ExperimentalMimeParser multipart truncated immediately after first boundary async")
func experimentalMimeParserMultipartTruncatedImmediatelyAfterFirstBoundaryAsync() async throws {
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
    let parser = try ExperimentalMimeParser(memory, .entity)
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
    let parserDos = try ExperimentalMimeParser(memoryDos, .entity)
    let messageDos = try await parserDos.parseMessageAsync()
    let expectedDos = replacingLastOccurrence(of: boundary, with: boundary + "--", in: text)
    try await assertSerializationAsync(messageDos, .dos, ensureTrailingNewline(expectedDos, newline: "\r\n"))
}

@Test("ExperimentalMimeParser multipart truncated immediately after second boundary")
func experimentalMimeParserMultipartTruncatedImmediatelyAfterSecondBoundary() throws {
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
    let parser = try ExperimentalMimeParser(memory, .entity)
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
    let parserDos = try ExperimentalMimeParser(memoryDos, .entity)
    let messageDos = try parserDos.parseMessage()
    let expectedDos = replacingLastOccurrence(of: boundary, with: boundary + "--", in: text)
    try assertSerialization(messageDos, .dos, ensureTrailingNewline(expectedDos, newline: "\r\n"))
}

@Test("ExperimentalMimeParser multipart truncated immediately after second boundary async")
func experimentalMimeParserMultipartTruncatedImmediatelyAfterSecondBoundaryAsync() async throws {
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
    let parser = try ExperimentalMimeParser(memory, .entity)
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
    let parserDos = try ExperimentalMimeParser(memoryDos, .entity)
    let messageDos = try await parserDos.parseMessageAsync()
    let expectedDos = replacingLastOccurrence(of: boundary, with: boundary + "--", in: text)
    try await assertSerializationAsync(messageDos, .dos, ensureTrailingNewline(expectedDos, newline: "\r\n"))
}

@Test("ExperimentalMimeParser multipart boundary without trailing newline")
func experimentalMimeParserMultipartBoundaryWithoutTrailingNewline() throws {
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
    let parser = try ExperimentalMimeParser(memory, .entity)
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
    let parserDos = try ExperimentalMimeParser(memoryDos, .entity)
    let messageDos = try parserDos.parseMessage()
    let expectedDos = replacingLastOccurrence(of: boundary, with: boundary + "--", in: text)
    try assertSerialization(messageDos, .dos, ensureTrailingNewline(expectedDos, newline: "\r\n"))
}

@Test("ExperimentalMimeParser multipart boundary without trailing newline async")
func experimentalMimeParserMultipartBoundaryWithoutTrailingNewlineAsync() async throws {
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
    let parser = try ExperimentalMimeParser(memory, .entity)
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
    let parserDos = try ExperimentalMimeParser(memoryDos, .entity)
    let messageDos = try await parserDos.parseMessageAsync()
    let expectedDos = replacingLastOccurrence(of: boundary, with: boundary + "--", in: text)
    try await assertSerializationAsync(messageDos, .dos, ensureTrailingNewline(expectedDos, newline: "\r\n"))
}

@Test("ExperimentalMimeParser truncated multipart subpart headers")
func experimentalMimeParserTruncatedMultipartSubpartHeaders() throws {
    var text = """
From: mimekit@example.com
To: mimekit@example.com
Subject: test of truncated multipart subpart headers
Date: Tue, 12 Nov 2013 09:12:42 -0500
MIME-Version: 1.0
Message-ID: <54AD68C9E3B0184CAC6041320424FD1B5B81E74D@localhost.localdomain>
X-Mailer: Microsoft Office Outlook 12.0
Content-Type: multipart/mixed;
\tboundary=\"----=_NextPart_000_003F_01CE98CE.6E826F90\"


------=_NextPart_000_003F_01CE98CE.6E826F90
Content-Type: text/plain; charset=utf-8
""".replacingOccurrences(of: "\r\n", with: "\n")

    let memory = MemoryStream(Array(text.utf8), writable: false)
    let parser = try ExperimentalMimeParser(memory, .entity)
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
    #expect(body.text == "")

    let boundary = "------=_NextPart_000_003F_01CE98CE.6E826F90"
    let expected = ensureTrailingNewline(text, newline: "\n") + "\n" + boundary + "--\n"
    try assertSerialization(message, .unix, expected)

    text = text.replacingOccurrences(of: "\n", with: "\r\n")
    let memoryDos = MemoryStream(Array(text.utf8), writable: false)
    let parserDos = try ExperimentalMimeParser(memoryDos, .entity)
    let messageDos = try parserDos.parseMessage()
    let expectedDos = ensureTrailingNewline(text, newline: "\r\n") + "\r\n" + boundary + "--\r\n"
    try assertSerialization(messageDos, .dos, expectedDos)
}

@Test("ExperimentalMimeParser truncated multipart subpart headers async")
func experimentalMimeParserTruncatedMultipartSubpartHeadersAsync() async throws {
    var text = """
From: mimekit@example.com
To: mimekit@example.com
Subject: test of truncated multipart subpart headers
Date: Tue, 12 Nov 2013 09:12:42 -0500
MIME-Version: 1.0
Message-ID: <54AD68C9E3B0184CAC6041320424FD1B5B81E74D@localhost.localdomain>
X-Mailer: Microsoft Office Outlook 12.0
Content-Type: multipart/mixed;
\tboundary=\"----=_NextPart_000_003F_01CE98CE.6E826F90\"


------=_NextPart_000_003F_01CE98CE.6E826F90
Content-Type: text/plain; charset=utf-8
""".replacingOccurrences(of: "\r\n", with: "\n")

    let memory = MemoryStream(Array(text.utf8), writable: false)
    let parser = try ExperimentalMimeParser(memory, .entity)
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
    #expect(body.text == "")

    let boundary = "------=_NextPart_000_003F_01CE98CE.6E826F90"
    let expected = ensureTrailingNewline(text, newline: "\n") + "\n" + boundary + "--\n"
    try await assertSerializationAsync(message, .unix, expected)

    text = text.replacingOccurrences(of: "\n", with: "\r\n")
    let memoryDos = MemoryStream(Array(text.utf8), writable: false)
    let parserDos = try ExperimentalMimeParser(memoryDos, .entity)
    let messageDos = try await parserDos.parseMessageAsync()
    let expectedDos = ensureTrailingNewline(text, newline: "\r\n") + "\r\n" + boundary + "--\r\n"
    try await assertSerializationAsync(messageDos, .dos, expectedDos)
}

@Test("ExperimentalMimeParser truncated multipart subpart header field name")
func experimentalMimeParserTruncatedMultipartSubpartHeaderFieldName() throws {
    var text = """
From: mimekit@example.com
To: mimekit@example.com
Subject: test of truncated multipart subpart header field name
Date: Tue, 12 Nov 2013 09:12:42 -0500
MIME-Version: 1.0
Message-ID: <54AD68C9E3B0184CAC6041320424FD1B5B81E74D@localhost.localdomain>
X-Mailer: Microsoft Office Outlook 12.0
Content-Type: multipart/mixed;
\tboundary=\"----=_NextPart_000_003F_01CE98CE.6E826F90\"


------=_NextPart_000_003F_01CE98CE.6E826F90
Content-Type: text/plain; charset=utf-8
Content-Dis
""".replacingOccurrences(of: "\r\n", with: "\n")

    let memory = MemoryStream(Array(text.utf8), writable: false)
    let parser = try ExperimentalMimeParser(memory, .entity)
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
    #expect(body.headers.count == 2)
    #expect(body.headers[.contentType] == "text/plain; charset=utf-8")
    #expect(body.contentType.charset == "utf-8")
    #expect(body.headers[1].isInvalid)
    #expect(body.headers[1].field == "Content-Dis")
    #expect(body.text == "")

    let boundary = "------=_NextPart_000_003F_01CE98CE.6E826F90"
    let expected = ensureTrailingNewline(text, newline: "\n") + "\n" + boundary + "--\n"
    try assertSerialization(message, .unix, expected)

    text = text.replacingOccurrences(of: "\n", with: "\r\n")
    let memoryDos = MemoryStream(Array(text.utf8), writable: false)
    let parserDos = try ExperimentalMimeParser(memoryDos, .entity)
    let messageDos = try parserDos.parseMessage()
    let expectedDos = ensureTrailingNewline(text, newline: "\r\n") + "\r\n" + boundary + "--\r\n"
    try assertSerialization(messageDos, .dos, expectedDos)
}

@Test("ExperimentalMimeParser truncated multipart subpart header field name async")
func experimentalMimeParserTruncatedMultipartSubpartHeaderFieldNameAsync() async throws {
    var text = """
From: mimekit@example.com
To: mimekit@example.com
Subject: test of truncated multipart subpart header field name
Date: Tue, 12 Nov 2013 09:12:42 -0500
MIME-Version: 1.0
Message-ID: <54AD68C9E3B0184CAC6041320424FD1B5B81E74D@localhost.localdomain>
X-Mailer: Microsoft Office Outlook 12.0
Content-Type: multipart/mixed;
\tboundary=\"----=_NextPart_000_003F_01CE98CE.6E826F90\"


------=_NextPart_000_003F_01CE98CE.6E826F90
Content-Type: text/plain; charset=utf-8
Content-Dis
""".replacingOccurrences(of: "\r\n", with: "\n")

    let memory = MemoryStream(Array(text.utf8), writable: false)
    let parser = try ExperimentalMimeParser(memory, .entity)
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
    #expect(body.headers.count == 2)
    #expect(body.headers[.contentType] == "text/plain; charset=utf-8")
    #expect(body.contentType.charset == "utf-8")
    #expect(body.headers[1].isInvalid)
    #expect(body.headers[1].field == "Content-Dis")
    #expect(body.text == "")

    let boundary = "------=_NextPart_000_003F_01CE98CE.6E826F90"
    let expected = ensureTrailingNewline(text, newline: "\n") + "\n" + boundary + "--\n"
    try await assertSerializationAsync(message, .unix, expected)

    text = text.replacingOccurrences(of: "\n", with: "\r\n")
    let memoryDos = MemoryStream(Array(text.utf8), writable: false)
    let parserDos = try ExperimentalMimeParser(memoryDos, .entity)
    let messageDos = try await parserDos.parseMessageAsync()
    let expectedDos = ensureTrailingNewline(text, newline: "\r\n") + "\r\n" + boundary + "--\r\n"
    try await assertSerializationAsync(messageDos, .dos, expectedDos)
}

@Test("ExperimentalMimeParser multipart subpart headers end with boundary")
func experimentalMimeParserMultipartSubpartHeadersEndWithBoundary() throws {
    var text = """
From: mimekit@example.com
To: mimekit@example.com
Subject: test of multipart subpart headers ending with a boundary
Date: Tue, 12 Nov 2013 09:12:42 -0500
MIME-Version: 1.0
Message-ID: <54AD68C9E3B0184CAC6041320424FD1B5B81E74D@localhost.localdomain>
X-Mailer: Microsoft Office Outlook 12.0
Content-Type: multipart/mixed;
\tboundary=\"----=_NextPart_000_003F_01CE98CE.6E826F90\"


------=_NextPart_000_003F_01CE98CE.6E826F90
Content-Type: text/plain; charset=utf-8
------=_NextPart_000_003F_01CE98CE.6E826F90--
""".replacingOccurrences(of: "\r\n", with: "\n")

    let memory = MemoryStream(Array(text.utf8), writable: false)
    let parser = try ExperimentalMimeParser(memory, .entity)
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
    #expect(body.text == "")

    let boundary = "------=_NextPart_000_003F_01CE98CE.6E826F90"
    let expected = ensureTrailingNewline(insertBlankLineBeforeEndBoundary(text, boundary: boundary, newline: "\n"), newline: "\n")
    try assertSerialization(message, .unix, expected)

    text = text.replacingOccurrences(of: "\n", with: "\r\n")
    let memoryDos = MemoryStream(Array(text.utf8), writable: false)
    let parserDos = try ExperimentalMimeParser(memoryDos, .entity)
    let messageDos = try parserDos.parseMessage()
    let expectedDos = ensureTrailingNewline(insertBlankLineBeforeEndBoundary(text, boundary: boundary, newline: "\r\n"), newline: "\r\n")
    try assertSerialization(messageDos, .dos, expectedDos)
}

@Test("ExperimentalMimeParser multipart subpart headers end with boundary async")
func experimentalMimeParserMultipartSubpartHeadersEndWithBoundaryAsync() async throws {
    var text = """
From: mimekit@example.com
To: mimekit@example.com
Subject: test of multipart subpart headers ending with a boundary
Date: Tue, 12 Nov 2013 09:12:42 -0500
MIME-Version: 1.0
Message-ID: <54AD68C9E3B0184CAC6041320424FD1B5B81E74D@localhost.localdomain>
X-Mailer: Microsoft Office Outlook 12.0
Content-Type: multipart/mixed;
\tboundary=\"----=_NextPart_000_003F_01CE98CE.6E826F90\"


------=_NextPart_000_003F_01CE98CE.6E826F90
Content-Type: text/plain; charset=utf-8
------=_NextPart_000_003F_01CE98CE.6E826F90--
""".replacingOccurrences(of: "\r\n", with: "\n")

    let memory = MemoryStream(Array(text.utf8), writable: false)
    let parser = try ExperimentalMimeParser(memory, .entity)
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
    #expect(body.text == "")

    let boundary = "------=_NextPart_000_003F_01CE98CE.6E826F90"
    let expected = ensureTrailingNewline(insertBlankLineBeforeEndBoundary(text, boundary: boundary, newline: "\n"), newline: "\n")
    try await assertSerializationAsync(message, .unix, expected)

    text = text.replacingOccurrences(of: "\n", with: "\r\n")
    let memoryDos = MemoryStream(Array(text.utf8), writable: false)
    let parserDos = try ExperimentalMimeParser(memoryDos, .entity)
    let messageDos = try await parserDos.parseMessageAsync()
    let expectedDos = ensureTrailingNewline(insertBlankLineBeforeEndBoundary(text, boundary: boundary, newline: "\r\n"), newline: "\r\n")
    try await assertSerializationAsync(messageDos, .dos, expectedDos)
}

@Test("ExperimentalMimeParser multipart subpart headers line starts with dash dash")
func experimentalMimeParserMultipartSubpartHeadersLineStartsWithDashDash() throws {
    var text = """
From: mimekit@example.com
To: mimekit@example.com
Subject: test of multipart subpart headers line starting with --
Date: Tue, 12 Nov 2013 09:12:42 -0500
MIME-Version: 1.0
Message-ID: <54AD68C9E3B0184CAC6041320424FD1B5B81E74D@localhost.localdomain>
X-Mailer: Microsoft Office Outlook 12.0
Content-Type: multipart/mixed;
\tboundary=\"----=_NextPart_000_003F_01CE98CE.6E826F90\"


------=_NextPart_000_003F_01CE98CE.6E826F90
Content-Type: text/plain; charset=utf-8
--not-the-boundary-muhahaha

This is the message body.

------=_NextPart_000_003F_01CE98CE.6E826F90--
""".replacingOccurrences(of: "\r\n", with: "\n")

    let memory = MemoryStream(Array(text.utf8), writable: false)
    let parser = try ExperimentalMimeParser(memory, .entity)
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
    #expect(body.headers.count == 2)
    #expect(body.headers[1].isInvalid)
    #expect(body.headers[1].field == "--not-the-boundary-muhahaha\n")
    #expect(body.text == "This is the message body.\n")

    let boundary = "------=_NextPart_000_003F_01CE98CE.6E826F90"
    let expected = ensureTrailingNewline(stripBoundaryTrailingWhitespace(text, boundary: boundary), newline: "\n")
    try assertSerialization(message, .unix, expected)

    text = text.replacingOccurrences(of: "\n", with: "\r\n")
    let memoryDos = MemoryStream(Array(text.utf8), writable: false)
    let parserDos = try ExperimentalMimeParser(memoryDos, .entity)
    let messageDos = try parserDos.parseMessage()
    try assertSerialization(messageDos, .dos, ensureTrailingNewline(text, newline: "\r\n"))
}

@Test("ExperimentalMimeParser multipart subpart headers line starts with dash dash async")
func experimentalMimeParserMultipartSubpartHeadersLineStartsWithDashDashAsync() async throws {
    var text = """
From: mimekit@example.com
To: mimekit@example.com
Subject: test of multipart subpart headers line starting with --
Date: Tue, 12 Nov 2013 09:12:42 -0500
MIME-Version: 1.0
Message-ID: <54AD68C9E3B0184CAC6041320424FD1B5B81E74D@localhost.localdomain>
X-Mailer: Microsoft Office Outlook 12.0
Content-Type: multipart/mixed;
\tboundary=\"----=_NextPart_000_003F_01CE98CE.6E826F90\"


------=_NextPart_000_003F_01CE98CE.6E826F90
Content-Type: text/plain; charset=utf-8
--not-the-boundary-muhahaha

This is the message body.

------=_NextPart_000_003F_01CE98CE.6E826F90--
""".replacingOccurrences(of: "\r\n", with: "\n")

    let memory = MemoryStream(Array(text.utf8), writable: false)
    let parser = try ExperimentalMimeParser(memory, .entity)
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
    #expect(body.headers.count == 2)
    #expect(body.headers[1].isInvalid)
    #expect(body.headers[1].field == "--not-the-boundary-muhahaha\n")
    #expect(body.text == "This is the message body.\n")

    try await assertSerializationAsync(message, .unix, ensureTrailingNewline(text, newline: "\n"))

    text = text.replacingOccurrences(of: "\n", with: "\r\n")
    let memoryDos = MemoryStream(Array(text.utf8), writable: false)
    let parserDos = try ExperimentalMimeParser(memoryDos, .entity)
    let messageDos = try await parserDos.parseMessageAsync()
    try await assertSerializationAsync(messageDos, .dos, ensureTrailingNewline(text, newline: "\r\n"))
}

@Test("ExperimentalMimeParser multipart subpart headers line starts with dash dash EOF")
func experimentalMimeParserMultipartSubpartHeadersLineStartsWithDashDashEOF() throws {
    var text = """
From: mimekit@example.com
To: mimekit@example.com
Subject: test of multipart subpart headers line starting with -- <EOF>
Date: Tue, 12 Nov 2013 09:12:42 -0500
MIME-Version: 1.0
Message-ID: <54AD68C9E3B0184CAC6041320424FD1B5B81E74D@localhost.localdomain>
X-Mailer: Microsoft Office Outlook 12.0
Content-Type: multipart/mixed;
\tboundary=\"----=_NextPart_000_003F_01CE98CE.6E826F90\"


------=_NextPart_000_003F_01CE98CE.6E826F90
Content-Type: text/plain; charset=utf-8
--not-the-boundary-muhahaha
""".replacingOccurrences(of: "\r\n", with: "\n")

    let memory = MemoryStream(Array(text.utf8), writable: false)
    let parser = try ExperimentalMimeParser(memory, .entity)
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
    #expect(body.headers.count == 2)
    #expect(body.headers[1].isInvalid)
    #expect(body.headers[1].field == "--not-the-boundary-muhahaha")
    #expect(body.text == "")

    let boundary = "------=_NextPart_000_003F_01CE98CE.6E826F90"
    let expected = ensureTrailingNewline(text, newline: "\n") + "\n" + boundary + "--\n"
    try assertSerialization(message, .unix, expected)

    text = text.replacingOccurrences(of: "\n", with: "\r\n")
    let memoryDos = MemoryStream(Array(text.utf8), writable: false)
    let parserDos = try ExperimentalMimeParser(memoryDos, .entity)
    let messageDos = try parserDos.parseMessage()
    let expectedDos = ensureTrailingNewline(text, newline: "\r\n") + "\r\n" + boundary + "--\r\n"
    try assertSerialization(messageDos, .dos, expectedDos)
}

@Test("ExperimentalMimeParser multipart subpart headers line starts with dash dash EOF async")
func experimentalMimeParserMultipartSubpartHeadersLineStartsWithDashDashEOFAsync() async throws {
    var text = """
From: mimekit@example.com
To: mimekit@example.com
Subject: test of multipart subpart headers line starting with -- <EOF>
Date: Tue, 12 Nov 2013 09:12:42 -0500
MIME-Version: 1.0
Message-ID: <54AD68C9E3B0184CAC6041320424FD1B5B81E74D@localhost.localdomain>
X-Mailer: Microsoft Office Outlook 12.0
Content-Type: multipart/mixed;
\tboundary=\"----=_NextPart_000_003F_01CE98CE.6E826F90\"


------=_NextPart_000_003F_01CE98CE.6E826F90
Content-Type: text/plain; charset=utf-8
--not-the-boundary-muhahaha
""".replacingOccurrences(of: "\r\n", with: "\n")

    let memory = MemoryStream(Array(text.utf8), writable: false)
    let parser = try ExperimentalMimeParser(memory, .entity)
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
    #expect(body.headers.count == 2)
    #expect(body.headers[1].isInvalid)
    #expect(body.headers[1].field == "--not-the-boundary-muhahaha")
    #expect(body.text == "")

    let boundary = "------=_NextPart_000_003F_01CE98CE.6E826F90"
    let expected = ensureTrailingNewline(text, newline: "\n") + "\n" + boundary + "--\n"
    try await assertSerializationAsync(message, .unix, expected)

    text = text.replacingOccurrences(of: "\n", with: "\r\n")
    let memoryDos = MemoryStream(Array(text.utf8), writable: false)
    let parserDos = try ExperimentalMimeParser(memoryDos, .entity)
    let messageDos = try await parserDos.parseMessageAsync()
    let expectedDos = ensureTrailingNewline(text, newline: "\r\n") + "\r\n" + boundary + "--\r\n"
    try await assertSerializationAsync(messageDos, .dos, expectedDos)
}

@Test("ExperimentalMimeParser multipart without end boundary")
func experimentalMimeParserMultipartWithoutEndBoundary() throws {
    var text = """
From: mimekit@example.com
To: mimekit@example.com
Subject: test of a multipart without an end boundary
Date: Tue, 12 Nov 2013 09:12:42 -0500
MIME-Version: 1.0
Message-ID: <54AD68C9E3B0184CAC6041320424FD1B5B81E74D@localhost.localdomain>
X-Mailer: Microsoft Office Outlook 12.0
Content-Type: multipart/mixed;
\tboundary=\"----=_NextPart_000_003F_01CE98CE.6E826F90\"


------=_NextPart_000_003F_01CE98CE.6E826F90
Content-Type: text/plain; charset=utf-8

This is the first part.

------=_NextPart_000_003F_01CE98CE.6E826F90
Content-Type: text/plain; charset=utf-8

This is the second part.
""".replacingOccurrences(of: "\r\n", with: "\n")

    let memory = MemoryStream(Array(text.utf8), writable: false)
    let parser = try ExperimentalMimeParser(memory, .entity)
    let message = try parser.parseMessage()

    guard let multipart = message.body as? Multipart else {
        #expect(Bool(false))
        return
    }
    #expect(multipart.count == 2)
    guard multipart.count >= 2, let first = multipart[0] as? TextPart, let second = multipart[1] as? TextPart else {
        #expect(Bool(false))
        return
    }
    #expect(first.headers[.contentType] == "text/plain; charset=utf-8")
    #expect(first.contentType.charset == "utf-8")
    #expect(first.text == "This is the first part.\n")
    #expect(second.headers[.contentType] == "text/plain; charset=utf-8")
    #expect(second.contentType.charset == "utf-8")
    #expect(second.text == "This is the second part.")

    let boundary = "------=_NextPart_000_003F_01CE98CE.6E826F90"
    let expected = ensureTrailingNewline(text, newline: "\n") + boundary + "--\n"
    try assertSerialization(message, .unix, expected)

    text = text.replacingOccurrences(of: "\n", with: "\r\n")
    let memoryDos = MemoryStream(Array(text.utf8), writable: false)
    let parserDos = try ExperimentalMimeParser(memoryDos, .entity)
    let messageDos = try parserDos.parseMessage()
    let expectedDos = ensureTrailingNewline(text, newline: "\r\n") + boundary + "--\r\n"
    try assertSerialization(messageDos, .dos, expectedDos)
}

@Test("ExperimentalMimeParser multipart without end boundary async")
func experimentalMimeParserMultipartWithoutEndBoundaryAsync() async throws {
    var text = """
From: mimekit@example.com
To: mimekit@example.com
Subject: test of a multipart without an end boundary
Date: Tue, 12 Nov 2013 09:12:42 -0500
MIME-Version: 1.0
Message-ID: <54AD68C9E3B0184CAC6041320424FD1B5B81E74D@localhost.localdomain>
X-Mailer: Microsoft Office Outlook 12.0
Content-Type: multipart/mixed;
\tboundary=\"----=_NextPart_000_003F_01CE98CE.6E826F90\"


------=_NextPart_000_003F_01CE98CE.6E826F90
Content-Type: text/plain; charset=utf-8

This is the first part.

------=_NextPart_000_003F_01CE98CE.6E826F90
Content-Type: text/plain; charset=utf-8

This is the second part.
""".replacingOccurrences(of: "\r\n", with: "\n")

    let memory = MemoryStream(Array(text.utf8), writable: false)
    let parser = try ExperimentalMimeParser(memory, .entity)
    let message = try await parser.parseMessageAsync()

    guard let multipart = message.body as? Multipart else {
        #expect(Bool(false))
        return
    }
    #expect(multipart.count == 2)
    guard multipart.count >= 2, let first = multipart[0] as? TextPart, let second = multipart[1] as? TextPart else {
        #expect(Bool(false))
        return
    }
    #expect(first.headers[.contentType] == "text/plain; charset=utf-8")
    #expect(first.contentType.charset == "utf-8")
    #expect(first.text == "This is the first part.\n")
    #expect(second.headers[.contentType] == "text/plain; charset=utf-8")
    #expect(second.contentType.charset == "utf-8")
    #expect(second.text == "This is the second part.")

    let boundary = "------=_NextPart_000_003F_01CE98CE.6E826F90"
    let expected = ensureTrailingNewline(text, newline: "\n") + boundary + "--\n"
    try await assertSerializationAsync(message, .unix, expected)

    text = text.replacingOccurrences(of: "\n", with: "\r\n")
    let memoryDos = MemoryStream(Array(text.utf8), writable: false)
    let parserDos = try ExperimentalMimeParser(memoryDos, .entity)
    let messageDos = try await parserDos.parseMessageAsync()
    let expectedDos = ensureTrailingNewline(text, newline: "\r\n") + boundary + "--\r\n"
    try await assertSerializationAsync(messageDos, .dos, expectedDos)
}

@Test("ExperimentalMimeParser multipart boundary line with trailing spaces")
func experimentalMimeParserMultipartBoundaryLineWithTrailingSpaces() throws {
    var text = """
From: mimekit@example.com
To: mimekit@example.com
Subject: test of a multipart boundary followed by trailing whitespace
Date: Tue, 12 Nov 2013 09:12:42 -0500
MIME-Version: 1.0
Message-ID: <54AD68C9E3B0184CAC6041320424FD1B5B81E74D@localhost.localdomain>
X-Mailer: Microsoft Office Outlook 12.0
Content-Type: multipart/mixed;
\tboundary=\"----=_NextPart_000_003F_01CE98CE.6E826F90\"


------=_NextPart_000_003F_01CE98CE.6E826F90   
Content-Type: text/plain; charset=utf-8

This is the first part.

------=_NextPart_000_003F_01CE98CE.6E826F90       
Content-Type: text/plain; charset=utf-8

This is the second part.

------=_NextPart_000_003F_01CE98CE.6E826F90--  
""".replacingOccurrences(of: "\r\n", with: "\n")

    let memory = MemoryStream(Array(text.utf8), writable: false)
    let parser = try ExperimentalMimeParser(memory, .entity)
    let message = try parser.parseMessage()

    guard let multipart = message.body as? Multipart else {
        #expect(Bool(false))
        return
    }
    #expect(multipart.count == 2)
    guard multipart.count >= 2, let first = multipart[0] as? TextPart, let second = multipart[1] as? TextPart else {
        #expect(Bool(false))
        return
    }
    #expect(first.text == "This is the first part.\n")
    #expect(second.text == "This is the second part.\n")

    let boundary = "------=_NextPart_000_003F_01CE98CE.6E826F90"
    let expected = ensureTrailingNewline(stripBoundaryTrailingWhitespace(text, boundary: boundary), newline: "\n")
    try assertSerialization(message, .unix, expected)

    text = text.replacingOccurrences(of: "\n", with: "\r\n")
    let memoryDos = MemoryStream(Array(text.utf8), writable: false)
    let parserDos = try ExperimentalMimeParser(memoryDos, .entity)
    let messageDos = try parserDos.parseMessage()
    let expectedDos = ensureTrailingNewline(stripBoundaryTrailingWhitespace(text, boundary: boundary), newline: "\r\n")
    try assertSerialization(messageDos, .dos, expectedDos)
}

@Test("ExperimentalMimeParser multipart boundary line with trailing spaces async")
func experimentalMimeParserMultipartBoundaryLineWithTrailingSpacesAsync() async throws {
    var text = """
From: mimekit@example.com
To: mimekit@example.com
Subject: test of a multipart boundary followed by trailing whitespace
Date: Tue, 12 Nov 2013 09:12:42 -0500
MIME-Version: 1.0
Message-ID: <54AD68C9E3B0184CAC6041320424FD1B5B81E74D@localhost.localdomain>
X-Mailer: Microsoft Office Outlook 12.0
Content-Type: multipart/mixed;
\tboundary=\"----=_NextPart_000_003F_01CE98CE.6E826F90\"


------=_NextPart_000_003F_01CE98CE.6E826F90   
Content-Type: text/plain; charset=utf-8

This is the first part.

------=_NextPart_000_003F_01CE98CE.6E826F90       
Content-Type: text/plain; charset=utf-8

This is the second part.

------=_NextPart_000_003F_01CE98CE.6E826F90--  
""".replacingOccurrences(of: "\r\n", with: "\n")

    let memory = MemoryStream(Array(text.utf8), writable: false)
    let parser = try ExperimentalMimeParser(memory, .entity)
    let message = try await parser.parseMessageAsync()

    guard let multipart = message.body as? Multipart else {
        #expect(Bool(false))
        return
    }
    #expect(multipart.count == 2)
    guard multipart.count >= 2, let first = multipart[0] as? TextPart, let second = multipart[1] as? TextPart else {
        #expect(Bool(false))
        return
    }
    #expect(first.text == "This is the first part.\n")
    #expect(second.text == "This is the second part.\n")

    let boundary = "------=_NextPart_000_003F_01CE98CE.6E826F90"
    let expected = ensureTrailingNewline(stripBoundaryTrailingWhitespace(text, boundary: boundary), newline: "\n")
    try await assertSerializationAsync(message, .unix, expected)

    text = text.replacingOccurrences(of: "\n", with: "\r\n")
    let memoryDos = MemoryStream(Array(text.utf8), writable: false)
    let parserDos = try ExperimentalMimeParser(memoryDos, .entity)
    let messageDos = try await parserDos.parseMessageAsync()
    let expectedDos = ensureTrailingNewline(stripBoundaryTrailingWhitespace(text, boundary: boundary), newline: "\r\n")
    try await assertSerializationAsync(messageDos, .dos, expectedDos)
}

@Test("ExperimentalMimeParser multipart boundary line with trailing spaces and then more characters")
func experimentalMimeParserMultipartBoundaryLineWithTrailingSpacesAndThenMoreCharacters() throws {
    var text = """
From: mimekit@example.com
To: mimekit@example.com
Subject: test of a multipart boundary followed by trailing whitespace and then more characters
Date: Tue, 12 Nov 2013 09:12:42 -0500
MIME-Version: 1.0
Message-ID: <54AD68C9E3B0184CAC6041320424FD1B5B81E74D@localhost.localdomain>
X-Mailer: Microsoft Office Outlook 12.0
Content-Type: multipart/mixed;
\tboundary=\"----=_NextPart_000_003F_01CE98CE.6E826F90\"


------=_NextPart_000_003F_01CE98CE.6E826F90
Content-Type: text/plain; charset=utf-8

This is the first part.

------=_NextPart_000_003F_01CE98CE.6E826F90       oops, not it.
------=_NextPart_000_003F_01CE98CE.6E826F90
Content-Type: text/plain; charset=utf-8

This is the second part.

------=_NextPart_000_003F_01CE98CE.6E826F90--
""".replacingOccurrences(of: "\r\n", with: "\n")

    let memory = MemoryStream(Array(text.utf8), writable: false)
    let parser = try ExperimentalMimeParser(memory, .entity)
    let message = try parser.parseMessage()

    guard let multipart = message.body as? Multipart else {
        #expect(Bool(false))
        return
    }
    #expect(multipart.count == 2)
    guard multipart.count >= 2, let first = multipart[0] as? TextPart, let second = multipart[1] as? TextPart else {
        #expect(Bool(false))
        return
    }
    #expect(first.text == "This is the first part.\n\n------=_NextPart_000_003F_01CE98CE.6E826F90       oops, not it.")
    #expect(second.text == "This is the second part.\n")

    try assertSerialization(message, .unix, ensureTrailingNewline(text, newline: "\n"))

    text = text.replacingOccurrences(of: "\n", with: "\r\n")
    let memoryDos = MemoryStream(Array(text.utf8), writable: false)
    let parserDos = try ExperimentalMimeParser(memoryDos, .entity)
    let messageDos = try parserDos.parseMessage()
    try assertSerialization(messageDos, .dos, ensureTrailingNewline(text, newline: "\r\n"))
}

@Test("ExperimentalMimeParser multipart boundary line with trailing spaces and then more characters async")
func experimentalMimeParserMultipartBoundaryLineWithTrailingSpacesAndThenMoreCharactersAsync() async throws {
    var text = """
From: mimekit@example.com
To: mimekit@example.com
Subject: test of a multipart boundary followed by trailing whitespace and then more characters
Date: Tue, 12 Nov 2013 09:12:42 -0500
MIME-Version: 1.0
Message-ID: <54AD68C9E3B0184CAC6041320424FD1B5B81E74D@localhost.localdomain>
X-Mailer: Microsoft Office Outlook 12.0
Content-Type: multipart/mixed;
\tboundary=\"----=_NextPart_000_003F_01CE98CE.6E826F90\"


------=_NextPart_000_003F_01CE98CE.6E826F90
Content-Type: text/plain; charset=utf-8

This is the first part.

------=_NextPart_000_003F_01CE98CE.6E826F90       oops, not it.
------=_NextPart_000_003F_01CE98CE.6E826F90
Content-Type: text/plain; charset=utf-8

This is the second part.

------=_NextPart_000_003F_01CE98CE.6E826F90--
""".replacingOccurrences(of: "\r\n", with: "\n")

    let memory = MemoryStream(Array(text.utf8), writable: false)
    let parser = try ExperimentalMimeParser(memory, .entity)
    let message = try await parser.parseMessageAsync()

    guard let multipart = message.body as? Multipart else {
        #expect(Bool(false))
        return
    }
    #expect(multipart.count == 2)
    guard multipart.count >= 2, let first = multipart[0] as? TextPart, let second = multipart[1] as? TextPart else {
        #expect(Bool(false))
        return
    }
    #expect(first.text == "This is the first part.\n\n------=_NextPart_000_003F_01CE98CE.6E826F90       oops, not it.")
    #expect(second.text == "This is the second part.\n")

    try await assertSerializationAsync(message, .unix, ensureTrailingNewline(text, newline: "\n"))

    text = text.replacingOccurrences(of: "\n", with: "\r\n")
    let memoryDos = MemoryStream(Array(text.utf8), writable: false)
    let parserDos = try ExperimentalMimeParser(memoryDos, .entity)
    let messageDos = try await parserDos.parseMessageAsync()
    try await assertSerializationAsync(messageDos, .dos, ensureTrailingNewline(text, newline: "\r\n"))
}

@Test("ExperimentalMimeParser multipart double boundary")
func experimentalMimeParserMultipartDoubleBoundary() throws {
    var text = """
From: mimekit@example.com
To: mimekit@example.com
Subject: test of double multipart boundaries
Date: Tue, 12 Nov 2013 09:12:42 -0500
MIME-Version: 1.0
Message-ID: <54AD68C9E3B0184CAC6041320424FD1B5B81E74D@localhost.localdomain>
X-Mailer: Microsoft Office Outlook 12.0
Content-Type: multipart/mixed;
\tboundary=\"----=_NextPart_000_003F_01CE98CE.6E826F90\"


------=_NextPart_000_003F_01CE98CE.6E826F90
Content-Type: text/plain; charset=utf-8

This is the first part.

------=_NextPart_000_003F_01CE98CE.6E826F90
------=_NextPart_000_003F_01CE98CE.6E826F90
Content-Type: text/plain; charset=utf-8

This is technically the third part.

------=_NextPart_000_003F_01CE98CE.6E826F90--
""".replacingOccurrences(of: "\r\n", with: "\n")

    let memory = MemoryStream(Array(text.utf8), writable: false)
    let parser = try ExperimentalMimeParser(memory, .entity)
    let message = try parser.parseMessage()

    guard let multipart = message.body as? Multipart else {
        #expect(Bool(false))
        return
    }
    #expect(multipart.count == 2)
    guard multipart.count >= 2,
          let first = multipart[0] as? TextPart,
          let second = multipart[1] as? TextPart else {
        #expect(Bool(false))
        return
    }
    #expect(first.text == "This is the first part.\n")
    #expect(second.text == "This is technically the third part.\n")

    let boundary = "------=_NextPart_000_003F_01CE98CE.6E826F90"
    let expected = ensureTrailingNewline(collapseDoubleBoundaryLines(text, boundary: boundary, newline: "\n"), newline: "\n")
    try assertSerialization(message, .unix, expected)

    text = text.replacingOccurrences(of: "\n", with: "\r\n")
    let memoryDos = MemoryStream(Array(text.utf8), writable: false)
    let parserDos = try ExperimentalMimeParser(memoryDos, .entity)
    let messageDos = try parserDos.parseMessage()
    let expectedDos = ensureTrailingNewline(collapseDoubleBoundaryLines(text, boundary: boundary, newline: "\r\n"), newline: "\r\n")
    try assertSerialization(messageDos, .dos, expectedDos)
}

@Test("ExperimentalMimeParser multipart double boundary async")
func experimentalMimeParserMultipartDoubleBoundaryAsync() async throws {
    var text = """
From: mimekit@example.com
To: mimekit@example.com
Subject: test of double multipart boundaries
Date: Tue, 12 Nov 2013 09:12:42 -0500
MIME-Version: 1.0
Message-ID: <54AD68C9E3B0184CAC6041320424FD1B5B81E74D@localhost.localdomain>
X-Mailer: Microsoft Office Outlook 12.0
Content-Type: multipart/mixed;
\tboundary=\"----=_NextPart_000_003F_01CE98CE.6E826F90\"


------=_NextPart_000_003F_01CE98CE.6E826F90
Content-Type: text/plain; charset=utf-8

This is the first part.

------=_NextPart_000_003F_01CE98CE.6E826F90
------=_NextPart_000_003F_01CE98CE.6E826F90
Content-Type: text/plain; charset=utf-8

This is technically the third part.

------=_NextPart_000_003F_01CE98CE.6E826F90--
""".replacingOccurrences(of: "\r\n", with: "\n")

    let memory = MemoryStream(Array(text.utf8), writable: false)
    let parser = try ExperimentalMimeParser(memory, .entity)
    let message = try await parser.parseMessageAsync()

    guard let multipart = message.body as? Multipart else {
        #expect(Bool(false))
        return
    }
    #expect(multipart.count == 2)
    guard multipart.count >= 2,
          let first = multipart[0] as? TextPart,
          let second = multipart[1] as? TextPart else {
        #expect(Bool(false))
        return
    }
    #expect(first.text == "This is the first part.\n")
    #expect(second.text == "This is technically the third part.\n")

    let boundary = "------=_NextPart_000_003F_01CE98CE.6E826F90"
    let expected = ensureTrailingNewline(collapseDoubleBoundaryLines(text, boundary: boundary, newline: "\n"), newline: "\n")
    try await assertSerializationAsync(message, .unix, expected)

    text = text.replacingOccurrences(of: "\n", with: "\r\n")
    let memoryDos = MemoryStream(Array(text.utf8), writable: false)
    let parserDos = try ExperimentalMimeParser(memoryDos, .entity)
    let messageDos = try await parserDos.parseMessageAsync()
    let expectedDos = ensureTrailingNewline(collapseDoubleBoundaryLines(text, boundary: boundary, newline: "\r\n"), newline: "\r\n")
    try await assertSerializationAsync(messageDos, .dos, expectedDos)
}

@Test("ExperimentalMimeParser issue 991 mbox offsets")
func experimentalMimeParserIssue991() throws {
    let (memory, expectedOffsets) = createIssue991Mbox()
    let parser = try ExperimentalMimeParser(memory, .mbox)
    var index = 0

    while !parser.isEndOfStream {
        let message = try parser.parseMessage()
        #expect(parser.position == expectedOffsets[index])
        #expect(message.messageId == "1234567890.\(index)@example.org")
        index += 1
    }
}

@Test("ExperimentalMimeParser issue 991 mbox offsets async")
func experimentalMimeParserIssue991Async() async throws {
    let (memory, expectedOffsets) = createIssue991Mbox()
    let parser = try ExperimentalMimeParser(memory, .mbox)
    var index = 0

    while !parser.isEndOfStream {
        let message = try await parser.parseMessageAsync()
        #expect(parser.position == expectedOffsets[index])
        #expect(message.messageId == "1234567890.\(index)@example.org")
        index += 1
    }
}

@Test("ExperimentalMimeParser mbox with lines exceeding max SMTP line length")
func experimentalMimeParserMboxWithLinesExceedingMaxSmtpLineLength() throws {
    let (memory, expectedOffsets) = createMboxWithLinesExceedingMaxSmtpLineLength()
    let parser = try ExperimentalMimeParser(memory, .mbox)
    var index = 0

    while !parser.isEndOfStream {
        let message = try parser.parseMessage()
        #expect(parser.position == expectedOffsets[index])
        #expect(message.messageId == "1234567890.\(index)@example.org")
        index += 1
    }
}

@Test("ExperimentalMimeParser mbox with lines exceeding max SMTP line length async")
func experimentalMimeParserMboxWithLinesExceedingMaxSmtpLineLengthAsync() async throws {
    let (memory, expectedOffsets) = createMboxWithLinesExceedingMaxSmtpLineLength()
    let parser = try ExperimentalMimeParser(memory, .mbox)
    var index = 0

    while !parser.isEndOfStream {
        let message = try await parser.parseMessageAsync()
        #expect(parser.position == expectedOffsets[index])
        #expect(message.messageId == "1234567890.\(index)@example.org")
        index += 1
    }
}

@Test("ExperimentalMimeParser multipart double boundary end boundary")
func experimentalMimeParserMultipartDoubleBoundaryEndBoundary() throws {
    var text = """
From: mimekit@example.com
To: mimekit@example.com
Subject: test of double multipart boundaries and then an end boundary
Date: Tue, 12 Nov 2013 09:12:42 -0500
MIME-Version: 1.0
Message-ID: <54AD68C9E3B0184CAC6041320424FD1B5B81E74D@localhost.localdomain>
X-Mailer: Microsoft Office Outlook 12.0
Content-Type: multipart/mixed;
\tboundary=\"----=_NextPart_000_003F_01CE98CE.6E826F90\"


------=_NextPart_000_003F_01CE98CE.6E826F90
Content-Type: text/plain; charset=utf-8

This is the first part.

------=_NextPart_000_003F_01CE98CE.6E826F90
Content-Type: text/plain; charset=utf-8

This is the second part.

------=_NextPart_000_003F_01CE98CE.6E826F90
------=_NextPart_000_003F_01CE98CE.6E826F90
------=_NextPart_000_003F_01CE98CE.6E826F90--
""".replacingOccurrences(of: "\r\n", with: "\n")

    let memory = MemoryStream(Array(text.utf8), writable: false)
    let parser = try ExperimentalMimeParser(memory, .entity)
    let message = try parser.parseMessage()

    guard let multipart = message.body as? Multipart else {
        #expect(Bool(false))
        return
    }
    #expect(multipart.count == 2)
    guard multipart.count >= 2,
          let first = multipart[0] as? TextPart,
          let second = multipart[1] as? TextPart else {
        #expect(Bool(false))
        return
    }
    #expect(first.text == "This is the first part.\n")
    #expect(second.text == "This is the second part.\n")

    let boundary = "------=_NextPart_000_003F_01CE98CE.6E826F90"
    let expected = ensureTrailingNewline(collapseDoubleBoundaryEndSequence(text, boundary: boundary, newline: "\n"), newline: "\n")
    try assertSerialization(message, .unix, expected)

    text = text.replacingOccurrences(of: "\n", with: "\r\n")
    let memoryDos = MemoryStream(Array(text.utf8), writable: false)
    let parserDos = try ExperimentalMimeParser(memoryDos, .entity)
    let messageDos = try parserDos.parseMessage()
    let expectedDos = ensureTrailingNewline(collapseDoubleBoundaryEndSequence(text, boundary: boundary, newline: "\r\n"), newline: "\r\n")
    try assertSerialization(messageDos, .dos, expectedDos)
}

@Test("ExperimentalMimeParser multipart double boundary end boundary async")
func experimentalMimeParserMultipartDoubleBoundaryEndBoundaryAsync() async throws {
    var text = """
From: mimekit@example.com
To: mimekit@example.com
Subject: test of double multipart boundaries and then an end boundary
Date: Tue, 12 Nov 2013 09:12:42 -0500
MIME-Version: 1.0
Message-ID: <54AD68C9E3B0184CAC6041320424FD1B5B81E74D@localhost.localdomain>
X-Mailer: Microsoft Office Outlook 12.0
Content-Type: multipart/mixed;
\tboundary=\"----=_NextPart_000_003F_01CE98CE.6E826F90\"


------=_NextPart_000_003F_01CE98CE.6E826F90
Content-Type: text/plain; charset=utf-8

This is the first part.

------=_NextPart_000_003F_01CE98CE.6E826F90
Content-Type: text/plain; charset=utf-8

This is the second part.

------=_NextPart_000_003F_01CE98CE.6E826F90
------=_NextPart_000_003F_01CE98CE.6E826F90
------=_NextPart_000_003F_01CE98CE.6E826F90--
""".replacingOccurrences(of: "\r\n", with: "\n")

    let memory = MemoryStream(Array(text.utf8), writable: false)
    let parser = try ExperimentalMimeParser(memory, .entity)
    let message = try await parser.parseMessageAsync()

    guard let multipart = message.body as? Multipart else {
        #expect(Bool(false))
        return
    }
    #expect(multipart.count == 2)
    guard multipart.count >= 2,
          let first = multipart[0] as? TextPart,
          let second = multipart[1] as? TextPart else {
        #expect(Bool(false))
        return
    }
    #expect(first.text == "This is the first part.\n")
    #expect(second.text == "This is the second part.\n")

    let boundary = "------=_NextPart_000_003F_01CE98CE.6E826F90"
    let expected = ensureTrailingNewline(collapseDoubleBoundaryEndSequence(text, boundary: boundary, newline: "\n"), newline: "\n")
    try await assertSerializationAsync(message, .unix, expected)

    text = text.replacingOccurrences(of: "\n", with: "\r\n")
    let memoryDos = MemoryStream(Array(text.utf8), writable: false)
    let parserDos = try ExperimentalMimeParser(memoryDos, .entity)
    let messageDos = try await parserDos.parseMessageAsync()
    let expectedDos = ensureTrailingNewline(collapseDoubleBoundaryEndSequence(text, boundary: boundary, newline: "\r\n"), newline: "\r\n")
    try await assertSerializationAsync(messageDos, .dos, expectedDos)
}

@Test("ExperimentalMimeParser multipart double boundary EOF")
func experimentalMimeParserMultipartDoubleBoundaryEOF() throws {
    var text = """
From: mimekit@example.com
To: mimekit@example.com
Subject: test of multipart ending with a double boundary
Date: Tue, 12 Nov 2013 09:12:42 -0500
MIME-Version: 1.0
Message-ID: <54AD68C9E3B0184CAC6041320424FD1B5B81E74D@localhost.localdomain>
X-Mailer: Microsoft Office Outlook 12.0
Content-Type: multipart/mixed;
\tboundary=\"----=_NextPart_000_003F_01CE98CE.6E826F90\"


------=_NextPart_000_003F_01CE98CE.6E826F90
Content-Type: text/plain; charset=utf-8

This is the first part.

------=_NextPart_000_003F_01CE98CE.6E826F90
Content-Type: text/plain; charset=utf-8

This is the second part.

------=_NextPart_000_003F_01CE98CE.6E826F90
------=_NextPart_000_003F_01CE98CE.6E826F90
""".replacingOccurrences(of: "\r\n", with: "\n")

    let memory = MemoryStream(Array(text.utf8), writable: false)
    let parser = try ExperimentalMimeParser(memory, .entity)
    let message = try parser.parseMessage()

    guard let multipart = message.body as? Multipart else {
        #expect(Bool(false))
        return
    }
    #expect(multipart.count == 2)
    guard multipart.count >= 2,
          let first = multipart[0] as? TextPart,
          let second = multipart[1] as? TextPart else {
        #expect(Bool(false))
        return
    }
    #expect(first.text == "This is the first part.\n")
    #expect(second.text == "This is the second part.\n")

    let boundary = "------=_NextPart_000_003F_01CE98CE.6E826F90"
    var expected = collapseDoubleBoundaryLinesAtEOF(text, boundary: boundary, newline: "\n")
    expected = replacingLastOccurrence(of: boundary, with: boundary + "--", in: expected)
    expected = ensureTrailingNewline(expected, newline: "\n")
    try assertSerialization(message, .unix, expected)

    text = text.replacingOccurrences(of: "\n", with: "\r\n")
    let memoryDos = MemoryStream(Array(text.utf8), writable: false)
    let parserDos = try ExperimentalMimeParser(memoryDos, .entity)
    let messageDos = try parserDos.parseMessage()
    var expectedDos = collapseDoubleBoundaryLinesAtEOF(text, boundary: boundary, newline: "\r\n")
    expectedDos = replacingLastOccurrence(of: boundary, with: boundary + "--", in: expectedDos)
    expectedDos = ensureTrailingNewline(expectedDos, newline: "\r\n")
    try assertSerialization(messageDos, .dos, expectedDos)
}

@Test("ExperimentalMimeParser multipart double boundary EOF async")
func experimentalMimeParserMultipartDoubleBoundaryEOFAsync() async throws {
    var text = """
From: mimekit@example.com
To: mimekit@example.com
Subject: test of multipart ending with a double boundary
Date: Tue, 12 Nov 2013 09:12:42 -0500
MIME-Version: 1.0
Message-ID: <54AD68C9E3B0184CAC6041320424FD1B5B81E74D@localhost.localdomain>
X-Mailer: Microsoft Office Outlook 12.0
Content-Type: multipart/mixed;
\tboundary=\"----=_NextPart_000_003F_01CE98CE.6E826F90\"


------=_NextPart_000_003F_01CE98CE.6E826F90
Content-Type: text/plain; charset=utf-8

This is the first part.

------=_NextPart_000_003F_01CE98CE.6E826F90
Content-Type: text/plain; charset=utf-8

This is the second part.

------=_NextPart_000_003F_01CE98CE.6E826F90
------=_NextPart_000_003F_01CE98CE.6E826F90
""".replacingOccurrences(of: "\r\n", with: "\n")

    let memory = MemoryStream(Array(text.utf8), writable: false)
    let parser = try ExperimentalMimeParser(memory, .entity)
    let message = try await parser.parseMessageAsync()

    guard let multipart = message.body as? Multipart else {
        #expect(Bool(false))
        return
    }
    #expect(multipart.count == 2)
    guard multipart.count >= 2,
          let first = multipart[0] as? TextPart,
          let second = multipart[1] as? TextPart else {
        #expect(Bool(false))
        return
    }
    #expect(first.text == "This is the first part.\n")
    #expect(second.text == "This is the second part.\n")

    let boundary = "------=_NextPart_000_003F_01CE98CE.6E826F90"
    var expected = collapseDoubleBoundaryLinesAtEOF(text, boundary: boundary, newline: "\n")
    expected = replacingLastOccurrence(of: boundary, with: boundary + "--", in: expected)
    expected = ensureTrailingNewline(expected, newline: "\n")
    try await assertSerializationAsync(message, .unix, expected)

    text = text.replacingOccurrences(of: "\n", with: "\r\n")
    let memoryDos = MemoryStream(Array(text.utf8), writable: false)
    let parserDos = try ExperimentalMimeParser(memoryDos, .entity)
    let messageDos = try await parserDos.parseMessageAsync()
    var expectedDos = collapseDoubleBoundaryLinesAtEOF(text, boundary: boundary, newline: "\r\n")
    expectedDos = replacingLastOccurrence(of: boundary, with: boundary + "--", in: expectedDos)
    expectedDos = ensureTrailingNewline(expectedDos, newline: "\r\n")
    try await assertSerializationAsync(messageDos, .dos, expectedDos)
}

@Test("ExperimentalMimeParser multipart double boundary parent boundary")
func experimentalMimeParserMultipartDoubleBoundaryParentBoundary() throws {
    var text = """
From: mimekit@example.com
To: mimekit@example.com
Subject: test of multipart with double boundaries and then a parent boundary
Date: Tue, 12 Nov 2013 09:12:42 -0500
MIME-Version: 1.0
Message-ID: <54AD68C9E3B0184CAC6041320424FD1B5B81E74D@localhost.localdomain>
Content-Type: multipart/mixed;
\tboundary=\"outer-boundary\"

--outer-boundary
Content-Type: multipart/mixed;
\tboundary=\"inner-boundary\"

--inner-boundary
Content-Type: text/plain; charset=utf-8

This is the first part.

--inner-boundary
Content-Type: text/plain; charset=utf-8

This is the second part.

--inner-boundary
--inner-boundary
--outer-boundary
Content-Type: image/jpeg

<base64 data>
--outer-boundary--
""".replacingOccurrences(of: "\r\n", with: "\n")

    let memory = MemoryStream(Array(text.utf8), writable: false)
    let parser = try ExperimentalMimeParser(memory, .entity)
    let message = try parser.parseMessage()

    guard let outer = message.body as? Multipart else {
        #expect(Bool(false))
        return
    }
    #expect(outer.count == 2)
    guard outer.count >= 2, let inner = outer[0] as? Multipart, let image = outer[1] as? MimePart else {
        #expect(Bool(false))
        return
    }
    #expect(inner.count == 2)
    #expect(image.contentType.mimeType == "image/jpeg")

    guard inner.count >= 2,
          let first = inner[0] as? TextPart,
          let second = inner[1] as? TextPart else {
        #expect(Bool(false))
        return
    }
    #expect(first.text == "This is the first part.\n")
    #expect(second.text == "This is the second part.\n")

    let expected = ensureTrailingNewline(
        text.replacingOccurrences(
            of: "--inner-boundary\n--inner-boundary\n--outer-boundary",
            with: "--inner-boundary--\n\n--outer-boundary"
        ),
        newline: "\n"
    )
    try assertSerialization(message, .unix, expected)

    text = text.replacingOccurrences(of: "\n", with: "\r\n")
    let memoryDos = MemoryStream(Array(text.utf8), writable: false)
    let parserDos = try ExperimentalMimeParser(memoryDos, .entity)
    let messageDos = try parserDos.parseMessage()
    let expectedDos = ensureTrailingNewline(
        text.replacingOccurrences(
            of: "--inner-boundary\r\n--inner-boundary\r\n--outer-boundary",
            with: "--inner-boundary--\r\n\r\n--outer-boundary"
        ),
        newline: "\r\n"
    )
    try assertSerialization(messageDos, .dos, expectedDos)
}

@Test("ExperimentalMimeParser multipart double boundary parent boundary async")
func experimentalMimeParserMultipartDoubleBoundaryParentBoundaryAsync() async throws {
    var text = """
From: mimekit@example.com
To: mimekit@example.com
Subject: test of multipart with double boundaries and then a parent boundary
Date: Tue, 12 Nov 2013 09:12:42 -0500
MIME-Version: 1.0
Message-ID: <54AD68C9E3B0184CAC6041320424FD1B5B81E74D@localhost.localdomain>
Content-Type: multipart/mixed;
\tboundary=\"outer-boundary\"

--outer-boundary
Content-Type: multipart/mixed;
\tboundary=\"inner-boundary\"

--inner-boundary
Content-Type: text/plain; charset=utf-8

This is the first part.

--inner-boundary
Content-Type: text/plain; charset=utf-8

This is the second part.

--inner-boundary
--inner-boundary
--outer-boundary
Content-Type: image/jpeg

<base64 data>
--outer-boundary--
""".replacingOccurrences(of: "\r\n", with: "\n")

    let memory = MemoryStream(Array(text.utf8), writable: false)
    let parser = try ExperimentalMimeParser(memory, .entity)
    let message = try await parser.parseMessageAsync()

    guard let outer = message.body as? Multipart else {
        #expect(Bool(false))
        return
    }
    #expect(outer.count == 2)
    guard outer.count >= 2, let inner = outer[0] as? Multipart, let image = outer[1] as? MimePart else {
        #expect(Bool(false))
        return
    }
    #expect(inner.count == 2)
    #expect(image.contentType.mimeType == "image/jpeg")

    guard inner.count >= 2,
          let first = inner[0] as? TextPart,
          let second = inner[1] as? TextPart else {
        #expect(Bool(false))
        return
    }
    #expect(first.text == "This is the first part.\n")
    #expect(second.text == "This is the second part.\n")

    let expected = ensureTrailingNewline(
        text.replacingOccurrences(
            of: "--inner-boundary\n--inner-boundary\n--outer-boundary",
            with: "--inner-boundary--\n\n--outer-boundary"
        ),
        newline: "\n"
    )
    try await assertSerializationAsync(message, .unix, expected)

    text = text.replacingOccurrences(of: "\n", with: "\r\n")
    let memoryDos = MemoryStream(Array(text.utf8), writable: false)
    let parserDos = try ExperimentalMimeParser(memoryDos, .entity)
    let messageDos = try await parserDos.parseMessageAsync()
    let expectedDos = ensureTrailingNewline(
        text.replacingOccurrences(
            of: "--inner-boundary\r\n--inner-boundary\r\n--outer-boundary",
            with: "--inner-boundary--\r\n\r\n--outer-boundary"
        ),
        newline: "\r\n"
    )
    try await assertSerializationAsync(messageDos, .dos, expectedDos)
}

@Test("ExperimentalMimeParser multipart without boundary parameter")
func experimentalMimeParserMultipartWithoutBoundaryParameter() throws {
    var text = """
Content-Type: multipart/mixed

------=_NextPart_000_003F_01CE98CE.6E826F90
Content-Type: text/plain; charset=utf-8

This is the first part.

------=_NextPart_000_003F_01CE98CE.6E826F90
Content-Type: text/plain; charset=utf-8

This is the second part.

------=_NextPart_000_003F_01CE98CE.6E826F90--
""".replacingOccurrences(of: "\r\n", with: "\n")

    let dashes = text.range(of: "--")?.lowerBound ?? text.startIndex
    let preamble = String(text[dashes...])

    let memory = MemoryStream(Array(text.utf8), writable: false)
    let parser = try ExperimentalMimeParser(memory, .entity)
    let multipart = try parser.parseEntity() as? Multipart

    guard let multipart else {
        #expect(Bool(false))
        return
    }
    #expect(multipart.boundary.isEmpty)
    #expect(multipart.count == 0)
    #expect(multipart.preamble == ensureTrailingNewline(preamble, newline: "\n"))

    try assertSerialization(multipart, .unix, ensureTrailingNewline(text, newline: "\n"))

    text = text.replacingOccurrences(of: "\n", with: "\r\n")
    let memoryDos = MemoryStream(Array(text.utf8), writable: false)
    let parserDos = try ExperimentalMimeParser(memoryDos, .entity)
    let multipartDos = try parserDos.parseEntity() as? Multipart

    guard let multipartDos else {
        #expect(Bool(false))
        return
    }
    #expect(multipartDos.boundary.isEmpty)
    #expect(multipartDos.count == 0)
    #expect(multipartDos.preamble == ensureTrailingNewline(preamble, newline: "\n"))

    try assertSerialization(multipartDos, .dos, ensureTrailingNewline(text, newline: "\r\n"))
}

@Test("ExperimentalMimeParser multipart without boundary parameter async")
func experimentalMimeParserMultipartWithoutBoundaryParameterAsync() async throws {
    var text = """
Content-Type: multipart/mixed

------=_NextPart_000_003F_01CE98CE.6E826F90
Content-Type: text/plain; charset=utf-8

This is the first part.

------=_NextPart_000_003F_01CE98CE.6E826F90
Content-Type: text/plain; charset=utf-8

This is the second part.

------=_NextPart_000_003F_01CE98CE.6E826F90--
""".replacingOccurrences(of: "\r\n", with: "\n")

    let dashes = text.range(of: "--")?.lowerBound ?? text.startIndex
    let preamble = String(text[dashes...])

    let memory = MemoryStream(Array(text.utf8), writable: false)
    let parser = try ExperimentalMimeParser(memory, .entity)
    let multipart = try await parser.parseEntityAsync() as? Multipart

    guard let multipart else {
        #expect(Bool(false))
        return
    }
    #expect(multipart.boundary.isEmpty)
    #expect(multipart.count == 0)
    #expect(multipart.preamble == ensureTrailingNewline(preamble, newline: "\n"))

    try await assertSerializationAsync(multipart, .unix, ensureTrailingNewline(text, newline: "\n"))

    text = text.replacingOccurrences(of: "\n", with: "\r\n")
    let memoryDos = MemoryStream(Array(text.utf8), writable: false)
    let parserDos = try ExperimentalMimeParser(memoryDos, .entity)
    let multipartDos = try await parserDos.parseEntityAsync() as? Multipart

    guard let multipartDos else {
        #expect(Bool(false))
        return
    }
    #expect(multipartDos.boundary.isEmpty)
    #expect(multipartDos.count == 0)
    #expect(multipartDos.preamble == ensureTrailingNewline(preamble, newline: "\n"))

    try await assertSerializationAsync(multipartDos, .dos, ensureTrailingNewline(text, newline: "\r\n"))
}
