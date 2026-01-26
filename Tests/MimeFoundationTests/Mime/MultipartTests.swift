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
// MultipartTests.swift
//

import Testing
import MimeFoundation

@Test("Multipart argument exceptions")
func multipartArgumentExceptions() {
    // Tests with nil have been removed since parameters are now non-optional

    #expect(throws: (any Error).self) {
        _ = try Multipart("")
    }

    #expect(throws: (any Error).self) {
        _ = try Multipart("mixed", 5)
    }

    let multipart = try! Multipart("mixed")

    #expect(throws: (any Error).self) {
        try multipart.remove(at: -1)
    }

    #expect(throws: (any Error).self) {
        var target: [MimeEntity] = []
        try multipart.copyTo(&target, at: -1)
    }

    #expect(throws: (any Error).self) {
        try multipart.prepare(.sevenBit, maxLineLength: 1)
    }
}

@Test("Multipart basic functionality")
func multipartBasicFunctionality() throws {
    let multipart = try Multipart("mixed")

    #expect(!multipart.boundary.isEmpty)
    #expect(!multipart.isReadOnly)

    multipart.setBoundary("__Next_Part_123")
    #expect(multipart.boundary == "__Next_Part_123")

    let generic = try MimePart("application", "octet-stream")
    generic.content = MimeContent(MemoryStream())
    generic.isAttachment = true

    let plain = TextPart("plain")
    plain.text = "This is some plain text."

    try multipart.add(generic)
    try multipart.insert(plain, at: 0)

    #expect(multipart.count == 2)
    #expect(multipart.contains(generic))
    #expect(multipart.indexOf(plain) == 0)

    var copied: [MimeEntity] = []
    try multipart.copyTo(&copied, at: 0)
    #expect(copied.count == 2)
    #expect(copied[0] === plain)
    #expect(copied[1] === generic)

    #expect(multipart.remove(generic))
    #expect(!multipart.remove(generic))

    try multipart.remove(at: 0)
    #expect(multipart.count == 0)

    try multipart.add(generic)
    try multipart.add(plain)
    #expect(multipart[0] === generic)
    #expect(multipart[1] === plain)

    try multipart.setItem(at: 0, plain)
    try multipart.setItem(at: 1, generic)

    #expect(multipart[0] === plain)
    #expect(multipart[1] === generic)

    multipart.clear()
    #expect(multipart.count == 0)
}

@Test("Multipart multi-line preamble")
func multipartMultiLinePreamble() throws {
    let multipart = try Multipart("alternative")
    let multiline = """
    This is a part in a (multipart) message generated with the MimeKit library.

    All of the parts of this message are identical, however they've been encoded for transport using different methods.
    """
    let expected = Multipart.foldPreambleOrEpilogue(.default, multiline, isEpilogue: false)

    multipart.preamble = multiline
    #expect(multipart.preamble == expected)

    multipart.preamble = nil
    #expect(multipart.preamble == nil)
}

@Test("Multipart long preamble")
func multipartLongPreamble() throws {
    let multipart = try Multipart("alternative")
    let multiline = "This is a part in a (multipart) message generated with the MimeKit library. All of the parts of this message are identical, however they've been encoded for transport using different methods."
    let expected = Multipart.foldPreambleOrEpilogue(.default, multiline, isEpilogue: false)

    multipart.preamble = multiline
    #expect(multipart.preamble == expected)

    multipart.preamble = nil
    #expect(multipart.preamble == nil)
}

@Test("Multipart multi-line epilogue")
func multipartMultiLineEpilogue() throws {
    let multipart = try Multipart("alternative")
    let multiline = """
    This is a part in a (multipart) message generated with the MimeKit library.

    All of the parts of this message are identical, however they've been encoded for transport using different methods.
    """
    let expected = Multipart.foldPreambleOrEpilogue(.default, multiline, isEpilogue: true)

    multipart.epilogue = multiline
    #expect(multipart.epilogue == expected)

    multipart.epilogue = nil
    #expect(multipart.epilogue == nil)
}

@Test("Multipart long epilogue")
func multipartLongEpilogue() throws {
    let multipart = try Multipart("alternative")
    let multiline = "This is a part in a (multipart) message generated with the MimeKit library. All of the parts of this message are identical, however they've been encoded for transport using different methods."
    let expected = Multipart.foldPreambleOrEpilogue(.default, multiline, isEpilogue: true)

    multipart.epilogue = multiline
    #expect(multipart.epilogue == expected)

    multipart.epilogue = nil
    #expect(multipart.epilogue == nil)
}

@Test("Multipart preamble folding")
func multipartPreambleFolding() {
    let text = "This is a multipart MIME message. If you are reading this text, then it means that your mail client does not support MIME.\n"
    let expected = "This is a multipart MIME message. If you are reading this text, then it means\nthat your mail client does not support MIME.\n"
    var options = FormatOptions.default
    options.newLineFormat = .unix

    let actual = Multipart.foldPreambleOrEpilogue(options, text, isEpilogue: false)
    #expect(actual == expected)
}

@Test("Multipart epilogue folding")
func multipartEpilogueFolding() {
    let text = "This is a multipart epilogue."
    let expected = "\nThis is a multipart epilogue.\n"
    var options = FormatOptions.default
    options.newLineFormat = .unix

    let actual = Multipart.foldPreambleOrEpilogue(options, text, isEpilogue: true)
    #expect(actual == expected)
}

@Test("Multipart preamble side effects")
func multipartPreambleSideEffects() throws {
    let preamble = "This is the preamble"
    let expected = "\(preamble)\(FormatOptions.default.newLine)"
    let multipart = try Multipart("mixed")

    #expect(multipart.preamble == nil)
    #expect(multipart.writeEndBoundary)

    multipart.preamble = preamble
    #expect(multipart.preamble == expected)

    multipart.preamble = expected
    #expect(multipart.preamble == expected)
}

@Test("Multipart epilogue side effects")
func multipartEpilogueSideEffects() throws {
    let epilogue = "This is the epilogue"
    let expected = "\(FormatOptions.default.newLine)\(epilogue)\(FormatOptions.default.newLine)"
    var multipart = try Multipart("mixed")

    #expect(multipart.epilogue == nil)
    #expect(multipart.writeEndBoundary)

    multipart.epilogue = epilogue
    #expect(multipart.epilogue == expected)
    #expect(multipart.writeEndBoundary)

    multipart.epilogue = expected
    #expect(multipart.epilogue == expected)
    #expect(multipart.writeEndBoundary)

    multipart = try Multipart("mixed")
    multipart.rawEndBoundary = []
    #expect(multipart.epilogue == nil)
    #expect(!multipart.writeEndBoundary)

    multipart.epilogue = epilogue
    #expect(multipart.epilogue == expected)
    #expect(multipart.writeEndBoundary)
}
