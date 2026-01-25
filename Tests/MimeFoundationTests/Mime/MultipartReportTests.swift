//
// MultipartReportTests.swift
//

import Testing
import MimeFoundation

// Test removed: args no longer takes nil, accept no longer takes optional visitor

@Test("MultipartReport generic args constructor")
func multipartReportGenericArgsConstructor() throws {
    let multipart = try MultipartReport(reportType: "disposition-notification",
        Header(.contentDescription, value: "This is a description of the multipart."),
        TextPart(.plain),
        try MimePart("image", "gif")
    )

    (multipart[0] as? TextPart)?.text = "This is the message body."
    (multipart[1] as? MimePart)?.fileName = "attachment.gif"

    #expect(multipart.reportType == "disposition-notification")
    #expect(multipart.headers.contains(.contentDescription))
    #expect(multipart.count == 2)
    #expect(multipart[0].contentType.mimeType == "text/plain")
    #expect(multipart[1].contentType.mimeType == "image/gif")
}
