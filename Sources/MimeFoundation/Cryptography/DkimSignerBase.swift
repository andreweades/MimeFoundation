//
// DkimSignerBase.swift
//
// Ported from MimeKit (C#) to Swift.
//

import Foundation
import Crypto
import _CryptoExtras

public enum DkimSignerError: Error, Equatable, Sendable {
    case invalidArgument
    case invalidPrivateKey
    case unsupportedAlgorithm
    case fileReadFailed
}

public enum DkimPrivateKey: Sendable {
    case rsa(_RSA.Signing.PrivateKey)
    case ed25519(Curve25519.Signing.PrivateKey)
}

open class DkimSignerBase {
    public let domain: String
    public let selector: String
    public var signatureAlgorithm: DkimSignatureAlgorithm
    public var bodyCanonicalizationAlgorithm: DkimCanonicalizationAlgorithm
    public var headerCanonicalizationAlgorithm: DkimCanonicalizationAlgorithm
    public var signaturesExpireAfter: TimeInterval?

    internal let privateKey: DkimPrivateKey

    public init(privateKey: DkimPrivateKey, domain: String, selector: String, algorithm: DkimSignatureAlgorithm = .rsaSha256) throws {
        guard !domain.isEmpty, !selector.isEmpty else {
            throw DkimSignerError.invalidArgument
        }

        self.privateKey = privateKey
        self.domain = domain
        self.selector = selector
        self.signatureAlgorithm = algorithm
        self.bodyCanonicalizationAlgorithm = .simple
        self.headerCanonicalizationAlgorithm = .simple
        self.signaturesExpireAfter = nil
    }

    public convenience init(filePath: String, domain: String, selector: String, algorithm: DkimSignatureAlgorithm = .rsaSha256) throws {
        guard !filePath.isEmpty else {
            throw DkimSignerError.invalidArgument
        }
        let data: Data
        do {
            data = try Data(contentsOf: URL(fileURLWithPath: filePath))
        } catch {
            throw DkimSignerError.fileReadFailed
        }
        try self.init(privateKeyData: data, domain: domain, selector: selector, algorithm: algorithm)
    }

    public convenience init(privateKeyData: Data, domain: String, selector: String, algorithm: DkimSignatureAlgorithm = .rsaSha256) throws {
        let key = try Self.loadPrivateKey(from: privateKeyData)
        try self.init(privateKey: key, domain: domain, selector: selector, algorithm: algorithm)
    }

    public convenience init(stream: MimeStream, domain: String, selector: String, algorithm: DkimSignatureAlgorithm = .rsaSha256) throws {
        let bytes = try Self.readAllBytes(from: stream)
        try self.init(privateKeyData: Data(bytes), domain: domain, selector: selector, algorithm: algorithm)
    }

    internal func createSigningContext() throws -> DkimSignatureContext {
        switch signatureAlgorithm {
        case .rsaSha1:
            guard case .rsa(let key) = privateKey else {
                throw DkimSignerError.invalidPrivateKey
            }
            return DkimRsaSignatureContext(key: key, algorithm: .rsaSha1)
        case .rsaSha256:
            guard case .rsa(let key) = privateKey else {
                throw DkimSignerError.invalidPrivateKey
            }
            return DkimRsaSignatureContext(key: key, algorithm: .rsaSha256)
        case .ed25519Sha256:
            guard case .ed25519(let key) = privateKey else {
                throw DkimSignerError.invalidPrivateKey
            }
            return DkimEd25519SignatureContext(key: key)
        }
    }

    private static func loadPrivateKey(from data: Data) throws -> DkimPrivateKey {
        if let pem = String(data: data, encoding: .utf8) {
            if let key = try? _RSA.Signing.PrivateKey(unsafePEMRepresentation: pem) {
                return .rsa(key)
            }
        }
        if data.count == 32 || data.count == 64 {
            if let key = try? Curve25519.Signing.PrivateKey(rawRepresentation: data) {
                return .ed25519(key)
            }
        }
        throw DkimSignerError.invalidPrivateKey
    }

    private static func readAllBytes(from stream: MimeStream) throws -> [UInt8] {
        var buffer = [UInt8](repeating: 0, count: 4096)
        var data: [UInt8] = []
        _ = try? stream.seek(0, origin: .begin)
        while true {
            let read = try stream.read(&buffer, offset: 0, count: buffer.count)
            if read == 0 {
                break
            }
            data.append(contentsOf: buffer[0..<read])
        }
        return data
    }
}
