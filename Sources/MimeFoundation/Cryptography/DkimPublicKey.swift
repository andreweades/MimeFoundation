//
// DkimPublicKey.swift
//
// Ported from MimeKit (C#) to Swift.
//

import Crypto
import _CryptoExtras

public enum DkimPublicKey: Sendable {
    case rsa(_RSA.Signing.PublicKey)
    case ed25519(Curve25519.Signing.PublicKey)
}
