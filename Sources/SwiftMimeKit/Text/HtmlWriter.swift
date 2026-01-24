//
// HtmlWriter.swift
//
// Ported from MimeKit (C#) to Swift.
//

public final class HtmlWriter {
    private let writer: TextWritable
    private var state: HtmlWriterState = .default
    private var emptyElement = false

    public init(_ writer: TextWritable) {
        self.writer = writer
    }

    public func flush() {
        flushWriterState()
    }

    public func writeMarkupText(_ text: String) {
        flushWriterState()
        if !text.isEmpty {
            writer.write(text)
        }
    }

    public func writeText(_ text: String) {
        flushWriterState()
        if !text.isEmpty {
            HtmlUtils.htmlEncode(writer, text)
        }
    }

    public func writeText(_ buffer: [Character], _ startIndex: Int, _ count: Int) {
        guard count > 0, startIndex >= 0, startIndex + count <= buffer.count else {
            return
        }
        let slice = buffer[startIndex..<(startIndex + count)]
        writeText(String(slice))
    }

    public func writeAttributeName(_ name: String) {
        guard state != .default else {
            return
        }
        writer.write(" ")
        writer.write(name)
        writer.write("=")
        state = .attribute
    }

    public func writeAttributeName(_ id: HtmlAttributeId) {
        writeAttributeName(id.attributeName)
    }

    public func writeAttributeValue(_ value: String) {
        guard state == .attribute else {
            return
        }
        HtmlUtils.htmlAttributeEncode(writer, value)
        state = .tag
    }

    public func writeAttribute(_ attribute: HtmlAttribute) {
        writeAttributeName(attribute.name)
        if let value = attribute.value {
            writeAttributeValue(value)
        }
    }

    public func writeEmptyElementTag(_ name: String) {
        flushWriterState()
        writer.write("<")
        writer.write(name)
        state = .tag
        emptyElement = true
    }

    public func writeStartTag(_ name: String) {
        flushWriterState()
        writer.write("<")
        writer.write(name)
        state = .tag
        emptyElement = false
    }

    public func writeEndTag(_ name: String) {
        flushWriterState()
        writer.write("</")
        writer.write(name)
        writer.write(">")
    }

    public func writeToken(_ token: HtmlToken) {
        flushWriterState()

        switch token.kind {
        case .data:
            if let dataToken = token as? HtmlDataToken {
                writer.write(dataToken.data)
            }
        case .comment:
            if let commentToken = token as? HtmlCommentToken {
                writer.write("<!--")
                writer.write(commentToken.comment)
                writer.write("-->")
            }
        case .tag:
            if let tagToken = token as? HtmlTagToken {
                if tagToken.isEndTag {
                    writeEndTag(tagToken.name)
                } else if tagToken.isEmptyElement || tagToken.id.isEmptyElement {
                    writeEmptyElementTag(tagToken.name)
                    for i in 0..<tagToken.attributes.count {
                        writeAttribute(tagToken.attributes[i])
                    }
                } else {
                    writeStartTag(tagToken.name)
                    for i in 0..<tagToken.attributes.count {
                        writeAttribute(tagToken.attributes[i])
                    }
                }
            }
        }
    }

    private func flushWriterState() {
        if state != .default {
            state = .default
            writer.write(emptyElement ? "/>" : ">")
            emptyElement = false
        }
    }
}
