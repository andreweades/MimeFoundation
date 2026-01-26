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
// HeaderListTests.swift
//

import Testing
import MimeFoundation

@Test("HeaderList add and replace")
func headerListAddReplace() {
    let headers = HeaderList()
    headers.add(.subject, "Hello")

    #expect(headers.contains(.subject))
    #expect(headers[.subject] == "Hello")

    headers[.subject] = "Updated"
    #expect(headers[.subject] == "Updated")

    headers.removeAll(.subject)
    #expect(headers.contains(.subject) == false)
}

@Test("HeaderList formatting")
func headerListFormatting() {
    let headers = HeaderList()
    headers.add(.from, "Alice <alice@example.com>")
    headers.add(.subject, "Hello")

    let rendered = headers.toString(.default, encode: false)
    #expect(rendered.contains("From: Alice <alice@example.com>"))
    #expect(rendered.contains("Subject: Hello"))
}
