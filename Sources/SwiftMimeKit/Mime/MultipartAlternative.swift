//
// MultipartAlternative.swift
//
// Ported from MimeKit (C#) to Swift.
//

import Foundation

public final class MultipartAlternative: Multipart {
    public override init(_ contentType: ContentType) {
        super.init(contentType)
    }

    public convenience init(_ args: Any?...) throws {
        try self.init(args: args)
    }

    public init(args: [Any?]?) throws {
        guard let args else {
            throw MultipartError.nilArgs
        }
        try super.init("alternative")
        try applyArgs(args)
    }

    public convenience init() {
        try! self.init(args: [])
    }

    public var textBody: String? {
        getTextBody(.plain)
    }

    public var htmlBody: String? {
        getTextBody(.html)
    }

    public override func accept(_ visitor: MimeVisitor?) throws {
        guard let visitor else {
            throw MimeEntityError.nilVisitor
        }
        visitor.visit(self)
    }

    public func getTextBody(_ format: TextFormat) -> String? {
        var body: TextPart? = nil
        if tryGetValue(format, body: &body), let body {
            return MultipartAlternative.getText(body)
        }
        return nil
    }

    internal static func getText(_ text: TextPart) -> String {
        guard let value = text.text else {
            return ""
        }
        return value
    }

    public override func tryGetValue(_ format: TextFormat, body: inout TextPart?) -> Bool {
        if count == 0 {
            body = nil
            return false
        }

        for index in stride(from: count - 1, through: 0, by: -1) {
            let entity = self[index]
            if let multipart = entity as? Multipart {
                if multipart.tryGetValue(format, body: &body) {
                    return true
                }
            }

            if let text = entity as? TextPart, text.isFormat(format) {
                body = text
                return true
            }
        }

        body = nil
        return false
    }
}
