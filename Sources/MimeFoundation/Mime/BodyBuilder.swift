//
// BodyBuilder.swift
//
// Ported from MimeKit (C#) to Swift.
//

import Foundation

public final class BodyBuilder {
    public private(set) var attachments: AttachmentCollection
    public private(set) var linkedResources: AttachmentCollection
    public let mimeTypes: MimeTypeRegistry

    public var textBody: String?
    public var htmlBody: String?

    private var bodyEncodingStorage: String.Encoding

    public init(mimeTypes: MimeTypeRegistry = .default) {
        self.mimeTypes = mimeTypes
        self.attachments = AttachmentCollection(false, mimeTypes: mimeTypes)
        self.linkedResources = AttachmentCollection(true, mimeTypes: mimeTypes)
        self.bodyEncodingStorage = .utf8
    }

    public var bodyEncoding: String.Encoding {
        get { bodyEncodingStorage }
        set { bodyEncodingStorage = newValue }
    }

    public func toMessageBody() throws -> MimeEntity {
        var alternative: MultipartAlternative? = nil
        var body: MimeEntity? = nil

        if let textBody {
            let text = TextPart("plain")
            text.setText(bodyEncodingStorage, textBody)

            if htmlBody != nil {
                let alt = MultipartAlternative()
                try alt.add(text)
                alternative = alt
                body = alt
            } else {
                body = text
            }
        }

        if let htmlBody {
            let text = TextPart("html")
            text.setText(bodyEncodingStorage, htmlBody)
            let htmlPart: MimeEntity

            if linkedResources.count > 0 {
                let related = MultipartRelated()
                try related.setRoot(text)
                for resource in linkedResources {
                    try related.add(resource)
                }
                htmlPart = related
            } else {
                htmlPart = text
            }

            if let alternative {
                try alternative.add(htmlPart)
            } else {
                body = htmlPart
            }
        }

        if attachments.count > 0 {
            if body == nil && attachments.count == 1 {
                return attachments[0]
            }

            let mixed = try Multipart("mixed")
            if let body {
                try mixed.add(body)
            }
            for attachment in attachments {
                try mixed.add(attachment)
            }
            body = mixed
        }

        if body == nil {
            let text = TextPart("plain")
            text.setText(bodyEncodingStorage, "")
            body = text
        }

        return body!
    }
}
