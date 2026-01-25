//
// SecureMimeContext.swift
//
// Abstract base class for S/MIME cryptographic operations.
//

import Foundation
@_spi(CMS) import X509

/// Abstract base class for S/MIME cryptographic operations.
///
/// This class provides the interface for S/MIME signing and verification.
/// Subclasses implement the actual cryptographic operations.
@available(macOS 11.0, iOS 14, tvOS 14, watchOS 7, macCatalyst 14, *)
open class SecureMimeContext: @unchecked Sendable {

    /// The MIME type for S/MIME signatures.
    public static let signatureProtocol = "application/pkcs7-signature"

    /// The MIME type for S/MIME encrypted content.
    public static let encryptionProtocol = "application/pkcs7-mime"

    /// Creates a new S/MIME context.
    public init() {}

    // MARK: - Signing

    /// Signs the provided content bytes using the specified signer.
    ///
    /// - Parameters:
    ///   - signer: The CMS signer containing the certificate and private key.
    ///   - content: The content bytes to sign.
    ///   - detached: If true, creates a detached signature (content not included).
    /// - Returns: The CMS signature bytes.
    /// - Throws: `SecureMimeError` if signing fails.
    open func sign<Bytes: DataProtocol>(
        _ signer: CmsSigner,
        content: Bytes,
        detached: Bool = true
    ) throws -> [UInt8] {
        do {
            return try CMS.sign(
                content,
                signatureAlgorithm: signer.signatureAlgorithm,
                additionalIntermediateCertificates: signer.certificateChain,
                certificate: signer.certificate,
                privateKey: signer.privateKey,
                signingTime: Date(),
                detached: detached
            )
        } catch {
            throw SecureMimeError.signingFailed(String(describing: error))
        }
    }

    /// Asynchronously signs the provided content bytes using the specified signer.
    ///
    /// - Parameters:
    ///   - signer: The CMS signer containing the certificate and private key.
    ///   - content: The content bytes to sign.
    ///   - detached: If true, creates a detached signature (content not included).
    /// - Returns: The CMS signature bytes.
    /// - Throws: `SecureMimeError` if signing fails.
    open func signAsync<Bytes: DataProtocol>(
        _ signer: CmsSigner,
        content: Bytes,
        detached: Bool = true
    ) async throws -> [UInt8] {
        try sign(signer, content: content, detached: detached)
    }

    /// Signs a MIME entity and creates a detached signature part.
    ///
    /// - Parameters:
    ///   - signer: The CMS signer containing the certificate and private key.
    ///   - entity: The MIME entity to sign.
    /// - Returns: An `ApplicationPkcs7Signature` containing the detached signature.
    /// - Throws: `SecureMimeError` if signing fails.
    open func createSignature(
        _ signer: CmsSigner,
        entity: MimeEntity
    ) throws -> ApplicationPkcs7Signature {
        let contentBytes = try serializeEntity(entity)
        let signatureBytes = try sign(signer, content: contentBytes, detached: true)
        return ApplicationPkcs7Signature(signatureBytes)
    }

    /// Asynchronously signs a MIME entity and creates a detached signature part.
    ///
    /// - Parameters:
    ///   - signer: The CMS signer containing the certificate and private key.
    ///   - entity: The MIME entity to sign.
    /// - Returns: An `ApplicationPkcs7Signature` containing the detached signature.
    /// - Throws: `SecureMimeError` if signing fails.
    open func createSignatureAsync(
        _ signer: CmsSigner,
        entity: MimeEntity
    ) async throws -> ApplicationPkcs7Signature {
        try createSignature(signer, entity: entity)
    }

    // MARK: - Verification

    /// Verifies a detached CMS signature against the provided content.
    ///
    /// - Parameters:
    ///   - signatureBytes: The CMS signature bytes.
    ///   - contentBytes: The original signed content bytes.
    ///   - trustRoots: The certificate store containing trusted root certificates.
    /// - Returns: A `DigitalSignatureCollection` containing the verification results.
    /// - Throws: `SecureMimeError` if verification fails.
    open func verify<SignatureBytes: DataProtocol, ContentBytes: DataProtocol>(
        signatureBytes: SignatureBytes,
        contentBytes: ContentBytes,
        trustRoots: CertificateStore
    ) async throws -> DigitalSignatureCollection {
        let result = await CMS.isValidSignature(
            dataBytes: contentBytes,
            signatureBytes: signatureBytes,
            trustRoots: trustRoots
        ) {
            RFC5280Policy()
        }

        switch result {
        case .success(let valid):
            let signature = DigitalSignature(
                signerCertificate: valid.signer,
                digestAlgorithm: .sha256, // TODO: Extract from signature
                creationDate: nil, // TODO: Extract from signing time attribute
                isValid: true
            )
            return DigitalSignatureCollection([signature])

        case .failure(let error):
            switch error {
            case .invalidCMSBlock(let block):
                throw SecureMimeError.signatureVerificationFailed(block.reason)
            case .unableToValidateSigner(let failure):
                let signature = DigitalSignature(
                    signerCertificate: failure.signer,
                    digestAlgorithm: .sha256,
                    creationDate: nil,
                    isValid: false
                )
                return DigitalSignatureCollection([signature])
            }
        }
    }

    /// Verifies a `MultipartSigned` entity.
    ///
    /// - Parameters:
    ///   - multipartSigned: The multipart/signed entity to verify.
    ///   - trustRoots: The certificate store containing trusted root certificates.
    /// - Returns: A tuple containing the verification results and the signed content entity.
    /// - Throws: `SecureMimeError` if verification fails.
    open func verify(
        multipartSigned: MultipartSigned,
        trustRoots: CertificateStore
    ) async throws -> (signatures: DigitalSignatureCollection, content: MimeEntity) {
        guard multipartSigned.count >= 2 else {
            throw SecureMimeError.invalidMultipartSigned("Must have at least 2 parts")
        }

        let contentEntity = multipartSigned[0]
        guard let signaturePart = multipartSigned[1] as? ApplicationPkcs7Signature else {
            throw SecureMimeError.invalidMultipartSigned("Second part must be application/pkcs7-signature")
        }

        let contentBytes = try serializeEntity(contentEntity)
        let signatureBytes = try signaturePart.getSignatureBytes()

        let signatures = try await verify(
            signatureBytes: signatureBytes,
            contentBytes: contentBytes,
            trustRoots: trustRoots
        )

        return (signatures, contentEntity)
    }

    // MARK: - Helpers

    /// Serializes a MIME entity to bytes for signing/verification.
    internal func serializeEntity(_ entity: MimeEntity) throws -> [UInt8] {
        let stream = MemoryStream()
        try entity.writeTo(stream)
        return stream.toByteArray()
    }
}
