//
// SecureMimeType.swift
//
// S/MIME type enumeration for identifying cryptographic content types.
//

import Foundation

/// Represents the type of S/MIME content.
public enum SecureMimeType: String, Sendable, Equatable, Hashable {
    /// Unknown or unrecognized S/MIME type.
    case unknown = "unknown"

    /// Compressed data (RFC 3274).
    case compressedData = "compressed-data"

    /// Enveloped (encrypted) data (RFC 5652).
    case envelopedData = "enveloped-data"

    /// Signed data (RFC 5652).
    case signedData = "signed-data"

    /// Certificate-only message (RFC 5652).
    case certsOnly = "certs-only"

    /// Authenticated enveloped data (RFC 5083).
    case authEnvelopedData = "authEnveloped-data"

    /// Initializes from the smime-type parameter value.
    /// - Parameter smimeType: The smime-type parameter string.
    public init(smimeType: String?) {
        guard let smimeType = smimeType?.lowercased().trimmingCharacters(in: .whitespaces) else {
            self = .unknown
            return
        }

        switch smimeType {
        case "compressed-data":
            self = .compressedData
        case "enveloped-data":
            self = .envelopedData
        case "signed-data":
            self = .signedData
        case "certs-only":
            self = .certsOnly
        case "authenveloped-data":
            self = .authEnvelopedData
        default:
            self = .unknown
        }
    }
}
