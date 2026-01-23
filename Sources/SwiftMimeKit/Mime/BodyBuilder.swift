//
// BodyBuilder.swift
//
// Ported from MimeKit (C#) to Swift.
//

import Foundation

public enum BodyBuilderError: Error, Equatable {
    case nilEncoding
}

public final class BodyBuilder {
    public private(set) var attachments: AttachmentCollection
    public private(set) var linkedResources: AttachmentCollection

    public var textBody: String?
    public var htmlBody: String?

    private var bodyEncodingStorage: String.Encoding

    public init() {
        self.attachments = AttachmentCollection()
        self.linkedResources = AttachmentCollection(true)
        self.bodyEncodingStorage = .utf8
    }

    public var bodyEncoding: String.Encoding {
        get { bodyEncodingStorage }
        set { bodyEncodingStorage = newValue }
    }

    public func setBodyEncoding(_ value: String.Encoding?) throws {
        guard let value else {
            throw BodyBuilderError.nilEncoding
        }
        bodyEncodingStorage = value
    }

    public func toMessageBody() throws -> MimeEntity {
        var alternative: MultipartAlternative? = nil
        var body: MimeEntity? = nil

        if let textBody {
            let text = TextPart("plain")
            try text.setText(bodyEncodingStorage, textBody)

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
            try text.setText(bodyEncodingStorage, htmlBody)
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
            try text.setText(bodyEncodingStorage, "")
            body = text
        }

        return body!
    }
}
