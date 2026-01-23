//
// MultipartAlternativeTests.swift
//

import Testing
import SwiftMimeKit

private func normalizeNewlines(_ value: String?) -> String? {
    value?.replacingOccurrences(of: "\r\n", with: "\n")
}

@Test("MultipartAlternative argument exceptions")
func multipartAlternativeArgumentExceptions() {
    let alternative = MultipartAlternative()

    #expect(throws: (any Error).self) {
        _ = try MultipartAlternative(args: nil)
    }

    #expect(throws: (any Error).self) {
        try alternative.accept(nil)
    }
}

@Test("MultipartAlternative generic args constructor")
func multipartAlternativeGenericArgsConstructor() throws {
    let multipart = try MultipartAlternative(
        Header(.contentDescription, value: "This is a description of the multipart."),
        TextPart(.plain),
        try MimePart("image", "gif")
    )

    (multipart[0] as? TextPart)?.text = "This is the message body."
    (multipart[1] as? MimePart)?.fileName = "attachment.gif"

    #expect(multipart.headers.contains(.contentDescription))
    #expect(multipart.count == 2)
    #expect(multipart[0].contentType.mimeType == "text/plain")
    #expect(multipart[1].contentType.mimeType == "image/gif")
}

@Test("MultipartAlternative getTextBody")
func multipartAlternativeGetTextBody() throws {
    let alternative = MultipartAlternative()
    let plain = TextPart("plain")
    plain.text = "plain\n"
    let flowed = TextPart(.flowed)
    flowed.text = "flowed\n"
    let richtext = TextPart("rtf")
    richtext.text = "rtf\n"
    let html = TextPart("html")
    html.text = "html\n"

    try alternative.add(plain)
    try alternative.add(richtext)
    try alternative.add(html)

    #expect(normalizeNewlines(alternative.textBody) == "plain\n")
    #expect(normalizeNewlines(alternative.htmlBody) == "html\n")

    try alternative.insert(flowed, at: 1)

    #expect(normalizeNewlines(alternative.getTextBody(.plain)) == "flowed\n")
    #expect(normalizeNewlines(alternative.getTextBody(.flowed)) == "flowed\n")
    #expect(normalizeNewlines(alternative.getTextBody(.richText)) == "rtf\n")
    #expect(normalizeNewlines(alternative.getTextBody(.html)) == "html\n")
    #expect(alternative.getTextBody(.enriched) == nil)
}

@Test("MultipartAlternative nested alternatives")
func multipartAlternativeNestedAlternatives() throws {
    let alternative = MultipartAlternative()
    let plain = TextPart("plain")
    plain.text = "plain\n"
    let flowed = TextPart(.flowed)
    flowed.text = "flowed\n"
    let richtext = TextPart("rtf")
    richtext.text = "rtf\n"
    let html = TextPart("html")
    html.text = "html\n"

    try alternative.add(plain)
    try alternative.add(richtext)
    try alternative.add(html)

    let outer = MultipartAlternative()
    try outer.add(alternative)

    #expect(normalizeNewlines(outer.textBody) == "plain\n")
    #expect(normalizeNewlines(outer.htmlBody) == "html\n")

    try alternative.insert(flowed, at: 1)

    #expect(normalizeNewlines(outer.getTextBody(.plain)) == "flowed\n")
    #expect(normalizeNewlines(outer.getTextBody(.flowed)) == "flowed\n")
    #expect(normalizeNewlines(outer.getTextBody(.richText)) == "rtf\n")
    #expect(normalizeNewlines(outer.getTextBody(.html)) == "html\n")
    #expect(outer.getTextBody(.enriched) == nil)
}

@Test("MultipartAlternative inside related")
func multipartAlternativeInsideRelated() throws {
    let alternative = MultipartAlternative()
    let plain = TextPart("plain")
    plain.text = "plain\n"
    let flowed = TextPart(.flowed)
    flowed.text = "flowed\n"
    let richtext = TextPart("rtf")
    richtext.text = "rtf\n"
    let html = TextPart("html")
    html.text = "html\n"

    try alternative.add(plain)
    try alternative.add(richtext)
    try alternative.add(html)

    let related = MultipartRelated()
    try related.add(alternative)

    let outer = MultipartAlternative()
    try outer.add(related)

    #expect(normalizeNewlines(outer.textBody) == "plain\n")
    #expect(normalizeNewlines(outer.htmlBody) == "html\n")

    try alternative.insert(flowed, at: 1)

    #expect(normalizeNewlines(outer.getTextBody(.plain)) == "flowed\n")
    #expect(normalizeNewlines(outer.getTextBody(.flowed)) == "flowed\n")
    #expect(normalizeNewlines(outer.getTextBody(.richText)) == "rtf\n")
    #expect(normalizeNewlines(outer.getTextBody(.html)) == "html\n")
    #expect(outer.getTextBody(.enriched) == nil)
}

@Test("MultipartAlternative mixed inside alternative")
func multipartAlternativeMixedInsideAlternative() throws {
    let mixed = try Multipart("mixed")
    let plain = TextPart("plain")
    plain.text = "plain\n"
    let flowed = TextPart(.flowed)
    flowed.text = "flowed\n"
    let richtext = TextPart("rtf")
    richtext.text = "rtf\n"
    let html = TextPart("html")
    html.text = "html\n"

    try mixed.add(plain)
    try mixed.add(richtext)
    try mixed.add(html)

    let alternative = MultipartAlternative()
    try alternative.add(mixed)

    #expect(normalizeNewlines(alternative.textBody) == "plain\n")

    try mixed.insert(flowed, at: 1)

    #expect(normalizeNewlines(alternative.getTextBody(.plain)) == "plain\n")
    #expect(alternative.getTextBody(.flowed) == nil)
    #expect(alternative.getTextBody(.richText) == nil)
    #expect(alternative.getTextBody(.html) == nil)
    #expect(alternative.getTextBody(.enriched) == nil)
}
