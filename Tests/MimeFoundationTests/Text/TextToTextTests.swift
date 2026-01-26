//
// Author: Jeffrey Stedfast <jestedfa@microsoft.com>
//
// Copyright (c) 2013-2026 .NET Foundation and Contributors
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.
//

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
