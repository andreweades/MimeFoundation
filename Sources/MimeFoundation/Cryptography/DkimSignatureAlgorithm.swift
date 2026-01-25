//
// DkimSignatureAlgorithm.swift
//
// Ported from MimeKit (C#) to Swift.
//

public enum DkimSignatureAlgorithm: Sendable {
    case rsaSha1
    case rsaSha256
    case ed25519Sha256
}
