//
// MultipartAlternative.swift
//
// Ported from MimeKit (C#) to Swift.
//

import Foundation

/// A multipart/alternative MIME entity.
///
/// A ``MultipartAlternative`` contains multiple alternative representations of the same
/// content, ordered from least faithful to most faithful. For example, a message might
/// contain both plain text and HTML versions of the same content, with the HTML version
/// listed last as the preferred format.
///
/// Typically, the first alternative is plain text and the last alternative is HTML, but
/// more complex arrangements are possible.
///
/// ## Topics
///
/// ### Creating Multipart Alternative Entities
/// - ``init()``
/// - ``init(_:)``
/// - ``init(args:)``
///
/// ### Accessing Content
/// - ``textBody``
/// - ``htmlBody``
/// - ``getTextBody(_:)``
public final class MultipartAlternative: Multipart {
    public override init(_ contentType: ContentType) {
        super.init(contentType)
    }

    public convenience init(_ args: Any?...) throws {
        try self.init(args: args)
    }

    public init(args: [Any?]) throws {
        try super.init("alternative")
        try applyArgs(args)
    }

    /// Initializes a new multipart/alternative entity.
    ///
    /// Creates a new multipart/alternative entity with an automatically generated boundary.
    public convenience init() {
        do {
            try self.init(args: [])
        } catch {
            preconditionFailure("Failed to create multipart/alternative - this is a programming error")
        }
    }

    /// The plain text body of the multipart/alternative, if available.
    ///
    /// Searches the alternatives for a plain text body, preferring alternatives
    /// that appear later in the list.
    public var textBody: String? {
        getTextBody(.plain)
    }

    /// The HTML body of the multipart/alternative, if available.
    ///
    /// Searches the alternatives for an HTML body, preferring alternatives
    /// that appear later in the list.
    public var htmlBody: String? {
        getTextBody(.html)
    }

    public override func accept(_ visitor: MimeVisitor) {
        visitor.visit(self)
    }

    /// Gets the text body in the specified format.
    ///
    /// Searches the alternatives for a body in the specified format, preferring
    /// alternatives that appear later in the list.
    ///
    /// - Parameter format: The desired text format.
    /// - Returns: The text body in the specified format, or `nil` if not found.
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
