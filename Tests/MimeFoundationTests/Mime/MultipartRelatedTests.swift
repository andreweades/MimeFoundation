//
// MultipartRelatedTests.swift
//

import Foundation
import Testing
import MimeFoundation

@Test("MultipartRelated argument exceptions")
func multipartRelatedArgumentExceptions() {
    let related = MultipartRelated()
    var mimeType = ""
    var charset: String? = nil

    // Tests with nil have been removed since parameters are now non-optional

    #expect(throws: (any Error).self) {
        _ = try related.open(URL(string: "http://www.xamarin.com/logo.png")!, mimeType: &mimeType, charset: &charset)
    }

    #expect(throws: (any Error).self) {
        _ = try related.open(URL(string: "http://www.xamarin.com/logo.png")!)
    }
}

@Test("MultipartRelated generic args constructor")
func multipartRelatedGenericArgsConstructor() throws {
    let multipart = try MultipartRelated(
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

@Test("MultipartRelated document root")
func multipartRelatedDocumentRoot() throws {
    let gif = try MimePart("image", "gif")
    gif.contentDisposition = try ContentDisposition(ContentDisposition.inline)
    gif.contentDisposition?.fileName = "empty.gif"
    gif.contentId = "gif-id"

    let jpg = try MimePart("image", "jpg")
    jpg.contentDisposition = try ContentDisposition(ContentDisposition.inline)
    jpg.contentDisposition?.fileName = "empty.jpg"
    jpg.contentId = "jpg-id"

    let html = TextPart("html")
    html.text = "This is the html body..."
    html.contentId = "html-id"

    let related = MultipartRelated()
    try related.add(gif)
    try related.add(jpg)
    try related.add(html)

    related.contentType.parameters["type"] = "text/html"
    related.contentType.parameters["start"] = "<\(html.contentId ?? "")>"

    #expect(related.count == 3)
    #expect(related.root === html)
    #expect(related[2] === html)

    let root = TextPart("html")
    root.text = "This is the replacement root document..."

    try related.setRoot(root)

    #expect(related.count == 3)
    #expect(related.root === root)
    #expect(related[2] === root)
    #expect(root.contentId != nil)
    #expect(!(root.contentId ?? "").isEmpty)

    let start = "<\(root.contentId ?? "")>"
    #expect(related.contentType.parameters["start"] == start)

    related.clear()
    try related.add(gif)
    try related.add(jpg)
    try related.setRoot(html)

    #expect(related.count == 3)
    #expect(related.root === html)
    #expect(related[0] === html)
    #expect(related.contentType.parameters["start"] == nil)
}

@Test("MultipartRelated document root by type")
func multipartRelatedDocumentRootByType() throws {
    let related = MultipartRelated()
    let image = try MimePart("image", "png")
    image.content = try MimeContent(MemoryStream([0x00], writable: false))
    let html = TextPart("html")
    html.text = "<html>body</html>"

    try related.add(image)
    try related.add(html)
    related.contentType.parameters["type"] = "text/html"

    #expect(related.count == 2)
    #expect(related[0].contentType.mimeType == "image/png")
    #expect(related[1].contentType.mimeType == "text/html")
    #expect(related.root === html)
}

@Test("MultipartRelated reference by content-id")
func multipartRelatedReferenceByContentId() throws {
    let related = MultipartRelated()
    let html = TextPart("html")
    html.text = "<html>This is an <b>html</b> body.</html>"

    try related.setRoot(html)

    let gif = try MimePart("image", "gif")
    gif.content = try MimeContent(MemoryStream([0x00], writable: false))
    gif.contentId = "gif-id"
    try related.add(gif)

    let jpg = try MimePart("image", "jpg")
    jpg.content = try MimeContent(MemoryStream([0x01], writable: false))
    jpg.contentId = "jpg-id"
    try related.add(jpg)

    #expect(related.contentType.parameters["type"] == "text/html")
    #expect(related.contentType.parameters["start"] == nil)

    for index in 1..<related.count {
        let entity = related[index]
        let cid = URL(string: "cid:\(entity.contentId ?? "")")!
        #expect(related.contains(cid))
        #expect(related.indexOf(cid) == index)

        var mimeType = ""
        var charset: String? = nil
        _ = try related.open(cid, mimeType: &mimeType, charset: &charset)
        #expect(mimeType == entity.contentType.mimeType)

        _ = try related.open(cid)
    }
}

@Test("MultipartRelated reference by content-location")
func multipartRelatedReferenceByContentLocation() throws {
    let related = MultipartRelated()
    let html = TextPart("html")
    html.text = "<html>This is an <b>html</b> body.</html>"

    try related.setRoot(html)

    let gif = try MimePart("image", "gif")
    gif.content = try MimeContent(MemoryStream([0x00], writable: false))
    gif.contentLocation = URL(string: "empty.gif")
    try related.add(gif)

    let jpg = try MimePart("image", "jpg")
    jpg.content = try MimeContent(MemoryStream([0x01], writable: false))
    jpg.contentLocation = URL(string: "empty.jpg")
    try related.add(jpg)

    #expect(related.contentType.parameters["type"] == "text/html")
    #expect(related.contentType.parameters["start"] == nil)

    for index in 1..<related.count {
        let entity = related[index]
        let location = entity.contentLocation
        #expect(location != nil)
        if let location {
            #expect(related.contains(location))
            #expect(related.indexOf(location) == index)

            var mimeType = ""
            var charset: String? = nil
            _ = try related.open(location, mimeType: &mimeType, charset: &charset)
            #expect(mimeType == entity.contentType.mimeType)

            _ = try related.open(location)
        }
    }
}
