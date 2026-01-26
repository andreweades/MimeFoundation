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

@Suite
struct DkimRelaxedBodyFilterTests {
    private static func applyFilter(_ filter: MimeFilter, to text: String) throws -> String {
        let input = Array(text.utf8)
        let output = MemoryStream([], writable: true)
        let filtered = try FilteredStream(output)
        try filtered.add(filter)
        try filtered.write(input, offset: 0, count: input.count)
        try filtered.flush()
        return String(decoding: output.toByteArray(), as: UTF8.self)
    }

    @Test("White space before newline")
    func whiteSpaceBeforeNewLine() throws {
        let text = "text\t \r\n\t \r\ntext\t \r\n"
        let expected = "text\r\n\r\ntext\r\n"
        let actual = try Self.applyFilter(DkimRelaxedBodyFilter(), to: text)
        #expect(actual == expected)
    }

    @Test("Trimming empty lines")
    func trimmingEmptyLines() throws {
        let text = "Hello!\r\n  \r\n\r\n"
        let expected = "Hello!\r\n"
        let actual = try Self.applyFilter(DkimRelaxedBodyFilter(), to: text)
        #expect(actual == expected)
    }

    @Test("Multiple whitespaces per line")
    func multipleWhiteSpacesPerLine() throws {
        let text = "This is a test of the relaxed body filter with  \t multiple \t  spaces\n"
        let expected = "This is a test of the relaxed body filter with multiple spaces\n"
        let actual = try Self.applyFilter(DkimRelaxedBodyFilter(), to: text)
        #expect(actual == expected)
    }

    @Test("Non-empty body ending with multiple newlines")
    func nonEmptyBodyEndingWithMultipleNewLines() throws {
        let text = "This is a test of the relaxed body filter with a non-empty body ending with multiple new-lines\n\n\n"
        let expected = "This is a test of the relaxed body filter with a non-empty body ending with multiple new-lines\n"
        let actual = try Self.applyFilter(DkimRelaxedBodyFilter(), to: text)
        #expect(actual == expected)
    }
}
