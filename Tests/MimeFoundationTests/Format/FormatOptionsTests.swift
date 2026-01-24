//
// FormatOptionsTests.swift
//

import Testing
@testable import MimeFoundation

@Test("FormatOptions defaults and clone")
func formatOptionsDefaultsAndClone() {
    let options = FormatOptions.default
    #expect(options.maxLineLength == FormatOptions.defaultMaxLineLength)
    #expect(options.newLine == (options.newLineFormat == .unix ? "\n" : "\r\n"))

    var clone = options.clone()
    clone.international = true
    #expect(clone.international)
    #expect(!options.international)
}

@Test("FormatOptions newLine format")
func formatOptionsNewLineFormat() {
    var options = FormatOptions.default
    options.newLineFormat = .unix
    #expect(options.newLine == "\n")

    options.newLineFormat = .dos
    #expect(options.newLine == "\r\n")
}
