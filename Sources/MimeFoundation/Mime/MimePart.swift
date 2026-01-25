//
// MimePart.swift
//
// Ported from MimeKit (C#) to Swift.
//

import Foundation
import CryptoKit

public enum MimePartError: Error, Equatable, Sendable {
    case emptyMediaType
    case emptyMediaSubtype
    case invalidContentDuration
    case invalidEncodingConstraint
    case invalidContentTransferEncoding
    case noContent
    case cryptoUnavailable
    case duplicateContent
    case invalidArgument
}

open class MimePart: MimeEntity {
    private static var octetStreamContentType: ContentType {
        guard let ct = try? ContentType("application", "octet-stream") else {
            preconditionFailure("Invalid static content type - this is a programming error")
        }
        return ct
    }

    private var contentDescriptionCache: String?
    private var contentDescriptionLoaded = false
    private var contentDurationCache: Int?
    private var contentDurationLoaded = false
    private var contentMd5Cache: String?
    private var contentMd5Loaded = false
    private var contentTransferEncodingCache: ContentEncoding = .default
    private var contentTransferEncodingLoaded = false

    public var content: MimeContent?

    public var contentDescription: String? {
        get {
            if !contentDescriptionLoaded {
                if let header = headers.tryGetHeader(.contentDescription) {
                    contentDescriptionCache = header.value
                } else {
                    contentDescriptionCache = nil
                }
                contentDescriptionLoaded = true
            }
            return contentDescriptionCache
        }
        set {
            contentDescriptionLoaded = true
            contentDescriptionCache = newValue
            if let value = newValue {
                setHeader(.contentDescription, value)
            } else {
                removeHeader(.contentDescription)
            }
        }
    }

    public var contentDuration: Int? {
        get {
            if !contentDurationLoaded {
                if let header = headers.tryGetHeader(.contentDuration) {
                    contentDurationCache = Int(header.value)
                } else {
                    contentDurationCache = nil
                }
                contentDurationLoaded = true
            }
            return contentDurationCache
        }
        set {
            _ = try? setContentDuration(newValue)
        }
    }

    public var contentMd5: String? {
        get {
            if !contentMd5Loaded {
                if let header = headers.tryGetHeader(.contentMd5) {
                    contentMd5Cache = header.value
                } else {
                    contentMd5Cache = nil
                }
                contentMd5Loaded = true
            }
            return contentMd5Cache
        }
        set {
            contentMd5Loaded = true
            contentMd5Cache = newValue
            if let value = newValue {
                setHeader(.contentMd5, value)
            } else {
                removeHeader(.contentMd5)
            }
        }
    }

    public var contentTransferEncoding: ContentEncoding {
        get {
            if !contentTransferEncodingLoaded {
                if let header = headers.tryGetHeader(.contentTransferEncoding) {
                    contentTransferEncodingCache = MimePart.parseContentEncoding(header.value)
                } else {
                    contentTransferEncodingCache = .default
                }
                contentTransferEncodingLoaded = true
            }
            return contentTransferEncodingCache
        }
        set {
            contentTransferEncodingLoaded = true
            contentTransferEncodingCache = newValue
            if newValue == .default {
                removeHeader(.contentTransferEncoding)
            } else {
                setHeader(.contentTransferEncoding, MimePart.formatContentEncoding(newValue))
            }
        }
    }

    public var isAttachment: Bool {
        get {
            contentDisposition?.isAttachment ?? false
        }
        set {
            if newValue {
                if contentDisposition == nil {
                    contentDisposition = try? ContentDisposition(ContentDisposition.attachment)
                }
                contentDisposition?.isAttachment = true
            } else if contentDisposition != nil {
                contentDisposition?.isAttachment = false
            }
        }
    }

    public var fileName: String? {
        get {
            var name: String? = nil
            if let disposition = contentDisposition {
                name = disposition.fileName
            }
            return name ?? contentType.name
        }
        set {
            if let value = newValue {
                if contentDisposition == nil {
                    contentDisposition = try? ContentDisposition(ContentDisposition.attachment)
                }
                contentDisposition?.fileName = value
            } else {
                contentDisposition?.fileName = nil
            }
            contentType.name = newValue
        }
    }

    public override init(_ contentType: ContentType) {
        super.init(contentType)
    }

    public convenience init(_ mediaType: String, _ mediaSubtype: String, _ args: Any...) throws {
        try self.init(mediaType, mediaSubtype, args: args)
    }

    public convenience init(_ mediaType: String, _ mediaSubtype: String, args: [Any?]) throws {
        guard !mediaType.isEmpty else {
            throw MimePartError.emptyMediaType
        }
        guard !mediaSubtype.isEmpty else {
            throw MimePartError.emptyMediaSubtype
        }
        let contentType = try ContentType(mediaType, mediaSubtype)
        self.init(contentType)
        var content: MimeContent?
        for arg in args {
            guard let arg else { continue }
            if tryInit(arg) {
                continue
            }
            if let mimeContent = arg as? MimeContent {
                if content != nil {
                    throw MimePartError.duplicateContent
                }
                content = mimeContent
                continue
            }
            if let stream = arg as? MimeStream {
                if content != nil {
                    throw MimePartError.duplicateContent
                }
                content = try MimeContent(stream: stream)
                continue
            }
            throw MimePartError.invalidArgument
        }
        if let content {
            self.content = content
        }
    }

    public convenience init(_ contentType: ContentType, _ args: Any...) {
        self.init(contentType)
        for arg in args {
            _ = tryInit(arg)
        }
    }

    public convenience init(_ mediaType: String, _ mediaSubtype: String) throws {
        try self.init(mediaType, mediaSubtype, args: [])
    }

    public convenience init(_ mimeType: String) throws {
        let parsed = try ContentType(parsing: mimeType)
        self.init(parsed)
    }

    public convenience init() {
        self.init(Self.octetStreamContentType)
    }

    internal func tryInit(_ obj: Any) -> Bool {
        if let header = obj as? Header {
            headers.add(header)
            return true
        }
        if let headers = obj as? [Header] {
            for header in headers {
                self.headers.add(header)
            }
            return true
        }
        return false
    }

    public func computeContentMd5() throws -> String {
        guard let content else {
            throw MimePartError.noContent
        }
        let data = try readAllBytes(content: content)
        if #available(macOS 10.15, iOS 13.0, *) {
            let digest = Insecure.MD5.hash(data: Data(data))
            let md5Data = Data(digest)
            let encoded = md5Data.base64EncodedString()
            contentMd5 = encoded
            return encoded
        }
        throw MimePartError.cryptoUnavailable
    }

    public func verifyContentMd5() -> Bool {
        guard let expected = contentMd5 else {
            return false
        }
        guard let content else {
            return false
        }
        guard let data = try? readAllBytes(content: content) else {
            return false
        }
        if #available(macOS 10.15, iOS 13.0, *) {
            let digest = Insecure.MD5.hash(data: Data(data))
            let md5Data = Data(digest).base64EncodedString()
            return md5Data == expected
        }
        return false
    }

    public func getBestEncoding(_ constraint: EncodingConstraint) throws -> ContentEncoding {
        switch constraint {
        case .sevenBit:
            return .base64
        case .eightBit:
            return .eightBit
        case .none:
            return contentTransferEncoding == .default ? .binary : contentTransferEncoding
        }
    }

    public func prepare(_ constraint: EncodingConstraint) throws {
        if constraint == .none {
            return
        }
        let best = try getBestEncoding(constraint)
        if contentTransferEncoding != best {
            contentTransferEncoding = best
        }
    }

    public func setContentDuration(_ value: Int?) throws {
        contentDurationLoaded = true
        guard let value else {
            contentDurationCache = nil
            removeHeader(.contentDuration)
            return
        }
        if value < 0 {
            throw MimePartError.invalidContentDuration
        }
        contentDurationCache = value
        setHeader(.contentDuration, String(value))
    }

    open override func writeTo(_ options: FormatOptions, _ stream: MimeStream) throws {
        try super.writeTo(options, stream)
    }

    internal override func writeBody(_ options: FormatOptions, stream: MimeStream) throws {
        guard let content else { return }

        if content.encoding != contentTransferEncoding {
            if contentTransferEncoding == .uuEncode {
                let name = fileName ?? "unknown"
                let begin = Array("begin 0644 \(name)".utf8)
                try stream.write(begin, offset: 0, count: begin.count)
                let newLine = options.newLineBytes
                try stream.write(newLine, offset: 0, count: newLine.count)
            }

            let filtered = try FilteredStream(stream)
            let filter = EncoderFilter.create(contentTransferEncoding)
            _ = try filtered.add(filter)
            if contentTransferEncoding != .binary {
                try filtered.add(options.createNewLineFilter(ensureNewLine))
            }
            try content.decodeTo(filtered)
            try filtered.flush()

            if contentTransferEncoding == .uuEncode {
                let end = Array("end".utf8)
                let newLine = options.newLineBytes
                try stream.write(end, offset: 0, count: end.count)
                try stream.write(newLine, offset: 0, count: newLine.count)
            }
            return
        }

        if contentTransferEncoding == .binary {
            try content.writeTo(stream)
            return
        }

        let filtered = try FilteredStream(stream)
        try filtered.add(options.createNewLineFilter(ensureNewLine))
        try content.writeTo(filtered)
        try filtered.flush()
    }

    public override func accept(_ visitor: MimeVisitor) {
        visitor.visit(self)
    }

    public override func headersChanged(_ action: HeaderListChangedAction, header: Header?) {
        super.headersChanged(action, header: header)

        switch action {
        case .cleared:
            contentDescriptionLoaded = false
            contentDurationLoaded = false
            contentMd5Loaded = false
            contentTransferEncodingLoaded = false
            return
        case .added, .changed, .removed:
            break
        }

        guard let header else { return }
        switch header.id {
        case .contentDescription:
            contentDescriptionLoaded = false
        case .contentDuration:
            contentDurationLoaded = false
        case .contentMd5:
            contentMd5Loaded = false
        case .contentTransferEncoding:
            contentTransferEncodingLoaded = false
        default:
            break
        }
    }

    internal func readAllBytes(content: MimeContent) throws -> [UInt8] {
        let stream = try content.open()
        var buffer = [UInt8](repeating: 0, count: 4096)
        var data: [UInt8] = []
        while true {
            let read = try stream.read(&buffer, offset: 0, count: buffer.count)
            if read == 0 {
                break
            }
            data.append(contentsOf: buffer[0..<read])
        }
        return data
    }

    private static func parseContentEncoding(_ value: String) -> ContentEncoding {
        switch value.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() {
        case "7bit":
            return .sevenBit
        case "8bit":
            return .eightBit
        case "binary":
            return .binary
        case "base64":
            return .base64
        case "quoted-printable":
            return .quotedPrintable
        case "x-uuencode", "uuencode":
            return .uuEncode
        default:
            return .default
        }
    }

    private static func formatContentEncoding(_ encoding: ContentEncoding) -> String {
        switch encoding {
        case .sevenBit:
            return "7bit"
        case .eightBit:
            return "8bit"
        case .binary:
            return "binary"
        case .base64:
            return "base64"
        case .quotedPrintable:
            return "quoted-printable"
        case .uuEncode:
            return "x-uuencode"
        case .default:
            return ""
        }
    }
}
