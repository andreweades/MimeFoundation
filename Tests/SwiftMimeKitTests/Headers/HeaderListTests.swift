//
// HeaderListTests.swift
//

import Testing
import SwiftMimeKit

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
