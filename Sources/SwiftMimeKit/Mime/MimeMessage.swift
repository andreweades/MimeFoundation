//
// MimeMessage.swift
//
// Ported from MimeKit (C#) to Swift.
//

import Foundation
public enum MimeMessageError: Error, Equatable {
    case invalidMaxLineLength
    case nilStream
}

public final class MimeMessage {
    public let headers: HeaderList
    public var body: MimeEntity?
    public let from: InternetAddressList
    public let to: InternetAddressList
    public var subject: String? {
        didSet {
            if let subject, !subject.isEmpty {
                headers[.subject] = subject
            } else {
                headers.removeAll(.subject)
            }
        }
    }

    public init() {
        self.headers = HeaderList()
        self.from = InternetAddressList()
        self.to = InternetAddressList()

        from.changed = { [weak self] _ in
            self?.updateAddressHeader(.from, list: self?.from)
        }
        to.changed = { [weak self] _ in
            self?.updateAddressHeader(.to, list: self?.to)
        }
    }

    public func prepare(_ constraint: EncodingConstraint, maxLineLength: Int = FormatOptions.defaultMaxLineLength) throws {
        if maxLineLength < FormatOptions.minimumLineLength || maxLineLength > FormatOptions.maximumLineLength {
            throw MimeMessageError.invalidMaxLineLength
        }

        if let part = body as? MimePart {
            try part.prepare(constraint)
        } else if let messagePart = body as? MessagePart {
            try messagePart.prepare(constraint, maxLineLength: maxLineLength)
        }
    }

    public func writeTo(_ stream: MimeStream?) throws {
        try writeTo(.default, stream)
    }

    public func writeTo(_ options: FormatOptions, _ stream: MimeStream?) throws {
        guard let stream else {
            throw MimeMessageError.nilStream
        }
        let headersText = headers.toString(options, encode: true)
        if !headersText.isEmpty {
            let headerBytes = Array(headersText.utf8)
            try stream.write(headerBytes, offset: 0, count: headerBytes.count)
        }
        let newLineBytes = options.newLineBytes
        try stream.write(newLineBytes, offset: 0, count: newLineBytes.count)
        try stream.write(newLineBytes, offset: 0, count: newLineBytes.count)

        if let body {
            try body.writeTo(options, stream)
        }
    }

    public static func load(_ stream: MimeStream?) throws -> MimeMessage {
        guard let stream else {
            throw MimeMessageError.nilStream
        }
        let bytes = try readAllBytes(from: stream)
        return try parse(bytes)
    }

    private static func parse(_ bytes: [UInt8]) throws -> MimeMessage {
        let (headerList, bodyBytes) = parseHeaders(bytes)
        let message = MimeMessage()
        for header in headerList {
            message.headers.add(header)
        }

        if let subject = message.headers[.subject] {
            message.subject = subject
        }

        if let fromHeader = message.headers[.from] {
            message.from.addRange(parseAddressList(fromHeader))
        }

        if let toHeader = message.headers[.to] {
            message.to.addRange(parseAddressList(toHeader))
        }

        if !bodyBytes.isEmpty {
            message.body = try parseEntity(bodyBytes)
        }

        return message
    }

    private static func parseEntity(_ bytes: [UInt8]) throws -> MimeEntity? {
        let (headers, bodyBytes) = parseHeaders(bytes)
        guard !headers.isEmpty else {
            return nil
        }

        var contentType: ContentType? = nil
        if let contentTypeValue = headers[.contentType] {
            var parsed: ContentType? = nil
            if ContentType.tryParse(contentTypeValue, contentType: &parsed) {
                contentType = parsed
            }
        }

        let mediaType = contentType?.mediaType.lowercased() ?? ""
        let mediaSubtype = contentType?.mediaSubtype.lowercased() ?? ""

        let entity: MimeEntity
        switch (mediaType, mediaSubtype) {
        case ("text", "rfc822-headers"):
            let part = TextRfc822Headers()
            entity = part
            if !bodyBytes.isEmpty {
                let (messageHeaders, _) = parseHeaders(bodyBytes)
                let message = MimeMessage()
                for header in messageHeaders {
                    message.headers.add(header)
                }
                part.message = message
            }
        case ("message", _):
            let part = MessagePart(mediaSubtype.isEmpty ? "rfc822" : mediaSubtype)
            entity = part
            if !bodyBytes.isEmpty {
                part.message = try parse(bodyBytes)
            }
        case ("text", _):
            let subtype = mediaSubtype.isEmpty ? "plain" : mediaSubtype
            let part = TextPart(subtype)
            if let contentType {
                part.contentType = contentType
            }
            if !bodyBytes.isEmpty {
                part.content = try MimeContent(MemoryStream(bodyBytes, writable: false))
            }
            entity = part
        default:
            let fallback = try ContentType("application", "octet-stream")
            let part = MimePart(contentType ?? fallback)
            if !bodyBytes.isEmpty {
                part.content = try MimeContent(MemoryStream(bodyBytes, writable: false))
            }
            entity = part
        }

        for header in headers {
            entity.headers.add(header)
        }

        return entity
    }

    private static func parseHeaders(_ bytes: [UInt8]) -> (HeaderList, [UInt8]) {
        let separator = findHeaderBodySeparator(bytes)
        let headerBytes: [UInt8]
        let bodyBytes: [UInt8]

        if let separator {
            headerBytes = Array(bytes[0..<separator.headerEnd])
            bodyBytes = Array(bytes[separator.bodyStart..<bytes.count])
        } else {
            headerBytes = bytes
            bodyBytes = []
        }

        let headerList = HeaderList()
        guard let text = String(data: Data(headerBytes), encoding: .isoLatin1) else {
            return (headerList, bodyBytes)
        }

        var currentField: String? = nil
        var currentValue = ""
        let lines = text.components(separatedBy: "\n")
        for rawLine in lines {
            var line = rawLine
            if line.hasSuffix("\r") {
                line.removeLast()
            }
            if line.isEmpty {
                break
            }
            if line.first == " " || line.first == "\t" {
                if currentField != nil {
                    let trimmed = line.trimmingCharacters(in: .whitespacesAndNewlines)
                    if !trimmed.isEmpty {
                        if !currentValue.isEmpty {
                            currentValue.append(" ")
                        }
                        currentValue.append(trimmed)
                    }
                }
                continue
            }

            if let field = currentField {
                headerList.add(Header(field: field, value: currentValue))
            }

            guard let colon = line.firstIndex(of: ":") else {
                currentField = nil
                currentValue = ""
                continue
            }

            let field = line[..<colon].trimmingCharacters(in: .whitespacesAndNewlines)
            let valueStart = line.index(after: colon)
            let value = line[valueStart...].trimmingCharacters(in: .whitespacesAndNewlines)
            currentField = field.isEmpty ? nil : field
            currentValue = String(value)
        }

        if let field = currentField {
            headerList.add(Header(field: field, value: currentValue))
        }

        return (headerList, bodyBytes)
    }

    private static func findHeaderBodySeparator(_ bytes: [UInt8]) -> (headerEnd: Int, bodyStart: Int)? {
        if bytes.count < 2 {
            return nil
        }
        var index = 0
        while index + 1 < bytes.count {
            if bytes[index] == 0x0D, bytes[index + 1] == 0x0A {
                if index + 3 < bytes.count,
                   bytes[index + 2] == 0x0D,
                   bytes[index + 3] == 0x0A {
                    return (index, index + 4)
                }
            }
            if bytes[index] == 0x0A, bytes[index + 1] == 0x0A {
                return (index, index + 2)
            }
            index += 1
        }
        return nil
    }

    private static func parseAddressList(_ value: String) -> [InternetAddress] {
        var index = 0
        var list: InternetAddressList? = nil
        let buffer = Array(value.utf8)
        _ = InternetAddressList.tryParse(.tryParse, .default, buffer, index: &index, endIndex: buffer.count, isGroup: false, groupDepth: 0, addresses: &list)
        return list?.map { $0 } ?? []
    }

    private static func readAllBytes(from stream: MimeStream) throws -> [UInt8] {
        var buffer = [UInt8](repeating: 0, count: 4096)
        var data: [UInt8] = []
        _ = try stream.seek(0, origin: .begin)
        while true {
            let read = try stream.read(&buffer, offset: 0, count: buffer.count)
            if read == 0 {
                break
            }
            data.append(contentsOf: buffer[0..<read])
        }
        return data
    }

    private func updateAddressHeader(_ id: HeaderId, list: InternetAddressList?) {
        guard let list else { return }
        if list.count == 0 {
            headers.removeAll(id)
        } else {
            headers[id] = list.toString(.default, encode: true)
        }
    }
}
