//
// MessageFeedbackReport.swift
//
// Ported from MimeKit (C#) to Swift.
//

import Foundation

public final class MessageFeedbackReport: MimePart {
    private var fieldsStorage: HeaderList
    private var fieldsLoaded = false

    private static var feedbackReportContentType: ContentType {
        guard let ct = try? ContentType("message", "feedback-report") else {
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
        super.init(Self.feedbackReportContentType)
        configureFields()
        fieldsLoaded = true
        updateContentFromFields()
    }

    public var fields: HeaderList {
        loadFieldsIfNeeded()
        return fieldsStorage
    }

    public override func accept(_ visitor: MimeVisitor) {
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
        let bytes = MessageFeedbackReport.readDecodedBytes(from: content)
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
        content = MimeContent(MemoryStream(bytes, writable: false), encoding: .default)
    }

    private static func readDecodedBytes(from content: MimeContent) -> [UInt8] {
        let memory = MemoryStream()
        _ = try? content.decodeTo(memory)
        return memory.toByteArray()
    }
}
