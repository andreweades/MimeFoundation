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
// MimeUtilsTests.swift
//

import Foundation
import Testing
@testable import MimeFoundation

@Test("MimeUtils validation")
func mimeUtilsValidation() {
    #expect(throws: MimeUtilsError.invalidArgument) {
        _ = try MimeUtils.generateMessageId(validating: "")
    }
}

private let goodReferences: [String] = [
    "<local-part@domain1@domain2>", "local-part@domain1@domain2",
    "<local-part@>", "local-part@",
    "<local-part>", "local-part",
    "<:invalid-local-part;@domain.com>", ":invalid-local-part;@domain.com",
]

@Test("MimeUtils parse good references")
func mimeUtilsParseGoodReferences() {
    var index = 0
    while index < goodReferences.count {
        let source = goodReferences[index]
        let expected = goodReferences[index + 1]

        let reference = MimeUtils.enumerateReferences(source).first
        #expect(reference == expected)

        let parsed = MimeUtils.parseMessageId(source)
        #expect(parsed == expected)

        index += 2
    }
}

private let brokenReferences: [String] = [
    " (this is an unterminated comment...",
    "(this is just a comment)",
    "<",
    "<local-part",
    "<local-part;",
    "<local-part@ (unterminated comment...",
    "<local-part@",
    "<local-part @ bad-domain (comment) . (comment com",
    "<local-part@[127.0"
]

@Test("MimeUtils parse broken references")
func mimeUtilsParseBrokenReferences() {
    for value in brokenReferences {
        let reference = MimeUtils.enumerateReferences(value).first
        #expect(reference == nil)

        let parsed = MimeUtils.parseMessageId(value)
        #expect(parsed == nil)
    }
}

@Test("MimeUtils try parse version")
func mimeUtilsTryParseVersion() {
    let version1 = MimeUtils.tryParseVersion(" 1 (comment) .\t0\r\n")
    #expect(version1?.description == "1.0")

    let version2 = MimeUtils.tryParseVersion(" 1 (comment) .\t0\r\n .0\r\n")
    #expect(version2?.description == "1.0.0")

    let version3 = MimeUtils.tryParseVersion(" 1 (comment) .\t0\r\n .0.0\r\n")
    #expect(version3?.description == "1.0.0.0")

    #expect(MimeUtils.tryParseVersion("1") == nil)
    #expect(MimeUtils.tryParseVersion("1.2.3.4.5") == nil)
    #expect(MimeUtils.tryParseVersion("1x2.3") == nil)
    #expect(MimeUtils.tryParseVersion("(unterminated comment") == nil)
    #expect(MimeUtils.tryParseVersion("1 (unterminated comment") == nil)
}

@Test("MimeUtils generate message id with international domain")
func mimeUtilsGenerateMessageIdWithInternationalDomain() throws {
    let domain = "Mjölnir"
    let msgid = try MimeUtils.generateMessageId(validating: domain)
    let parts = msgid.split(separator: "@", maxSplits: 1)
    let idn = parts.count == 2 ? String(parts[1]) : ""
    #expect(idn == "xn--mjlnir-xxa")
}

@Test("MimeUtils append quoted")
func mimeUtilsAppendQuoted() {
    let expected = "\"This is a multi-line quoted string with \\\\backslashes\\\\ and an escaped dquote (\\\") inside of it.\""
    let text = "This is a multi-line quoted string with \\backslashes\\ and an escaped dquote (\") inside of it."
    var builder = ""

    MimeUtils.appendQuoted(&builder, text)
    #expect(builder == expected)
}

@Test("MimeUtils unquote")
func mimeUtilsUnquote() {
    let quoted = "\"This is a multi-line quoted string with\r\n\t\\\\backslashes\\\\ and an escaped dquote (\\\") inside of it.\""
    let expected = "This is a multi-line quoted string with \\backslashes\\ and an escaped dquote (\") inside of it."

    let unquoted = MimeUtils.unquote(quoted, convertTabsToSpaces: true)
    #expect(unquoted == expected)

    let bytes = Array(quoted.utf8)
    let result = MimeUtils.unquote(bytes, startIndex: 0, length: bytes.count, convertTabsToSpaces: true)
    let decoded = String(bytes: result, encoding: .ascii)
    #expect(decoded == expected)
}
