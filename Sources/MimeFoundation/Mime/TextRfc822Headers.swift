//
// TextRfc822Headers.swift
//
// Ported from MimeKit (C#) to Swift.
//

public enum TextRfc822HeadersError: Error, Equatable {
    case nilArgs
    case duplicateMessage
    case invalidArgument
}

public final class TextRfc822Headers: MessagePart {
    public override init(_ contentType: ContentType) {
        super.init(contentType)
    }

    public convenience init() {
        let contentType = try! ContentType("text", "rfc822-headers")
        self.init(contentType)
    }

    public convenience init(_ args: Any?...) throws {
        try self.init(args: args)
    }

    public convenience init(args: [Any?]?) throws {
        guard let args else {
            throw TextRfc822HeadersError.nilArgs
        }
        self.init()
        try applyArgs(args)
    }

    public override func accept(_ visitor: MimeVisitor?) throws {
        guard let visitor else {
            throw MimeEntityError.nilVisitor
        }
        visitor.visit(self)
    }

    private func applyArgs(_ args: [Any?]) throws {
        var message: MimeMessage?

        for obj in args {
            guard let obj else { continue }
            if tryInit(obj) {
                continue
            }
            if let value = obj as? MimeMessage {
                if message != nil {
                    throw TextRfc822HeadersError.duplicateMessage
                }
                message = value
                continue
            }
            throw TextRfc822HeadersError.invalidArgument
        }

        if let message {
            self.message = message
        }
    }

    private func tryInit(_ obj: Any) -> Bool {
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
}
