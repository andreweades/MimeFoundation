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
    case invalidMessageId
    case invalidResentMessageId
    case invalidInReplyTo
}

public final class MimeMessage {
    public let headers: HeaderList
    public var body: MimeEntity?
    public let from: InternetAddressList
    public let to: InternetAddressList
    public let cc: InternetAddressList
    public let replyTo: InternetAddressList
    public let bcc: InternetAddressList
    public let resentFrom: InternetAddressList
    public let resentReplyTo: InternetAddressList
    public let resentTo: InternetAddressList
    public let resentCc: InternetAddressList
    public let resentBcc: InternetAddressList
    public let references: MessageIdList

    private var subjectStorage: String?
    private var dateStorage: DateTimeOffset?
    private var resentDateStorage: DateTimeOffset?
    private var senderStorage: MailboxAddress?
    private var resentSenderStorage: MailboxAddress?
    private var messageIdStorage: String?
    private var resentMessageIdStorage: String?
    private var inReplyToStorage: String?
    private var mimeVersionStorage: MimeVersion?
    private var importanceStorage: MessageImportance = .normal
    private var priorityStorage: MessagePriority = .normal
    private var xPriorityStorage: XMessagePriority = .normal
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

    public var resentDate: DateTimeOffset? {
        get { resentDateStorage }
        set {
            resentDateStorage = newValue
            updateResentDateHeader()
        }
    }

    public var sender: MailboxAddress? {
        get { senderStorage }
        set {
            senderStorage = newValue
            updateSenderHeader()
        }
    }

    public var resentSender: MailboxAddress? {
        get { resentSenderStorage }
        set {
            resentSenderStorage = newValue
            updateResentSenderHeader()
        }
    }

    public var messageId: String? {
        get { messageIdStorage }
        set {
            _ = try? setMessageId(newValue)
        }
    }

    public var resentMessageId: String? {
        get { resentMessageIdStorage }
        set {
            _ = try? setResentMessageId(newValue)
        }
    }

    public var inReplyTo: String? {
        get { inReplyToStorage }
        set {
            _ = try? setInReplyTo(newValue)
        }
    }

    public var mimeVersion: MimeVersion? {
        get { mimeVersionStorage }
        set {
            mimeVersionStorage = newValue
            updateMimeVersionHeader()
        }
    }

    public var importance: MessageImportance {
        get { importanceStorage }
        set {
            importanceStorage = newValue
            updateImportanceHeader()
        }
    }

    public var priority: MessagePriority {
        get { priorityStorage }
        set {
            priorityStorage = newValue
            updatePriorityHeader()
        }
    }

    public var xPriority: XMessagePriority {
        get { xPriorityStorage }
        set {
            xPriorityStorage = newValue
            updateXPriorityHeader()
        }
    }

    internal init(addDefaults: Bool) {
        self.headers = HeaderList()
        self.from = InternetAddressList()
        self.to = InternetAddressList()
        self.cc = InternetAddressList()
        self.replyTo = InternetAddressList()
        self.bcc = InternetAddressList()
        self.resentFrom = InternetAddressList()
        self.resentReplyTo = InternetAddressList()
        self.resentTo = InternetAddressList()
        self.resentCc = InternetAddressList()
        self.resentBcc = InternetAddressList()
        self.references = MessageIdList()

        configureAddressList(from, id: .from)
        configureAddressList(to, id: .to)
        configureAddressList(cc, id: .cc)
        configureAddressList(replyTo, id: .replyTo)
        configureAddressList(bcc, id: .bcc)
        configureAddressList(resentFrom, id: .resentFrom)
        configureAddressList(resentReplyTo, id: .resentReplyTo)
        configureAddressList(resentTo, id: .resentTo)
        configureAddressList(resentCc, id: .resentCc)
        configureAddressList(resentBcc, id: .resentBcc)

        references.changed = { [weak self] _ in
            self?.updateReferencesHeader()
        }

        headers.changed = { [weak self] action, header in
            self?.headersChanged(action, header: header)
        }

        if addDefaults {
            headers[.from] = ""
            date = DateTimeOffset.now()
            subject = ""
            messageId = MimeUtils.generateMessageId()
        }
    }

    public convenience init() {
        self.init(addDefaults: true)
    }

    public convenience init(_ args: Any?...) throws {
        try self.init(args: args)
    }

    public convenience init(args: [Any?]?) throws {
        self.init(addDefaults: false)
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
        if headers[.messageId] == nil {
            messageId = MimeUtils.generateMessageId()
        }
    }

    public convenience init(headers: [Header]) {
        self.init(addDefaults: false)
        for header in headers where !header.field.lowercased().hasPrefix("content-") {
            self.headers.add(header)
        }
        syncFromHeaders()
    }

    public convenience init(from: [InternetAddress], to: [InternetAddress], subject: String, body: MimeEntity) {
        self.init(addDefaults: true)
        self.from.addRange(from)
        self.to.addRange(to)
        self.subject = subject
        self.body = body
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

    public var textBody: String? {
        getTextBody(.plain)
    }

    public var htmlBody: String? {
        getTextBody(.html)
    }

    public func getTextBody(_ format: TextFormat) -> String? {
        if let multipart = body as? Multipart {
            var text: TextPart? = nil
            if multipart.tryGetValue(format, body: &text), let text {
                return MultipartAlternative.getText(text)
            }
        } else if let text = body as? TextPart, text.isFormat(format), !text.isAttachment {
            return MultipartAlternative.getText(text)
        }
        return nil
    }

    public var bodyParts: [MimeEntity] {
        return enumerateMimeParts(body)
    }

    public var attachments: [MimeEntity] {
        return enumerateMimeParts(body).filter { $0.contentDisposition?.isAttachment ?? false }
    }

    public func getRecipients(_ onlyUnique: Bool = false) -> [MailboxAddress] {
        return getMailboxes(includeSenders: false, onlyUnique: onlyUnique)
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

    internal func hashBody(_ options: FormatOptions, signatureAlgorithm: DkimSignatureAlgorithm, bodyCanonicalization: DkimCanonicalizationAlgorithm, maxLength: Int) throws -> [UInt8] {
        let stream = DkimHashStream(signatureAlgorithm, maxLength: maxLength)
        let filtered = try FilteredStream(stream)
        let dkimFilter: DkimBodyFilter

        switch bodyCanonicalization {
        case .relaxed:
            dkimFilter = DkimRelaxedBodyFilter()
        case .simple:
            dkimFilter = DkimSimpleBodyFilter()
        }

        try filtered.add(options.createNewLineFilter(true))
        try filtered.add(dkimFilter)

        if let body {
            try body.writeBody(options, stream: filtered)
        }

        try filtered.flush()

        if !dkimFilter.lastWasNewLine {
            let newLine = options.newLineBytes
            try stream.write(newLine, offset: 0, count: newLine.count)
        }

        return stream.generateHash()
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
        let message = MimeMessage(addDefaults: false)
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
        func removeAutoContentTypeHeader(from entity: MimeEntity) {
            for index in 0..<entity.headers.count {
                let header = entity.headers[index]
                if header.id == .contentType || header.field.caseInsensitiveCompare("content-type") == .orderedSame {
                    entity.headers.remove(at: index)
                    break
                }
            }
        }

        func applyHeaders(_ entity: MimeEntity, removeAutoContentType: Bool = true) {
            for header in headers {
                entity.headers.add(header)
            }
            if removeAutoContentType {
                removeAutoContentTypeHeader(from: entity)
            }
        }

        var contentType: ContentType? = nil
        if let header = headers.tryGetHeader(.contentType) {
            let value = header.value
            var parsed: ContentType? = nil
            if ContentType.tryParse(value, contentType: &parsed) {
                contentType = parsed
            } else {
                let fallback = try ContentType("application", "octet-stream")
                let bytes = Array(value.utf8)
                if let semiIndex = bytes.firstIndex(of: UInt8(ascii: ";")) {
                    var index = semiIndex + 1
                    var params: ParameterList?
                    _ = try? ParameterList.tryParse(options, bytes, index: &index, endIndex: bytes.count, throwOnError: false, paramList: &params)
                    if let params {
                        fallback.parameters = params
                    }
                }
                contentType = fallback
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
            applyHeaders(multipart)
            if let boundary = multipart.contentType.boundary, !boundary.isEmpty, !bodyBytes.isEmpty {
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
            } else if !bodyBytes.isEmpty {
                if let preamble = String(data: Data(bodyBytes), encoding: .isoLatin1) {
                    multipart.preamble = preamble
                }
            }
            entity = multipart
        case ("text", "rfc822-headers"), ("message", "global-headers"):
            let part = (customEntity as? TextRfc822Headers) ?? TextRfc822Headers()
            applyHeaders(part)
            if !bodyBytes.isEmpty {
                let (messageHeaders, _) = parseHeaders(bodyBytes)
                let message = MimeMessage(addDefaults: false)
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
            applyHeaders(part)
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
            applyHeaders(part)
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
            applyHeaders(part)
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
            applyHeaders(part)
            if !bodyBytes.isEmpty {
                let encoding = part.contentTransferEncoding
                let decoded = decodeContentBytes(bodyBytes, encoding: encoding)
                part.content = try MimeContent(MemoryStream(decoded, writable: false), encoding: .default)
            }
            entity = part
        case ("message", _):
            let part = (customEntity as? MessagePart) ?? MessagePart(mediaSubtype.isEmpty ? "rfc822" : mediaSubtype)
            applyHeaders(part)
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
            applyHeaders(part)
            if !bodyBytes.isEmpty {
                let encoding = part.contentTransferEncoding
                let decoded = decodeContentBytes(bodyBytes, encoding: encoding)
                part.content = try MimeContent(MemoryStream(decoded, writable: false), encoding: .default)
            }
            entity = part
        default:
            let fallback = try ContentType("application", "octet-stream")
            let part = (customEntity as? MimePart) ?? MimePart(contentType ?? fallback)
            applyHeaders(part)
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
        let headerList = HeaderList()
        var bodyBytes: [UInt8] = []

        var headerLimit = bytes.count
        if let separator {
            let lineBreakLength = (bytes[separator.headerEnd] == 0x0D) ? 2 : 1
            headerLimit = min(bytes.count, separator.headerEnd + lineBreakLength)
            bodyBytes = Array(bytes[separator.bodyStart..<bytes.count])
        }

        var currentFieldBytes: [UInt8]? = nil
        var currentFieldNameLength = 0
        var currentRawValue: [UInt8] = []

        func finalizeHeader() {
            guard let fieldBytes = currentFieldBytes else { return }
            let header = Header(.default, fieldBytes: fieldBytes, fieldNameLength: currentFieldNameLength, rawValue: currentRawValue)
            headerList.add(header)
            currentFieldBytes = nil
            currentFieldNameLength = 0
            currentRawValue = []
        }

        var index = 0
        while index < headerLimit {
            let lineStart = index
            while index < headerLimit && bytes[index] != 0x0A {
                index += 1
            }
            let lineEnd = index
            var hasLineFeed = false
            if index < headerLimit && bytes[index] == 0x0A {
                hasLineFeed = true
                index += 1
            }

            var lineBytes = Array(bytes[lineStart..<lineEnd])
            var lineBreak: [UInt8] = []
            if hasLineFeed {
                if lineBytes.last == 0x0D {
                    lineBytes.removeLast()
                    lineBreak = [0x0D, 0x0A]
                } else {
                    lineBreak = [0x0A]
                }
            }

            if lineBytes.isEmpty {
                finalizeHeader()
                break
            }

            if lineBytes.first == 0x20 || lineBytes.first == 0x09 {
                if currentFieldBytes != nil {
                    currentRawValue.append(contentsOf: lineBytes)
                    currentRawValue.append(contentsOf: lineBreak)
                }
                continue
            }

            finalizeHeader()

            if let colonIndex = lineBytes.firstIndex(of: UInt8(ascii: ":")) {
                let fieldBytes = Array(lineBytes[0..<colonIndex])
                let valueStart = lineBytes.index(after: colonIndex)
                let rawValue = Array(lineBytes[valueStart..<lineBytes.count]) + lineBreak
                currentFieldBytes = fieldBytes
                currentFieldNameLength = fieldBytes.count
                currentRawValue = rawValue
            } else {
                let rawField = lineBytes + lineBreak
                let header = Header(.default, fieldBytes: rawField, fieldNameLength: rawField.count, rawValue: [])
                header.isInvalid = true
                headerList.add(header)
            }
        }

        finalizeHeader()

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
        var parts: [[UInt8]] = []
        var current: [String] = []
        var preambleLines: [String] = []
        var epilogueLines: [String] = []
        var inPart = false
        var inEpilogue = false
        var pendingEmptyPart = false

        func isEndBoundaryLine(_ line: String) -> Bool {
            guard line.hasPrefix(boundaryLine) else {
                return false
            }
            let remainder = line.dropFirst(boundaryLine.count)
            guard remainder.hasPrefix("--") else {
                return false
            }
            let trailing = remainder.dropFirst(2)
            return trailing.allSatisfy { $0 == " " || $0 == "\t" }
        }

        func isBoundaryLine(_ line: String) -> Bool {
            guard line.hasPrefix(boundaryLine) else {
                return false
            }
            let remainder = line.dropFirst(boundaryLine.count)
            if remainder.hasPrefix("--") {
                return false
            }
            return remainder.allSatisfy { $0 == " " || $0 == "\t" || $0 == "-" }
        }

        let lines = normalized.split(separator: "\n", omittingEmptySubsequences: false)
        for rawLine in lines {
            let line = String(rawLine)
            if isEndBoundaryLine(line) {
                if inPart {
                    let partText = current.joined(separator: "\n")
                    parts.append(Array(partText.utf8))
                    current.removeAll(keepingCapacity: true)
                }
                inPart = false
                inEpilogue = true
                pendingEmptyPart = false
                continue
            }
            if isBoundaryLine(line) {
                if inPart {
                    let partText = current.joined(separator: "\n")
                    parts.append(Array(partText.utf8))
                    current.removeAll(keepingCapacity: true)
                } else {
                    inPart = true
                }
                pendingEmptyPart = true
                continue
            }
            if inEpilogue {
                epilogueLines.append(line)
            } else if inPart {
                pendingEmptyPart = false
                current.append(line)
            } else {
                preambleLines.append(line)
            }
        }

        if inPart && (!current.isEmpty || pendingEmptyPart) {
            let partText = current.joined(separator: "\n")
            parts.append(Array(partText.utf8))
        }

        func joinPreambleLines(_ lines: [String]) -> String? {
            guard !lines.isEmpty else { return nil }
            var joined = lines.joined(separator: "\n")
            if lines.last == "" {
                joined.append("\n")
            }
            return joined.isEmpty ? nil : joined
        }

        func joinEpilogueLines(_ lines: [String]) -> String? {
            guard !lines.isEmpty else { return nil }
            let joined = lines.joined(separator: "\n")
            return joined.isEmpty ? nil : joined
        }

        let preamble = joinPreambleLines(preambleLines)
        let epilogue = joinEpilogueLines(epilogueLines)
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

    private func enumerateMimeParts(_ entity: MimeEntity?) -> [MimeEntity] {
        guard let entity else { return [] }
        if let multipart = entity as? Multipart {
            var parts: [MimeEntity] = []
            for part in multipart {
                parts.append(contentsOf: enumerateMimeParts(part))
            }
            return parts
        }
        return [entity]
    }

    private func getMailboxes(includeSenders: Bool, onlyUnique: Bool) -> [MailboxAddress] {
        var recipients: [MailboxAddress] = []
        var unique: Set<String>? = nil
        if onlyUnique {
            unique = Set<String>()
        }

        func addMailboxes(_ mailboxes: [MailboxAddress]) {
            for mailbox in mailboxes {
                if var uniqueSet = unique {
                    let key = mailbox.address.lowercased()
                    if uniqueSet.contains(key) {
                        continue
                    }
                    uniqueSet.insert(key)
                    unique = uniqueSet
                }
                recipients.append(mailbox)
            }
        }

        if resentSenderStorage != nil || resentFrom.count > 0 {
            if includeSenders {
                if let resentSenderStorage {
                    addMailboxes([resentSenderStorage])
                }
                addMailboxes(resentFrom.mailboxes)
            }
            addMailboxes(resentTo.mailboxes)
            addMailboxes(resentCc.mailboxes)
            addMailboxes(resentBcc.mailboxes)
        } else {
            if includeSenders {
                if let senderStorage {
                    addMailboxes([senderStorage])
                }
                addMailboxes(from.mailboxes)
            }
            addMailboxes(to.mailboxes)
            addMailboxes(cc.mailboxes)
            addMailboxes(bcc.mailboxes)
        }

        return recipients
    }

    private static func findHeaderBodySeparator(_ bytes: [UInt8]) -> (headerEnd: Int, bodyStart: Int)? {
        if bytes.count < 2 {
            return nil
        }
        if bytes[0] == 0x0D, bytes[1] == 0x0A {
            return (0, 2)
        }
        if bytes[0] == 0x0A {
            return (0, 1)
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

    private func configureAddressList(_ list: InternetAddressList, id: HeaderId) {
        list.changed = { [weak self, weak list] _ in
            guard let list else { return }
            self?.updateAddressHeader(id, list: list)
        }
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

    private func updateResentDateHeader() {
        guard !isUpdatingHeaders else { return }
        isUpdatingHeaders = true
        if let resentDateStorage {
            headers[.resentDate] = DateUtils.formatDate(resentDateStorage)
        } else {
            headers.removeAll(.resentDate)
        }
        isUpdatingHeaders = false
    }

    private func updateSenderHeader() {
        updateMailboxHeader(.sender, mailbox: senderStorage)
    }

    private func updateResentSenderHeader() {
        updateMailboxHeader(.resentSender, mailbox: resentSenderStorage)
    }

    private func updateMimeVersionHeader() {
        guard !isUpdatingHeaders else { return }
        isUpdatingHeaders = true
        if let mimeVersionStorage {
            headers[.mimeVersion] = mimeVersionStorage.description
        } else {
            headers.removeAll(.mimeVersion)
        }
        isUpdatingHeaders = false
    }

    private func updateImportanceHeader() {
        guard !isUpdatingHeaders else { return }
        isUpdatingHeaders = true
        let value: String
        switch importanceStorage {
        case .high:
            value = "high"
        case .low:
            value = "low"
        case .normal:
            value = "normal"
        }
        headers[.importance] = value
        isUpdatingHeaders = false
    }

    private func updatePriorityHeader() {
        guard !isUpdatingHeaders else { return }
        isUpdatingHeaders = true
        let value: String
        switch priorityStorage {
        case .nonUrgent:
            value = "non-urgent"
        case .normal:
            value = "normal"
        case .urgent:
            value = "urgent"
        }
        headers[.priority] = value
        isUpdatingHeaders = false
    }

    private func updateXPriorityHeader() {
        guard !isUpdatingHeaders else { return }
        isUpdatingHeaders = true
        let value: String
        switch xPriorityStorage {
        case .highest:
            value = "1 (Highest)"
        case .high:
            value = "2 (High)"
        case .normal:
            value = "3 (Normal)"
        case .low:
            value = "4 (Low)"
        case .lowest:
            value = "5 (Lowest)"
        }
        headers[.xPriority] = value
        isUpdatingHeaders = false
    }

    private func updateReferencesHeader() {
        guard !isUpdatingHeaders else { return }
        isUpdatingHeaders = true
        if references.count == 0 {
            headers.removeAll(.references)
        } else {
            headers[.references] = references.toString()
        }
        isUpdatingHeaders = false
    }

    private func updateMailboxHeader(_ id: HeaderId, mailbox: MailboxAddress?) {
        guard !isUpdatingHeaders else { return }
        isUpdatingHeaders = true
        if let mailbox {
            let list = InternetAddressList([mailbox])
            headers[id] = list.toString(.default, encode: true)
        } else {
            headers.removeAll(id)
        }
        isUpdatingHeaders = false
    }

    public func setMessageId(_ value: String?) throws {
        if let value {
            let msgid = try parseMessageIdValue(value, error: .invalidMessageId)
            messageIdStorage = msgid
            updateMessageIdHeader(.messageId, value: msgid)
        } else {
            messageIdStorage = nil
            updateMessageIdHeader(.messageId, value: nil)
        }
    }

    public func setResentMessageId(_ value: String?) throws {
        if let value {
            let msgid = try parseMessageIdValue(value, error: .invalidResentMessageId)
            resentMessageIdStorage = msgid
            updateMessageIdHeader(.resentMessageId, value: msgid)
        } else {
            resentMessageIdStorage = nil
            updateMessageIdHeader(.resentMessageId, value: nil)
        }
    }

    public func setInReplyTo(_ value: String?) throws {
        if let value {
            let msgid = try parseMessageIdValue(value, error: .invalidInReplyTo)
            inReplyToStorage = msgid
            updateMessageIdHeader(.inReplyTo, value: msgid)
        } else {
            inReplyToStorage = nil
            updateMessageIdHeader(.inReplyTo, value: nil)
        }
    }

    private func updateMessageIdHeader(_ id: HeaderId, value: String?) {
        guard !isUpdatingHeaders else { return }
        isUpdatingHeaders = true
        if let value {
            headers[id] = "<\(value)>"
        } else {
            headers.removeAll(id)
        }
        isUpdatingHeaders = false
    }

    private func parseMessageIdValue(_ value: String, error: MimeMessageError) throws -> String {
        let buffer = Array(value.utf8)
        var index = 0
        var msgid: String? = nil
        let parsed = (try? ParseUtils.tryParseMsgId(buffer, index: &index, endIndex: buffer.count, requireAngleAddr: false, throwOnError: false, msgid: &msgid)) ?? false
        guard parsed, let msgid else {
            throw error
        }
        return msgid
    }

    private func headersChanged(_ action: HeaderListChangedAction, header: Header?) {
        guard !isUpdatingHeaders else { return }
        switch action {
        case .cleared, .added, .changed, .removed:
            syncFromHeaders()
        }
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
            var list: InternetAddressList? = nil
            if InternetAddressList.tryParse(headers.options, header.rawValue, startIndex: 0, length: header.rawValue.count, addresses: &list),
               let list {
                addresses.append(contentsOf: list)
            }
        }
        return addresses
    }

    private func mailboxFromHeader(_ id: HeaderId) -> MailboxAddress? {
        guard let header = headers.tryGetHeader(id) else { return nil }
        var mailbox: MailboxAddress? = nil
        _ = MailboxAddress.tryParse(headers.options, header.rawValue, startIndex: 0, length: header.rawValue.count, mailbox: &mailbox)
        return mailbox
    }

    private func dateFromHeader(_ id: HeaderId) -> DateTimeOffset? {
        guard let header = headers.tryGetHeader(id) else { return nil }
        var parsed: DateTimeOffset? = nil
        if DateUtils.tryParse(header.rawValue, date: &parsed) {
            return parsed
        }
        return nil
    }

    private func messageIdFromHeader(_ id: HeaderId) -> String? {
        guard let header = headers.tryGetHeader(id) else { return nil }
        return MimeUtils.parseMessageId(header.rawValue, startIndex: 0, length: header.rawValue.count)
    }

    private func inReplyToFromHeader() -> String? {
        guard let header = headers.tryGetHeader(.inReplyTo) else { return nil }
        return MimeUtils.enumerateReferences(header.rawValue, startIndex: 0, length: header.rawValue.count).first
    }

    private func mimeVersionFromHeader() -> MimeVersion? {
        guard let header = headers.tryGetHeader(.mimeVersion) else { return nil }
        return MimeUtils.tryParseVersion(header.rawValue, startIndex: 0, length: header.rawValue.count)
    }

    private func importanceFromHeader() -> MessageImportance {
        let value = headers[.importance]?.lowercased().trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        switch value {
        case "high":
            return .high
        case "low":
            return .low
        default:
            return .normal
        }
    }

    private func priorityFromHeader() -> MessagePriority {
        let value = headers[.priority]?.lowercased().trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        switch value {
        case "non-urgent":
            return .nonUrgent
        case "urgent":
            return .urgent
        default:
            return .normal
        }
    }

    private func xPriorityFromHeader() -> XMessagePriority {
        guard let header = headers.tryGetHeader(.xPriority) else { return .normal }
        var index = 0
        let rawValue = header.rawValue
        _ = ParseUtils.skipWhiteSpace(rawValue, index: &index, endIndex: rawValue.count)
        var number = 0
        if ParseUtils.tryParseInt32(rawValue, index: &index, endIndex: rawValue.count, value: &number) {
            let clamped = Swift.min(Swift.max(number, 1), 5)
            return XMessagePriority(rawValue: clamped) ?? .normal
        }
        return .normal
    }

    private func updateReferencesFromHeaders() {
        let saved = references.changed
        references.changed = nil
        references.clear()
        if let header = headers.tryGetHeader(.references) {
            for msgid in MimeUtils.enumerateReferences(header.rawValue, startIndex: 0, length: header.rawValue.count) {
                try? references.add(msgid)
            }
        }
        references.changed = saved
    }

    private func syncFromHeaders() {
        updateAddressList(from, addresses: addressesFromHeaders(.from))
        updateAddressList(to, addresses: addressesFromHeaders(.to))
        updateAddressList(cc, addresses: addressesFromHeaders(.cc))
        updateAddressList(replyTo, addresses: addressesFromHeaders(.replyTo))
        updateAddressList(bcc, addresses: addressesFromHeaders(.bcc))
        updateAddressList(resentFrom, addresses: addressesFromHeaders(.resentFrom))
        updateAddressList(resentReplyTo, addresses: addressesFromHeaders(.resentReplyTo))
        updateAddressList(resentTo, addresses: addressesFromHeaders(.resentTo))
        updateAddressList(resentCc, addresses: addressesFromHeaders(.resentCc))
        updateAddressList(resentBcc, addresses: addressesFromHeaders(.resentBcc))
        senderStorage = mailboxFromHeader(.sender)
        resentSenderStorage = mailboxFromHeader(.resentSender)
        subjectStorage = headers[.subject]
        dateStorage = dateFromHeader(.date)
        resentDateStorage = dateFromHeader(.resentDate)
        messageIdStorage = messageIdFromHeader(.messageId)
        resentMessageIdStorage = messageIdFromHeader(.resentMessageId)
        inReplyToStorage = inReplyToFromHeader()
        mimeVersionStorage = mimeVersionFromHeader()
        importanceStorage = importanceFromHeader()
        priorityStorage = priorityFromHeader()
        xPriorityStorage = xPriorityFromHeader()
        updateReferencesFromHeaders()
    }
}
