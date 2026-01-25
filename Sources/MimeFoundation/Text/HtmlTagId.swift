//
// HtmlTagId.swift
//
// Ported from MimeKit (C#) to Swift.
//

public enum HtmlTagId: String, Sendable {
    case unknown = ""
    case a = "a"
    case blockQuote = "blockquote"
    case br = "br"
    case p = "p"
    case html = "html"
    case head = "head"
    case body = "body"
    case title = "title"
    case meta = "meta"
    case image = "img"
    case script = "script"
    case style = "style"
    case div = "div"
    case span = "span"
    case table = "table"
    case tbody = "tbody"
    case tr = "tr"
    case td = "td"
    case center = "center"
    case link = "link"
    case hr = "hr"
    case input = "input"
}

public enum HtmlTagIdUtils {
    private static let nameToId: [String: HtmlTagId] = {
        var map: [String: HtmlTagId] = [:]
        for id in [HtmlTagId.a, .blockQuote, .br, .p, .html, .head, .body, .title, .meta, .image, .script, .style, .div, .span, .table, .tbody, .tr, .td, .center, .link, .hr, .input] {
            map[id.rawValue] = id
        }
        return map
    }()

    private static let emptyElements: Set<HtmlTagId> = [
        .br,
        .meta,
        .image,
        .hr,
        .link,
        .input
    ]

    public static func toHtmlTagName(_ id: HtmlTagId) -> String {
        if id == .unknown {
            return ""
        }
        return id.rawValue
    }

    public static func toHtmlTagId(_ name: String) -> HtmlTagId {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            return .unknown
        }
        if let mapped = nameToId[trimmed.lowercased()] {
            return mapped
        }
        return .unknown
    }

    public static func isEmptyElement(_ id: HtmlTagId) -> Bool {
        emptyElements.contains(id)
    }
}

public extension HtmlTagId {
    var htmlTagName: String {
        HtmlTagIdUtils.toHtmlTagName(self)
    }

    var isEmptyElement: Bool {
        HtmlTagIdUtils.isEmptyElement(self)
    }

    static func from(tagName: String) -> HtmlTagId {
        HtmlTagIdUtils.toHtmlTagId(tagName)
    }
}
