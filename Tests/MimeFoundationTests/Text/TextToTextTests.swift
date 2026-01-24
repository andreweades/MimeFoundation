import Testing
@testable import MimeFoundation

@Test("TextToText default property values")
func textToTextDefaultPropertyValues() {
    let converter = TextToText()

    #expect(converter.detectEncodingFromByteOrderMark == false)
    #expect(converter.footer == nil)
    #expect(converter.header == nil)
    #expect(converter.inputEncoding == .utf8)
    #expect(converter.inputFormat == .plain)
    #expect(converter.outputEncoding == .utf8)
    #expect(converter.outputFormat == .plain)
    #expect(converter.inputStreamBufferSize == 4096)
    #expect(converter.outputStreamBufferSize == 4096)
}

@Test("TextToText header and footer")
func textToTextHeaderAndFooter() {
    let converter = TextToText()
    converter.header = "Header"
    converter.footer = "Footer"

    let result = converter.convert(",")

    #expect(result == "Header,Footer")
}

@Test("TextToText simple conversion")
func textToTextSimpleConversion() {
    let newline = "\n"
    let expected = "This is some sample text. This is line #1." + newline +
        "This is line #2." + newline +
        "And this is line #3." + newline
    let text = expected
    let converter = TextToText()
    let result = converter.convert(text)

    #expect(result == expected)
}
