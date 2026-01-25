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
