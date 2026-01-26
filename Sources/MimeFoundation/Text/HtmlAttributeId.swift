//
// HtmlAttributeId.swift
//
// Ported from MimeKit (C#) to Swift.
//

/// HTML attribute identifiers.
///
/// An enumeration of known HTML attribute identifiers used for efficient
/// attribute comparison without string matching.
public enum HtmlAttributeId: String, Sendable {
    /// An unknown HTML attribute identifier.
    case unknown = ""

    /// The "href" attribute.
    case href = "href"

    /// The "src" attribute.
    case src = "src"

    /// The "alt" attribute.
    case alt = "alt"

    /// The "xmlns" attribute.
    case xmlns = "xmlns"

    /// The "http-equiv" attribute.
    case httpEquiv = "http-equiv"

    /// The "content" attribute.
    case content = "content"

    /// The "charset" attribute.
    case charset = "charset"
}

/// Utility methods for ``HtmlAttributeId`` operations.
///
/// Provides methods for converting between attribute names and identifiers.
public enum HtmlAttributeIdUtils {
    private static let nameToId: [String: HtmlAttributeId] = [
        "href": .href,
        "src": .src,
        "alt": .alt,
        "xmlns": .xmlns,
        "http-equiv": .httpEquiv,
        "content": .content,
        "charset": .charset
    ]

    /// Converts the enum value into the equivalent attribute name.
    ///
    /// - Parameter id: The enum value.
    /// - Returns: The attribute name.
    public static func toAttributeName(_ id: HtmlAttributeId) -> String {
        if id == .unknown {
            return ""
        }
        return id.rawValue
    }

    /// Converts the attribute name into the equivalent attribute id.
    ///
    /// - Parameter name: The attribute name.
    /// - Returns: The attribute id.
    public static func toHtmlAttributeId(_ name: String) -> HtmlAttributeId {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            return .unknown
        }
        return nameToId[trimmed.lowercased()] ?? .unknown
    }
}

/// ``HtmlAttributeId`` extension methods.
public extension HtmlAttributeId {
    /// Gets the attribute name for this identifier.
    var attributeName: String {
        HtmlAttributeIdUtils.toAttributeName(self)
    }

    /// Creates an ``HtmlAttributeId`` from an attribute name string.
    ///
    /// - Parameter name: The attribute name.
    /// - Returns: The corresponding attribute identifier, or ``HtmlAttributeId/unknown`` if not recognized.
    static func from(name: String) -> HtmlAttributeId {
        HtmlAttributeIdUtils.toHtmlAttributeId(name)
    }
}
