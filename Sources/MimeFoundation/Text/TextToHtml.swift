//
// TextToHtml.swift
//
// Ported from MimeKit (C#) to Swift.
//

/// A text to HTML converter.
///
/// Used to convert plain text into HTML.
public final class TextToHtml: TextConverter {
    private let scanner: UrlScanner

    /// The footer format.
    public var footerFormat: HeaderFooterFormat = .text

    /// The header format.
    public var headerFormat: HeaderFooterFormat = .text

    /// The `HtmlTagCallback` method to use for custom filtering of HTML tags and content.
    public var htmlTagCallback: HtmlTagCallback?

    /// Whether the converter should only output an HTML fragment.
    ///
    /// `true` if the converter should only output an HTML fragment; otherwise, `false`.
    public var outputHtmlFragment: Bool = false

    /// Initialize a new instance of `TextToHtml`.
    ///
    /// Creates a new text to HTML converter.
    public override init() {
        scanner = UrlScanner()
        for pattern in TextConverter.urlPatterns {
            scanner.add(pattern)
        }
        super.init()
    }

    /// The input format.
    public override var inputFormat: TextFormat {
        .plain
    }

    /// The output format.
    public override var outputFormat: TextFormat {
        .html
    }

    private final class TextToHtmlTagContext: HtmlTagContext {
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

    private static func defaultHtmlTagCallback(_ tagContext: HtmlTagContext, _ htmlWriter: HtmlWriter) {
        tagContext.writeTag(htmlWriter, writeAttributes: true)
    }

    private static func unquote(_ line: String) -> (line: String, quoteDepth: Int) {
        var index = 0
        let chars = Array(line)
        var quoteDepth = 0

        if chars.isEmpty || chars[0] != ">" {
            return (line, 0)
        }

        repeat {
            quoteDepth += 1
            index += 1
            if index < chars.count, chars[index] == " " {
                index += 1
            }
        } while index < chars.count && chars[index] == ">"

        if index >= chars.count {
            return ("", quoteDepth)
        }

        return (String(chars[index..<chars.count]), quoteDepth)
    }

    private static func suppressContent(_ stack: [TextToHtmlTagContext]) -> Bool {
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
                let ctx = TextToHtmlTagContext(tag: .a, attribute: HtmlAttribute(.href, href))
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
        var stack: [TextToHtmlTagContext] = []
        var currentQuoteDepth = 0

        while let rawLine = reader.readLine() {
            let (line, quoteDepth) = Self.unquote(rawLine)

            while currentQuoteDepth < quoteDepth {
                let ctx = TextToHtmlTagContext(tag: .blockQuote)
                callback(ctx, htmlWriter)
                currentQuoteDepth += 1
                stack.append(ctx)
            }

            while quoteDepth < currentQuoteDepth {
                guard let ctx = stack.popLast() else {
                    break
                }

                if !Self.suppressContent(stack) && !ctx.deleteEndTag {
                    ctx.setIsEndTag(true)
                    if ctx.invokeCallbackForEndTag {
                        callback(ctx, htmlWriter)
                    } else {
                        ctx.writeTag(htmlWriter)
                    }
                }

                if ctx.tagId == .blockQuote {
                    currentQuoteDepth -= 1
                }
            }

            if !Self.suppressContent(stack) {
                writeText(htmlWriter, line)
                let ctx = TextToHtmlTagContext(tag: .br)
                callback(ctx, htmlWriter)
            }
        }

        for ctx in stack.reversed() {
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
