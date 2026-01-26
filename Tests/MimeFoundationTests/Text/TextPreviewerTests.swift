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
import Foundation
@testable import MimeFoundation

@Suite("TextPreviewer tests")
struct TextPreviewerTests {
    @Test("Test PlainTextPreviewer basic")
    func testPlainTextPreviewerBasic() {
        let previewer = PlainTextPreviewer()
        previewer.maximumPreviewLength = 10
        let text = "Hello world this is a long text"
        let preview = previewer.getPreviewText(text)
        #expect(preview == "Hello wor\u{2026}")
    }

    @Test("Test PlainTextPreviewer whitespace")
    func testPlainTextPreviewerWhitespace() {
        let previewer = PlainTextPreviewer()
        previewer.maximumPreviewLength = 20
        let text = "Hello     world   \n  this is a test"
        let preview = previewer.getPreviewText(text)
        #expect(preview == "Hello world this is\u{2026}")
    }

    @Test("Test HtmlTextPreviewer basic")
    func testHtmlTextPreviewerBasic() {
        let previewer = HtmlTextPreviewer()
        previewer.maximumPreviewLength = 20
        let html = "<html><body>Hello world <b>this is</b> a test</body></html>"
        let preview = previewer.getPreviewText(html)
        #expect(preview == "Hello world this is\u{2026}")
    }

    @Test("Test HtmlTextPreviewer with alt text")
    func testHtmlTextPreviewerAltText() {
        let previewer = HtmlTextPreviewer()
        previewer.maximumPreviewLength = 30
        let html = "<html><body>Hello <img src='foo.png' alt='world'> this is a test</body></html>"
        let preview = previewer.getPreviewText(html)
        #expect(preview == "Hello world this is a test")
    }

    @Test("Test HtmlTextPreviewer suppress script")
    func testHtmlTextPreviewerSuppressScript() {
        let previewer = HtmlTextPreviewer()
        previewer.maximumPreviewLength = 20
        let html = "<html><body>Hello <script>var x = 1;</script>world</body></html>"
        let preview = previewer.getPreviewText(html)
        #expect(preview == "Hello world")
    }

    @Test("Test HtmlTextPreviewer with entities")
    func testHtmlTextPreviewerEntities() {
        let previewer = HtmlTextPreviewer()
        previewer.maximumPreviewLength = 30
        let html = "<html><body>Hello &amp; world &lt;this&gt; is a test</body></html>"
        let preview = previewer.getPreviewText(html)
        #expect(preview == "Hello & world <this> is a test")
    }

    @Test("Test GetPreviewText for TextPart")
    func testGetPreviewTextTextPart() {
        let body = TextPart("plain")
        body.text = "Hello world this is a test"
        let preview = TextPreviewer.getPreviewText(for: body)
        #expect(preview == "Hello world this is a test")
    }
}
