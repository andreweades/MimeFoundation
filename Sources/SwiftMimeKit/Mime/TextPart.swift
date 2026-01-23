//
// TextPart.swift
//
// Ported from MimeKit (C#) to Swift.
//

import Foundation

public enum TextPartError: Error, Equatable {
    case nilArgs
    case nilCharset
    case nilText
    case unsupportedCharset
    case duplicateEncoding
    case duplicateText
    case invalidArgument
}

open class TextPart: MimePart {
    private var textStorage: String?
    private var textLoaded = false

    public override init(_ contentType: ContentType) {
        super.init(contentType)
    }

    public var text: String? {
        get {
            if textLoaded {
                return textStorage
            }
            var encoding: String.Encoding? = nil
            let value = getText(&encoding)
            textStorage = value
            textLoaded = true
            return value
        }
        set {
            textLoaded = true
            if let value = newValue {
                _ = try? setText(.utf8, value)
                textStorage = value
            } else {
                textStorage = nil
                content = nil
            }
        }
    }

    public convenience init(_ subtype: String) {
        let contentType = try! ContentType("text", subtype)
        self.init(contentType)
    }

    public convenience init(_ subtype: String, _ args: Any?...) throws {
        try self.init(subtype, args: args)
    }

    @available(*, unavailable, message: "Use TextPart(subtype:args:) or TextPart(format:) for text parts.")
    public convenience init(_ mediaType: String, _ mediaSubtype: String, _ args: Any...) throws {
        fatalError("Use TextPart(subtype:args:) instead.")
    }

    public convenience init(_ subtype: String, _ text: String) {
        self.init(subtype)
        _ = try? setText(.utf8, text)
    }

    public convenience init(_ subtype: String, args: [Any?]?) throws {
        guard let args else {
            throw TextPartError.nilArgs
        }
        self.init(subtype)
        try applyArgs(args)
    }

    public convenience init(_ format: TextFormat) {
        switch format {
        case .plain:
            self.init("plain")
        case .flowed:
            self.init("plain")
            contentType.format = "flowed"
        case .html:
            self.init("html")
        case .enriched:
            self.init("enriched")
        case .richText, .compressedRichText:
            let contentType = try! ContentType("text", "rtf")
            self.init(contentType)
        }
    }

    public convenience init() {
        self.init("plain")
    }

    private func applyArgs(_ args: [Any?]) throws {
        var encoding: String.Encoding?
        var text: String?

        for obj in args {
            guard let obj else { continue }
            if tryInit(obj) {
                continue
            }
            if let enc = obj as? String.Encoding {
                if encoding != nil {
                    throw TextPartError.duplicateEncoding
                }
                encoding = enc
                continue
            }
            if let value = obj as? String {
                if text != nil {
                    throw TextPartError.duplicateText
                }
                text = value
                continue
            }
            throw TextPartError.invalidArgument
        }

        if let text {
            try setText(encoding ?? .utf8, text)
        }
    }

    public var format: TextFormat {
        if isMimeType("text", "plain") {
            if let format = contentType.format?.trimmingCharacters(in: .whitespacesAndNewlines),
               format.caseInsensitiveCompare("flowed") == .orderedSame {
                return .flowed
            }
            return .plain
        }
        if isMimeType("text", "html") {
            return .html
        }
        if isMimeType("text", "rtf") {
            return .richText
        }
        if isMimeType("text", "enriched") || isMimeType("text", "richtext") {
            return .enriched
        }
        if isMimeType("application", "rtf") {
            return .richText
        }
        return .plain
    }

    public var isHtml: Bool {
        isMimeType("text", "html")
    }

    public var isPlain: Bool {
        isMimeType("text", "plain")
    }

    public var isFlowed: Bool {
        guard isPlain,
              let format = contentType.format?.trimmingCharacters(in: .whitespacesAndNewlines) else {
            return false
        }
        return format.caseInsensitiveCompare("flowed") == .orderedSame
    }

    public var isEnriched: Bool {
        isMimeType("text", "enriched") || isMimeType("text", "richtext")
    }

    public var isRichText: Bool {
        isMimeType("text", "rtf") || isMimeType("application", "rtf")
    }

    public func isFormat(_ format: TextFormat) -> Bool {
        switch format {
        case .plain:
            return isPlain
        case .flowed:
            return isFlowed
        case .html:
            return isHtml
        case .enriched:
            return isEnriched
        case .richText:
            return isRichText
        case .compressedRichText:
            return false
        }
    }

    public func tryDetectEncoding(
        _ encoding: inout String.Encoding?,
        confidence: inout TextEncodingConfidence
    ) -> Bool {
        if content == nil {
            confidence = .irrelevant
            encoding = .ascii
            return true
        }

        if let charsetEncoding = contentType.charsetEncoding {
            confidence = .certain
            encoding = charsetEncoding
            return true
        }

        if let content, let bomEncoding = tryDetectBomEncoding(content) {
            confidence = .certain
            encoding = bomEncoding
            return true
        }

        if isHtml, let content {
            return TextPart.tryDetectHtmlEncoding(content, encoding: &encoding, confidence: &confidence)
        }

        confidence = .undefined
        encoding = nil
        return false
    }

    public func getText(_ encoding: inout String.Encoding?) -> String {
        var detectedConfidence: TextEncodingConfidence = .undefined
        if !tryDetectEncoding(&encoding, confidence: &detectedConfidence) {
            encoding = .utf8
        }
        if let encoding, let decoded = try? decodeText(using: encoding) {
            return TextPart.normalizeNewLines(decoded, newLine: FormatOptions.default.newLine)
        }
        encoding = .isoLatin1
        if let decoded = try? decodeText(using: .isoLatin1) {
            return TextPart.normalizeNewLines(decoded, newLine: FormatOptions.default.newLine)
        }
        return ""
    }

    public func setText(_ charset: String?, _ text: String?) throws {
        guard let charset else {
            throw TextPartError.nilCharset
        }
        guard let text else {
            throw TextPartError.nilText
        }
        guard let encoding = CharsetUtils.getEncoding(charset) else {
            throw TextPartError.unsupportedCharset
        }
        try setText(encoding, text)
        contentType.charset = CharsetUtils.getMimeCharset(encoding)
    }

    public func setText(_ encoding: String.Encoding?, _ text: String?) throws {
        guard let encoding else {
            throw TextPartError.nilCharset
        }
        guard let text else {
            throw TextPartError.nilText
        }
        let normalized = TextPart.normalizeNewLines(text, newLine: "\r\n")
        let bytes = CharsetUtils.getBytes(normalized, encoding: encoding)
        content = try MimeContent(MemoryStream(bytes, writable: false))
        textStorage = text
        textLoaded = true
        contentType.charset = CharsetUtils.getMimeCharset(encoding)
    }

    public override func accept(_ visitor: MimeVisitor?) throws {
        guard let visitor else {
            throw MimeEntityError.nilVisitor
        }
        visitor.visit(self)
    }

    public override func writeTo(_ options: FormatOptions?, _ stream: MimeStream?) throws {
        guard let options else {
            throw MimeEntityError.nilOptions
        }
        guard let stream else {
            throw MimeEntityError.nilStream
        }

        if contentTransferEncoding == .base64 || contentTransferEncoding == .quotedPrintable || contentTransferEncoding == .uuEncode {
            try super.writeTo(options, stream)
            return
        }

        try writeHeaders(options, stream: stream)
        guard let content else { return }

        let data = try readAllBytes(content: content)
        if options.newLine == "\n" {
            let normalized = TextPart.normalizeNewLines(data)
            try stream.write(normalized, offset: 0, count: normalized.count)
        } else {
            try stream.write(data, offset: 0, count: data.count)
        }
    }

    private static func normalizeNewLines(_ bytes: [UInt8]) -> [UInt8] {
        var output: [UInt8] = []
        output.reserveCapacity(bytes.count)
        var index = 0
        while index < bytes.count {
            let byte = bytes[index]
            if byte == 0x0D {
                if index + 1 < bytes.count, bytes[index + 1] == 0x0A {
                    output.append(0x0A)
                    index += 2
                    continue
                }
            }
            output.append(byte)
            index += 1
        }
        return output
    }

    public func getText(_ charset: String?) throws -> String {
        guard let charset else {
            throw TextPartError.nilCharset
        }
        guard let encoding = CharsetUtils.getEncoding(charset) else {
            throw TextPartError.unsupportedCharset
        }
        return try getText(encoding)
    }

    public func getText(_ encoding: String.Encoding?) throws -> String {
        guard let encoding else {
            throw TextPartError.nilCharset
        }
        guard let content else {
            return ""
        }
        let data = try readAllBytes(content: content)
        if let decoded = String(data: Data(data), encoding: encoding) {
            return TextPart.normalizeNewLines(decoded, newLine: FormatOptions.default.newLine)
        }
        return ""
    }

    private func decodeText(using encoding: String.Encoding) throws -> String? {
        guard let content else {
            return ""
        }
        let data = try readAllBytes(content: content)
        return String(data: Data(data), encoding: encoding)
    }

    private func isMimeType(_ mediaType: String, _ mediaSubtype: String) -> Bool {
        (try? contentType.isMimeType(mediaType, mediaSubtype)) ?? false
    }

    private enum HtmlTagState {
        case none
        case html
        case head
        case stop
    }

    private struct HtmlTag {
        let name: String
        let isEndTag: Bool
        let isEmptyElement: Bool
        let attributes: [(String, String?)]
    }

    private static func tryDetectHtmlEncoding(
        _ content: MimeContent,
        encoding: inout String.Encoding?,
        confidence: inout TextEncodingConfidence
    ) -> Bool {
        guard let bytes = try? readPrefix(content, length: 1024) else {
            confidence = .undefined
            encoding = nil
            return false
        }
        guard let text = String(data: Data(bytes), encoding: .isoLatin1) else {
            confidence = .undefined
            encoding = nil
            return false
        }

        var state: HtmlTagState = .none
        var index = text.startIndex

        while let open = text[index...].firstIndex(of: "<") {
            guard let close = text[open...].firstIndex(of: ">") else {
                break
            }

            let tagText = String(text[text.index(after: open)..<close])
            index = text.index(after: close)

            guard let tag = parseHtmlTag(tagText) else {
                continue
            }

            switch tag.name {
            case "html":
                if state == .none {
                    if tag.isEndTag || tag.isEmptyElement {
                        state = .stop
                    } else {
                        state = .html
                    }
                }
            case "head":
                if state == .html {
                    if tag.isEndTag || tag.isEmptyElement {
                        state = .stop
                    } else {
                        state = .head
                    }
                }
            case "meta":
                if state == .head && !tag.isEndTag {
                    if let detected = detectMetaCharset(tag.attributes) {
                        encoding = detected
                        if encoding == .utf16 || encoding == .utf16BigEndian || encoding == .utf16LittleEndian {
                            encoding = .utf8
                        }
                        confidence = .tentative
                        return true
                    }
                }
            case "body":
                state = .stop
            default:
                break
            }

            if state == .stop {
                break
            }
        }

        confidence = .undefined
        encoding = nil
        return false
    }

    private static func detectMetaCharset(_ attributes: [(String, String?)]) -> String.Encoding? {
        var seen = Set<String>()
        var gotPragma = false
        var needPragma: Bool? = nil
        var charset: String? = nil

        for (name, value) in attributes {
            let key = name.lowercased()
            if !seen.insert(key).inserted {
                continue
            }
            guard let value else {
                continue
            }
            switch key {
            case "http-equiv":
                if value.caseInsensitiveCompare("Content-Type") == .orderedSame {
                    gotPragma = true
                }
            case "content":
                if charset == nil {
                    var parsed: ContentType?
                    if ContentType.tryParse(value, contentType: &parsed),
                       let parsed,
                       let param = parsed.charset,
                       !param.isEmpty {
                        charset = param.trimmingCharacters(in: .whitespacesAndNewlines)
                        needPragma = true
                    }
                }
            case "charset":
                if !value.isEmpty {
                    charset = value.trimmingCharacters(in: .whitespacesAndNewlines)
                    needPragma = false
                }
            default:
                break
            }
        }

        guard let charset, let needPragma else {
            return nil
        }

        if needPragma && !gotPragma {
            return nil
        }

        var effective = charset
        if charset.caseInsensitiveCompare("x-user-defined") == .orderedSame {
            effective = "windows-1252"
        }

        return CharsetUtils.getEncoding(effective)
    }

    private static func parseHtmlTag(_ text: String) -> HtmlTag? {
        var tagText = text.trimmingCharacters(in: .whitespacesAndNewlines)
        if tagText.isEmpty {
            return nil
        }

        var isEndTag = false
        if tagText.first == "/" {
            isEndTag = true
            tagText.removeFirst()
            tagText = tagText.trimmingCharacters(in: .whitespacesAndNewlines)
        }

        var isEmptyElement = false
        if tagText.hasSuffix("/") {
            isEmptyElement = true
            tagText.removeLast()
            tagText = tagText.trimmingCharacters(in: .whitespacesAndNewlines)
        }

        let nameEnd = tagText.firstIndex(where: { $0.isWhitespace }) ?? tagText.endIndex
        let name = String(tagText[..<nameEnd]).lowercased()
        let rest = nameEnd < tagText.endIndex ? String(tagText[tagText.index(after: nameEnd)...]) : ""
        let attributes = parseHtmlAttributes(rest)

        if name.isEmpty {
            return nil
        }

        return HtmlTag(name: name, isEndTag: isEndTag, isEmptyElement: isEmptyElement, attributes: attributes)
    }

    private static func parseHtmlAttributes(_ text: String) -> [(String, String?)] {
        var attributes: [(String, String?)] = []
        var index = text.startIndex

        func skipWhitespace() {
            while index < text.endIndex, text[index].isWhitespace {
                index = text.index(after: index)
            }
        }

        func isNameChar(_ ch: Character) -> Bool {
            guard let scalar = ch.unicodeScalars.first, ch.unicodeScalars.count == 1 else {
                return false
            }
            let value = scalar.value
            return (value >= 0x41 && value <= 0x5A)
                || (value >= 0x61 && value <= 0x7A)
                || (value >= 0x30 && value <= 0x39)
                || value == 0x2D
                || value == 0x5F
                || value == 0x3A
        }

        while index < text.endIndex {
            skipWhitespace()
            if index >= text.endIndex {
                break
            }

            let nameStart = index
            while index < text.endIndex, isNameChar(text[index]) {
                index = text.index(after: index)
            }

            if index == nameStart {
                break
            }

            let name = String(text[nameStart..<index])
            skipWhitespace()

            var value: String? = nil
            if index < text.endIndex, text[index] == "=" {
                index = text.index(after: index)
                skipWhitespace()
                if index < text.endIndex {
                    if text[index] == "\"" || text[index] == "'" {
                        let quote = text[index]
                        index = text.index(after: index)
                        let valueStart = index
                        while index < text.endIndex, text[index] != quote {
                            index = text.index(after: index)
                        }
                        value = String(text[valueStart..<index])
                        if index < text.endIndex {
                            index = text.index(after: index)
                        }
                    } else {
                        let valueStart = index
                        while index < text.endIndex, !text[index].isWhitespace {
                            index = text.index(after: index)
                        }
                        value = String(text[valueStart..<index])
                    }
                } else {
                    value = ""
                }
            }

            attributes.append((name.lowercased(), value))
        }

        return attributes
    }

    private static func readPrefix(_ content: MimeContent, length: Int) throws -> [UInt8] {
        let stream = try content.open()
        var buffer = [UInt8](repeating: 0, count: length)
        let read = try stream.read(&buffer, offset: 0, count: length)
        if read <= 0 {
            return []
        }
        return Array(buffer[0..<read])
    }

    private func tryDetectBomEncoding(_ content: MimeContent) -> String.Encoding? {
        guard let bytes = try? TextPart.readPrefix(content, length: 3), !bytes.isEmpty else {
            return nil
        }
        if bytes.count >= 3, bytes[0] == 0xEF, bytes[1] == 0xBB, bytes[2] == 0xBF {
            return .utf8
        }
        if bytes.count >= 2, bytes[0] == 0xFE, bytes[1] == 0xFF {
            return .utf16BigEndian
        }
        if bytes.count >= 2, bytes[0] == 0xFF, bytes[1] == 0xFE {
            return .utf16LittleEndian
        }
        return nil
    }

    private static func normalizeNewLines(_ text: String, newLine: String) -> String {
        var result = ""
        let scalars = Array(text.unicodeScalars)
        var index = 0
        while index < scalars.count {
            let scalar = scalars[index]
            if scalar == "\r" {
                if index + 1 < scalars.count, scalars[index + 1] == "\n" {
                    index += 1
                }
                result.append(contentsOf: newLine)
            } else if scalar == "\n" {
                result.append(contentsOf: newLine)
            } else {
                result.unicodeScalars.append(scalar)
            }
            index += 1
        }
        return result
    }
}
