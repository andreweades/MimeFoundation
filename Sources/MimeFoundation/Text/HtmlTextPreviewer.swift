//
// HtmlTextPreviewer.swift
//
// Ported from MimeKit (C#) to Swift.
//

import Foundation

/// A text previewer for HTML content.
public class HtmlTextPreviewer: TextPreviewer {
    /// Initialize a new instance of the `HtmlTextPreviewer` class.
    public override init() {
        super.init()
    }

    /// Get the input format.
    public override var inputFormat: TextFormat {
        .html
    }

    private static func isWhiteSpace(_ c: Character) -> Bool {
        if c.isWhitespace {
            return true
        }
        for scalar in c.unicodeScalars {
            let v = scalar.value
            if v >= 0x200B && v <= 0x200D {
                return true
            }
        }
        return false
    }

    private static func append(_ preview: inout String, previewLength: inout Int, maximumLength: Int, value: String, lwsp: inout Bool) -> Bool {
        let chars = Array(value)
        var i = 0
        while i < chars.count && previewLength < maximumLength {
            let c = chars[i]
            if isWhiteSpace(c) {
                if !lwsp {
                    preview.append(" ")
                    previewLength += 1
                    lwsp = true
                }
            } else {
                preview.append(c)
                previewLength += 1
                lwsp = false
            }
            i += 1
        }

        if i < chars.count {
            if !preview.isEmpty {
                preview.removeLast()
                preview.append("\u{2026}")
            }
            lwsp = false
            return true
        }

        return false
    }

    private class HtmlTagContext {
        let tagId: HtmlTagId
        var listIndex: Int = 0
        var suppressInnerContent: Bool = false

        init(tagId: HtmlTagId) {
            self.tagId = tagId
        }
    }

    private static func pop(_ stack: inout [HtmlTagContext], _ id: HtmlTagId) {
        if let index = stack.lastIndex(where: { $0.tagId == id }) {
            stack.remove(at: index)
        }
    }

    private static func shouldSuppressInnerContent(_ id: HtmlTagId) -> Bool {
        switch id {
        case .ol, .script, .style, .table, .tbody, .thead, .tr, .ul:
            return true
        default:
            return false
        }
    }

    private static func suppressContent(_ stack: [HtmlTagContext]) -> Bool {
        return stack.last?.suppressInnerContent ?? false
    }

    private static func getListItemContext(_ stack: [HtmlTagContext]) -> HtmlTagContext? {
        return stack.last(where: { $0.tagId == .ol || $0.tagId == .ul })
    }

    /// Get a text preview of a stream of text.
    public override func getPreviewText(_ reader: TextReadable) -> String {
        let tokenizer = HtmlTokenizer(reader)
        
        var preview = ""
        var previewLength = 0
        var stack: [HtmlTagContext] = []
        var prefix = ""
        var body = false
        var full = false
        var lwsp = true

        while !full, let token = tokenizer.readNextToken() {
            switch token.kind {
            case .tag:
                guard let tag = token as? HtmlTagToken else { break }
                if !tag.isEndTag {
                    if body {
                        switch tag.id {
                        case .image:
                            if let attr = tag.attributes.first(where: { $0.id == .alt }), let value = attr.value {
                                full = Self.append(&preview, previewLength: &previewLength, maximumLength: maximumPreviewLength, value: prefix + value, lwsp: &lwsp)
                                prefix = ""
                            }
                        case .li:
                            if let ctx = Self.getListItemContext(stack) {
                                if ctx.tagId == .ol {
                                    ctx.listIndex += 1
                                    full = Self.append(&preview, previewLength: &previewLength, maximumLength: maximumPreviewLength, value: " \(ctx.listIndex). ", lwsp: &lwsp)
                                    prefix = ""
                                } else {
                                    prefix = " "
                                }
                            }
                        case .br, .p:
                            prefix = " "
                        default:
                            break
                        }

                        if !tag.isEmptyElement {
                            let ctx = HtmlTagContext(tagId: tag.id)
                            ctx.suppressInnerContent = Self.shouldSuppressInnerContent(tag.id)
                            stack.append(ctx)
                        }
                    } else if tag.id == .body && !tag.isEmptyElement {
                        body = true
                    }
                } else if tag.id == .body {
                    stack.removeAll()
                    body = false
                } else {
                    Self.pop(&stack, tag.id)
                }
            case .data:
                if body && !Self.suppressContent(stack) {
                    guard let dataToken = token as? HtmlDataToken else { break }
                    full = Self.append(&preview, previewLength: &previewLength, maximumLength: maximumPreviewLength, value: prefix + dataToken.data, lwsp: &lwsp)
                    prefix = ""
                }
            default:
                break
            }
        }

        if lwsp && !preview.isEmpty {
            preview.removeLast()
        }

        return preview
    }
}
