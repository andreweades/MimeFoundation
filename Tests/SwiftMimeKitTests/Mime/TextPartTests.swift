//
// TextPartTests.swift
//

import Testing
import SwiftMimeKit

@Test("TextPart argument exceptions")
func textPartArgumentExceptions() {
    let text = TextPart(.plain)

    #expect(throws: (any Error).self) {
        _ = try TextPart("plain", args: nil)
    }

    #expect(throws: (any Error).self) {
        _ = try TextPart("plain", String.Encoding.utf8, "blah blah blah", String.Encoding.utf8)
    }

    #expect(throws: (any Error).self) {
        _ = try TextPart("plain", String.Encoding.utf8, "blah blah blah", "blah blah")
    }

    #expect(throws: (any Error).self) {
        _ = try TextPart("plain", 5)
    }

    #expect(throws: (any Error).self) {
        try text.accept(nil)
    }

    #expect(throws: (any Error).self) {
        _ = try text.getText(nil as String?)
    }

    #expect(throws: (any Error).self) {
        _ = try text.getText(nil as String.Encoding?)
    }

    #expect(throws: (any Error).self) {
        try text.setText(nil as String?, "text")
    }

    #expect(throws: (any Error).self) {
        try text.setText(nil as String.Encoding?, "text")
    }

    #expect(throws: (any Error).self) {
        try text.setText("iso-8859-1", nil)
    }

    #expect(throws: (any Error).self) {
        try text.setText(.utf8, nil)
    }
}

@Test("TextPart format")
func textPartFormat() {
    var text = TextPart(.html)
    #expect(text.isHtml)
    #expect(!text.isPlain)
    #expect(!text.isFlowed)
    #expect(!text.isEnriched)
    #expect(!text.isRichText)
    #expect(text.format == .html)
    #expect(text.isFormat(.html))

    text = TextPart(.plain)
    #expect(!text.isHtml)
    #expect(text.isPlain)
    #expect(!text.isFlowed)
    #expect(!text.isEnriched)
    #expect(!text.isRichText)
    #expect(text.format == .plain)
    #expect(text.isFormat(.plain))

    text = TextPart(.flowed)
    #expect(!text.isHtml)
    #expect(text.isPlain)
    #expect(text.isFlowed)
    #expect(!text.isEnriched)
    #expect(!text.isRichText)
    #expect(text.format == .flowed)
    #expect(text.isFormat(.plain))
    #expect(text.isFormat(.flowed))

    text = TextPart(.richText)
    #expect(!text.isHtml)
    #expect(!text.isPlain)
    #expect(!text.isFlowed)
    #expect(!text.isEnriched)
    #expect(text.isRichText)
    #expect(text.format == .richText)
    #expect(text.isFormat(.richText))

    text = TextPart(try! ContentType("application", "rtf"))
    #expect(!text.isHtml)
    #expect(!text.isPlain)
    #expect(!text.isFlowed)
    #expect(!text.isEnriched)
    #expect(text.isRichText)
    #expect(text.format == .richText)
    #expect(text.isFormat(.richText))
    #expect(!text.isFormat(.compressedRichText))

    text = TextPart(.enriched)
    #expect(!text.isHtml)
    #expect(!text.isPlain)
    #expect(!text.isFlowed)
    #expect(text.isEnriched)
    #expect(!text.isRichText)
    #expect(text.format == .enriched)
    #expect(text.isFormat(.enriched))

    text = TextPart("richtext")
    #expect(!text.isHtml)
    #expect(!text.isPlain)
    #expect(!text.isFlowed)
    #expect(text.isEnriched)
    #expect(!text.isRichText)
    #expect(text.format == .enriched)
    #expect(text.isFormat(.enriched))
}

@Test("TextPart get text")
func textPartGetText() throws {
    let text = "This is some Låtín1 text."
    let encoding = CharsetUtils.getEncoding("iso-8859-1") ?? .isoLatin1
    let part = TextPart("plain")

    try part.setText("iso-8859-1", text)

    #expect(try part.getText("iso-8859-1") == text)
    #expect(try part.getText(encoding) == text)
}

@Test("TextPart invalid charset")
func textPartInvalidCharset() throws {
    let text = "This is some Låtín1 text."
    let latin1 = CharsetUtils.getEncoding("iso-8859-1") ?? .isoLatin1
    let part = TextPart("plain")

    try part.setText("iso-8859-1", text)
    part.contentType.charset = "flubber"

    #expect(part.text == text)

    var encoding: String.Encoding? = nil
    let actual = part.getText(&encoding)

    #expect(actual == text)
    #expect(encoding == latin1)
}

@Test("TextPart null content is ascii")
func textPartNullContentIsAscii() throws {
    let part = TextPart("plain")

    #expect(part.text == "")
    #expect(try part.getText(.ascii) == "")

    var encoding: String.Encoding? = nil
    let actual = part.getText(&encoding)

    #expect(actual == "")
    #expect(encoding == .ascii)
}

@Test("TextPart latin1")
func textPartLatin1() throws {
    let text = "This is some Låtín1 text."
    let latin1 = CharsetUtils.getEncoding("iso-8859-1") ?? .isoLatin1
    let bytes = CharsetUtils.getBytes(text, encoding: latin1)
    let memory = MemoryStream(bytes, writable: false)
    let part = TextPart("plain")
    part.content = try MimeContent(memory)

    #expect(part.text == text)

    var encoding: String.Encoding? = nil
    let actual = part.getText(&encoding)

    #expect(actual == text)
    #expect(encoding == latin1)
}

@Test("TextPart UTF-16BE")
func textPartUTF16BE() throws {
    let text = "This is some UTF-16BE text.\r\nThis is line #2."
    let expected = text.replacingOccurrences(of: "\r\n", with: FormatOptions.default.newLine)
    var bytes: [UInt8] = [0xFE, 0xFF]
    bytes.append(contentsOf: CharsetUtils.getBytes(text, encoding: .utf16BigEndian))
    let memory = MemoryStream(bytes, writable: false)
    let part = TextPart("plain")
    part.content = try MimeContent(memory)

    let value = part.text ?? ""
    #expect(String(value.dropFirst()) == expected)

    var encoding: String.Encoding? = nil
    let actual = part.getText(&encoding)

    #expect(String(actual.dropFirst()) == expected)
    #expect(encoding == .utf16BigEndian)
}

@Test("TextPart UTF-16LE")
func textPartUTF16LE() throws {
    let text = "This is some UTF-16LE text.\r\nThis is line #2."
    let expected = text.replacingOccurrences(of: "\r\n", with: FormatOptions.default.newLine)
    var bytes: [UInt8] = [0xFF, 0xFE]
    bytes.append(contentsOf: CharsetUtils.getBytes(text, encoding: .utf16LittleEndian))
    let memory = MemoryStream(bytes, writable: false)
    let part = TextPart("plain")
    part.content = try MimeContent(memory)

    let value = part.text ?? ""
    #expect(String(value.dropFirst()) == expected)

    var encoding: String.Encoding? = nil
    let actual = part.getText(&encoding)

    #expect(String(actual.dropFirst()) == expected)
    #expect(encoding == .utf16LittleEndian)
}

@Test("TextPart TryDetectEncoding no content")
func textPartTryDetectEncodingNoContent() {
    let part = TextPart(.html)
    var encoding: String.Encoding? = nil
    var confidence: TextEncodingConfidence = .undefined

    #expect(part.tryDetectEncoding(&encoding, confidence: &confidence))
    #expect(confidence == .irrelevant)
    #expect(encoding == .ascii)
}

@Test("TextPart TryDetectEncoding BOM UTF8")
func textPartTryDetectEncodingBomUtf8() throws {
    let html = "<html><head><meta http-equiv=\"Content-Type\" content=\"text/html; charset=iso-8859-1\" /></head><body><p>Hello, world!</p></body></html>"
    var bytes: [UInt8] = [0xEF, 0xBB, 0xBF]
    bytes.append(contentsOf: Array(html.utf8))

    let part = TextPart(.html)
    part.content = try MimeContent(MemoryStream(bytes, writable: false))

    var encoding: String.Encoding? = nil
    var confidence: TextEncodingConfidence = .undefined

    #expect(part.tryDetectEncoding(&encoding, confidence: &confidence))
    #expect(confidence == .certain)
    #expect(encoding == .utf8)
}

@Test("TextPart TryDetectEncoding BOM UTF-16BE")
func textPartTryDetectEncodingBomUtf16BE() throws {
    let html = "<html><head><meta http-equiv=\"Content-Type\" content=\"text/html; charset=iso-8859-1\" /></head><body><p>Hello, world!</p></body></html>"
    var bytes: [UInt8] = [0xFE, 0xFF]
    bytes.append(contentsOf: CharsetUtils.getBytes(html, encoding: .utf16BigEndian))

    let part = TextPart(.html)
    part.content = try MimeContent(MemoryStream(bytes, writable: false))

    var encoding: String.Encoding? = nil
    var confidence: TextEncodingConfidence = .undefined

    #expect(part.tryDetectEncoding(&encoding, confidence: &confidence))
    #expect(confidence == .certain)
    #expect(encoding == .utf16BigEndian)
}

@Test("TextPart TryDetectEncoding BOM UTF-16LE")
func textPartTryDetectEncodingBomUtf16LE() throws {
    let html = "<html><head><meta http-equiv=\"Content-Type\" content=\"text/html; charset=iso-8859-1\" /></head><body><p>Hello, world!</p></body></html>"
    var bytes: [UInt8] = [0xFF, 0xFE]
    bytes.append(contentsOf: CharsetUtils.getBytes(html, encoding: .utf16LittleEndian))

    let part = TextPart(.html)
    part.content = try MimeContent(MemoryStream(bytes, writable: false))

    var encoding: String.Encoding? = nil
    var confidence: TextEncodingConfidence = .undefined

    #expect(part.tryDetectEncoding(&encoding, confidence: &confidence))
    #expect(confidence == .certain)
    #expect(encoding == .utf16LittleEndian)
}

@Test("TextPart TryDetectHtmlEncoding")
func textPartTryDetectHtmlEncoding() throws {
    let html = "<html><head><meta http-equiv=\"Content-Type\" content=\"text/html; charset=euc-kr\" /></head><body><p>Hello, world!</p></body></html>"
    let part = TextPart(.html)
    part.content = try MimeContent(MemoryStream(Array(html.utf8), writable: false))

    var encoding: String.Encoding? = nil
    var confidence: TextEncodingConfidence = .undefined

    #expect(part.tryDetectEncoding(&encoding, confidence: &confidence))
    #expect(confidence == .tentative)
    #expect(CharsetUtils.getMimeCharset(encoding ?? .utf8) == "euc-kr")
}

@Test("TextPart TryDetectHtmlEncoding invalid charset")
func textPartTryDetectHtmlEncodingInvalidCharset() throws {
    let html = "<html><head><meta http-equiv=\"Content-Type\" content=\"text/html; charset=x-unknown\" /></head><body><p>Hello, world!</p></body></html>"
    let part = TextPart(.html)
    part.content = try MimeContent(MemoryStream(Array(html.utf8), writable: false))

    var encoding: String.Encoding? = nil
    var confidence: TextEncodingConfidence = .undefined

    #expect(!part.tryDetectEncoding(&encoding, confidence: &confidence))
}

@Test("TextPart TryDetectHtmlEncoding x-user-defined")
func textPartTryDetectHtmlEncodingXUserDefined() throws {
    let html = "<html><head><meta http-equiv=\"Content-Type\" content=\"text/html; charset=x-user-defined\" /></head><body><p>Hello, world!</p></body></html>"
    let part = TextPart(.html)
    part.content = try MimeContent(MemoryStream(Array(html.utf8), writable: false))

    var encoding: String.Encoding? = nil
    var confidence: TextEncodingConfidence = .undefined

    #expect(part.tryDetectEncoding(&encoding, confidence: &confidence))
    #expect(confidence == .tentative)
    #expect(CharsetUtils.getMimeCharset(encoding ?? .utf8) == "windows-1252")
}

@Test("TextPart TryDetectHtmlEncoding charset attribute")
func textPartTryDetectHtmlEncodingCharsetAttribute() throws {
    let html = "<html><head><meta charset=\"x-user-defined\" /></head><body><p>Hello, world!</p></body></html>"
    let part = TextPart(.html)
    part.content = try MimeContent(MemoryStream(Array(html.utf8), writable: false))

    var encoding: String.Encoding? = nil
    var confidence: TextEncodingConfidence = .undefined

    #expect(part.tryDetectEncoding(&encoding, confidence: &confidence))
    #expect(confidence == .tentative)
    #expect(CharsetUtils.getMimeCharset(encoding ?? .utf8) == "windows-1252")
}

@Test("TextPart TryDetectHtmlEncoding http-equiv + charset attributes")
func textPartTryDetectHtmlEncodingHttpEquivAndCharsetAttributes() throws {
    let html = "<html><head><meta http-equiv=\"Content-Type\" content=\"text/html; charset=iso-8859-1\" charset=\"windows-1252\" /></head><body><p>Hello, world!</p></body></html>"
    let part = TextPart(.html)
    part.content = try MimeContent(MemoryStream(Array(html.utf8), writable: false))

    var encoding: String.Encoding? = nil
    var confidence: TextEncodingConfidence = .undefined

    #expect(part.tryDetectEncoding(&encoding, confidence: &confidence))
    #expect(confidence == .tentative)
    #expect(CharsetUtils.getMimeCharset(encoding ?? .utf8) == "windows-1252")
}

@Test("TextPart TryDetectHtmlEncoding http-equiv + charset attributes reversed")
func textPartTryDetectHtmlEncodingHttpEquivAndCharsetAttributesReversed() throws {
    let html = "<html><head><meta charset=\"windows-1252\" http-equiv=\"Content-Type\" content=\"text/html; charset=iso-8859-1\" /></head><body><p>Hello, world!</p></body></html>"
    let part = TextPart(.html)
    part.content = try MimeContent(MemoryStream(Array(html.utf8), writable: false))

    var encoding: String.Encoding? = nil
    var confidence: TextEncodingConfidence = .undefined

    #expect(part.tryDetectEncoding(&encoding, confidence: &confidence))
    #expect(confidence == .tentative)
    #expect(CharsetUtils.getMimeCharset(encoding ?? .utf8) == "windows-1252")
}

@Test("TextPart TryDetectHtmlEncoding no charset parameter")
func textPartTryDetectHtmlEncodingNoCharsetParameter() throws {
    let html = "<html><head><meta http-equiv=\"Content-Type\" content=\"text/html\" /></head><body><p>Hello, world!</p></body></html>"
    let part = TextPart(.html)
    part.content = try MimeContent(MemoryStream(Array(html.utf8), writable: false))

    var encoding: String.Encoding? = nil
    var confidence: TextEncodingConfidence = .undefined

    #expect(!part.tryDetectEncoding(&encoding, confidence: &confidence))
}

@Test("TextPart TryDetectHtmlEncoding invalid content type")
func textPartTryDetectHtmlEncodingInvalidContentType() throws {
    let html = "<html><head><meta http-equiv=\"Content-Type\" content=\"this is invalid\" /></head><body><p>Hello, world!</p></body></html>"
    let part = TextPart(.html)
    part.content = try MimeContent(MemoryStream(Array(html.utf8), writable: false))

    var encoding: String.Encoding? = nil
    var confidence: TextEncodingConfidence = .undefined

    #expect(!part.tryDetectEncoding(&encoding, confidence: &confidence))
}

@Test("TextPart TryDetectHtmlEncoding empty content attribute")
func textPartTryDetectHtmlEncodingEmptyContentAttribute() throws {
    let html = "<html><head><meta http-equiv=\"Content-Type\" content /></head><body><p>Hello, world!</p></body></html>"
    let part = TextPart(.html)
    part.content = try MimeContent(MemoryStream(Array(html.utf8), writable: false))

    var encoding: String.Encoding? = nil
    var confidence: TextEncodingConfidence = .undefined

    #expect(!part.tryDetectEncoding(&encoding, confidence: &confidence))
}

@Test("TextPart TryDetectHtmlEncoding no content attribute")
func textPartTryDetectHtmlEncodingNoContentAttribute() throws {
    let html = "<html><head><meta http-equiv=\"Content-Type\" /></head><body><p>Hello, world!</p></body></html>"
    let part = TextPart(.html)
    part.content = try MimeContent(MemoryStream(Array(html.utf8), writable: false))

    var encoding: String.Encoding? = nil
    var confidence: TextEncodingConfidence = .undefined

    #expect(!part.tryDetectEncoding(&encoding, confidence: &confidence))
}

@Test("TextPart TryDetectHtmlEncoding http-equiv not content-type")
func textPartTryDetectHtmlEncodingEmptyHttpEquivNotContentType() throws {
    let html = "<html><head><meta http-equiv=\"Content-Transfer-Encoding\" /></head><body><p>Hello, world!</p></body></html>"
    let part = TextPart(.html)
    part.content = try MimeContent(MemoryStream(Array(html.utf8), writable: false))

    var encoding: String.Encoding? = nil
    var confidence: TextEncodingConfidence = .undefined

    #expect(!part.tryDetectEncoding(&encoding, confidence: &confidence))
}

@Test("TextPart TryDetectHtmlEncoding empty http-equiv attribute")
func textPartTryDetectHtmlEncodingEmptyHttpEquivAttribute() throws {
    let html = "<html><head><meta http-equiv /></head><body><p>Hello, world!</p></body></html>"
    let part = TextPart(.html)
    part.content = try MimeContent(MemoryStream(Array(html.utf8), writable: false))

    var encoding: String.Encoding? = nil
    var confidence: TextEncodingConfidence = .undefined

    #expect(!part.tryDetectEncoding(&encoding, confidence: &confidence))
}

@Test("TextPart TryDetectHtmlEncoding meta not http-equiv")
func textPartTryDetectHtmlEncodingMetaNotHttpEquiv() throws {
    let html = "<html><head><meta data=\"metadata\" /></head><body><p>Hello, world!</p></body></html>"
    let part = TextPart(.html)
    part.content = try MimeContent(MemoryStream(Array(html.utf8), writable: false))

    var encoding: String.Encoding? = nil
    var confidence: TextEncodingConfidence = .undefined

    #expect(!part.tryDetectEncoding(&encoding, confidence: &confidence))
}

@Test("TextPart TryDetectHtmlEncoding no meta tags")
func textPartTryDetectHtmlEncodingNoMetaTags() throws {
    let html = "<html><head></head><body><p>Hello, world!</p></body></html>"
    let part = TextPart(.html)
    part.content = try MimeContent(MemoryStream(Array(html.utf8), writable: false))

    var encoding: String.Encoding? = nil
    var confidence: TextEncodingConfidence = .undefined

    #expect(!part.tryDetectEncoding(&encoding, confidence: &confidence))
}

@Test("TextPart TryDetectHtmlEncoding empty html tag")
func textPartTryDetectHtmlEncodingEmptyHtmlTag() throws {
    let html = "<html /><head><meta http-equiv=\"Content-Type\" content=\"text/html; charset=euc-kr\" /></head><body><p>Hello, world!</p></body></html>"
    let part = TextPart(.html)
    part.content = try MimeContent(MemoryStream(Array(html.utf8), writable: false))

    var encoding: String.Encoding? = nil
    var confidence: TextEncodingConfidence = .undefined

    #expect(!part.tryDetectEncoding(&encoding, confidence: &confidence))
}

@Test("TextPart TryDetectHtmlEncoding empty head tag")
func textPartTryDetectHtmlEncodingEmptyHeadTag() throws {
    let html = "<html><head /><meta http-equiv=\"Content-Type\" content=\"text/html; charset=euc-kr\" /></head><body><p>Hello, world!</p></body></html>"
    let part = TextPart(.html)
    part.content = try MimeContent(MemoryStream(Array(html.utf8), writable: false))

    var encoding: String.Encoding? = nil
    var confidence: TextEncodingConfidence = .undefined

    #expect(!part.tryDetectEncoding(&encoding, confidence: &confidence))
}
