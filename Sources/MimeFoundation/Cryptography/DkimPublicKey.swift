//
// DkimPublicKey.swift
//
// Ported from MimeKit (C#) to Swift.
//

import Crypto
import _CryptoExtras

/// A DKIM public key for signature verification.
///
/// This enum wraps the cryptographic public keys used for DKIM verification,
/// supporting both RSA and Ed25519 key types.
///
/// DKIM public keys are typically retrieved from DNS TXT records at the location
/// `{selector}._domainkey.{domain}` and parsed using ``DkimPublicKeyLocatorBase/getPublicKey(_:)``.
///
/// ## Topics
///
/// ### Key Types
/// - ``rsa(_:)``
/// - ``ed25519(_:)``
public enum DkimPublicKey: Sendable {
    /// An RSA public key for RSA-SHA1 or RSA-SHA256 verification.
    case rsa(_RSA.Signing.PublicKey)
    /// An Ed25519 public key for Ed25519-SHA256 verification.
    case ed25519(Curve25519.Signing.PublicKey)
}
