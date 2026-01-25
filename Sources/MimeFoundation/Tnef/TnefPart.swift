//
// TnefPart.swift
//
// Ported from MimeKit (C#) to Swift.
//

import Foundation

/// A MIME part containing Microsoft TNEF data.
open class TnefPart: MimePart {
    /// Initialize a new instance of the `TnefPart` class.
    public init() {
        let contentType = try! ContentType("application", "vnd.ms-tnef")
        super.init(contentType)
        fileName = "winmail.dat"
    }

    public override init(_ contentType: ContentType) {
        super.init(contentType)
    }

    public override func accept(_ visitor: MimeVisitor) {
        visitor.visit(self)
    }

    /// Convert the TNEF content into a `MimeMessage`.
    public func convertToMessage() throws -> MimeMessage {
        guard let content = content else {
            throw StreamError.notSupported // Cannot parse null TNEF data
        }

        var codepage = 0
        if let charset = contentType.charset, !charset.isEmpty {
            codepage = CharsetUtils.getCodePage(charset)
            if codepage == -1 { codepage = 0 }
        }

        let reader = TnefReader(inputStream: try content.open(), defaultMessageCodepage: codepage, complianceMode: .loose)
        
        return try TnefPart.extractTnefMessage(reader)
    }

    private static func extractTnefMessage(_ reader: TnefReader) throws -> MimeMessage {
        let message = MimeMessage()
        let alternatives = MultipartAlternative()
        var body: MimeEntity? = nil

        while try reader.readNextAttribute() {
            if reader.attributeLevel == .attachment {
                break
            }

            let prop = reader.tnefPropertyReader!

            switch reader.attributeTag {
            case .recipientTable:
                try extractRecipientTable(reader, message)
            case .mapiProperties:
                try extractMapiProperties(reader, message, alternatives)
            case .dateSent:
                message.date = try prop.readValueAsDateTime()
            case .body:
                let text = try prop.readValueAsString()
                body = TextPart("plain", text)
            default:
                break
            }
        }

        if let b = body {
            if alternatives.count > 0 {
                try alternatives.add(b)
                body = alternatives
            }
        } else if alternatives.count > 0 {
            if alternatives.count == 1 {
                body = alternatives[0]
            } else {
                body = alternatives
            }
        }

        if reader.attributeLevel == .attachment {
            let attachments = try Multipart("mixed")
            if let b = body {
                try attachments.add(b)
            }
            message.body = attachments
            try extractAttachments(reader, attachments)
        } else {
            message.body = body
        }

        return message
    }

    private static func extractRecipientTable(_ reader: TnefReader, _ message: MimeMessage) throws {
        let prop = reader.tnefPropertyReader!

        while try prop.readNextRow() {
            var transmitableDisplayName: String? = nil
            var recipientDisplayName: String? = nil
            var displayName: String = ""
            var list: InternetAddressList? = nil
            var addr: String? = nil

            while try prop.readNextProperty() {
                switch prop.propertyTag.id {
                case .recipientType:
                    let recipientType = try prop.readValueAsInt32()
                    switch recipientType {
                    case 1: list = message.to
                    case 2: list = message.cc
                    case 3: list = message.bcc
                    default: break
                    }
                case .transmitableDisplayName:
                    transmitableDisplayName = try prop.readValueAsString()
                case .recipientDisplayName:
                    recipientDisplayName = try prop.readValueAsString()
                case .displayName:
                    displayName = try prop.readValueAsString()
                case .emailAddress:
                    if addr == nil || addr!.isEmpty {
                        addr = try prop.readValueAsString()
                    }
                case .smtpAddress:
                    addr = try prop.readValueAsString()
                default:
                    break
                }
            }

            if let list = list, let addr = addr, !addr.isEmpty {
                let name = recipientDisplayName ?? transmitableDisplayName ?? displayName
                list.add(MailboxAddress(name: name, address: addr))
            }
        }
    }

    private class TnefEmailAddress {
        var addrType = "SMTP"
        var searchKey: String?
        var name: String?
        var addr: String?

        func tryGetMailboxAddress() -> MailboxAddress? {
            var address = addr
            if (address == nil || address!.isEmpty), let key = searchKey, key.lowercased().hasPrefix("smtp:") {
                address = String(key.dropFirst(5))
            }
            
            guard let address = address, !address.isEmpty else { return nil }
            
            return MailboxAddress(name: name ?? "", address: address)
        }
    }

    private static func extractMapiProperties(_ reader: TnefReader, _ message: MimeMessage, _ alternatives: MultipartAlternative) throws {
        let prop = reader.tnefPropertyReader!
        let sender = TnefEmailAddress()
        let recipient = TnefEmailAddress()
        var normalizedSubject: String? = nil
        var subjectPrefix: String? = nil

        while try prop.readNextProperty() {
            switch prop.propertyTag.id {
            case .internetMessageId:
                message.messageId = try prop.readValueAsString()
            case .subject:
                message.subject = try prop.readValueAsString()
            case .subjectPrefix:
                subjectPrefix = try prop.readValueAsString()
            case .normalizedSubject:
                normalizedSubject = try prop.readValueAsString()
            case .senderName:
                sender.name = try prop.readValueAsString()
            case .senderEmailAddress:
                sender.addr = try prop.readValueAsString()
            case .senderSearchKey:
                sender.searchKey = try prop.readValueAsString()
            case .receivedByName:
                recipient.name = try prop.readValueAsString()
            case .receivedByEmailAddress:
                recipient.addr = try prop.readValueAsString()
            case .receivedBySearchKey:
                recipient.searchKey = try prop.readValueAsString()
            case .rtfCompressed:
                let converter = RtfCompressedToRtf()
                let content = MemoryBlockStream()
                let filtered = try FilteredStream(content)
                try filtered.add(converter)
                let compressed = prop.getRawValueReadStream()
                var buffer = [UInt8](repeating: 0, count: 4096)
                while true {
                    let n = try compressed.read(&buffer, offset: 0, count: buffer.count)
                    if n <= 0 { break }
                    try filtered.write(buffer, offset: 0, count: n)
                }
                try filtered.flush()
                content.position = 0
                let rtf = TextPart("rtf")
                rtf.content = MimeContent(content)
                try alternatives.add(rtf)
            case .bodyHtml:
                let html = TextPart("html")
                html.text = try prop.readValueAsString()
                try alternatives.add(html)
            case .body:
                let plain = TextPart("plain")
                plain.text = try prop.readValueAsString()
                try alternatives.add(plain)
            case .importance:
                let val = try prop.readValueAsInt32()
                switch val {
                case 2: message.importance = .high
                case 1: message.importance = .normal
                case 0: message.importance = .low
                default: break
                }
            case .priority:
                let val = try prop.readValueAsInt32()
                switch val {
                case 1: message.priority = .urgent
                case 0: message.priority = .normal
                case -1: message.priority = .nonUrgent
                default: break
                }
            default:
                break
            }
        }

        if (message.subject == nil || message.subject!.isEmpty), let normalized = normalizedSubject {
            if let prefix = subjectPrefix {
                message.subject = prefix + normalized
            } else {
                message.subject = normalized
            }
        }

        if let mailbox = sender.tryGetMailboxAddress() {
            message.from.add(mailbox)
        }
        if let mailbox = recipient.tryGetMailboxAddress() {
            message.to.add(mailbox)
        }
    }

    private static func extractAttachments(_ reader: TnefReader, _ attachments: Multipart) throws {
        var attachMethod: TnefAttachMethod = .byValue
        let prop = reader.tnefPropertyReader!
        var attachment: MimePart? = nil

        repeat {
            if reader.attributeLevel != .attachment {
                break
            }

            switch reader.attributeTag {
            case .attachRenderData:
                attachMethod = .byValue
                attachment = MimePart()
            case .attachment:
                guard let part = attachment else { break }
                var attachData: [UInt8]? = nil

                while try prop.readNextProperty() {
                    switch prop.propertyTag.id {
                    case .attachLongFilename:
                        part.fileName = try prop.readValueAsString()
                    case .attachFilename:
                        if part.fileName == nil {
                            part.fileName = try prop.readValueAsString()
                        }
                    case .attachData:
                        attachData = try prop.readValueAsBytes()
                    case .attachMethod:
                        attachMethod = TnefAttachMethod(rawValue: Int(try prop.readValueAsInt32())) ?? .byValue
                    default:
                        break
                    }
                }

                if let data = attachData {
                    if attachMethod == .embeddedMessage {
                        // Handle embedded TNEF message
                        let tnef = TnefPart()
                        tnef.content = MimeContent(MemoryStream(Array(data.dropFirst(16)), writable: false))
                        try attachments.add(tnef)
                    } else {
                        part.content = MimeContent(MemoryStream(data, writable: false))
                        try attachments.add(part)
                    }
                }
            default:
                break
            }
        } while try reader.readNextAttribute()
    }
}
