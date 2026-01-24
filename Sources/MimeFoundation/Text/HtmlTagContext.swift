//
// HtmlTagContext.swift
//
// Ported from MimeKit (C#) to Swift.
//

public typealias HtmlTagCallback = (_ tagContext: HtmlTagContext, _ htmlWriter: HtmlWriter) -> Void

open class HtmlTagContext {
    public let tagId: HtmlTagId

    public var suppressInnerContent: Bool = false
    public var deleteEndTag: Bool = false
    public var deleteTag: Bool = false
    public var invokeCallbackForEndTag: Bool = false

    public init(_ tagId: HtmlTagId) {
        self.tagId = tagId
    }

    open var tagName: String {
        tagId.htmlTagName
    }

    open var attributes: HtmlAttributeCollection {
        HtmlAttributeCollection.empty
    }

    open var isEmptyElementTag: Bool {
        tagId.isEmptyElement
    }

    open var isEndTag: Bool {
        false
    }

    public func writeTag(_ htmlWriter: HtmlWriter) {
        writeTag(htmlWriter, writeAttributes: false)
    }

    public func writeTag(_ htmlWriter: HtmlWriter, writeAttributes: Bool) {
        if deleteTag {
            return
        }

        if isEndTag {
            htmlWriter.writeEndTag(tagName)
            return
        }

        if isEmptyElementTag {
            htmlWriter.writeEmptyElementTag(tagName)
        } else {
            htmlWriter.writeStartTag(tagName)
        }

        if writeAttributes {
            for i in 0..<attributes.count {
                htmlWriter.writeAttribute(attributes[i])
            }
        }
    }
}
