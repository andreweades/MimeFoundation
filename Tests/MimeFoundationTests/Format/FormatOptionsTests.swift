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
// FormatOptionsTests.swift
//

import Testing
@testable import MimeFoundation

@Test("FormatOptions defaults and clone")
func formatOptionsDefaultsAndClone() {
    let options = FormatOptions.default
    #expect(options.maxLineLength == FormatOptions.defaultMaxLineLength)
    #expect(options.newLine == (options.newLineFormat == .unix ? "\n" : "\r\n"))

    var clone = options.copy()
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
