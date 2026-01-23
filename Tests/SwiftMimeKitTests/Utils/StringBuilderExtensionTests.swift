//
// StringBuilderExtensionTests.swift
//

import Testing
@testable import SwiftMimeKit

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
