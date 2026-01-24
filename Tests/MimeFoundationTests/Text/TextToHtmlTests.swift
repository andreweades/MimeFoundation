import Foundation
import Testing
@testable import MimeFoundation

@Test("TextToHtml default property values")
func textToHtmlDefaultPropertyValues() {
    let converter = TextToHtml()

    #expect(converter.detectEncodingFromByteOrderMark == false)
    #expect(converter.footer == nil)
    #expect(converter.footerFormat == .text)
    #expect(converter.header == nil)
    #expect(converter.headerFormat == .text)
    #expect(converter.htmlTagCallback == nil)
    #expect(converter.inputEncoding == .utf8)
    #expect(converter.inputFormat == .plain)
    #expect(converter.inputStreamBufferSize == 4096)
    #expect(converter.outputEncoding == .utf8)
    #expect(converter.outputFormat == .html)
    #expect(converter.outputHtmlFragment == false)
    #expect(converter.outputStreamBufferSize == 4096)
}

@Test("TextToHtml output fragment")
func textToHtmlOutputFragment() {
    let input = "This is the html body"
    let expected = "<html><body>This is the html body<br/></body></html>"
    let expected2 = "This is the html body<br/>"

    let converter = TextToHtml()
    let result = converter.convert(input)
    #expect(result == expected)

    converter.outputHtmlFragment = true
    let result2 = converter.convert(input)
    #expect(result2 == expected2)
}

@Test("TextToHtml header footer")
func textToHtmlHeaderFooter() {
    let input = "This is the html body"
    let header = "This is the header"
    let footer = "This is the footer"
    let expected = "<html><body>" + header + "<br/>" + input + "<br/>" + footer + "<br/></body></html>"

    let converter = TextToHtml()
    converter.headerFormat = .text
    converter.header = header
    converter.footerFormat = .text
    converter.footer = footer

    let result = converter.convert(input)
    #expect(result == expected)
}

@Test("TextToHtml emoji encoding")
func textToHtmlEmoji() {
    let emojiData: [UInt8] = [0xF0, 0x9F, 0x98, 0xB1]
    let emoji = String(data: Data(emojiData), encoding: .utf8) ?? ""
    let expected = "<html><body>&#128561;<br/></body></html>"

    let converter = TextToHtml()
    let result = converter.convert(emoji)

    #expect(result == expected)
}

@Test("TextToHtml increasing quote levels")
func textToHtmlIncreasingQuoteLevels() {
    let newline = "\n"
    let expected = "<blockquote>Thou villainous ill-breeding spongy dizzy-eyed reeky elf-skinned pigeon-egg!<br/>" +
        "<blockquote>Thou artless swag-bellied milk-livered dismal-dreaming idle-headed scut!<br/>" +
        "<blockquote>Thou errant folly-fallen spleeny reeling-ripe unmuzzled ratsbane!<br/>" +
        "<blockquote>Henceforth, the coding style is to be strictly enforced, including the use of only upper case.<br/>" +
        "<blockquote>I&#39;ve noticed a lack of adherence to the coding styles, of late.<br/>" +
        "<blockquote>Any complaints?<br/>" +
        "</blockquote></blockquote></blockquote></blockquote></blockquote></blockquote>"

    let text = "> Thou villainous ill-breeding spongy dizzy-eyed reeky elf-skinned pigeon-egg!" + newline +
        ">> Thou artless swag-bellied milk-livered dismal-dreaming idle-headed scut!" + newline +
        ">>> Thou errant folly-fallen spleeny reeling-ripe unmuzzled ratsbane!" + newline +
        ">>>> Henceforth, the coding style is to be strictly enforced, including the use of only upper case." + newline +
        ">>>>> I've noticed a lack of adherence to the coding styles, of late." + newline +
        ">>>>>> Any complaints?" + newline

    let converter = TextToHtml()
    converter.outputHtmlFragment = true
    let result = converter.convert(text)

    #expect(result == expected)
}

@Test("TextToHtml increasing quote levels no trailing newline")
func textToHtmlIncreasingQuoteLevelsNoNewline() {
    let newline = "\n"
    let expected = "<blockquote>Thou villainous ill-breeding spongy dizzy-eyed reeky elf-skinned pigeon-egg!<br/>" +
        "<blockquote>Thou artless swag-bellied milk-livered dismal-dreaming idle-headed scut!<br/>" +
        "<blockquote>Thou errant folly-fallen spleeny reeling-ripe unmuzzled ratsbane!<br/>" +
        "<blockquote>Henceforth, the coding style is to be strictly enforced, including the use of only upper case.<br/>" +
        "<blockquote>I&#39;ve noticed a lack of adherence to the coding styles, of late.<br/>" +
        "<blockquote>Any complaints?<br/>" +
        "</blockquote></blockquote></blockquote></blockquote></blockquote></blockquote>"

    let text = "> Thou villainous ill-breeding spongy dizzy-eyed reeky elf-skinned pigeon-egg!" + newline +
        ">> Thou artless swag-bellied milk-livered dismal-dreaming idle-headed scut!" + newline +
        ">>> Thou errant folly-fallen spleeny reeling-ripe unmuzzled ratsbane!" + newline +
        ">>>> Henceforth, the coding style is to be strictly enforced, including the use of only upper case." + newline +
        ">>>>> I've noticed a lack of adherence to the coding styles, of late." + newline +
        ">>>>>> Any complaints?"

    let converter = TextToHtml()
    converter.outputHtmlFragment = true
    let result = converter.convert(text)

    #expect(result == expected)
}

@Test("TextToHtml decreasing quote levels")
func textToHtmlDecreasingQuoteLevels() {
    let newline = "\n"
    let expected = "<blockquote><blockquote><blockquote><blockquote><blockquote><blockquote>Thou villainous ill-breeding spongy dizzy-eyed reeky elf-skinned pigeon-egg!<br/>" +
        "</blockquote>Thou artless swag-bellied milk-livered dismal-dreaming idle-headed scut!<br/>" +
        "</blockquote>Thou errant folly-fallen spleeny reeling-ripe unmuzzled ratsbane!<br/>" +
        "</blockquote>Henceforth, the coding style is to be strictly enforced, including the use of only upper case.<br/>" +
        "</blockquote>I&#39;ve noticed a lack of adherence to the coding styles, of late.<br/>" +
        "</blockquote>Any complaints?<br/>" +
        "</blockquote>"

    let text = ">>>>>> Thou villainous ill-breeding spongy dizzy-eyed reeky elf-skinned pigeon-egg!" + newline +
        ">>>>> Thou artless swag-bellied milk-livered dismal-dreaming idle-headed scut!" + newline +
        ">>>> Thou errant folly-fallen spleeny reeling-ripe unmuzzled ratsbane!" + newline +
        ">>> Henceforth, the coding style is to be strictly enforced, including the use of only upper case." + newline +
        ">> I've noticed a lack of adherence to the coding styles, of late." + newline +
        "> Any complaints?" + newline

    let converter = TextToHtml()
    converter.outputHtmlFragment = true
    let result = converter.convert(text)

    #expect(result == expected)
}

@Test("TextToHtml simple text")
func textToHtmlSimpleText() {
    let newline = "\n"
    let expected = "This is some sample text. This is line #1.<br/>" +
        "This is line #2.<br/>" +
        "And this is line #3.<br/>"
    let text = "This is some sample text. This is line #1." + newline +
        "This is line #2." + newline +
        "And this is line #3." + newline

    let converter = TextToHtml()
    converter.outputHtmlFragment = true
    let result = converter.convert(text)

    #expect(result == expected)
}

@Test("TextToHtml text with URL")
func textToHtmlSimpleTextWithUrls() {
    let newline = "\n"
    let expected = "Check out <a href=\"http://www.xamarin.com\">http://www.xamarin.com</a> - it&#39;s amazing!<br/>"
    let text = "Check out http://www.xamarin.com - it's amazing!" + newline

    let converter = TextToHtml()
    converter.outputHtmlFragment = true
    let result = converter.convert(text)

    #expect(result == expected)
}
