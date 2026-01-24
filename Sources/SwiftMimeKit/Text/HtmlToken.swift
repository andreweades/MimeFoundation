//
// HtmlToken.swift
//
// Ported from MimeKit (C#) to Swift.
//

open class HtmlToken {
    public let kind: HtmlTokenKind

    public init(kind: HtmlTokenKind) {
        self.kind = kind
    }
}

public final class HtmlDataToken: HtmlToken {
    public let data: String

    public init(_ data: String) {
        self.data = data
        super.init(kind: .data)
    }
}

public final class HtmlCommentToken: HtmlToken {
    public let comment: String

    public init(_ comment: String) {
        self.comment = comment
        super.init(kind: .comment)
    }
}

public final class HtmlTagToken: HtmlToken {
    public let name: String
    public let attributes: HtmlAttributeCollection
    public let isEndTag: Bool
    public let isEmptyElement: Bool

    private lazy var cachedId: HtmlTagId = HtmlTagId.from(tagName: name)

    public init(name: String, attributes: [HtmlAttribute], isEndTag: Bool, isEmptyElement: Bool) {
        self.name = name
        self.attributes = HtmlAttributeCollection(attributes)
        self.isEndTag = isEndTag
        self.isEmptyElement = isEmptyElement
        super.init(kind: .tag)
    }

    public var id: HtmlTagId {
        cachedId
    }
}
