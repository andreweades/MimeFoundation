//
// MimeEntity.swift
//
// Ported from MimeKit (C#) to Swift.
//

import Foundation

public enum MimeEntityError: Error, Equatable {
    case nilContentType
    case invalidContentBase
    case invalidContentId
    case nilOptions
    case nilStream
    case nilFilePath
    case nilVisitor
    case invalidEntity
}

public protocol MimeVisitor {
    func visit(_ message: MimeMessage)
    func visit(_ entity: MimeEntity)
    func visit(_ part: MimePart)
    func visit(_ part: TextPart)
    func visit(_ part: MessagePart)
    func visit(_ part: MessageDeliveryStatus)
    func visit(_ part: MessageDispositionNotification)
    func visit(_ part: MessageFeedbackReport)
    func visit(_ part: MessagePartial)
    func visit(_ part: TextRfc822Headers)
    func visit(_ multipart: Multipart)
    func visit(_ multipart: MultipartAlternative)
    func visit(_ multipart: MultipartRelated)
    func visit(_ multipart: MultipartReport)
}

public extension MimeVisitor {
    func visit(_ message: MimeMessage) {}
    func visit(_ entity: MimeEntity) {}
    func visit(_ part: MimePart) {}
    func visit(_ part: TextPart) {}
    func visit(_ part: MessagePart) {}
    func visit(_ part: MessageDeliveryStatus) {}
    func visit(_ part: MessageDispositionNotification) {}
    func visit(_ part: MessageFeedbackReport) {}
    func visit(_ part: MessagePartial) {}
    func visit(_ part: TextRfc822Headers) {}
    func visit(_ multipart: Multipart) {}
    func visit(_ multipart: MultipartAlternative) {}
    func visit(_ multipart: MultipartRelated) {}
    func visit(_ multipart: MultipartReport) {}
}

open class MimeEntity {
    public let headers: HeaderList
    public let options: ParserOptions

    private var contentTypeStorage: ContentType
    private var contentDispositionCache: ContentDisposition?
    private var contentDispositionLoaded = false
    private var contentIdCache: String?
    private var contentIdLoaded = false
    private var contentLocationCache: URL?
    private var contentLocationLoaded = false
    private var contentBaseCache: URL?
    private var contentBaseLoaded = false

    private var isUpdatingHeaders = false

    public var contentType: ContentType {
        get { contentTypeStorage }
        set { setContentType(newValue, updateHeaders: true) }
    }

    public var contentDisposition: ContentDisposition? {
        get {
            if !contentDispositionLoaded {
                if let header = headers.tryGetHeader(.contentDisposition) {
                    var parsed: ContentDisposition?
                    if ContentDisposition.tryParse(options, header.rawValue, disposition: &parsed) {
                        parsed?.changed = { [weak self] in
                            self?.updateContentDispositionHeader()
                        }
                    }
                    contentDispositionCache = parsed
                } else {
                    contentDispositionCache = nil
                }
                contentDispositionLoaded = true
            }
            return contentDispositionCache
        }
        set {
            contentDispositionLoaded = true
            if let value = newValue {
                value.changed = { [weak self] in
                    self?.updateContentDispositionHeader()
                }
                contentDispositionCache = value
                updateContentDispositionHeader()
            } else {
                contentDispositionCache = nil
                removeHeader(.contentDisposition)
            }
        }
    }

    public var contentId: String? {
        get {
            if !contentIdLoaded {
                if let header = headers.tryGetHeader(.contentId) {
                    contentIdCache = MimeEntity.parseMessageId(header.value)
                } else {
                    contentIdCache = nil
                }
                contentIdLoaded = true
            }
            return contentIdCache
        }
        set {
            _ = try? setContentId(newValue)
        }
    }

    public var contentLocation: URL? {
        get {
            if !contentLocationLoaded {
                if let header = headers.tryGetHeader(.contentLocation) {
                    contentLocationCache = URL(string: header.value)
                } else {
                    contentLocationCache = nil
                }
                contentLocationLoaded = true
            }
            return contentLocationCache
        }
        set {
            contentLocationLoaded = true
            if let value = newValue {
                contentLocationCache = value
                setHeader(.contentLocation, value.absoluteString)
            } else {
                contentLocationCache = nil
                removeHeader(.contentLocation)
            }
        }
    }

    public var contentBase: URL? {
        get {
            if !contentBaseLoaded {
                if let header = headers.tryGetHeader(.contentBase) {
                    contentBaseCache = URL(string: header.value)
                } else {
                    contentBaseCache = nil
                }
                contentBaseLoaded = true
            }
            return contentBaseCache
        }
        set {
            _ = try? setContentBase(newValue)
        }
    }

    open func accept(_ visitor: MimeVisitor?) throws {
        guard let visitor else {
            throw MimeEntityError.nilVisitor
        }
        visitor.visit(self)
    }

    public init(_ contentType: ContentType) {
        self.options = .default
        self.headers = HeaderList()
        self.contentTypeStorage = contentType
        attachHandlers()
        updateContentTypeHeader()
    }

    public convenience init(_ mediaType: String, _ mediaSubtype: String) throws {
        let contentType = try ContentType(mediaType, mediaSubtype)
        self.init(contentType)
    }

    private func attachHandlers() {
        headers.changed = { [weak self] action, header in
            self?.headersChanged(action, header: header)
        }
        contentTypeStorage.changed = { [weak self] in
            self?.updateContentTypeHeader()
        }
    }

    private func setContentType(_ contentType: ContentType, updateHeaders: Bool) {
        contentTypeStorage.changed = nil
        contentTypeStorage = contentType
        contentTypeStorage.changed = { [weak self] in
            self?.updateContentTypeHeader()
        }
        if updateHeaders {
            updateContentTypeHeader()
        }
    }

    private func updateContentTypeHeader() {
        guard !isUpdatingHeaders else { return }
        isUpdatingHeaders = true
        let encoded = contentTypeStorage.encode(.default, .utf8)
        let value = MimeEntity.trimHeaderValue(encoded, newLine: FormatOptions.default.newLine)
        headers[.contentType] = value
        isUpdatingHeaders = false
    }

    private func updateContentDispositionHeader() {
        guard !isUpdatingHeaders else { return }
        isUpdatingHeaders = true
        if let disposition = contentDispositionCache {
            let encoded = disposition.encode(.default, .utf8)
            let value = MimeEntity.trimHeaderValue(encoded, newLine: FormatOptions.default.newLine)
            headers[.contentDisposition] = value
        } else {
            removeHeader(.contentDisposition)
        }
        isUpdatingHeaders = false
    }

    open func headersChanged(_ action: HeaderListChangedAction, header: Header?) {
        guard !isUpdatingHeaders else { return }

        switch action {
        case .cleared:
            contentDispositionLoaded = false
            contentIdLoaded = false
            contentLocationLoaded = false
            contentBaseLoaded = false
            return
        case .added, .changed, .removed:
            break
        }

        guard let header else { return }
        switch header.id {
        case .contentType:
            if let parsed = try? ContentType.parse(options, header.rawValue) {
                isUpdatingHeaders = true
                setContentType(parsed, updateHeaders: false)
                isUpdatingHeaders = false
            }
        case .contentDisposition:
            contentDispositionLoaded = false
        case .contentId:
            contentIdLoaded = false
        case .contentLocation:
            contentLocationLoaded = false
        case .contentBase:
            contentBaseLoaded = false
        default:
            break
        }
    }

    internal func setHeader(_ id: HeaderId, _ value: String) {
        headers[id] = value
    }

    internal func removeHeader(_ id: HeaderId) {
        headers.removeAll(id)
    }

    public func writeTo(_ stream: MimeStream?) throws {
        try writeTo(.default, stream)
    }

    public func writeTo(_ options: FormatOptions?, _ stream: MimeStream?) throws {
        guard let options else {
            throw MimeEntityError.nilOptions
        }
        guard let stream else {
            throw MimeEntityError.nilStream
        }
        try writeHeaders(options, stream: stream)
        try writeBody(options, stream: stream)
    }

    public func writeTo(_ options: FormatOptions?, _ filePath: String?) throws {
        guard let options else {
            throw MimeEntityError.nilOptions
        }
        guard let filePath else {
            throw MimeEntityError.nilFilePath
        }
        let memory = MemoryStream()
        try writeTo(options, memory)
        let data = Data(memory.toByteArray())
        try data.write(to: URL(fileURLWithPath: filePath))
    }

    public func writeTo(_ filePath: String?) throws {
        try writeTo(.default, filePath)
    }

    public func writeToAsync(_ stream: MimeStream?) async throws {
        try writeTo(.default, stream)
    }

    public func writeToAsync(_ options: FormatOptions?, _ stream: MimeStream?) async throws {
        try writeTo(options, stream)
    }

    public func writeToAsync(_ options: FormatOptions?, _ filePath: String?) async throws {
        try writeTo(options, filePath)
    }

    public func writeToAsync(_ filePath: String?) async throws {
        try writeTo(.default, filePath)
    }

    public static func load(_ stream: MimeStream?) throws -> MimeEntity {
        guard let stream else {
            throw MimeEntityError.nilStream
        }
        let bytes = try readAllBytes(from: stream)
        if let entity = try MimeMessage.parseEntity(.default, bytes) {
            return entity
        }
        throw MimeEntityError.invalidEntity
    }

    public static func load(_ options: ParserOptions, _ stream: MimeStream?) throws -> MimeEntity {
        guard let stream else {
            throw MimeEntityError.nilStream
        }
        let bytes = try readAllBytes(from: stream)
        if let entity = try MimeMessage.parseEntity(options, bytes) {
            return entity
        }
        throw MimeEntityError.invalidEntity
    }

    public static func load(_ contentType: ContentType?, _ stream: MimeStream?) throws -> MimeEntity {
        guard let contentType else {
            throw MimeEntityError.nilContentType
        }
        guard let stream else {
            throw MimeEntityError.nilStream
        }
        let bytes = try readAllBytes(from: stream)
        let isText = (try? contentType.isMimeType("text", "*")) == true
        let part: MimePart = isText ? TextPart(contentType) : MimePart(contentType)
        part.content = try MimeContent(MemoryStream(bytes, writable: false), encoding: part.contentTransferEncoding)
        return part
    }

    public static func load(_ options: ParserOptions, _ contentType: ContentType?, _ stream: MimeStream?) throws -> MimeEntity {
        guard let contentType else {
            throw MimeEntityError.nilContentType
        }
        guard let stream else {
            throw MimeEntityError.nilStream
        }
        if let custom = options.makeEntity(for: contentType) as? MimePart {
            let bytes = try readAllBytes(from: stream)
            custom.contentType = contentType
            custom.content = try MimeContent(MemoryStream(bytes, writable: false), encoding: custom.contentTransferEncoding)
            return custom
        }
        return try load(contentType, stream)
    }

    public static func load(_ filePath: String?) throws -> MimeEntity {
        guard let filePath else {
            throw MimeEntityError.nilFilePath
        }
        let data = try Data(contentsOf: URL(fileURLWithPath: filePath))
        return try load(MemoryStream(Array(data), writable: false))
    }

    public static func loadAsync(_ stream: MimeStream?) async throws -> MimeEntity {
        try load(stream)
    }

    public static func loadAsync(_ options: ParserOptions, _ stream: MimeStream?) async throws -> MimeEntity {
        try load(options, stream)
    }

    public static func loadAsync(_ contentType: ContentType?, _ stream: MimeStream?) async throws -> MimeEntity {
        try load(contentType, stream)
    }

    public static func loadAsync(_ options: ParserOptions, _ contentType: ContentType?, _ stream: MimeStream?) async throws -> MimeEntity {
        try load(options, contentType, stream)
    }

    public static func loadAsync(_ filePath: String?) async throws -> MimeEntity {
        try load(filePath)
    }

    private static func readAllBytes(from stream: MimeStream) throws -> [UInt8] {
        var buffer = [UInt8](repeating: 0, count: 4096)
        var data: [UInt8] = []
        _ = try? stream.seek(0, origin: .begin)
        while true {
            let read = try stream.read(&buffer, offset: 0, count: buffer.count)
            if read == 0 {
                break
            }
            data.append(contentsOf: buffer[0..<read])
        }
        return data
    }

    internal func writeHeaders(_ options: FormatOptions, stream: MimeStream) throws {
        var text = headers.toString(options, encode: true)
        text.append(options.newLine)
        text.append(options.newLine)
        let bytes = Array(text.utf8)
        try stream.write(bytes, offset: 0, count: bytes.count)
    }

    internal func writeBody(_ options: FormatOptions, stream: MimeStream) throws {
        // Default: no body for base entity.
    }

    private static func trimHeaderValue(_ encoded: String, newLine: String) -> String {
        var trimmed = encoded
        while trimmed.hasSuffix(newLine) {
            trimmed.removeLast(newLine.count)
        }
        if trimmed.hasPrefix(" ") {
            trimmed.removeFirst()
        }
        return trimmed
    }

    public func setContentId(_ value: String?) throws {
        contentIdLoaded = true
        guard let value else {
            contentIdCache = nil
            removeHeader(.contentId)
            return
        }
        guard let parsed = MimeEntity.parseMessageId(value) else {
            throw MimeEntityError.invalidContentId
        }
        contentIdCache = parsed
        setHeader(.contentId, "<\(parsed)>")
    }

    public func setContentBase(_ value: URL?) throws {
        contentBaseLoaded = true
        if let value {
            guard value.scheme != nil else {
                throw MimeEntityError.invalidContentBase
            }
            contentBaseCache = value
            setHeader(.contentBase, value.absoluteString)
        } else {
            contentBaseCache = nil
            removeHeader(.contentBase)
        }
    }

    internal static func parseMessageId(_ value: String) -> String? {
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty {
            return nil
        }
        if trimmed.hasPrefix("<") {
            guard trimmed.hasSuffix(">") else {
                return nil
            }
            let start = trimmed.index(after: trimmed.startIndex)
            let end = trimmed.index(before: trimmed.endIndex)
            let inner = trimmed[start..<end].trimmingCharacters(in: .whitespacesAndNewlines)
            return inner.isEmpty ? nil : String(inner)
        }
        if trimmed.contains("<") || trimmed.contains(">") {
            return nil
        }
        return trimmed
    }
}
