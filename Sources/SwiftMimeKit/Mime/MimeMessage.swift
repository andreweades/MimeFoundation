//
// MimeMessage.swift
//
// Ported from MimeKit (C#) to Swift.
//

import Foundation
public enum MimeMessageError: Error, Equatable {
    case invalidMaxLineLength
    case nilStream
    case nilArgs
    case duplicateBody
    case invalidArgument
}

public final class MimeMessage {
    public let headers: HeaderList
    public var body: MimeEntity?
    public let from: InternetAddressList
    public let to: InternetAddressList
    public let cc: InternetAddressList

    private var subjectStorage: String?
    private var dateStorage: DateTimeOffset?
    private var isUpdatingHeaders = false

    public var subject: String? {
        get { subjectStorage }
        set {
            subjectStorage = newValue
            updateSubjectHeader()
        }
    }

    public var date: DateTimeOffset? {
        get { dateStorage }
        set {
            dateStorage = newValue
            updateDateHeader()
        }
    }

    public init() {
        self.headers = HeaderList()
        self.from = InternetAddressList()
        self.to = InternetAddressList()
        self.cc = InternetAddressList()

        from.changed = { [weak self] _ in
            self?.updateAddressHeader(.from, list: self?.from)
        }
        to.changed = { [weak self] _ in
            self?.updateAddressHeader(.to, list: self?.to)
        }
        cc.changed = { [weak self] _ in
            self?.updateAddressHeader(.cc, list: self?.cc)
        }

        headers.changed = { [weak self] action, header in
            self?.headersChanged(action, header: header)
        }
    }

    public convenience init(_ args: Any?...) throws {
        try self.init(args: args)
    }

    public convenience init(args: [Any?]?) throws {
        self.init()
        guard let args else {
            throw MimeMessageError.nilArgs
        }
        var body: MimeEntity?
        for obj in args {
            guard let obj else { continue }
            if let header = obj as? Header {
                if !header.field.hasPrefix("Content-") && !header.field.hasPrefix("content-") {
                    headers.add(header)
                }
                continue
            }
            if let headerList = obj as? [Header] {
                for header in headerList where !header.field.lowercased().hasPrefix("content-") {
                    headers.add(header)
                }
                continue
            }
            if let entity = obj as? MimeEntity {
                if body != nil {
                    throw MimeMessageError.duplicateBody
                }
                body = entity
                continue
            }
            throw MimeMessageError.invalidArgument
        }

        if let body {
            self.body = body
        }

        syncFromHeaders()

        if headers[.from] == nil {
            headers[.from] = ""
        }
        if headers[.date] == nil {
            date = DateTimeOffset.now()
        }
        if headers[.subject] == nil {
            subject = ""
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
        let combinedHeaders = HeaderList()
        for header in headers {
            combinedHeaders.add(header.clone())
        }
        if let body {
            for header in body.headers where header.field.lowercased().hasPrefix("content-") {
                if header.id != .unknown {
                    if combinedHeaders.contains(header.id) {
                        continue
                    }
                } else if combinedHeaders.contains(field: header.field) {
                    continue
                }
                combinedHeaders.add(header.clone())
            }
        }

        let headersText = combinedHeaders.toString(options, encode: true)
        if !headersText.isEmpty {
            let headerBytes = Array(headersText.utf8)
            try stream.write(headerBytes, offset: 0, count: headerBytes.count)
        }
        let newLineBytes = options.newLineBytes
        try stream.write(newLineBytes, offset: 0, count: newLineBytes.count)
        try stream.write(newLineBytes, offset: 0, count: newLineBytes.count)

        if let body {
            try body.writeBody(options, stream: stream)
        }
    }

    public func accept(_ visitor: MimeVisitor?) throws {
        guard let visitor else {
            throw MimeEntityError.nilVisitor
        }
        visitor.visit(self)
    }

    public static func load(_ stream: MimeStream?) throws -> MimeMessage {
        guard let stream else {
            throw MimeMessageError.nilStream
        }
        let bytes = try readAllBytes(from: stream)
        return try parse(.default, bytes)
    }

    public static func load(_ options: ParserOptions, _ stream: MimeStream?) throws -> MimeMessage {
        guard let stream else {
            throw MimeMessageError.nilStream
        }
        let bytes = try readAllBytes(from: stream)
        return try parse(options, bytes)
    }

    private static func parse(_ options: ParserOptions, _ bytes: [UInt8]) throws -> MimeMessage {
        let (headerList, bodyBytes) = parseHeaders(bytes)
        let message = MimeMessage()
        for header in headerList {
            message.headers.add(header)
        }

        message.syncFromHeaders()

        if !bodyBytes.isEmpty {
            let entityHeaders = HeaderList()
            for header in headerList where header.field.lowercased().hasPrefix("content-") {
                entityHeaders.add(header.clone())
            }
            message.body = try parseEntity(options, entityHeaders, bodyBytes)
        }

        return message
    }

    internal static func parseEntity(_ options: ParserOptions, _ bytes: [UInt8]) throws -> MimeEntity? {
        let (headers, bodyBytes) = parseHeaders(bytes)
        if headers.isEmpty && bodyBytes.isEmpty {
            return nil
        }
        return try parseEntity(options, headers, bodyBytes)
    }

    internal static func parseEntity(_ options: ParserOptions, _ headers: HeaderList, _ bodyBytes: [UInt8]) throws -> MimeEntity? {
        var contentType: ContentType? = nil
        if let contentTypeValue = headers[.contentType] {
            var parsed: ContentType? = nil
            if ContentType.tryParse(contentTypeValue, contentType: &parsed) {
                contentType = parsed
            }
        }
        if contentType == nil {
            contentType = try ContentType("text", "plain")
        }

        let mediaType = contentType?.mediaType.lowercased() ?? ""
        let mediaSubtype = contentType?.mediaSubtype.lowercased() ?? ""
        let customEntity = contentType.flatMap { options.makeEntity(for: $0) }

        let entity: MimeEntity
        switch (mediaType, mediaSubtype) {
        case ("multipart", _):
            let subtype = mediaSubtype.isEmpty ? "mixed" : mediaSubtype
            let multipart: Multipart
            if let custom = customEntity as? Multipart {
                multipart = custom
            } else {
                multipart = try createMultipart(subtype: subtype)
            }
            if let contentType {
                multipart.contentType = contentType
            }
            for header in headers {
                multipart.headers.add(header)
            }
            if let boundary = multipart.contentType.boundary, !bodyBytes.isEmpty {
                let split = splitMultipartBody(bodyBytes, boundary: boundary)
                if let preamble = split.preamble {
                    multipart.preamble = preamble
                }
                if let epilogue = split.epilogue {
                    multipart.epilogue = epilogue
                }
                for partBytes in split.parts {
                    if let child = try parseEntity(options, partBytes) {
                        try multipart.add(child)
                    }
                }
            }
            entity = multipart
        case ("text", "rfc822-headers"), ("message", "global-headers"):
            let part = (customEntity as? TextRfc822Headers) ?? TextRfc822Headers()
            for header in headers {
                part.headers.add(header)
            }
            if !bodyBytes.isEmpty {
                let (messageHeaders, _) = parseHeaders(bodyBytes)
                let message = MimeMessage()
                for header in messageHeaders {
                    message.headers.add(header)
                }
                part.message = message
            }
            entity = part
        case ("message", "delivery-status"):
            let resolvedContentType: ContentType
            if let contentType {
                resolvedContentType = contentType
            } else {
                resolvedContentType = try ContentType("message", "delivery-status")
            }
            let part = (customEntity as? MessageDeliveryStatus) ?? MessageDeliveryStatus(resolvedContentType)
            if let contentType {
                part.contentType = contentType
            }
            for header in headers {
                part.headers.add(header)
            }
            if !bodyBytes.isEmpty {
                let encoding = part.contentTransferEncoding
                let decoded = decodeContentBytes(bodyBytes, encoding: encoding)
                part.content = try MimeContent(MemoryStream(decoded, writable: false), encoding: .default)
            }
            entity = part
        case ("message", "disposition-notification"):
            let resolvedContentType: ContentType
            if let contentType {
                resolvedContentType = contentType
            } else {
                resolvedContentType = try ContentType("message", "disposition-notification")
            }
            let part = (customEntity as? MessageDispositionNotification) ?? MessageDispositionNotification(resolvedContentType)
            if let contentType {
                part.contentType = contentType
            }
            for header in headers {
                part.headers.add(header)
            }
            if !bodyBytes.isEmpty {
                let encoding = part.contentTransferEncoding
                let decoded = decodeContentBytes(bodyBytes, encoding: encoding)
                part.content = try MimeContent(MemoryStream(decoded, writable: false), encoding: .default)
            }
            entity = part
        case ("message", "feedback-report"):
            let resolvedContentType: ContentType
            if let contentType {
                resolvedContentType = contentType
            } else {
                resolvedContentType = try ContentType("message", "feedback-report")
            }
            let part = (customEntity as? MessageFeedbackReport) ?? MessageFeedbackReport(resolvedContentType)
            if let contentType {
                part.contentType = contentType
            }
            for header in headers {
                part.headers.add(header)
            }
            if !bodyBytes.isEmpty {
                let encoding = part.contentTransferEncoding
                let decoded = decodeContentBytes(bodyBytes, encoding: encoding)
                part.content = try MimeContent(MemoryStream(decoded, writable: false), encoding: .default)
            }
            entity = part
        case ("message", "partial"):
            let resolvedContentType: ContentType
            if let contentType {
                resolvedContentType = contentType
            } else {
                resolvedContentType = try ContentType("message", "partial")
            }
            let part = (customEntity as? MessagePartial) ?? MessagePartial(resolvedContentType)
            for header in headers {
                part.headers.add(header)
            }
            if !bodyBytes.isEmpty {
                let encoding = part.contentTransferEncoding
                let decoded = decodeContentBytes(bodyBytes, encoding: encoding)
                part.content = try MimeContent(MemoryStream(decoded, writable: false), encoding: .default)
            }
            entity = part
        case ("message", _):
            let part = (customEntity as? MessagePart) ?? MessagePart(mediaSubtype.isEmpty ? "rfc822" : mediaSubtype)
            for header in headers {
                part.headers.add(header)
            }
            if !bodyBytes.isEmpty {
                part.message = try parse(options, bodyBytes)
            }
            entity = part
        case ("text", _), ("application", "rtf"):
            let subtype = mediaSubtype.isEmpty ? "plain" : mediaSubtype
            let part = (customEntity as? TextPart) ?? TextPart(subtype)
            if let contentType {
                part.contentType = contentType
            }
            for header in headers {
                part.headers.add(header)
            }
            if !bodyBytes.isEmpty {
                let encoding = part.contentTransferEncoding
                let decoded = decodeContentBytes(bodyBytes, encoding: encoding)
                part.content = try MimeContent(MemoryStream(decoded, writable: false), encoding: .default)
            }
            entity = part
        default:
            let fallback = try ContentType("application", "octet-stream")
            let part = (customEntity as? MimePart) ?? MimePart(contentType ?? fallback)
            for header in headers {
                part.headers.add(header)
            }
            if !bodyBytes.isEmpty {
                let encoding = part.contentTransferEncoding
                let decoded = decodeContentBytes(bodyBytes, encoding: encoding)
                part.content = try MimeContent(MemoryStream(decoded, writable: false), encoding: .default)
            }
            entity = part
        }

        return entity
    }

    internal static func parseHeaders(_ bytes: [UInt8]) -> (HeaderList, [UInt8]) {
        let separator = findHeaderBodySeparator(bytes)
        let headerBytes: [UInt8]
        var bodyBytes: [UInt8]

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
                    currentValue.append(line)
                }
                continue
            }

            if let field = currentField, let header = try? Header(validating: field, value: currentValue) {
                headerList.add(header)
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

        if let field = currentField, let header = try? Header(validating: field, value: currentValue) {
            headerList.add(header)
        }

        if separator == nil && headerList.isEmpty {
            bodyBytes = bytes
        }

        return (headerList, bodyBytes)
    }

    private static func createMultipart(subtype: String) throws -> Multipart {
        switch subtype.lowercased() {
        case "alternative":
            return MultipartAlternative()
        case "related":
            return MultipartRelated()
        case "report":
            return MultipartReport()
        default:
            return try Multipart(subtype)
        }
    }

    private static func splitMultipartBody(_ bytes: [UInt8], boundary: String) -> (preamble: String?, parts: [[UInt8]], epilogue: String?) {
        guard let text = String(data: Data(bytes), encoding: .isoLatin1) else {
            return (nil, [], nil)
        }
        let normalized = text
            .replacingOccurrences(of: "\r\n", with: "\n")
            .replacingOccurrences(of: "\r", with: "\n")
        let boundaryLine = "--" + boundary
        let endBoundaryLine = boundaryLine + "--"
        var parts: [[UInt8]] = []
        var current: [String] = []
        var preambleLines: [String] = []
        var epilogueLines: [String] = []
        var inPart = false
        var inEpilogue = false

        let lines = normalized.split(separator: "\n", omittingEmptySubsequences: false)
        for rawLine in lines {
            let line = String(rawLine)
            if line == boundaryLine {
                if inPart {
                    let partText = current.joined(separator: "\n")
                    parts.append(Array(partText.utf8))
                    current.removeAll(keepingCapacity: true)
                } else {
                    inPart = true
                }
                continue
            }
            if line == endBoundaryLine {
                if inPart {
                    let partText = current.joined(separator: "\n")
                    parts.append(Array(partText.utf8))
                    current.removeAll(keepingCapacity: true)
                }
                inPart = false
                inEpilogue = true
                continue
            }
            if inEpilogue {
                epilogueLines.append(line)
            } else if inPart {
                current.append(line)
            } else {
                preambleLines.append(line)
            }
        }

        if inPart && !current.isEmpty {
            let partText = current.joined(separator: "\n")
            parts.append(Array(partText.utf8))
        }

        let preamble = preambleLines.isEmpty ? nil : preambleLines.joined(separator: "\n")
        let epilogue = epilogueLines.isEmpty ? nil : epilogueLines.joined(separator: "\n")
        return (preamble, parts, epilogue)
    }

    private static func decodeContentBytes(_ bytes: [UInt8], encoding: ContentEncoding) -> [UInt8] {
        switch encoding {
        case .base64, .quotedPrintable, .uuEncode:
            let source = MemoryStream(bytes, writable: false)
            let filtered = try? FilteredStream(source)
            let filter = DecoderFilter.create(encoding)
            _ = try? filtered?.add(filter)
            var buffer = [UInt8](repeating: 0, count: 4096)
            var output: [UInt8] = []
            while true {
                let read = (try? filtered?.read(&buffer, offset: 0, count: buffer.count)) ?? 0
                if read == 0 {
                    break
                }
                output.append(contentsOf: buffer[0..<read])
            }
            return output
        default:
            return bytes
        }
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
        guard !isUpdatingHeaders else { return }
        isUpdatingHeaders = true
        if list.count == 0 {
            headers.removeAll(id)
        } else {
            headers[id] = list.toString(.default, encode: true)
        }
        isUpdatingHeaders = false
    }

    private func updateSubjectHeader() {
        guard !isUpdatingHeaders else { return }
        isUpdatingHeaders = true
        if let subjectStorage {
            headers[.subject] = subjectStorage
        } else {
            headers.removeAll(.subject)
        }
        isUpdatingHeaders = false
    }

    private func updateDateHeader() {
        guard !isUpdatingHeaders else { return }
        isUpdatingHeaders = true
        if let dateStorage {
            headers[.date] = DateUtils.formatDate(dateStorage)
        } else {
            headers.removeAll(.date)
        }
        isUpdatingHeaders = false
    }

    private func headersChanged(_ action: HeaderListChangedAction, header: Header?) {
        guard !isUpdatingHeaders else { return }
        switch action {
        case .cleared:
            syncFromHeaders()
        case .added, .changed, .removed:
            break
        }
        guard let header else { return }
        switch header.id {
        case .from:
            updateAddressList(from, addresses: addressesFromHeaders(.from))
        case .to:
            updateAddressList(to, addresses: addressesFromHeaders(.to))
        case .cc:
            updateAddressList(cc, addresses: addressesFromHeaders(.cc))
        case .subject:
            subjectStorage = headers[.subject]
        case .date:
            var parsed: DateTimeOffset? = nil
            if let value = headers[.date], DateUtils.tryParse(value, date: &parsed) {
                dateStorage = parsed
            } else {
                dateStorage = nil
            }
        default:
            break
        }
    }

    private func updateAddressList(_ list: InternetAddressList, value: String?) {
        let saved = list.changed
        list.changed = nil
        list.clear()
        if let value {
            for address in MimeMessage.parseAddressList(value) {
                list.add(address)
            }
        }
        list.changed = saved
    }

    private func updateAddressList(_ list: InternetAddressList, addresses: [InternetAddress]) {
        let saved = list.changed
        list.changed = nil
        list.clear()
        for address in addresses {
            list.add(address)
        }
        list.changed = saved
    }

    private func addressesFromHeaders(_ id: HeaderId) -> [InternetAddress] {
        var addresses: [InternetAddress] = []
        for header in headers where header.id == id {
            addresses.append(contentsOf: MimeMessage.parseAddressList(header.value))
        }
        return addresses
    }

    private func syncFromHeaders() {
        updateAddressList(from, addresses: addressesFromHeaders(.from))
        updateAddressList(to, addresses: addressesFromHeaders(.to))
        updateAddressList(cc, addresses: addressesFromHeaders(.cc))
        subjectStorage = headers[.subject]
        var parsed: DateTimeOffset? = nil
        if let value = headers[.date], DateUtils.tryParse(value, date: &parsed) {
            dateStorage = parsed
        } else {
            dateStorage = nil
        }
    }
}
