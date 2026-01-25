//
// MimePartTests.swift
//

import Foundation
import Testing
@testable import MimeFoundation

private func hexString(_ bytes: [UInt8]) -> String {
    bytes.map { String(format: "%02x", $0) }.joined()
}

@Test("MimePart argument exceptions")
func mimePartArgumentExceptions() {
    // Tests with nil have been removed since parameters are now non-optional

    #expect(throws: MimePartError.emptyMediaType) {
        _ = try MimePart("", "octet-stream")
    }
    #expect(throws: MimePartError.emptyMediaSubtype) {
        _ = try MimePart("application", "")
    }

    let part = MimePart()
    #expect(throws: MimePartError.invalidContentDuration) {
        try part.setContentDuration(-1)
    }
}

@Test("MimePart parameterized ctor")
func mimePartParameterizedCtor() throws {
    let headers = [Header(field: "Content-Id", value: "<id@localhost.com>")]
    let part = try MimePart("text", "plain", Header(field: "Content-Transfer-Encoding", value: "base64"), headers)
    part.content = try MimeContent(MemoryStream())

    #expect(part.contentId == "id@localhost.com")
    #expect(part.contentTransferEncoding == .base64)

    let stream = MemoryStream()
    var options = FormatOptions.default
    options.newLineFormat = .unix

    try part.writeTo(options, stream)
    let serialized = String(decoding: stream.toByteArray(), as: UTF8.self)
    let expected = "Content-Type: text/plain\nContent-Transfer-Encoding: base64\nContent-Id: <id@localhost.com>\n\n"
    #expect(serialized == expected)
}

@Test("MimePart content disposition")
func mimePartContentDisposition() {
    let part = MimePart()

    #expect(part.contentDisposition == nil)
    part.contentDisposition = try? ContentDisposition(ContentDisposition.attachment)
    #expect(part.contentDisposition != nil)
    #expect(part.headers.contains(.contentDisposition))

    part.contentDisposition = nil
    #expect(part.contentDisposition == nil)
    #expect(!part.headers.contains(.contentDisposition))

    part.headers.add(.contentDisposition, "attachment")
    #expect(part.contentDisposition != nil)

    part.headers.removeAll(.contentDisposition)
    #expect(part.contentDisposition == nil)

    part.contentDisposition = try? ContentDisposition()
    part.fileName = "fileName"
    part.headers.clear()
    #expect(part.contentDisposition == nil)
}

@Test("MimePart isAttachment")
func mimePartIsAttachment() {
    let part = MimePart()

    #expect(part.contentDisposition == nil)
    part.isAttachment = true
    #expect(part.contentDisposition != nil)
    #expect(part.headers.contains(.contentDisposition))
    #expect(part.contentDisposition?.disposition == ContentDisposition.attachment)

    part.isAttachment = false
    #expect(part.contentDisposition != nil)
    #expect(part.contentDisposition?.disposition == ContentDisposition.inline)

    part.isAttachment = true
    #expect(part.contentDisposition?.disposition == ContentDisposition.attachment)

    part.contentDisposition = nil
    #expect(part.contentDisposition == nil)
    #expect(!part.headers.contains(.contentDisposition))

    part.isAttachment = false
    #expect(part.contentDisposition == nil)
}

@Test("MimePart content base")
func mimePartContentBase() throws {
    let relative = URL(string: "relative")!
    let uri = URL(string: "http://www.google.com")!
    let part = MimePart()

    #expect(part.contentBase == nil)
    #expect(throws: MimeEntityError.invalidContentBase) {
        try part.setContentBase(relative)
    }

    try part.setContentBase(uri)
    #expect(part.contentBase == uri)
    #expect(part.headers.contains(.contentBase))

    try part.setContentBase(nil)
    #expect(part.contentBase == nil)
    #expect(!part.headers.contains(.contentBase))

    part.headers.add(.contentBase, uri.absoluteString)
    #expect(part.contentBase == uri)

    part.headers.removeAll(.contentBase)
    #expect(part.contentBase == nil)

    try part.setContentBase(uri)
    part.headers.clear()
    #expect(part.contentBase == nil)
}

@Test("MimePart content location")
func mimePartContentLocation() {
    let part = MimePart()
    let uri = URL(string: "http://www.google.com")!

    #expect(part.contentLocation == nil)
    part.contentLocation = uri
    #expect(part.contentLocation == uri)
    #expect(part.headers.contains(.contentLocation))

    part.contentLocation = nil
    #expect(part.contentLocation == nil)
    #expect(!part.headers.contains(.contentLocation))

    part.headers.add(.contentLocation, uri.absoluteString)
    #expect(part.contentLocation == uri)

    part.headers.removeAll(.contentLocation)
    #expect(part.contentLocation == nil)

    part.contentLocation = uri
    part.headers.clear()
    #expect(part.contentLocation == nil)
}

@Test("MimePart content description")
func mimePartContentDescription() {
    let description = "This is a sample description."
    let part = MimePart()

    #expect(part.contentDescription == nil)

    part.contentDescription = description
    #expect(part.contentDescription != nil)
    #expect(part.headers.contains(.contentDescription))

    part.contentDescription = nil
    #expect(part.contentDescription == nil)
    #expect(!part.headers.contains(.contentDescription))

    part.headers.add(.contentDescription, description)
    #expect(part.contentDescription != nil)

    part.headers.removeAll(.contentDescription)
    #expect(part.contentDescription == nil)

    part.contentDescription = description
    part.headers.clear()
    #expect(part.contentDescription == nil)
}

@Test("MimePart content duration")
func mimePartContentDuration() throws {
    let part = MimePart()

    #expect(part.contentDuration == nil)

    try part.setContentDuration(500)
    #expect(part.contentDuration == 500)
    #expect(part.headers.contains(.contentDuration))

    try part.setContentDuration(nil)
    #expect(part.contentDuration == nil)
    #expect(!part.headers.contains(.contentDuration))

    part.headers.add(.contentDuration, "500")
    #expect(part.contentDuration == 500)

    part.headers.removeAll(.contentDuration)
    #expect(part.contentDuration == nil)

    try part.setContentDuration(500)
    part.headers.clear()
    #expect(part.contentDuration == nil)
}

@Test("MimePart content id")
func mimePartContentId() throws {
    let id = MimeUtils.generateMessageId()
    let part = MimePart()

    #expect(part.contentId == nil)

    try part.setContentId(id)
    #expect(part.contentId == id)
    #expect(part.headers.contains(.contentId))

    try part.setContentId(nil)
    #expect(part.contentId == nil)
    #expect(!part.headers.contains(.contentId))

    part.headers.add(.contentId, "<\(id)>")
    #expect(part.contentId == id)

    part.headers.removeAll(.contentId)
    #expect(part.contentId == nil)

    try part.setContentId(id)
    part.headers.clear()
    #expect(part.contentId == nil)

    #expect(throws: MimeEntityError.invalidContentId) {
        try part.setContentId("<image.jpg")
    }
}

@Test("MimePart content md5")
func mimePartContentMd5() throws {
    let part = MimePart()

    #expect(part.contentMd5 == nil)

    part.contentMd5 = "XYZ"
    #expect(part.contentMd5 == "XYZ")
    #expect(part.headers.contains(.contentMd5))

    part.contentMd5 = nil
    #expect(part.contentMd5 == nil)
    #expect(!part.headers.contains(.contentMd5))

    part.headers.add(.contentMd5, "XYZ")
    #expect(part.contentMd5 == "XYZ")

    part.headers.removeAll(.contentMd5)
    #expect(part.contentMd5 == nil)

    part.contentMd5 = "XYZ"
    part.headers.clear()
    #expect(part.contentMd5 == nil)

    #expect(throws: MimePartError.noContent) {
        _ = try part.computeContentMd5()
    }
    #expect(part.verifyContentMd5() == false)

    let textPart = TextPart("plain")
    textPart.text = "Hello, World.\n\nLet's check the MD5 sum of this text!\n"

    let md5sum = try textPart.computeContentMd5()
    #expect(md5sum == "8criUiOQmpfifOuOmYFtEQ==")

    let decoded = Data(base64Encoded: md5sum) ?? Data()
    #expect(hexString(Array(decoded)) == "f1cae25223909a97e27ceb8e99816d11")

    textPart.contentMd5 = md5sum
    #expect(textPart.verifyContentMd5())
}

@Test("MimePart content transfer encoding")
func mimePartContentTransferEncoding() throws {
    let part = MimePart()

    #expect(part.contentTransferEncoding == .default)

    part.contentTransferEncoding = .eightBit
    #expect(part.contentTransferEncoding == .eightBit)
    #expect(part.headers.contains(.contentTransferEncoding))

    part.contentTransferEncoding = .default
    #expect(part.contentTransferEncoding == .default)
    #expect(!part.headers.contains(.contentTransferEncoding))

    part.headers.add(.contentTransferEncoding, "base64")
    #expect(part.contentTransferEncoding == .base64)

    part.headers.removeAll(.contentTransferEncoding)
    #expect(part.contentTransferEncoding == .default)
}

@Test("MimePart prepare")
func mimePartPrepare() throws {
    let content = MemoryStream([UInt8](repeating: 0, count: 64), writable: false)
    let part = try MimePart("application", "octet-stream")
    part.content = try MimeContent(content)

    let encoding = try part.getBestEncoding(.sevenBit)
    #expect(encoding == .base64)

    try part.prepare(.sevenBit)
    #expect(part.contentTransferEncoding == .base64)

    try part.prepare(.sevenBit)
    #expect(part.contentTransferEncoding == .base64)

    part.contentTransferEncoding = .binary
    try part.prepare(.none)
    #expect(part.contentTransferEncoding == .binary)

    try part.prepare(.sevenBit)
    #expect(part.contentTransferEncoding == .base64)
}

@Test("MimePart transcoding")
func mimePartTranscoding() throws {
    let expected = try TestHelper.loadData(relativePath: "images/girl.jpg")
    var part = try MimePart("image", "jpeg")
    part.content = try MimeContent(MemoryStream(expected, writable: false))
    part.contentTransferEncoding = .base64
    part.fileName = "girl.jpg"

    let output = MemoryStream()
    try part.writeTo(output)
    output.position = 0

    part = try MimeEntity.load(output) as! MimePart

    part.contentTransferEncoding = .uuEncode
    let output2 = MemoryStream()
    try part.writeTo(output2)
    output2.position = 0

    part = try MimeEntity.load(output2) as! MimePart

    let decoded = MemoryStream()
    try part.content?.decodeTo(decoded)
    let actual = decoded.toByteArray()

    #expect(actual.count == expected.count)
    for index in expected.indices {
        #expect(actual[index] == expected[index])
    }
}

@Test("MimePart transcoding async")
func mimePartTranscodingAsync() async throws {
    let expected = try TestHelper.loadData(relativePath: "images/girl.jpg")
    var part = try MimePart("image", "jpeg")
    part.content = try MimeContent(MemoryStream(expected, writable: false))
    part.contentTransferEncoding = .base64
    part.fileName = "girl.jpg"

    let output = MemoryStream()
    try await part.writeToAsync(output)
    output.position = 0

    part = try await MimeEntity.loadAsync(output) as! MimePart

    part.contentTransferEncoding = .uuEncode
    let output2 = MemoryStream()
    try await part.writeToAsync(output2)
    output2.position = 0

    part = try await MimeEntity.loadAsync(output2) as! MimePart

    let decoded = MemoryStream()
    try part.content?.decodeTo(decoded)
    let actual = decoded.toByteArray()

    #expect(actual.count == expected.count)
    for index in expected.indices {
        #expect(actual[index] == expected[index])
    }
}

@Test("MimePart writeTo preserves content")
func mimePartWriteTo() throws {
    let builder = BodyBuilder()
    let bytes = Array("content".utf8)
    _ = try builder.attachments.add(fileName: "filename", stream: MemoryStream(bytes, writable: false))
    builder.textBody = "This is the text body."

    let body = try builder.toMessageBody()
    let stream = MemoryStream()
    var options = FormatOptions.default
    options.newLineFormat = .dos
    try body.writeTo(options, stream)

    stream.position = 0
    let multipart = try MimeEntity.load(stream) as! Multipart
    let part = multipart[1] as! MimePart
    let contentStream = try part.content?.open()
    var buffer = [UInt8](repeating: 0, count: 1024)
    let read = try contentStream?.read(&buffer, offset: 0, count: buffer.count) ?? 0
    let content = String(decoding: buffer[0..<read], as: UTF8.self)
    #expect(content == "content")
}

@Test("MimePart writeTo async preserves content")
func mimePartWriteToAsync() async throws {
    let builder = BodyBuilder()
    let bytes = Array("content".utf8)
    _ = try builder.attachments.add(fileName: "filename", stream: MemoryStream(bytes, writable: false))
    builder.textBody = "This is the text body."

    let body = try builder.toMessageBody()
    let stream = MemoryStream()
    var options = FormatOptions.default
    options.newLineFormat = .dos
    try await body.writeToAsync(options, stream)

    stream.position = 0
    let multipart = try MimeEntity.load(stream) as! Multipart
    let part = multipart[1] as! MimePart
    let contentStream = try part.content?.open()
    var buffer = [UInt8](repeating: 0, count: 1024)
    let read = try contentStream?.read(&buffer, offset: 0, count: buffer.count) ?? 0
    let content = String(decoding: buffer[0..<read], as: UTF8.self)
    #expect(content == "content")
}

@Test("MimePart writeTo file newlines")
func mimePartWriteToFile() throws {
    let fileUrl = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(UUID().uuidString)
    let text = "content\r\n"
    let body = TextPart("plain")
    body.text = text

    var options = FormatOptions.default
    options.newLineFormat = .dos
    try body.writeTo(options, fileUrl.path)
    let data = try Data(contentsOf: fileUrl)
    let textData = String(decoding: data, as: UTF8.self)
    let snippet = String(textData.suffix(text.count))
    #expect(snippet == text)

    options.newLineFormat = .unix
    try body.writeTo(options, fileUrl.path)
    let dataUnix = try Data(contentsOf: fileUrl)
    let textUnix = String(decoding: dataUnix, as: UTF8.self)
    let expected = text.replacingOccurrences(of: "\r\n", with: "\n")
    let snippetUnix = String(textUnix.suffix(expected.count))
    #expect(snippetUnix == expected)
}

@Test("MimePart load http response")
func mimePartLoadHttpResponse() throws {
    let text = "This is some text and stuff.\n"
    let contentType = try ContentType("text", "plain")
    let data = Array(text.utf8)
    let entity = try MimeEntity.load(contentType, MemoryStream(data, writable: false))
    let part = entity as? TextPart
    #expect(part != nil)
    #expect(part?.text == text)
}
