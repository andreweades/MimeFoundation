//
// TextPart.swift
//
// Ported from MimeKit (C#) to Swift.
//

import Foundation

public enum TextPartError: Error, Equatable {
    case nilCharset
    case nilText
    case unsupportedCharset
}

public final class TextPart: MimePart {
    private var textStorage: String?

    private init(contentType: ContentType) {
        super.init(contentType)
        if contentType.charset == nil {
            contentType.charset = "utf-8"
        }
    }

    public var text: String? {
        get {
            if let textStorage {
                return textStorage
            }
            guard let content else {
                return nil
            }
            guard let data = try? readAllBytes(content: content) else {
                return nil
            }
            let charset = contentType.charset ?? "utf-8"
            let encoding = CharsetUtils.getEncoding(charset) ?? .utf8
            let decoded = String(data: Data(data), encoding: encoding)
            if let decoded {
                let normalized = decoded.replacingOccurrences(of: "\r\n", with: "\n")
                textStorage = normalized
                return normalized
            }
            return nil
        }
        set {
            if let value = newValue {
                _ = try? setText(contentType.charset ?? "utf-8", value)
            } else {
                textStorage = nil
                content = nil
            }
        }
    }

    public convenience init(_ subtype: String) {
        let contentType = try! ContentType("text", subtype)
        self.init(contentType: contentType)
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
        case .richText:
            let contentType = try! ContentType("text", "richtext")
            self.init(contentType: contentType)
        case .compressedRichText:
            let contentType = try! ContentType("text", "compressed-richtext")
            self.init(contentType: contentType)
        }
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
        let normalized = TextPart.normalizeNewLines(text)
        let bytes = CharsetUtils.getBytes(normalized, encoding: encoding)
        content = try MimeContent(MemoryStream(bytes, writable: false))
        textStorage = text
        contentType.charset = CharsetUtils.getMimeCharset(encoding)
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
        return String(data: Data(data), encoding: encoding) ?? ""
    }

    private static func normalizeNewLines(_ text: String) -> String {
        var result = ""
        var index = text.startIndex
        while index < text.endIndex {
            let ch = text[index]
            if ch == "\r" {
                let next = text.index(after: index)
                if next < text.endIndex, text[next] == "\n" {
                    index = next
                }
                result.append("\r\n")
            } else if ch == "\n" {
                result.append("\r\n")
            } else {
                result.append(ch)
            }
            index = text.index(after: index)
        }
        return result
    }
}
