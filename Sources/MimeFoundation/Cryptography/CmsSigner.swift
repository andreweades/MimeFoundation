//
// CmsSigner.swift
//
// CMS signer for S/MIME signing operations.
//

import Foundation
@_spi(CMS) import X509

/// Represents a signer for CMS (Cryptographic Message Syntax) operations.
///
/// A `CmsSigner` wraps a certificate and its associated private key,
/// along with configuration options for signing operations.
@available(macOS 11.0, iOS 14, tvOS 14, watchOS 7, macCatalyst 14, *)
public struct CmsSigner: Sendable {
    /// The certificate used for signing.
    public let certificate: Certificate

    /// The private key used for signing.
    public let privateKey: Certificate.PrivateKey

    /// Additional intermediate certificates to include in the signature.
    public var certificateChain: [Certificate]

    /// The digest algorithm to use for signing.
    public var digestAlgorithm: DigestAlgorithm

    /// Creates a new CMS signer with a certificate and private key.
    ///
    /// - Parameters:
    ///   - certificate: The certificate to use for signing.
    ///   - privateKey: The private key corresponding to the certificate.
    ///   - certificateChain: Additional intermediate certificates to include.
    ///   - digestAlgorithm: The digest algorithm to use. Defaults to SHA-256.
    public init(
        certificate: Certificate,
        privateKey: Certificate.PrivateKey,
        certificateChain: [Certificate] = [],
        digestAlgorithm: DigestAlgorithm = .sha256
    ) {
        self.certificate = certificate
        self.privateKey = privateKey
        self.certificateChain = certificateChain
        self.digestAlgorithm = digestAlgorithm
    }

    /// Creates a CMS signer from PEM-encoded certificate and private key data.
    ///
    /// - Parameters:
    ///   - certificatePEM: The PEM-encoded certificate.
    ///   - privateKeyPEM: The PEM-encoded private key.
    ///   - certificateChain: Additional intermediate certificates.
    ///   - digestAlgorithm: The digest algorithm to use.
    /// - Throws: `SecureMimeError` if the certificate or key cannot be parsed.
    public init(
        certificatePEM: String,
        privateKeyPEM: String,
        certificateChain: [Certificate] = [],
        digestAlgorithm: DigestAlgorithm = .sha256
    ) throws {
        do {
            self.certificate = try Certificate(pemEncoded: certificatePEM)
        } catch {
            throw SecureMimeError.invalidCertificate(String(describing: error))
        }

        do {
            self.privateKey = try Certificate.PrivateKey(pemEncoded: privateKeyPEM)
        } catch {
            throw SecureMimeError.invalidPrivateKey(String(describing: error))
        }

        self.certificateChain = certificateChain
        self.digestAlgorithm = digestAlgorithm
    }

    /// Creates a CMS signer from DER-encoded certificate and private key data.
    ///
    /// - Parameters:
    ///   - certificateDER: The DER-encoded certificate bytes.
    ///   - privateKeyDER: The DER-encoded private key bytes (PKCS#8 format).
    ///   - certificateChain: Additional intermediate certificates.
    ///   - digestAlgorithm: The digest algorithm to use.
    /// - Throws: `SecureMimeError` if the certificate or key cannot be parsed.
    public init(
        certificateDER: [UInt8],
        privateKeyDER: [UInt8],
        certificateChain: [Certificate] = [],
        digestAlgorithm: DigestAlgorithm = .sha256
    ) throws {
        do {
            self.certificate = try Certificate(derEncoded: certificateDER)
        } catch {
            throw SecureMimeError.invalidCertificate(String(describing: error))
        }

        do {
            self.privateKey = try Certificate.PrivateKey(derBytes: privateKeyDER)
        } catch {
            throw SecureMimeError.invalidPrivateKey(String(describing: error))
        }

        self.certificateChain = certificateChain
        self.digestAlgorithm = digestAlgorithm
    }

    /// Creates a CMS signer by loading a certificate and private key from files.
    ///
    /// - Parameters:
    ///   - certificatePath: Path to the PEM-encoded certificate file.
    ///   - privateKeyPath: Path to the PEM-encoded private key file.
    ///   - certificateChain: Additional intermediate certificates.
    ///   - digestAlgorithm: The digest algorithm to use.
    /// - Throws: `SecureMimeError` if the files cannot be read or parsed.
    public init(
        certificatePath: String,
        privateKeyPath: String,
        certificateChain: [Certificate] = [],
        digestAlgorithm: DigestAlgorithm = .sha256
    ) throws {
        let certData: Data
        let keyData: Data

        do {
            certData = try Data(contentsOf: URL(fileURLWithPath: certificatePath))
        } catch {
            throw SecureMimeError.fileReadFailed("Failed to read certificate file: \(error.localizedDescription)")
        }

        do {
            keyData = try Data(contentsOf: URL(fileURLWithPath: privateKeyPath))
        } catch {
            throw SecureMimeError.fileReadFailed("Failed to read private key file: \(error.localizedDescription)")
        }

        guard let certPEM = String(data: certData, encoding: .utf8) else {
            throw SecureMimeError.invalidCertificate("Certificate file is not valid UTF-8")
        }

        guard let keyPEM = String(data: keyData, encoding: .utf8) else {
            throw SecureMimeError.invalidPrivateKey("Private key file is not valid UTF-8")
        }

        try self.init(
            certificatePEM: certPEM,
            privateKeyPEM: keyPEM,
            certificateChain: certificateChain,
            digestAlgorithm: digestAlgorithm
        )
    }

    /// Returns the signature algorithm to use based on the private key type and digest algorithm.
    internal var signatureAlgorithm: Certificate.SignatureAlgorithm {
        let supported = privateKey.supportedSignatureAlgorithms

        switch digestAlgorithm {
        case .sha256:
            if supported.contains(.ecdsaWithSHA256) {
                return .ecdsaWithSHA256
            } else if supported.contains(.sha256WithRSAEncryption) {
                return .sha256WithRSAEncryption
            }
        case .sha384:
            if supported.contains(.ecdsaWithSHA384) {
                return .ecdsaWithSHA384
            } else if supported.contains(.sha384WithRSAEncryption) {
                return .sha384WithRSAEncryption
            }
        case .sha512:
            if supported.contains(.ecdsaWithSHA512) {
                return .ecdsaWithSHA512
            } else if supported.contains(.sha512WithRSAEncryption) {
                return .sha512WithRSAEncryption
            }
        case .sha1:
            if supported.contains(.sha1WithRSAEncryption) {
                return .sha1WithRSAEncryption
            }
        case .md5, .none:
            break
        }

        // Fall back to a sensible default based on what's supported
        if supported.contains(.ecdsaWithSHA256) {
            return .ecdsaWithSHA256
        } else if supported.contains(.sha256WithRSAEncryption) {
            return .sha256WithRSAEncryption
        } else if supported.contains(.ed25519) {
            return .ed25519
        } else if let first = supported.first {
            return first
        }

        // Ultimate fallback (shouldn't reach here with valid keys)
        return .sha256WithRSAEncryption
    }
}
