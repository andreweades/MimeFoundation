//
// AttachmentCollectionTests.swift
//

import Foundation
import Testing
@testable import MimeFoundation

private func didThrowAsync<T>(_ operation: @escaping () async throws -> T) async -> Bool {
    do {
        _ = try await operation()
        return false
    } catch {
        return true
    }
}

@Test("AttachmentCollection argument exceptions")
func attachmentCollectionArgumentExceptions() throws {
    let contentType = try ContentType("application", "octet-stream")
    let attachments = AttachmentCollection()
    var items: [MimeEntity]? = []
    let data = [UInt8](repeating: 0, count: 1024)
    let stream = MemoryStream()

    #expect(attachments.isReadOnly == false)

    #expect(throws: (any Error).self) { _ = try attachments.add("") }
    #expect(throws: (any Error).self) { _ = try attachments.add(nil as String?) }
    #expect(throws: (any Error).self) { _ = try attachments.add(nil as MimeEntity?) }
    #expect(throws: (any Error).self) { _ = try attachments.add("", data) }
    #expect(throws: (any Error).self) { _ = try attachments.add(nil as String?, data) }
    #expect(throws: (any Error).self) { _ = try attachments.add("", stream) }
    #expect(throws: (any Error).self) { _ = try attachments.add(nil as String?, stream) }
    #expect(throws: (any Error).self) { _ = try attachments.add("", contentType) }
    #expect(throws: (any Error).self) { _ = try attachments.add(nil as String?, contentType) }
    #expect(throws: (any Error).self) { _ = try attachments.add("", data, contentType) }
    #expect(throws: (any Error).self) { _ = try attachments.add(nil as String?, data, contentType) }
    #expect(throws: (any Error).self) { _ = try attachments.add("", stream, contentType) }
    #expect(throws: (any Error).self) { _ = try attachments.add(nil as String?, stream, contentType) }

    #expect(throws: (any Error).self) { _ = try attachments.add("file.dat", nil as [UInt8]?) }
    #expect(throws: (any Error).self) { _ = try attachments.add("file.dat", nil as MimeStream?) }
    #expect(throws: (any Error).self) { _ = try attachments.add("file.dat", nil as [UInt8]?, contentType) }
    #expect(throws: (any Error).self) { _ = try attachments.add("file.dat", nil as MimeStream?, contentType) }

    #expect(throws: (any Error).self) { _ = try attachments.add("file.dat", nil as ContentType?) }
    #expect(throws: (any Error).self) { _ = try attachments.add("file.dat", data, nil) }
    #expect(throws: (any Error).self) { _ = try attachments.add("file.dat", stream, nil) }

    #expect(throws: (any Error).self) { _ = try attachments.contains(nil) }
    #expect(throws: (any Error).self) { _ = try attachments.copyTo(&items, at: -1) }
    items = nil
    #expect(throws: (any Error).self) { _ = try attachments.copyTo(&items, at: 0) }

    #expect(throws: (any Error).self) { _ = try attachments.indexOf(nil) }
    #expect(throws: (any Error).self) { _ = try attachments.remove(nil) }
    #expect(throws: (any Error).self) { try attachments.remove(at: 0) }

    _ = try attachments.add(TextPart("plain"))
    #expect(throws: (any Error).self) { try attachments.insert(nil, at: 0) }
    #expect(throws: (any Error).self) { try attachments.insert(TextPart("plain"), at: -1) }
}

@Test("AttachmentCollection argument exceptions async")
func attachmentCollectionArgumentExceptionsAsync() async throws {
    let contentType = try ContentType("application", "octet-stream")
    let attachments = AttachmentCollection()
    let stream = MemoryStream()

    #expect(await didThrowAsync { try await attachments.addAsync("") })
    #expect(await didThrowAsync { try await attachments.addAsync(nil as String?) })
    #expect(await didThrowAsync { try await attachments.addAsync("", stream) })
    #expect(await didThrowAsync { try await attachments.addAsync(nil as String?, stream) })
    #expect(await didThrowAsync { try await attachments.addAsync("", contentType) })
    #expect(await didThrowAsync { try await attachments.addAsync(nil as String?, contentType) })
    #expect(await didThrowAsync { try await attachments.addAsync("", stream, contentType) })
    #expect(await didThrowAsync { try await attachments.addAsync(nil as String?, stream, contentType) })

    #expect(await didThrowAsync { try await attachments.addAsync("file.dat", nil as MimeStream?) })
    #expect(await didThrowAsync { try await attachments.addAsync("file.dat", nil as MimeStream?, contentType) })
    #expect(await didThrowAsync { try await attachments.addAsync("file.dat", nil as ContentType?) })
    #expect(await didThrowAsync { try await attachments.addAsync("file.dat", stream, nil) })
}

@Test("AttachmentCollection clear")
func attachmentCollectionClear() throws {
    let fileURL = TestHelper.dataURL(for: "images/girl.jpg")
    let attachments = AttachmentCollection()

    _ = try attachments.add(fileURL.path)
    attachments.clear()
    #expect(attachments.count == 0)

    _ = try attachments.add(fileURL.path)
    attachments.clear(true)
    #expect(attachments.count == 0)
}

@Test("AttachmentCollection add file name")
func attachmentCollectionAddFileName() throws {
    let fileURL = TestHelper.dataURL(for: "images/girl.jpg")
    let attachments = AttachmentCollection()

    let attachment = try attachments.add(fileURL.path)
    let part = attachment as? MimePart
    #expect(part != nil)
    #expect(part?.contentType.mimeType == "image/jpeg")
    #expect(part?.contentType.name == "girl.jpg")
    #expect(part?.contentDisposition?.disposition == ContentDisposition.attachment)
    #expect(part?.contentDisposition?.fileName == "girl.jpg")
    #expect(part?.fileName == "girl.jpg")
    #expect(part?.contentTransferEncoding == .base64)
    #expect(attachments.count == 1)

    #expect(try attachments.contains(attachment))
    #expect(try attachments.indexOf(attachment) == 0)
    #expect(try attachments.remove(attachment))
    #expect(attachments.count == 0)
    attachments.clear(true)
}

@Test("AttachmentCollection add file name async")
func attachmentCollectionAddFileNameAsync() async throws {
    let fileURL = TestHelper.dataURL(for: "images/girl.jpg")
    let attachments = AttachmentCollection()

    let attachment = try await attachments.addAsync(fileURL.path)
    let part = attachment as? MimePart
    #expect(part != nil)
    #expect(part?.contentType.mimeType == "image/jpeg")
    #expect(part?.contentType.name == "girl.jpg")
    #expect(part?.contentDisposition?.disposition == ContentDisposition.attachment)
    #expect(part?.contentDisposition?.fileName == "girl.jpg")
    #expect(part?.fileName == "girl.jpg")
    #expect(part?.contentTransferEncoding == .base64)
    #expect(attachments.count == 1)
}

@Test("AttachmentCollection add inline file name")
func attachmentCollectionAddInlineFileName() throws {
    let fileURL = TestHelper.dataURL(for: "images/girl.jpg")
    let attachments = AttachmentCollection(true)

    let attachment = try attachments.add(fileURL.path)
    let part = attachment as? MimePart
    #expect(part != nil)
    #expect(part?.contentType.mimeType == "image/jpeg")
    #expect(part?.contentType.name == "girl.jpg")
    #expect(part?.contentDisposition?.disposition == ContentDisposition.inline)
    #expect(part?.contentDisposition?.fileName == "girl.jpg")
    #expect(part?.fileName == "girl.jpg")
    #expect(part?.contentTransferEncoding == .base64)
    #expect(attachments.count == 1)
}

@Test("AttachmentCollection add inline file name async")
func attachmentCollectionAddInlineFileNameAsync() async throws {
    let fileURL = TestHelper.dataURL(for: "images/girl.jpg")
    let attachments = AttachmentCollection(true)

    let attachment = try await attachments.addAsync(fileURL.path)
    let part = attachment as? MimePart
    #expect(part != nil)
    #expect(part?.contentType.mimeType == "image/jpeg")
    #expect(part?.contentType.name == "girl.jpg")
    #expect(part?.contentDisposition?.disposition == ContentDisposition.inline)
    #expect(part?.contentDisposition?.fileName == "girl.jpg")
    #expect(part?.fileName == "girl.jpg")
    #expect(part?.contentTransferEncoding == .base64)
    #expect(attachments.count == 1)
}

@Test("AttachmentCollection add file name with content type")
func attachmentCollectionAddFileNameContentType() throws {
    let fileURL = TestHelper.dataURL(for: "images/girl.jpg")
    let contentType = try ContentType("image", "gif")
    let attachments = AttachmentCollection()

    let attachment = try attachments.add(fileURL.path, contentType)
    let part = attachment as? MimePart
    #expect(part?.contentType.mimeType == contentType.mimeType)
    #expect(part?.contentType.name == "girl.jpg")
    #expect(part?.contentDisposition?.disposition == ContentDisposition.attachment)
    #expect(part?.contentDisposition?.fileName == "girl.jpg")
    #expect(part?.fileName == "girl.jpg")
    #expect(part?.contentTransferEncoding == .base64)
}

@Test("AttachmentCollection add data")
func attachmentCollectionAddData() throws {
    let fileURL = TestHelper.dataURL(for: "images/girl.jpg")
    let data = try TestHelper.loadData(relativePath: "images/girl.jpg")
    let attachments = AttachmentCollection()

    let attachment = try attachments.add(fileURL.path, data)
    let part = attachment as? MimePart
    #expect(part?.contentType.mimeType == "image/jpeg")
    #expect(part?.contentType.name == "girl.jpg")
    #expect(part?.contentDisposition?.disposition == ContentDisposition.attachment)
    #expect(part?.contentDisposition?.fileName == "girl.jpg")
    #expect(part?.fileName == "girl.jpg")
    #expect(part?.contentTransferEncoding == .base64)
}

@Test("AttachmentCollection add data with content type")
func attachmentCollectionAddDataContentType() throws {
    let fileURL = TestHelper.dataURL(for: "images/girl.jpg")
    let data = try TestHelper.loadData(relativePath: "images/girl.jpg")
    let contentType = try ContentType("image", "gif")
    let attachments = AttachmentCollection()

    let attachment = try attachments.add(fileURL.path, data, contentType)
    let part = attachment as? MimePart
    #expect(part?.contentType.mimeType == contentType.mimeType)
    #expect(part?.contentType.name == "girl.jpg")
    #expect(part?.contentDisposition?.disposition == ContentDisposition.attachment)
    #expect(part?.contentDisposition?.fileName == "girl.jpg")
    #expect(part?.fileName == "girl.jpg")
    #expect(part?.contentTransferEncoding == .base64)
}

@Test("AttachmentCollection add stream")
func attachmentCollectionAddStream() throws {
    let fileURL = TestHelper.dataURL(for: "images/girl.jpg")
    let data = try TestHelper.loadData(relativePath: "images/girl.jpg")
    let stream = MemoryStream(data, writable: false)
    let attachments = AttachmentCollection()

    let attachment = try attachments.add(fileURL.path, stream)
    let part = attachment as? MimePart
    #expect(part?.contentType.mimeType == "image/jpeg")
    #expect(part?.contentType.name == "girl.jpg")
    #expect(part?.contentDisposition?.disposition == ContentDisposition.attachment)
    #expect(part?.contentDisposition?.fileName == "girl.jpg")
    #expect(part?.fileName == "girl.jpg")
    #expect(part?.contentTransferEncoding == .base64)
}

@Test("AttachmentCollection add stream with content type")
func attachmentCollectionAddStreamContentType() throws {
    let fileURL = TestHelper.dataURL(for: "images/girl.jpg")
    let data = try TestHelper.loadData(relativePath: "images/girl.jpg")
    let stream = MemoryStream(data, writable: false)
    let contentType = try ContentType("image", "gif")
    let attachments = AttachmentCollection()

    let attachment = try attachments.add(fileURL.path, stream, contentType)
    let part = attachment as? MimePart
    #expect(part?.contentType.mimeType == contentType.mimeType)
    #expect(part?.contentType.name == "girl.jpg")
    #expect(part?.contentDisposition?.disposition == ContentDisposition.attachment)
    #expect(part?.contentDisposition?.fileName == "girl.jpg")
    #expect(part?.fileName == "girl.jpg")
    #expect(part?.contentTransferEncoding == .base64)
}

@Test("AttachmentCollection add text file name")
func attachmentCollectionAddTextFileName() throws {
    let fileURL = TestHelper.dataURL(for: "text/lorem-ipsum.txt")
    let attachments = AttachmentCollection()

    let attachment = try attachments.add(fileURL.path)
    let part = attachment as? MimePart
    #expect(part?.contentType.mimeType == "text/plain")
    #expect(part?.contentType.name == "lorem-ipsum.txt")
    #expect(part?.contentDisposition?.disposition == ContentDisposition.attachment)
    #expect(part?.contentDisposition?.fileName == "lorem-ipsum.txt")
    #expect(part?.fileName == "lorem-ipsum.txt")
    #expect(part?.contentTransferEncoding == .sevenBit)
}

@Test("AttachmentCollection add email message")
func attachmentCollectionAddEmailMessage() throws {
    let data = try TestHelper.loadData(relativePath: "messages/body.1.txt")
    let stream = MemoryStream(data, writable: false)
    let attachments = AttachmentCollection()

    let attachment = try attachments.add("message.eml", stream)
    #expect(attachment.contentType.mimeType == "message/rfc822")
    #expect(attachment.contentType.name == "message.eml")
    #expect(attachment.contentDisposition?.disposition == ContentDisposition.attachment)
    #expect(attachment.contentDisposition?.fileName == "message.eml")
    #expect(attachments.count == 1)
}

@Test("AttachmentCollection add email message fallback")
func attachmentCollectionAddEmailMessageFallback() throws {
    let data = try TestHelper.loadData(relativePath: "images/girl.jpg")
    let stream = MemoryStream(data, writable: false)
    let attachments = AttachmentCollection()

    let attachment = try attachments.add("message.eml", stream)
    #expect(attachment.contentType.mimeType == "application/octet-stream")
    #expect(attachment.contentType.name == "message.eml")
    #expect(attachment.contentDisposition?.disposition == ContentDisposition.attachment)
    #expect(attachment.contentDisposition?.fileName == "message.eml")
    #expect(attachments.count == 1)
}

@Test("AttachmentCollection add inline email message")
func attachmentCollectionAddInlineEmailMessage() throws {
    let data = try TestHelper.loadData(relativePath: "messages/body.1.txt")
    let stream = MemoryStream(data, writable: false)
    let attachments = AttachmentCollection(true)

    let attachment = try attachments.add("message.eml", stream)
    #expect(attachment.contentType.mimeType == "message/rfc822")
    #expect(attachment.contentType.name == "message.eml")
    #expect(attachment.contentDisposition?.disposition == ContentDisposition.inline)
    #expect(attachment.contentDisposition?.fileName == "message.eml")
}

@Test("AttachmentCollection list methods")
func attachmentCollectionListMethods() throws {
    let attachments = AttachmentCollection()

    let plainURL = TestHelper.dataURL(for: "text/lorem-ipsum.txt")
    let plain = try attachments.add(plainURL.path)

    let jpegURL = TestHelper.dataURL(for: "images/girl.jpg")
    let jpeg = try attachments.add(jpegURL.path)

    var copied: [MimeEntity]? = []
    try attachments.copyTo(&copied, at: 0)
    #expect(copied?[0] === plain)
    #expect(copied?[1] === jpeg)

    try attachments.remove(at: 0)
    #expect(attachments.count == 1)
    #expect(attachments[0] === jpeg)

    attachments[0] = plain
    #expect(attachments.count == 1)
    #expect(attachments[0] === plain)

    try attachments.insert(jpeg, at: 0)
    #expect(attachments.count == 2)
    #expect(attachments[0] === jpeg)
    #expect(attachments[1] === plain)

    var collected: [MimeEntity] = []
    for attachment in attachments {
        collected.append(attachment)
    }
    #expect(collected[0] === jpeg)
    #expect(collected[1] === plain)
}
