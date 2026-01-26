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

//
// StringBuilderExtensionTests.swift
//

import Testing
@testable import MimeFoundation

@Test("StringBuilderUtils line wrap")
func stringBuilderLineWrap() {
    var builder = "This is supposed to be a really long string of text that is about to be folded "
    let expected1 = "This is supposed to be a really long string of text that is about to be folded\n "
    let expected2 = "This is supposed to be a really long string of text that is about to be folded\n\t"
    var format = FormatOptions.default
    format.newLineFormat = .unix

    StringBuilderUtils.lineWrap(&builder, options: format)
    #expect(builder == expected1)

    builder.removeLast(2)
    StringBuilderUtils.lineWrap(&builder, options: format)
    #expect(builder == expected2)
}

@Test("StringBuilderUtils append tokens")
func stringBuilderAppendTokens() {
    var builder = "Authentication-Results:"
    var format = FormatOptions.default
    format.newLineFormat = .unix
    let tokens = [
        " ",
        "this-is-a-really-long-parameter-name",
        "=",
        "this-is-a-really-long-parameter-value"
    ]
    var lineLength = builder.count

    StringBuilderUtils.appendTokens(&builder, options: format, lineLength: &lineLength, tokens: tokens)

    let expected = "Authentication-Results: this-is-a-really-long-parameter-name=\n\tthis-is-a-really-long-parameter-value"
    #expect(builder == expected)
}

@Test("StringBuilderUtils append folded with quoted string")
func stringBuilderAppendFoldedWithQuotedString() {
    let expected = "This is about to get a quoted string appended to it:\n \"and this is a \\\"quoted string\\\" that must not get broken up!\" Got it? Good.\n There should be another wrap in here..."
    var builder = "This is about to get a quoted string appended "
    var format = FormatOptions.default
    format.newLineFormat = .unix
    var lineLength = builder.count
    var firstToken = false

    StringBuilderUtils.appendFolded(
        &builder,
        options: format,
        firstToken: &firstToken,
        value: "to it: \"and this is a \\\"quoted string\\\" that must not get broken up!\" Got it? Good. There should be another wrap in here...",
        lineLength: &lineLength
    )

    #expect(builder == expected)
    #expect(lineLength == 40)
}
