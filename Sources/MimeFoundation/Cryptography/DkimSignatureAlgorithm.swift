//
// DkimSignatureAlgorithm.swift
//
// Ported from MimeKit (C#) to Swift.
//

/// A DKIM signature algorithm.
///
/// DomainKeys Identified Mail (DKIM) supports several signature algorithms
/// for signing email messages. This enum represents the available algorithms.
///
/// ## Topics
///
/// ### Signature Algorithms
/// - ``rsaSha1``
/// - ``rsaSha256``
/// - ``ed25519Sha256``
public enum DkimSignatureAlgorithm: Sendable {
    /// The RSA-SHA1 signature algorithm.
    ///
    /// - Warning: Due to the recognized weakness of the SHA-1 hash algorithm,
    ///   it is recommended that this algorithm NOT be used. Use ``rsaSha256``
    ///   or ``ed25519Sha256`` instead.
    case rsaSha1

    /// The RSA-SHA256 signature algorithm.
    ///
    /// This is the most widely supported and recommended algorithm for DKIM signatures
    /// when using RSA keys.
    case rsaSha256

    /// The Ed25519-SHA256 signature algorithm.
    ///
    /// This algorithm uses elliptic curve cryptography (Ed25519) with SHA-256 hashing.
    /// It provides strong security with smaller key sizes compared to RSA.
    case ed25519Sha256
}
