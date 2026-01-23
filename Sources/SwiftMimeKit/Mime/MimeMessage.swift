//
// MimeMessage.swift
//
// Ported from MimeKit (C#) to Swift.
//

public enum MimeMessageError: Error, Equatable {
    case invalidMaxLineLength
}

public final class MimeMessage {
    public let headers: HeaderList
    public var body: MimeEntity?

    public init() {
        self.headers = HeaderList()
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
}
