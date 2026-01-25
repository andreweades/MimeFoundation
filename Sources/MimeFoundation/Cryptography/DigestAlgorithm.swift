//
// DigestAlgorithm.swift
//
// Digest algorithm enumeration for S/MIME signing.
//

import Foundation

/// Represents a cryptographic digest (hash) algorithm.
public enum DigestAlgorithm: String, Sendable, Equatable, Hashable, CaseIterable {
    /// No digest algorithm specified.
    case none = "none"

    /// MD5 digest algorithm (deprecated, insecure).
    case md5 = "md5"

    /// SHA-1 digest algorithm (deprecated, weak).
    case sha1 = "sha1"

    /// SHA-256 digest algorithm (recommended).
    case sha256 = "sha256"

    /// SHA-384 digest algorithm.
    case sha384 = "sha384"

    /// SHA-512 digest algorithm.
    case sha512 = "sha512"

    /// The default digest algorithm (SHA-256).
    public static var `default`: DigestAlgorithm { .sha256 }

    /// Returns the micalg parameter value for this digest algorithm.
    ///
    /// The micalg (Message Integrity Check Algorithm) parameter is used
    /// in multipart/signed messages to indicate the digest algorithm.
    public var micalg: String {
        switch self {
        case .none:
            return ""
        case .md5:
            return "md5"
        case .sha1:
            return "sha-1"
        case .sha256:
            return "sha-256"
        case .sha384:
            return "sha-384"
        case .sha512:
            return "sha-512"
        }
    }

    /// Initializes a DigestAlgorithm from a micalg parameter string.
    /// - Parameter micalg: The micalg parameter value.
    public init(micalg: String?) {
        guard let micalg = micalg?.lowercased().trimmingCharacters(in: .whitespaces) else {
            self = .none
            return
        }

        switch micalg {
        case "md5":
            self = .md5
        case "sha-1", "sha1":
            self = .sha1
        case "sha-256", "sha256":
            self = .sha256
        case "sha-384", "sha384":
            self = .sha384
        case "sha-512", "sha512":
            self = .sha512
        default:
            self = .none
        }
    }

    /// Initializes a DigestAlgorithm from an OID string.
    /// - Parameter oid: The OID string (e.g., "2.16.840.1.101.3.4.2.1" for SHA-256).
    public init(oid: String) {
        switch oid {
        case "1.2.840.113549.2.5":
            self = .md5
        case "1.3.14.3.2.26":
            self = .sha1
        case "2.16.840.1.101.3.4.2.1":
            self = .sha256
        case "2.16.840.1.101.3.4.2.2":
            self = .sha384
        case "2.16.840.1.101.3.4.2.3":
            self = .sha512
        default:
            self = .none
        }
    }

    /// The OID (Object Identifier) for this digest algorithm.
    public var oid: String {
        switch self {
        case .none:
            return ""
        case .md5:
            return "1.2.840.113549.2.5"
        case .sha1:
            return "1.3.14.3.2.26"
        case .sha256:
            return "2.16.840.1.101.3.4.2.1"
        case .sha384:
            return "2.16.840.1.101.3.4.2.2"
        case .sha512:
            return "2.16.840.1.101.3.4.2.3"
        }
    }
}
