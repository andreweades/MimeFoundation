//
// HeaderId.swift
//
// Ported from MimeKit (C#) to Swift.
//

import Foundation

public enum HeaderId: Int, Sendable, CaseIterable {
    case unknown
    case adHoc
    case bcc
    case cc
    case from
    case to
    case replyTo
    case sender
    case resentBcc
    case resentCc
    case resentFrom
    case resentTo
    case resentReplyTo
    case resentSender
    case resentDate
    case resentMessageId
    case originalMessageId
    case date
    case subject
    case messageId
    case inReplyTo
    case references
    case mimeVersion
    case contentType
    case contentDisposition
    case contentTransferEncoding
    case contentDescription
    case contentId
    case contentBase
    case contentLanguage
    case contentLocation
    case contentMd5
    case contentLength
    case contentDuration
    case importance
    case priority
    case xPriority
    case sensitivity
    case returnPath
    case received
    case comments
    case dispositionNotificationTo
    case dispositionNotificationOptions
    case arcAuthenticationResults
    case authenticationResults
    case arcMessageSignature
    case arcSeal
    case dkimSignature
}

public extension HeaderId {
    var headerName: String {
        switch self {
        case .unknown:
            return ""
        case .adHoc:
            return "Ad-Hoc"
        case .bcc:
            return "Bcc"
        case .cc:
            return "Cc"
        case .from:
            return "From"
        case .to:
            return "To"
        case .replyTo:
            return "Reply-To"
        case .sender:
            return "Sender"
        case .resentBcc:
            return "Resent-Bcc"
        case .resentCc:
            return "Resent-Cc"
        case .resentFrom:
            return "Resent-From"
        case .resentTo:
            return "Resent-To"
        case .resentReplyTo:
            return "Resent-Reply-To"
        case .resentSender:
            return "Resent-Sender"
        case .resentDate:
            return "Resent-Date"
        case .resentMessageId:
            return "Resent-Message-Id"
        case .originalMessageId:
            return "Original-Message-Id"
        case .date:
            return "Date"
        case .subject:
            return "Subject"
        case .messageId:
            return "Message-Id"
        case .inReplyTo:
            return "In-Reply-To"
        case .references:
            return "References"
        case .mimeVersion:
            return "MIME-Version"
        case .contentType:
            return "Content-Type"
        case .contentDisposition:
            return "Content-Disposition"
        case .contentTransferEncoding:
            return "Content-Transfer-Encoding"
        case .contentDescription:
            return "Content-Description"
        case .contentId:
            return "Content-Id"
        case .contentBase:
            return "Content-Base"
        case .contentLanguage:
            return "Content-Language"
        case .contentLocation:
            return "Content-Location"
        case .contentMd5:
            return "Content-Md5"
        case .contentLength:
            return "Content-Length"
        case .contentDuration:
            return "Content-Duration"
        case .importance:
            return "Importance"
        case .priority:
            return "Priority"
        case .xPriority:
            return "X-Priority"
        case .sensitivity:
            return "Sensitivity"
        case .returnPath:
            return "Return-Path"
        case .received:
            return "Received"
        case .comments:
            return "Comments"
        case .dispositionNotificationTo:
            return "Disposition-Notification-To"
        case .dispositionNotificationOptions:
            return "Disposition-Notification-Options"
        case .arcAuthenticationResults:
            return "ARC-Authentication-Results"
        case .authenticationResults:
            return "Authentication-Results"
        case .arcMessageSignature:
            return "ARC-Message-Signature"
        case .arcSeal:
            return "ARC-Seal"
        case .dkimSignature:
            return "DKIM-Signature"
        }
    }

    static func from(field: String) -> HeaderId {
        let key = field.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        return HeaderIdMappings.byName[key] ?? .unknown
    }
}

private enum HeaderIdMappings {
    static let byName: [String: HeaderId] = {
        var mapping: [String: HeaderId] = [:]
        for id in HeaderId.allCases where id != .unknown {
            mapping[id.headerName.lowercased()] = id
        }
        return mapping
    }()
}
