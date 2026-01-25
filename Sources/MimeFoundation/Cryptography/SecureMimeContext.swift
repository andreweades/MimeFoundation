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

    // MARK: - Encryption

    /// Encrypts the provided content bytes for the specified recipients.
    ///
    /// - Parameters:
    ///   - recipients: The recipients who will be able to decrypt the message.
    ///   - content: The content bytes to encrypt.
    /// - Returns: The encrypted CMS content bytes.
    /// - Throws: `SecureMimeError.unsupportedAlgorithm` if encryption is not supported.
    ///
    /// - Note: The default implementation throws an error. Subclasses that support
    ///   encryption (like `AppleSecureMimeContext` on macOS) override this method.
    open func encrypt(
        recipients: CmsRecipientCollection,
        content: [UInt8]
    ) throws -> [UInt8] {
        throw SecureMimeError.unsupportedAlgorithm("Encryption is not supported by this context. Use AppleSecureMimeContext on macOS.")
    }

    /// Encrypts a MIME entity for the specified recipients.
    ///
    /// - Parameters:
    ///   - recipients: The recipients who will be able to decrypt the message.
    ///   - entity: The MIME entity to encrypt.
    /// - Returns: An `ApplicationPkcs7Mime` containing the encrypted content.
    /// - Throws: `SecureMimeError` if encryption fails.
    open func encrypt(
        recipients: CmsRecipientCollection,
        entity: MimeEntity
    ) throws -> ApplicationPkcs7Mime {
        let contentBytes = try serializeEntity(entity)
        let encryptedBytes = try encrypt(recipients: recipients, content: contentBytes)
        return ApplicationPkcs7Mime(encryptedBytes, smimeType: .envelopedData)
    }

    /// Signs and encrypts a MIME entity.
    ///
    /// - Parameters:
    ///   - signer: The CMS signer for signing.
    ///   - recipients: The recipients who will be able to decrypt the message.
    ///   - entity: The MIME entity to sign and encrypt.
    /// - Returns: An `ApplicationPkcs7Mime` containing the signed and encrypted content.
    /// - Throws: `SecureMimeError` if signing or encryption fails.
    ///
    /// - Note: The message is first signed, then the signed message is encrypted.
    open func signAndEncrypt(
        signer: CmsSigner,
        recipients: CmsRecipientCollection,
        entity: MimeEntity
    ) throws -> ApplicationPkcs7Mime {
        // First, create a signed message
        let signedMultipart = try MultipartSigned.create(entity, signer: signer, context: self)

        // Then encrypt the signed message
        return try encrypt(recipients: recipients, entity: signedMultipart)
    }

    // MARK: - Decryption

    /// Decrypts the provided CMS encrypted content.
    ///
    /// - Parameter encryptedBytes: The encrypted CMS content bytes.
    /// - Returns: The decrypted content bytes.
    /// - Throws: `SecureMimeError.unsupportedAlgorithm` if decryption is not supported.
    ///
    /// - Note: The default implementation throws an error. Subclasses that support
    ///   decryption (like `AppleSecureMimeContext` on macOS) override this method.
    open func decrypt(encryptedBytes: [UInt8]) throws -> [UInt8] {
        throw SecureMimeError.unsupportedAlgorithm("Decryption is not supported by this context. Use AppleSecureMimeContext on macOS.")
    }

    /// Decrypts an `ApplicationPkcs7Mime` entity.
    ///
    /// - Parameter encryptedPart: The encrypted MIME part.
    /// - Returns: The decrypted MIME entity.
    /// - Throws: `SecureMimeError` if decryption fails.
    open func decrypt(encryptedPart: ApplicationPkcs7Mime) throws -> MimeEntity {
        let encryptedBytes = try encryptedPart.getContentBytes()
        let decryptedBytes = try decrypt(encryptedBytes: encryptedBytes)

        // Parse the decrypted content as a MIME entity
        guard let entity = try MimeMessage.parseEntity(.default, decryptedBytes) else {
            throw SecureMimeError.invalidSignatureData("Failed to parse decrypted content as MIME entity")
        }

        return entity
    }

    /// Decrypts and verifies an encrypted and signed message.
    ///
    /// - Parameters:
    ///   - encryptedPart: The encrypted MIME part.
    ///   - trustRoots: The certificate store containing trusted root certificates.
    /// - Returns: A tuple containing the verification results and the decrypted content.
    /// - Throws: `SecureMimeError` if decryption or verification fails.
    open func decryptAndVerify(
        encryptedPart: ApplicationPkcs7Mime,
        trustRoots: CertificateStore
    ) async throws -> (signatures: DigitalSignatureCollection, content: MimeEntity) {
        // First decrypt
        let decryptedEntity = try decrypt(encryptedPart: encryptedPart)

        // Check if the decrypted content is a signed message
        if let signedMultipart = decryptedEntity as? MultipartSigned {
            return try await verify(multipartSigned: signedMultipart, trustRoots: trustRoots)
        }

        // Not signed, return with empty signatures
        return (DigitalSignatureCollection([]), decryptedEntity)
    }

    // MARK: - Helpers

    /// Serializes a MIME entity to bytes for signing/verification.
    ///
    /// S/MIME requires CRLF line endings for the canonicalized content.
    /// This method ensures proper formatting regardless of platform.
    internal func serializeEntity(_ entity: MimeEntity) throws -> [UInt8] {
        var options = FormatOptions.default
        options.newLineFormat = .dos  // S/MIME requires CRLF
        let stream = MemoryStream()
        try entity.writeTo(options, stream)
        return stream.toByteArray()
    }

    /// Returns whether this context supports encryption.
    open var supportsEncryption: Bool { false }

    /// Returns whether this context supports decryption.
    open var supportsDecryption: Bool { false }
}
