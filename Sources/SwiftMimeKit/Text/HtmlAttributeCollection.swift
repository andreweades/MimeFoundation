//
// HtmlAttributeCollection.swift
//
// Ported from MimeKit (C#) to Swift.
//

public final class HtmlAttributeCollection: Sequence {
    public static var empty: HtmlAttributeCollection {
        HtmlAttributeCollection()
    }

    private var attributes: [HtmlAttribute]

    public init(_ attributes: [HtmlAttribute] = []) {
        self.attributes = attributes
    }

    public var count: Int {
        attributes.count
    }

    public subscript(index: Int) -> HtmlAttribute {
        attributes[index]
    }

    public func add(_ attribute: HtmlAttribute) {
        attributes.append(attribute)
    }

    public func makeIterator() -> IndexingIterator<[HtmlAttribute]> {
        attributes.makeIterator()
    }

    public func contains(_ id: HtmlAttributeId) -> Bool {
        attributes.contains { $0.id == id }
    }

    public func indexOf(_ id: HtmlAttributeId) -> Int? {
        attributes.firstIndex { $0.id == id }
    }

    public func tryGetValue(_ id: HtmlAttributeId) -> HtmlAttribute? {
        attributes.first { $0.id == id }
    }

    public func tryGetValue(_ name: String) -> HtmlAttribute? {
        attributes.first { $0.name.caseInsensitiveCompare(name) == .orderedSame }
    }
}
