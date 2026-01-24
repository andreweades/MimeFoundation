import Testing
@testable import MimeFoundation

@Test("FlowedToHtml default property values")
func flowedToHtmlDefaultPropertyValues() {
    let converter = FlowedToHtml()

    #expect(converter.deleteSpace == false)
    #expect(converter.detectEncodingFromByteOrderMark == false)
    #expect(converter.footer == nil)
    #expect(converter.footerFormat == .text)
    #expect(converter.header == nil)
    #expect(converter.headerFormat == .text)
    #expect(converter.htmlTagCallback == nil)
    #expect(converter.inputEncoding == .utf8)
    #expect(converter.inputFormat == .flowed)
    #expect(converter.inputStreamBufferSize == 4096)
    #expect(converter.outputEncoding == .utf8)
    #expect(converter.outputFormat == .html)
    #expect(converter.outputHtmlFragment == false)
    #expect(converter.outputStreamBufferSize == 4096)
}

@Test("FlowedToHtml simple")
func flowedToHtmlSimple() {
    let newline = "\n"
    let expected = "<p>This is some sample text that has been formatted " +
        "according to the format=flowed rules defined in rfc3676. " +
        "This text, once converted, should all be on a single line.</p>" + newline +
        "<br/>" + newline +
        "<br/>" + newline +
        "<br/>" + newline +
        "<br/>" + newline +
        "<p>And this line of text should be separate by 4 blank lines.</p>" + newline
    let text = "This is some sample text that has been formatted " + newline +
        "according to the format=flowed rules defined in rfc3676. " + newline +
        "This text, once converted, should all be on a single line." + newline +
        newline + newline + newline + newline +
        "And this line of text should be separate by 4 blank lines." + newline

    let converter = FlowedToHtml()
    converter.outputHtmlFragment = true
    let result = converter.convert(text)

    #expect(result == expected)
}

@Test("FlowedToHtml increasing quote levels")
func flowedToHtmlIncreasingQuoteLevels() {
    let newline = "\n"
    let expected = "<blockquote><p>Thou villainous ill-breeding spongy dizzy-eyed reeky elf-skinned pigeon-egg!</p>" + newline +
        "<blockquote><p>Thou artless swag-bellied milk-livered dismal-dreaming idle-headed scut!</p>" + newline +
        "<blockquote><p>Thou errant folly-fallen spleeny reeling-ripe unmuzzled ratsbane!</p>" + newline +
        "<blockquote><p>Henceforth, the coding style is to be strictly enforced, including the use of only upper case.</p>" + newline +
        "<blockquote><p>I&#39;ve noticed a lack of adherence to the coding styles, of late.</p>" + newline +
        "<blockquote><p>Any complaints?</p>" + newline +
        "</blockquote></blockquote></blockquote></blockquote></blockquote></blockquote>"

    let text = "> Thou villainous ill-breeding spongy dizzy-eyed " + newline +
        "> reeky elf-skinned pigeon-egg!" + newline +
        ">> Thou artless swag-bellied milk-livered " + newline +
        ">> dismal-dreaming idle-headed scut!" + newline +
        ">>> Thou errant folly-fallen spleeny reeling-ripe " + newline +
        ">>> unmuzzled ratsbane!" + newline +
        ">>>> Henceforth, the coding style is to be strictly " + newline +
        ">>>> enforced, including the use of only upper case." + newline +
        ">>>>> I've noticed a lack of adherence to the coding " + newline +
        ">>>>> styles, of late." + newline +
        ">>>>>> Any complaints?" + newline

    let converter = FlowedToHtml()
    converter.outputHtmlFragment = true
    let result = converter.convert(text)

    #expect(result == expected)
}

@Test("FlowedToHtml decreasing quote levels")
func flowedToHtmlDecreasingQuoteLevels() {
    let newline = "\n"
    let expected = "<blockquote><blockquote><blockquote><blockquote><blockquote><blockquote><p>Thou villainous ill-breeding spongy dizzy-eyed reeky elf-skinned pigeon-egg!</p>" + newline +
        "</blockquote><p>Thou artless swag-bellied milk-livered dismal-dreaming idle-headed scut!</p>" + newline +
        "</blockquote><p>Thou errant folly-fallen spleeny reeling-ripe unmuzzled ratsbane!</p>" + newline +
        "</blockquote><p>Henceforth, the coding style is to be strictly enforced, including the use of only upper case.</p>" + newline +
        "</blockquote><p>I&#39;ve noticed a lack of adherence to the coding styles, of late.</p>" + newline +
        "</blockquote><p>Any complaints?</p>" + newline +
        "</blockquote>"

    let text = ">>>>>> Thou villainous ill-breeding spongy dizzy-eyed " + newline +
        ">>>>>> reeky elf-skinned pigeon-egg!" + newline +
        ">>>>> Thou artless swag-bellied milk-livered " + newline +
        ">>>>> dismal-dreaming idle-headed scut!" + newline +
        ">>>> Thou errant folly-fallen spleeny reeling-ripe " + newline +
        ">>>> unmuzzled ratsbane!" + newline +
        ">>> Henceforth, the coding style is to be strictly " + newline +
        ">>> enforced, including the use of only upper case." + newline +
        ">> I've noticed a lack of adherence to the coding " + newline +
        ">> styles, of late." + newline +
        "> Any complaints?" + newline

    let converter = FlowedToHtml()
    converter.outputHtmlFragment = true
    let result = converter.convert(text)

    #expect(result == expected)
}

@Test("FlowedToHtml broken quoted")
func flowedToHtmlBrokenQuoted() {
    let newline = "\n"
    let expected = "<blockquote><p>Thou villainous ill-breeding spongy dizzy-eyed reeky elf-skinned pigeon-egg! </p>" + newline +
        "<blockquote><p>Thou artless swag-bellied milk-livered dismal-dreaming idle-headed scut!</p>" + newline +
        "<blockquote><p>Thou errant folly-fallen spleeny reeling-ripe unmuzzled ratsbane!</p>" + newline +
        "<blockquote><p>Henceforth, the coding style is to be strictly enforced, including the use of only upper case.</p>" + newline +
        "<blockquote><p>I&#39;ve noticed a lack of adherence to the coding styles, of late.</p>" + newline +
        "<blockquote><p>Any complaints?</p>" + newline +
        "</blockquote></blockquote></blockquote></blockquote></blockquote></blockquote>"

    let text = "> Thou villainous ill-breeding spongy dizzy-eyed " + newline +
        "> reeky elf-skinned pigeon-egg! " + newline +
        ">> Thou artless swag-bellied milk-livered " + newline +
        ">> dismal-dreaming idle-headed scut!" + newline +
        ">>> Thou errant folly-fallen spleeny reeling-ripe " + newline +
        ">>> unmuzzled ratsbane!" + newline +
        ">>>> Henceforth, the coding style is to be strictly " + newline +
        ">>>> enforced, including the use of only upper case." + newline +
        ">>>>> I've noticed a lack of adherence to the coding " + newline +
        ">>>>> styles, of late." + newline +
        ">>>>>> Any complaints?" + newline

    let converter = FlowedToHtml()
    converter.outputHtmlFragment = true
    let result = converter.convert(text)

    #expect(result == expected)
}

@Test("FlowedToHtml text header and footer")
func flowedToHtmlTextHeaderFooter() {
    let newline = "\n"
    let expected = "<html><body>On &lt;date&gt;, so-and-so said:<br/><blockquote><p>Thou villainous ill-breeding spongy dizzy-eyed reeky elf-skinned pigeon-egg!</p>" + newline +
        "<blockquote><p>Thou artless swag-bellied milk-livered dismal-dreaming idle-headed scut!</p>" + newline +
        "<blockquote><p>Thou errant folly-fallen spleeny reeling-ripe unmuzzled ratsbane!</p>" + newline +
        "<blockquote><p>Henceforth, the coding style is to be strictly enforced, including the use of only upper case.</p>" + newline +
        "<blockquote><p>I&#39;ve noticed a lack of adherence to the coding styles, of late.</p>" + newline +
        "<blockquote><p>Any complaints?</p>" + newline +
        "</blockquote></blockquote></blockquote></blockquote></blockquote></blockquote>Tha-tha-tha-tha that&#39;s all, folks!<br/></body></html>"

    let text = "> Thou villainous ill-breeding spongy dizzy-eyed " + newline +
        "> reeky elf-skinned pigeon-egg!" + newline +
        ">> Thou artless swag-bellied milk-livered " + newline +
        ">> dismal-dreaming idle-headed scut!" + newline +
        ">>> Thou errant folly-fallen spleeny reeling-ripe " + newline +
        ">>> unmuzzled ratsbane!" + newline +
        ">>>> Henceforth, the coding style is to be strictly " + newline +
        ">>>> enforced, including the use of only upper case." + newline +
        ">>>>> I've noticed a lack of adherence to the coding " + newline +
        ">>>>> styles, of late." + newline +
        ">>>>>> Any complaints?" + newline

    let converter = FlowedToHtml()
    converter.header = "On <date>, so-and-so said:" + newline
    converter.headerFormat = .text
    converter.footer = "Tha-tha-tha-tha that's all, folks!" + newline
    converter.footerFormat = .text
    converter.htmlTagCallback = nil

    let result = converter.convert(text)
    #expect(result == expected)
}

@Test("FlowedToHtml text with URL")
func flowedToHtmlTextWithUrls() {
    let newline = "\n"
    let expected = "<p>Check out <a href=\"http://www.xamarin.com\">http://www.xamarin.com</a> - it&#39;s amazing!</p>" + newline
    let text = "Check out http://www.xamarin.com - it's amazing!" + newline

    let converter = FlowedToHtml()
    converter.header = nil
    converter.footer = nil
    converter.outputHtmlFragment = true
    let result = converter.convert(text)

    #expect(result == expected)
}

@Test("FlowedToHtml ending with space")
func flowedToHtmlEndingWithSpace() {
    let newline = "\n"
    let expected = "<p>We should have access, and apparently did a few months ago, but now there isa &quot;You do not currently have access to this content.&quot; at the bottom of therecord</p>" + newline +
        "<br/>" + newline +
        "<p>The URL in question URL:</p>" + newline +
        "<p><a href=\"https://example.com/\">https://example.com/</a></p>" + newline

    let text = "We should have access, and apparently did a few months ago, but now there is " + newline +
        "a \"You do not currently have access to this content.\" at the bottom of the " + newline +
        "record" + newline +
        newline +
        "The URL in question URL:" + newline +
        "https://example.com/ "

    let converter = FlowedToHtml()
    converter.deleteSpace = true
    converter.outputHtmlFragment = true
    let result = converter.convert(text)

    #expect(result == expected)
}
