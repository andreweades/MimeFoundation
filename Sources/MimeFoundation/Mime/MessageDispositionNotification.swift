//
// MessageDispositionNotification.swift
//
// Ported from MimeKit (C#) to Swift.
//

import Foundation

public final class MessageDispositionNotification: MimePart {
    private var fieldsStorage: HeaderList
    private var fieldsLoaded = false

    private static var dispositionNotificationContentType: ContentType {
        guard let ct = try? ContentType("message", "disposition-notification") else {
            preconditionFailure("Invalid static content type - this is a programming error")
        }
        return ct
    }

    public override init(_ contentType: ContentType) {
        self.fieldsStorage = HeaderList()
        super.init(contentType)
        configureFields()
        fieldsLoaded = false
    }

    public init() {
        self.fieldsStorage = HeaderList()
        super.init(Self.dispositionNotificationContentType)
        configureFields()
        fieldsLoaded = true
        updateContentFromFields()
    }

    public var fields: HeaderList {
        loadFieldsIfNeeded()
        return fieldsStorage
    }

    public override func accept(_ visitor: MimeVisitor?) throws {
        guard let visitor else {
            throw MimeEntityError.nilVisitor
        }
        visitor.visit(self)
    }

    private func configureFields() {
        fieldsStorage.changed = { [weak self] _, _ in
            self?.updateContentFromFields()
        }
    }

    private func loadFieldsIfNeeded() {
        guard !fieldsLoaded else { return }
        fieldsLoaded = true

        let headers = HeaderList()
        headers.changed = { [weak self] _, _ in
            self?.updateContentFromFields()
        }
        fieldsStorage = headers

        guard let content else { return }
        let bytes = MessageDispositionNotification.readDecodedBytes(from: content)
        let (parsed, _) = MimeMessage.parseHeaders(bytes)
        for header in parsed {
            fieldsStorage.add(header)
        }
    }

    private func updateContentFromFields() {
        guard fieldsLoaded else { return }
        let options = FormatOptions.default
        var text = fieldsStorage.toString(options, encode: true)
        if !text.isEmpty {
            text.append(options.newLine)
        }
        let bytes = Array(text.utf8)
        content = try? MimeContent(MemoryStream(bytes, writable: false), encoding: .default)
    }

    private static func readDecodedBytes(from content: MimeContent) -> [UInt8] {
        let memory = MemoryStream()
        _ = try? content.decodeTo(memory)
        return memory.toByteArray()
    }
}
