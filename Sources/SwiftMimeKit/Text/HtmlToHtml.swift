//
// HtmlToHtml.swift
//
// Ported from MimeKit (C#) to Swift.
//

public final class HtmlToHtml: TextConverter {
    public var filterComments: Bool = false
    public var filterHtml: Bool = false
    public var footerFormat: HeaderFooterFormat = .text
    public var headerFormat: HeaderFooterFormat = .text
    public var htmlTagCallback: HtmlTagCallback?

    public override init() {
        super.init()
    }

    public override var inputFormat: TextFormat {
        .html
    }

    public override var outputFormat: TextFormat {
        .html
    }

    private final class HtmlToHtmlTagContext: HtmlTagContext {
        private let tag: HtmlTagToken

        init(_ tag: HtmlTagToken) {
            self.tag = tag
            super.init(tag.id)
        }

        override var tagName: String {
            tag.name
        }

        override var attributes: HtmlAttributeCollection {
            tag.attributes
        }

        override var isEmptyElementTag: Bool {
            tag.isEmptyElement || tag.id.isEmptyElement
        }

        override var isEndTag: Bool {
            tag.isEndTag
        }
    }

    private static func defaultHtmlTagCallback(_ tagContext: HtmlTagContext, _ htmlWriter: HtmlWriter) {
        tagContext.writeTag(htmlWriter, writeAttributes: true)
    }

    private static func suppressContent(_ stack: [HtmlToHtmlTagContext]) -> Bool {
        for ctx in stack.reversed() {
            if ctx.suppressInnerContent {
                return true
            }
        }
        return false
    }

    private static func pop(_ stack: inout [HtmlToHtmlTagContext], _ name: String) -> HtmlToHtmlTagContext? {
        guard !stack.isEmpty else {
            return nil
        }
        for i in stride(from: stack.count - 1, through: 0, by: -1) {
            if stack[i].tagName.compare(name, options: .caseInsensitive) == .orderedSame {
                return stack.remove(at: i)
            }
        }
        return nil
    }

    public override func convert(_ reader: TextReadable, _ writer: TextWritable) {
        if let header, !header.isEmpty {
            if headerFormat == .text {
                let converter = TextToHtml()
                converter.outputHtmlFragment = true
                let headerReader = StringReader(header)
                converter.convert(headerReader, writer)
            } else {
                writer.write(header)
            }
        }

        let htmlWriter = HtmlWriter(writer)
        let callback = htmlTagCallback ?? Self.defaultHtmlTagCallback
        var stack: [HtmlToHtmlTagContext] = []
        let tokenizer = HtmlTokenizer(reader)
        tokenizer.decodeCharacterReferences = false

        while let token = tokenizer.readNextToken() {
            switch token.kind {
            case .comment:
                if !filterComments, !Self.suppressContent(stack) {
                    htmlWriter.writeToken(token)
                }
            case .tag:
                guard let tagToken = token as? HtmlTagToken else {
                    break
                }

                if !tagToken.isEndTag {
                    if !tagToken.isEmptyElement {
                        let ctx = HtmlToHtmlTagContext(tagToken)
                        if filterHtml, ctx.tagId == .script {
                            ctx.suppressInnerContent = true
                            ctx.deleteEndTag = true
                            ctx.deleteTag = true
                        } else if !Self.suppressContent(stack) {
                            callback(ctx, htmlWriter)
                        }
                        stack.append(ctx)
                    } else if !Self.suppressContent(stack) {
                        let ctx = HtmlToHtmlTagContext(tagToken)
                        if !filterHtml || ctx.tagId != .script {
                            callback(ctx, htmlWriter)
                        }
                    }
                } else {
                    if let ctx = Self.pop(&stack, tagToken.name) {
                        if !Self.suppressContent(stack) {
                            if ctx.invokeCallbackForEndTag {
                                let endCtx = HtmlToHtmlTagContext(tagToken)
                                endCtx.invokeCallbackForEndTag = ctx.invokeCallbackForEndTag
                                endCtx.suppressInnerContent = ctx.suppressInnerContent
                                endCtx.deleteEndTag = ctx.deleteEndTag
                                endCtx.deleteTag = ctx.deleteTag
                                callback(endCtx, htmlWriter)
                            } else if !ctx.deleteEndTag {
                                htmlWriter.writeEndTag(tagToken.name)
                            }
                        }
                    } else if !Self.suppressContent(stack) {
                        let ctx = HtmlToHtmlTagContext(tagToken)
                        callback(ctx, htmlWriter)
                    }
                }
            case .data:
                if !Self.suppressContent(stack) {
                    htmlWriter.writeToken(token)
                }
            }
        }

        htmlWriter.flush()

        if let footer, !footer.isEmpty {
            if footerFormat == .text {
                let converter = TextToHtml()
                converter.outputHtmlFragment = true
                let footerReader = StringReader(footer)
                converter.convert(footerReader, writer)
            } else {
                writer.write(footer)
            }
        }
    }
}
