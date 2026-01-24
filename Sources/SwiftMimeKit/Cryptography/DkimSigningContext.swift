//
// DkimSigningContext.swift
//
// Ported from MimeKit (C#) to Swift.
//

import Foundation
import Crypto
import _CryptoExtras

private enum DkimDigestState {
    case sha1(Insecure.SHA1)
    case sha256(SHA256)

    mutating func update(_ data: ArraySlice<UInt8>) {
        switch self {
        case .sha1(var digest):
            digest.update(data: data)
            self = .sha1(digest)
        case .sha256(var digest):
            digest.update(data: data)
            self = .sha256(digest)
        }
    }

    mutating func finalizeSha1() -> Insecure.SHA1Digest? {
        switch self {
        case .sha1(let digest):
            return digest.finalize()
        default:
            return nil
        }
    }

    mutating func finalizeSha256() -> SHA256Digest? {
        switch self {
        case .sha256(let digest):
            return digest.finalize()
        default:
            return nil
        }
    }

    mutating func finalizeBytes() -> [UInt8] {
        switch self {
        case .sha1(let digest):
            return Array(digest.finalize())
        case .sha256(let digest):
            return Array(digest.finalize())
        }
    }
}

final class DkimRsaSignatureContext: DkimSignatureContext {
    private var digest: DkimDigestState
    private let key: _RSA.Signing.PrivateKey
    private let algorithm: DkimSignatureAlgorithm

    init(key: _RSA.Signing.PrivateKey, algorithm: DkimSignatureAlgorithm) {
        self.key = key
        self.algorithm = algorithm
        switch algorithm {
        case .rsaSha1:
            digest = .sha1(Insecure.SHA1())
        case .rsaSha256:
            digest = .sha256(SHA256())
        case .ed25519Sha256:
            digest = .sha256(SHA256())
        }
    }

    func update(_ buffer: [UInt8], offset: Int, count: Int) {
        guard count > 0 else { return }
        digest.update(buffer[offset..<(offset + count)])
    }

    func generateSignature() throws -> [UInt8] {
        switch algorithm {
        case .rsaSha1:
            guard let hash = digest.finalizeSha1() else {
                throw DkimSignerError.unsupportedAlgorithm
            }
            let signature = try key.signature(for: hash, padding: .insecurePKCS1v1_5)
            return Array(signature.rawRepresentation)
        case .rsaSha256:
            guard let hash = digest.finalizeSha256() else {
                throw DkimSignerError.unsupportedAlgorithm
            }
            let signature = try key.signature(for: hash, padding: .insecurePKCS1v1_5)
            return Array(signature.rawRepresentation)
        case .ed25519Sha256:
            throw DkimSignerError.unsupportedAlgorithm
        }
    }

    func verify(signature: [UInt8]) throws -> Bool {
        false
    }
}

final class DkimEd25519SignatureContext: DkimSignatureContext {
    private var digest = DkimDigestState.sha256(SHA256())
    private let key: Curve25519.Signing.PrivateKey

    init(key: Curve25519.Signing.PrivateKey) {
        self.key = key
    }

    func update(_ buffer: [UInt8], offset: Int, count: Int) {
        guard count > 0 else { return }
        digest.update(buffer[offset..<(offset + count)])
    }

    func generateSignature() throws -> [UInt8] {
        let hash = digest.finalizeBytes()
        let signature = try key.signature(for: Data(hash))
        return Array(signature)
    }

    func verify(signature: [UInt8]) throws -> Bool {
        false
    }
}
