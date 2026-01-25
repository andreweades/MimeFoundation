//
// HtmlAttributeId.swift
//
// Ported from MimeKit (C#) to Swift.
//

public enum HtmlAttributeId: String, Sendable {
    case unknown = ""
    case href = "href"
    case src = "src"
    case alt = "alt"
    case xmlns = "xmlns"
    case httpEquiv = "http-equiv"
    case content = "content"
    case charset = "charset"
}

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

    public static func toAttributeName(_ id: HtmlAttributeId) -> String {
        if id == .unknown {
            return ""
        }
        return id.rawValue
    }

    public static func toHtmlAttributeId(_ name: String) -> HtmlAttributeId {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            return .unknown
        }
        return nameToId[trimmed.lowercased()] ?? .unknown
    }
}

public extension HtmlAttributeId {
    var attributeName: String {
        HtmlAttributeIdUtils.toAttributeName(self)
    }

    static func from(name: String) -> HtmlAttributeId {
        HtmlAttributeIdUtils.toHtmlAttributeId(name)
    }
}
