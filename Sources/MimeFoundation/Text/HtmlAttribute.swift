//
// HtmlAttribute.swift
//
// Ported from MimeKit (C#) to Swift.
//

public final class HtmlAttribute {
    private var cachedId: HtmlAttributeId?

    public let name: String
    public let value: String?

    public init(_ id: HtmlAttributeId, _ value: String?) {
        precondition(id != .unknown, "HtmlAttributeId.unknown is not valid for HtmlAttribute initialization.")
        self.name = id.attributeName
        self.value = value
        self.cachedId = id
    }

    public init(name: String, value: String?) {
        self.name = name
        self.value = value
        self.cachedId = nil
    }

    public var id: HtmlAttributeId {
        if let cachedId {
            return cachedId
        }
        let resolved = HtmlAttributeId.from(name: name)
        cachedId = resolved
        return resolved
    }
}
