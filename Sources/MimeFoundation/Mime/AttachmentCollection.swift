//
// AttachmentCollection.swift
//
// Ported from MimeKit (C#) to Swift.
//

import Foundation

public enum AttachmentCollectionError: Error, Equatable {
    case nilFileName
    case emptyFileName
    case nilData
    case nilStream
    case nilContentType
    case nilEntity
    case indexOutOfRange
}

public final class AttachmentCollection: RandomAccessCollection, MutableCollection {
    public typealias Element = MimeEntity
    public typealias Index = Int

    private static var octetStreamContentType: ContentType {
        guard let ct = try? ContentType("application", "octet-stream") else {
            preconditionFailure("Invalid static content type - this is a programming error")
        }
        return ct
    }

    private var attachments: [MimeEntity]
    private let linkedResources: Bool
    private let mimeTypes: MimeTypeRegistry

    public init(_ linkedResources: Bool = false, mimeTypes: MimeTypeRegistry = .default) {
        self.attachments = []
        self.linkedResources = linkedResources
        self.mimeTypes = mimeTypes
    }

    public var startIndex: Int { attachments.startIndex }
    public var endIndex: Int { attachments.endIndex }

    public func index(after i: Int) -> Int { attachments.index(after: i) }

    public var count: Int { attachments.count }
    public var isReadOnly: Bool { false }

    public subscript(position: Int) -> MimeEntity {
        get { attachments[position] }
        set { attachments[position] = newValue }
    }

    public func add(_ entity: MimeEntity?) throws -> MimeEntity {
        guard let entity else {
            throw AttachmentCollectionError.nilEntity
        }
        return append(entity)
    }

    public func add(_ fileName: String?) throws -> MimeEntity {
        let fileName = try validateFileName(fileName)
        let contentType = contentType(for: fileName)
        let data = try readFileBytes(fileName)
        let attachment = try createAttachment(contentType: contentType, autoDetected: true, path: fileName, data: data)
        return append(attachment)
    }

    public func add(_ fileName: String?, _ contentType: ContentType?) throws -> MimeEntity {
        let fileName = try validateFileName(fileName)
        guard let contentType else {
            throw AttachmentCollectionError.nilContentType
        }
        let data = try readFileBytes(fileName)
        let attachment = try createAttachment(contentType: contentType, autoDetected: false, path: fileName, data: data)
        return append(attachment)
    }

    public func add(_ fileName: String?, _ data: [UInt8]?) throws -> MimeEntity {
        let fileName = try validateFileName(fileName)
        guard let data else {
            throw AttachmentCollectionError.nilData
        }
        let contentType = contentType(for: fileName)
        let attachment = try createAttachment(contentType: contentType, autoDetected: true, path: fileName, data: data)
        return append(attachment)
    }

    public func add(_ fileName: String?, _ data: [UInt8]?, _ contentType: ContentType?) throws -> MimeEntity {
        let fileName = try validateFileName(fileName)
        guard let data else {
            throw AttachmentCollectionError.nilData
        }
        guard let contentType else {
            throw AttachmentCollectionError.nilContentType
        }
        let attachment = try createAttachment(contentType: contentType, autoDetected: false, path: fileName, data: data)
        return append(attachment)
    }

    public func add(_ fileName: String?, _ stream: MimeStream?) throws -> MimeEntity {
        let fileName = try validateFileName(fileName)
        guard let stream else {
            throw AttachmentCollectionError.nilStream
        }
        let data = try readAllBytes(from: stream)
        let contentType = contentType(for: fileName)
        let attachment = try createAttachment(contentType: contentType, autoDetected: true, path: fileName, data: data)
        return append(attachment)
    }

    public func add(_ fileName: String?, _ stream: MimeStream?, _ contentType: ContentType?) throws -> MimeEntity {
        let fileName = try validateFileName(fileName)
        guard let stream else {
            throw AttachmentCollectionError.nilStream
        }
        guard let contentType else {
            throw AttachmentCollectionError.nilContentType
        }
        let data = try readAllBytes(from: stream)
        let attachment = try createAttachment(contentType: contentType, autoDetected: false, path: fileName, data: data)
        return append(attachment)
    }

    public func addAsync(_ fileName: String?) async throws -> MimeEntity {
        try add(fileName)
    }

    public func addAsync(_ fileName: String?, _ contentType: ContentType?) async throws -> MimeEntity {
        try add(fileName, contentType)
    }

    public func addAsync(_ fileName: String?, _ data: [UInt8]?) async throws -> MimeEntity {
        try add(fileName, data)
    }

    public func addAsync(_ fileName: String?, _ data: [UInt8]?, _ contentType: ContentType?) async throws -> MimeEntity {
        try add(fileName, data, contentType)
    }

    public func addAsync(_ fileName: String?, _ stream: MimeStream?) async throws -> MimeEntity {
        try add(fileName, stream)
    }

    public func addAsync(_ fileName: String?, _ stream: MimeStream?, _ contentType: ContentType?) async throws -> MimeEntity {
        try add(fileName, stream, contentType)
    }

    public func contains(_ entity: MimeEntity?) throws -> Bool {
        guard let entity else {
            throw AttachmentCollectionError.nilEntity
        }
        return attachments.contains(where: { $0 === entity })
    }

    public func indexOf(_ entity: MimeEntity?) throws -> Int {
        guard let entity else {
            throw AttachmentCollectionError.nilEntity
        }
        return attachments.firstIndex(where: { $0 === entity }) ?? -1
    }

    public func remove(_ entity: MimeEntity?) throws -> Bool {
        guard let entity else {
            throw AttachmentCollectionError.nilEntity
        }
        guard let index = attachments.firstIndex(where: { $0 === entity }) else {
            return false
        }
        attachments.remove(at: index)
        return true
    }

    public func remove(at index: Int) throws {
        guard index >= 0 && index < attachments.count else {
            throw AttachmentCollectionError.indexOutOfRange
        }
        attachments.remove(at: index)
    }

    public func insert(_ entity: MimeEntity?, at index: Int) throws {
        guard let entity else {
            throw AttachmentCollectionError.nilEntity
        }
        guard index >= 0 && index <= attachments.count else {
            throw AttachmentCollectionError.indexOutOfRange
        }
        attachments.insert(entity, at: index)
    }

    public func copyTo(_ array: inout [MimeEntity]?, at index: Int) throws {
        guard array != nil else {
            throw AttachmentCollectionError.nilEntity
        }
        guard index >= 0 && index <= (array?.count ?? 0) else {
            throw AttachmentCollectionError.indexOutOfRange
        }
        array!.insert(contentsOf: attachments, at: index)
    }

    public func clear(_ dispose: Bool = false) {
        attachments.removeAll(keepingCapacity: true)
        _ = dispose
    }

    private func append(_ attachment: MimeEntity) -> MimeEntity {
        attachments.append(attachment)
        return attachment
    }

    private func validateFileName(_ fileName: String?) throws -> String {
        guard let fileName else {
            throw AttachmentCollectionError.nilFileName
        }
        guard !fileName.isEmpty else {
            throw AttachmentCollectionError.emptyFileName
        }
        return fileName
    }

    private func readFileBytes(_ fileName: String) throws -> [UInt8] {
        let url = URL(fileURLWithPath: fileName)
        let data = try Data(contentsOf: url)
        return Array(data)
    }

    private func readAllBytes(from stream: MimeStream) throws -> [UInt8] {
        var buffer = [UInt8](repeating: 0, count: 4096)
        var data: [UInt8] = []
        _ = try? stream.seek(0, origin: .begin)
        while true {
            let read = try stream.read(&buffer, offset: 0, count: buffer.count)
            if read == 0 {
                break
            }
            data.append(contentsOf: buffer[0..<read])
        }
        return data
    }

    private func createAttachment(contentType: ContentType, autoDetected: Bool, path: String, data: [UInt8]) throws -> MimeEntity {
        let fileName = fileNameFromPath(path)
        var attachment: MimeEntity? = nil

        if (try? contentType.isMimeType("message", "rfc822")) == true {
            if autoDetected, !looksLikeMessage(data) {
                let fallback = try ContentType("application", "octet-stream")
                attachment = try createStreamAttachment(contentType: fallback, data: data)
            } else {
                do {
                    let message = try MimeMessage.load(MemoryStream(data, writable: false))
                    if message.headers.count == 0 {
                        throw AttachmentCollectionError.nilEntity
                    }
                    let part = MessagePart()
                    part.message = message
                    attachment = part
                } catch {
                    if autoDetected {
                        let fallback = try ContentType("application", "octet-stream")
                        attachment = try createStreamAttachment(contentType: fallback, data: data)
                    } else {
                        throw error
                    }
                }
            }
        }

        if attachment == nil {
            attachment = try createStreamAttachment(contentType: contentType, data: data)
        }

        if let attachment {
            let disposition = try ContentDisposition(linkedResources ? ContentDisposition.inline : ContentDisposition.attachment)
            disposition.fileName = fileName
            attachment.contentDisposition = disposition
            attachment.contentType.name = fileName
            if linkedResources {
                attachment.contentLocation = URL(string: fileName)
            }
            return attachment
        }

        throw AttachmentCollectionError.nilEntity
    }

    private func createStreamAttachment(contentType: ContentType, data: [UInt8]) throws -> MimeEntity {
        let isText = (try? contentType.isMimeType("text", "*")) == true
        let part: MimePart
        if isText {
            part = TextPart(contentType)
            part.contentTransferEncoding = .sevenBit
        } else {
            part = MimePart(contentType)
            part.contentTransferEncoding = .base64
        }
        part.content = try MimeContent(MemoryStream(data, writable: false))
        return part
    }

    private func fileNameFromPath(_ path: String) -> String {
        let url = URL(fileURLWithPath: path)
        return url.lastPathComponent
    }

    private func contentType(for path: String) -> ContentType {
        let mimeType = mimeTypes.mimeType(for: path)
        if let slashIndex = mimeType.firstIndex(of: "/") {
            let type = String(mimeType[..<slashIndex])
            let subtype = String(mimeType[mimeType.index(after: slashIndex)...])
            if let contentType = try? ContentType(type, subtype) {
                return contentType
            }
        }
        return Self.octetStreamContentType
    }

    private func looksLikeMessage(_ data: [UInt8]) -> Bool {
        if data.isEmpty {
            return false
        }
        var line: [UInt8] = []
        for byte in data {
            if byte == 0x0A || byte == 0x0D {
                break
            }
            line.append(byte)
            if line.count > 200 {
                break
            }
        }
        guard let colonIndex = line.firstIndex(of: UInt8(ascii: ":")) else {
            return false
        }
        if colonIndex == 0 {
            return false
        }
        for byte in line[0..<colonIndex] {
            if !isFieldText(byte) {
                return false
            }
        }
        return true
    }

    private func isFieldText(_ byte: UInt8) -> Bool {
        if byte == UInt8(ascii: ":") {
            return false
        }
        if byte < 0x21 || byte > 0x7E {
            return false
        }
        return true
    }
}
