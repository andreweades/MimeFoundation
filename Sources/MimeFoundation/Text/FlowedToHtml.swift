//
// FlowedToHtml.swift
//
// Ported from MimeKit (C#) to Swift.
//

public final class FlowedToHtml: TextConverter {
    private let scanner: UrlScanner

    public var deleteSpace: Bool = false
    public var footerFormat: HeaderFooterFormat = .text
    public var headerFormat: HeaderFooterFormat = .text
    public var htmlTagCallback: HtmlTagCallback?
    public var outputHtmlFragment: Bool = false

    public override init() {
        scanner = UrlScanner()
        for pattern in TextConverter.urlPatterns {
            scanner.add(pattern)
        }
        super.init()
    }

    public override var inputFormat: TextFormat {
        .flowed
    }

    public override var outputFormat: TextFormat {
        .html
    }

    private final class FlowedToHtmlTagContext: HtmlTagContext {
        private let attrs: HtmlAttributeCollection
        private var endTag = false

        init(tag: HtmlTagId, attribute: HtmlAttribute) {
            self.attrs = HtmlAttributeCollection([attribute])
            super.init(tag)
        }

        init(tag: HtmlTagId) {
            self.attrs = HtmlAttributeCollection.empty
            super.init(tag)
        }

        override var tagName: String {
            tagId.htmlTagName
        }

        override var attributes: HtmlAttributeCollection {
            attrs
        }

        override var isEmptyElementTag: Bool {
            tagId == .br
        }

        override var isEndTag: Bool {
            endTag
        }

        func setIsEndTag(_ value: Bool) {
            endTag = value
        }
    }

    private struct WriterState {
        var stack: [FlowedToHtmlTagContext] = []
        var currentQuoteDepth: Int = 0
    }

    private static func defaultHtmlTagCallback(_ tagContext: HtmlTagContext, _ htmlWriter: HtmlWriter) {
        tagContext.writeTag(htmlWriter, writeAttributes: true)
    }

    private static func unquote(_ line: [Character]) -> (content: ArraySlice<Character>, quoteDepth: Int) {
        var index = 0
        var quoteDepth = 0

        if line.isEmpty {
            return (line[index...], 0)
        }

        while index < line.count && line[index] == ">" {
            quoteDepth += 1
            index += 1
        }

        if index > 0, index < line.count, line[index] == " " {
            index += 1
        }

        if index >= line.count {
            return (line[line.count..<line.count], quoteDepth)
        }

        return (line[index...], quoteDepth)
    }

    private static func suppressContent(_ stack: [FlowedToHtmlTagContext]) -> Bool {
        for ctx in stack.reversed() {
            if ctx.suppressInnerContent {
                return true
            }
        }
        return false
    }

    private func writeText(_ htmlWriter: HtmlWriter, _ text: String) {
        let callback = htmlTagCallback ?? Self.defaultHtmlTagCallback
        let content = Array(text)
        var startIndex = 0
        let endIndex = content.count

        while startIndex < endIndex {
            let count = endIndex - startIndex
            if let match = scanner.scan(content, startIndex: startIndex, count: count) {
                let matchCount = match.endIndex - match.startIndex

                if match.startIndex > startIndex {
                    htmlWriter.writeText(content, startIndex, match.startIndex - startIndex)
                }

                let href = match.prefix + String(content[match.startIndex..<match.endIndex])
                let ctx = FlowedToHtmlTagContext(tag: .a, attribute: HtmlAttribute(.href, href))
                callback(ctx, htmlWriter)

                if !ctx.suppressInnerContent {
                    htmlWriter.writeText(content, match.startIndex, matchCount)
                }

                if !ctx.deleteEndTag {
                    ctx.setIsEndTag(true)
                    if ctx.invokeCallbackForEndTag {
                        callback(ctx, htmlWriter)
                    } else {
                        ctx.writeTag(htmlWriter)
                    }
                }

                startIndex = match.endIndex
            } else {
                htmlWriter.writeText(content, startIndex, count)
                break
            }
        }
    }

    private func writeParagraph(_ htmlWriter: HtmlWriter, state: inout WriterState, paragraph: String, quoteDepth: Int) {
        let callback = htmlTagCallback ?? Self.defaultHtmlTagCallback

        while state.currentQuoteDepth < quoteDepth {
            let ctx = FlowedToHtmlTagContext(tag: .blockQuote)
            callback(ctx, htmlWriter)
            state.currentQuoteDepth += 1
            state.stack.append(ctx)
        }

        while quoteDepth < state.currentQuoteDepth {
            guard let ctx = state.stack.popLast() else {
                break
            }

            if !Self.suppressContent(state.stack) && !ctx.deleteEndTag {
                ctx.setIsEndTag(true)
                if ctx.invokeCallbackForEndTag {
                    callback(ctx, htmlWriter)
                } else {
                    ctx.writeTag(htmlWriter)
                }
            }

            if ctx.tagId == .blockQuote {
                state.currentQuoteDepth -= 1
            }
        }

        if Self.suppressContent(state.stack) {
            return
        }

        let ctx = FlowedToHtmlTagContext(tag: paragraph.isEmpty ? .br : .p)
        callback(ctx, htmlWriter)

        if !paragraph.isEmpty {
            if !ctx.suppressInnerContent {
                writeText(htmlWriter, paragraph)
            }

            if !ctx.deleteEndTag {
                ctx.setIsEndTag(true)
                if ctx.invokeCallbackForEndTag {
                    callback(ctx, htmlWriter)
                } else {
                    ctx.writeTag(htmlWriter)
                }
            }
        }

        if !ctx.deleteTag {
            htmlWriter.writeMarkupText("\n")
        }
    }

    public override func convert(_ reader: TextReadable, _ writer: TextWritable) {
        if !outputHtmlFragment {
            writer.write("<html><body>")
        }

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
        var state = WriterState()
        var paragraph = ""
        var paragraphQuoteDepth = -1

        while let line = reader.readLine() {
            let chars = Array(line)
            var (unquoted, quoteDepth) = Self.unquote(chars)

            if quoteDepth == 0, let first = unquoted.first, first == " " {
                unquoted = unquoted.dropFirst()
            }

            if paragraph.isEmpty {
                paragraphQuoteDepth = quoteDepth
            } else if quoteDepth != paragraphQuoteDepth {
                writeParagraph(htmlWriter, state: &state, paragraph: paragraph, quoteDepth: paragraphQuoteDepth)
                paragraphQuoteDepth = quoteDepth
                paragraph = ""
            }

            if !unquoted.isEmpty {
                paragraph.append(contentsOf: unquoted)
            }

            if unquoted.isEmpty || unquoted.last != " " {
                writeParagraph(htmlWriter, state: &state, paragraph: paragraph, quoteDepth: paragraphQuoteDepth)
                paragraphQuoteDepth = 0
                paragraph = ""
            } else if deleteSpace, !paragraph.isEmpty {
                paragraph.removeLast()
            }
        }

        if !paragraph.isEmpty {
            writeParagraph(htmlWriter, state: &state, paragraph: paragraph, quoteDepth: paragraphQuoteDepth)
        }

        for ctx in state.stack.reversed() {
            ctx.setIsEndTag(true)
            if ctx.invokeCallbackForEndTag {
                callback(ctx, htmlWriter)
            } else {
                ctx.writeTag(htmlWriter)
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

        if !outputHtmlFragment {
            writer.write("</body></html>")
        }
    }
}
