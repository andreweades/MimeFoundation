import Foundation
import Testing
@testable import MimeFoundation

@Test("HtmlToHtml default property values")
func htmlToHtmlDefaultPropertyValues() {
    let converter = HtmlToHtml()

    #expect(converter.detectEncodingFromByteOrderMark == false)
    #expect(converter.filterComments == false)
    #expect(converter.filterHtml == false)
    #expect(converter.footer == nil)
    #expect(converter.footerFormat == .text)
    #expect(converter.header == nil)
    #expect(converter.headerFormat == .text)
    #expect(converter.htmlTagCallback == nil)
    #expect(converter.inputEncoding == .utf8)
    #expect(converter.inputFormat == .html)
    #expect(converter.inputStreamBufferSize == 4096)
    #expect(converter.outputEncoding == .utf8)
    #expect(converter.outputFormat == .html)
    #expect(converter.outputStreamBufferSize == 4096)
}

private func replaceUrlsWithFileNames(_ ctx: HtmlTagContext, _ htmlWriter: HtmlWriter) {
    if ctx.tagId == .image {
        htmlWriter.writeEmptyElementTag(ctx.tagName)
        ctx.deleteEndTag = true

        for i in 0..<ctx.attributes.count {
            let attr = ctx.attributes[i]
            if attr.id == .src, let value = attr.value {
                let fileName = URL(fileURLWithPath: value).lastPathComponent
                htmlWriter.writeAttributeName(attr.name)
                htmlWriter.writeAttributeValue(fileName)
            } else {
                htmlWriter.writeAttribute(attr)
            }
        }
    } else {
        ctx.writeTag(htmlWriter, writeAttributes: true)
    }
}

@Test("HtmlToHtml simple")
func htmlToHtmlSimple() throws {
    let expectedURL = TestHelper.dataURL(for: "html/xamarin3.xhtml")
    let inputURL = TestHelper.dataURL(for: "html/xamarin3.html")

    let expected = try String(contentsOf: expectedURL, encoding: .utf8)
    let text = try String(contentsOf: inputURL, encoding: .utf8)

    let converter = HtmlToHtml()
    converter.header = nil
    converter.footer = nil
    converter.htmlTagCallback = replaceUrlsWithFileNames

    let result = converter.convert(text)

    #expect(converter.inputFormat == .html)
    #expect(converter.outputFormat == .html)
    #expect(result == expected)
}

private func suppressInnerContentCallback(_ ctx: HtmlTagContext, _ htmlWriter: HtmlWriter) {
    ctx.invokeCallbackForEndTag = true

    if ctx.tagId == .head || ctx.tagId == .script || ctx.tagId == .style {
        ctx.suppressInnerContent = true
    } else {
        if ctx.tagId == .image && !ctx.isEndTag {
            for attr in ctx.attributes {
                if attr.id == .src, let value = attr.value {
                    htmlWriter.writeText(value + " ")
                }
            }
        } else if ctx.tagId == .a {
            for attr in ctx.attributes {
                if attr.id == .href, let value = attr.value {
                    htmlWriter.writeText(" [ " + value + " ] ")
                }
            }
        } else {
            if ctx.tagId == .p || ctx.tagId == .div || ctx.tagId == .br {
                htmlWriter.writeText("\n")
            } else {
                for attr in ctx.attributes {
                    if attr.id == .src, let value = attr.value {
                        htmlWriter.writeText(value)
                    }
                }
            }
        }
    }
}

@Test("HtmlToHtml suppress inner content")
func htmlToHtmlSuppressInnerContent() {
    let input = "<html xmlns:v=\"urn:schemas-microsoft-com:vml\" xmlns:o=\"urn:schemas-microsoft-com:office:office\" xmlns:w=\"urn:schemas-microsoft-com:office:word\" xmlns:m=\"http://schemas.microsoft.com/office/2004/12/omml\"xmlns=\"http://www.w3.org/TR/REC-html40\"><head><meta http-equiv=Content-Type content=\"text/html; charset=iso-8859-2\"><meta name=Generator content=\"Microsoft Word 15 (filtered medium)\"><!--[if !mso]><style>v\\:* {behavior:url(#default#VML);}\r\no\\:* {behavior:url(#default#VML);}\r\nw\\:* {behavior:url(#default#VML);}\r\n.shape{behavior:url(#default#VML);}\r\n</style><![endif]--><style><!--\r\n/* Font Definitions */\r\n@font-face\r\n\t{font-family:\"Cambria Math\";\r\n\tpanose-1:2 4 5 3 5 4 6 3 2 4;}\r\n@font-face\r\n\t{font-family:Calibri;\r\n\tpanose-1:2 15 5 2 2 2 4 3 2 4;}\r\n@font-face\r\n\t{font-family:\"Segoe UI\";\r\n\tpanose-1:2 11 5 2 4 2 4 2 2 3;}\r\n@font-face\r\n\t{font-family:Verdana;\r\n\tpanose-1:2 11 6 4 3 5 4 4 2 4;}\r\n/* Style Definitions */\r\np.MsoNormal, li.MsoNormal, div.MsoNormal\r\n\t{margin:0cm;\r\n\tmargin-bottom:.0001pt;\r\n\tfont-size:11.0pt;\r\n\tfont-family:\"Calibri\",sans-serif;\r\n\tmso-fareast-language:EN-US;}\r\nh3\r\n\t{mso-style-priority:9;\r\n\tmso-style-link:\"Heading 3 Char\";\r\n\tmso-margin-top-alt:auto;\r\n\tmargin-right:0cm;\r\n\tmso-margin-bottom-alt:auto;\r\n\tmargin-left:0cm;\r\n\tfont-size:13.5pt;\r\n\tfont-family:\"Times New Roman\",serif;}\r\na:link, span.MsoHyperlink\r\n\t{mso-style-priority:99;\r\n\tcolor:#0563C1;\r\n\ttext-decoration:underline;}\r\na:visited,span.MsoHyperlinkFollowed\r\n\t{mso-style-priority:99;\r\n\tcolor:#954F72;\r\n\ttext-decoration:underline;}\r\nspan.Heading3Char\r\n\t{mso-style-name:\"Heading 3 Char\";\r\n\tmso-style-priority:9;\r\n\tmso-style-link:\"Heading 3\";\r\n\tfont-family:\"Times New Roman\",serif;\r\n\tmso-fareast-language:FR;\r\n\tfont-weight:bold;}\r\nspan.EmailStyle18\r\n\t{mso-style-type:personal;\r\n\tfont-family:\"Calibri\",sans-serif;\r\n\tcolor:windowtext;}\r\nspan.EmailStyle19\r\n\t{mso-style-type:personal-reply;\r\n\tfont-family:\"Calibri\",sans-serif;\r\n\tcolor:#1F497D;}\r\n.MsoChpDefault\r\n\t{mso-style-type:export-only;\r\n\tfont-size:10.0pt;}\r\n@page WordSection1\r\n\t{size:612.0pt 792.0pt;\r\n\tmargin:70.85pt 70.85pt 70.85pt 70.85pt;}\r\ndiv.WordSection1\r\n\t{page:WordSection1;}\r\n--></style><!--[if gte mso 9]><xml>\r\n<o:shapedefaults v:ext=\"edit\" spidmax=\"1026\" />\r\n</xml><![endif]--><!--[if gte mso 9]><xml>\r\n<o:shapelayout v:ext=\"edit\">\r\n<o:idmap v:ext=\"edit\" data=\"1\" />\r\n</o:shapelayout></xml><![endif]--></head><body lang=FR link=\"#0563C1\" vlink=\"#954F72\">Here is the body content which seems fine so far</body></html>"
    let expected = "Here is the body content which seems fine so far"

    let converter = HtmlToHtml()
    converter.htmlTagCallback = suppressInnerContentCallback

    let result = converter.convert(input)

    #expect(result == expected)
}

@Test("HtmlToHtml filter comments")
func htmlToHtmlFilterComments() {
    let input = "<html><head><!-- this is a comment --></head><body>Here is the body content <!-- this is another comment -->which seems fine so far</body></html>"
    let expected = "<html><head></head><body>Here is the body content which seems fine so far</body></html>"

    let converter = HtmlToHtml()
    converter.filterComments = true

    let result = converter.convert(input)

    #expect(result == expected)
}

@Test("HtmlToHtml filter html")
func htmlToHtmlFilterHtml() {
    let input = "<html><head><script>/* this is a script */</script></head><body>Here is the body content which seems fine so far</body></html>"
    let expected = "<html><head></head><body>Here is the body content which seems fine so far</body></html>"

    let converter = HtmlToHtml()
    converter.filterHtml = true

    let result = converter.convert(input)

    #expect(result == expected)
}

@Test("HtmlToHtml header footer")
func htmlToHtmlHeaderFooter() {
    let input = "<body>Here is the body content which seems fine so far</body>"
    let expected = "<html><head></head><body>Here is the body content which seems fine so far</body></html>"

    let converter = HtmlToHtml()
    converter.headerFormat = .html
    converter.header = "<html><head></head>"
    converter.footerFormat = .html
    converter.footer = "</html>"

    let result = converter.convert(input)

    #expect(result == expected)
}

@Test("HtmlToHtml text header footer")
func htmlToHtmlTextHeaderFooter() {
    let input = "<body>Here is the body content which seems fine so far</body>"
    let expected = "&lt;html&gt;&lt;head&gt;&lt;/head&gt;<br/><body>Here is the body content which seems fine so far</body>&lt;/html&gt;<br/>"

    let converter = HtmlToHtml()
    converter.headerFormat = .text
    converter.header = "<html><head></head>"
    converter.footerFormat = .text
    converter.footer = "</html>"

    let result = converter.convert(input)

    #expect(result == expected)
}

@Test("HtmlToHtml issue 808")
func htmlToHtmlIssue808() {
    let input = "<html><body>I'm on holiday until&nbsp; June 17, 2022.&#13;</body></html>"
    let expected = "<html><body>I'm on holiday until&nbsp; June 17, 2022.&#13;</body></html>"

    let converter = HtmlToHtml()
    let result = converter.convert(input)

    #expect(result == expected)
}
