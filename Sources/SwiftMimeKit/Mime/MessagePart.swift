//
// MessagePart.swift
//
// Ported from MimeKit (C#) to Swift.
//

public enum MessagePartError: Error, Equatable {
    case nilArgs
    case duplicateMessage
    case invalidArgument
    case invalidMaxLineLength
}

open class MessagePart: MimeEntity {
    public var message: MimeMessage?

    public override init(_ contentType: ContentType) {
        super.init(contentType)
    }

    public convenience init(_ subtype: String) {
        let contentType = try! ContentType("message", subtype)
        self.init(contentType)
    }

    public convenience init() {
        self.init("rfc822")
    }

    public convenience init(_ subtype: String, _ args: Any?...) throws {
        try self.init(subtype, args: args)
    }

    public convenience init(_ subtype: String, args: [Any?]?) throws {
        guard let args else {
            throw MessagePartError.nilArgs
        }
        self.init(subtype)
        try applyArgs(args)
    }

    public func prepare(_ constraint: EncodingConstraint, maxLineLength: Int = FormatOptions.defaultMaxLineLength) throws {
        if maxLineLength < FormatOptions.minimumLineLength || maxLineLength > FormatOptions.maximumLineLength {
            throw MessagePartError.invalidMaxLineLength
        }
        try message?.prepare(constraint, maxLineLength: maxLineLength)
    }

    public override func accept(_ visitor: MimeVisitor?) throws {
        guard let visitor else {
            throw MimeEntityError.nilVisitor
        }
        visitor.visit(self)
    }

    public override func writeTo(_ options: FormatOptions?, _ stream: MimeStream?) throws {
        try super.writeTo(options, stream)
        guard let options, let stream else {
            return
        }
        if let message {
            try message.writeTo(options, stream)
        }
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
                    throw MessagePartError.duplicateMessage
                }
                message = value
                continue
            }
            throw MessagePartError.invalidArgument
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
