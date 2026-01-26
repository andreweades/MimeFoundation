//
// HtmlAttribute.swift
//
// Ported from MimeKit (C#) to Swift.
//

/// An HTML attribute.
///
/// Represents an HTML attribute with a name and optional value.
public final class HtmlAttribute {
    private var cachedId: HtmlAttributeId?

    /// Gets the name of the attribute.
    public let name: String

    /// Gets the value of the attribute.
    public let value: String?

    /// Initializes a new instance of the ``HtmlAttribute`` class.
    ///
    /// Creates a new HTML attribute with the given id and value.
    ///
    /// - Parameters:
    ///   - id: The attribute identifier. Must not be ``HtmlAttributeId/unknown``.
    ///   - value: The attribute value.
    public init(_ id: HtmlAttributeId, _ value: String?) {
        precondition(id != .unknown, "HtmlAttributeId.unknown is not valid for HtmlAttribute initialization.")
        self.name = id.attributeName
        self.value = value
        self.cachedId = id
    }

    /// Initializes a new instance of the ``HtmlAttribute`` class.
    ///
    /// Creates a new HTML attribute with the given name and value.
    ///
    /// - Parameters:
    ///   - name: The attribute name.
    ///   - value: The attribute value.
    public init(name: String, value: String?) {
        self.name = name
        self.value = value
        self.cachedId = nil
    }

    /// Gets the HTML attribute identifier.
    ///
    /// The identifier is lazily resolved from the name if not already known.
    public var id: HtmlAttributeId {
        if let cachedId {
            return cachedId
        }
        let resolved = HtmlAttributeId.from(name: name)
        cachedId = resolved
        return resolved
    }
}
