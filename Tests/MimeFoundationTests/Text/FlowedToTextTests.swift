import Testing
@testable import MimeFoundation

@Test("FlowedToText default property values")
func flowedToTextDefaultPropertyValues() {
    let converter = FlowedToText()

    #expect(converter.deleteSpace == false)
    #expect(converter.detectEncodingFromByteOrderMark == false)
    #expect(converter.footer == nil)
    #expect(converter.header == nil)
    #expect(converter.inputEncoding == .utf8)
    #expect(converter.inputFormat == .flowed)
    #expect(converter.inputStreamBufferSize == 4096)
    #expect(converter.outputEncoding == .utf8)
    #expect(converter.outputFormat == .plain)
    #expect(converter.outputStreamBufferSize == 4096)
}

@Test("FlowedToText simple")
func flowedToTextSimple() {
    let newline = "\n"
    let expected = "This is some sample text that has been formatted " +
        "according to the format=flowed rules defined in rfc3676. " +
        "This text, once converted, should all be on a single line." + newline
    let text = "This is some sample text that has been formatted " + newline +
        "according to the format=flowed rules defined in rfc3676. " + newline +
        "This text, once converted, should all be on a single line." + newline

    let converter = FlowedToText()
    let result = converter.convert(text)

    #expect(result == expected)
}

@Test("FlowedToText quoted")
func flowedToTextQuoted() {
    let newline = "\n"
    let expected = "> Thou villainous ill-breeding spongy dizzy-eyed reeky elf-skinned pigeon-egg!" + newline +
        ">> Thou artless swag-bellied milk-livered dismal-dreaming idle-headed scut!" + newline +
        ">>> Thou errant folly-fallen spleeny reeling-ripe unmuzzled ratsbane!" + newline +
        ">>>> Henceforth, the coding style is to be strictly enforced, including the use of only upper case." + newline +
        ">>>>> I've noticed a lack of adherence to the coding styles, of late." + newline +
        ">>>>>> Any complaints?" + newline
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

    let converter = FlowedToText()
    let result = converter.convert(text)

    #expect(result == expected)
}

@Test("FlowedToText broken quoted")
func flowedToTextBrokenQuoted() {
    let newline = "\n"
    let expected = "> Thou villainous ill-breeding spongy dizzy-eyed reeky elf-skinned pigeon-egg! " + newline +
        ">> Thou artless swag-bellied milk-livered dismal-dreaming idle-headed scut!" + newline +
        ">>> Thou errant folly-fallen spleeny reeling-ripe unmuzzled ratsbane!" + newline +
        ">>>> Henceforth, the coding style is to be strictly enforced, including the use of only upper case." + newline +
        ">>>>> I've noticed a lack of adherence to the coding styles, of late." + newline +
        ">>>>>> Any complaints?" + newline
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

    let converter = FlowedToText()
    let result = converter.convert(text)

    #expect(result == expected)
}

@Test("FlowedToText ending with space")
func flowedToTextEndingWithSpace() {
    let newline = "\n"
    let expected = "We should have access, and apparently did a few months ago, but now there isa \"You do not currently have access to this content.\" at the bottom of therecord" + newline +
        newline +
        "The URL in question URL:" + newline +
        "https://example.com/"
    let text = "We should have access, and apparently did a few months ago, but now there is " + newline +
        "a \"You do not currently have access to this content.\" at the bottom of the " + newline +
        "record" + newline +
        newline +
        "The URL in question URL:" + newline +
        "https://example.com/ "

    let converter = FlowedToText()
    converter.deleteSpace = true
    let result = converter.convert(text)

    #expect(result == expected)
}
