//
// ApplicationPkcs7Mime.swift
//
// MIME part for S/MIME encrypted or signed-and-encrypted content.
//

import Foundation

/// Represents an `application/pkcs7-mime` MIME part.
///
/// This class represents S/MIME encrypted content (EnvelopedData),
/// signed content (SignedData), or compressed content.
/// The `smimeType` parameter indicates the specific type of content.
public class ApplicationPkcs7Mime: MimePart {

    /// Creates a new PKCS#7 MIME part with the default content type.
    public convenience init() {
        self.init(ApplicationPkcs7Mime.defaultContentType)
        contentTransferEncoding = .base64
    }

    /// Creates a new PKCS#7 MIME part with the specified S/MIME type.
    ///
    /// - Parameter smimeType: The S/MIME content type.
    public convenience init(smimeType: SecureMimeType) {
        self.init()
        self.smimeType = smimeType
    }

    /// Creates a new PKCS#7 MIME part from encrypted/signed bytes.
    ///
    /// - Parameters:
    ///   - contentBytes: The raw CMS content bytes.
    ///   - smimeType: The S/MIME content type.
    public convenience init(_ contentBytes: [UInt8], smimeType: SecureMimeType) {
        self.init(smimeType: smimeType)
        let stream = MemoryStream(contentBytes, writable: false)
        content = MimeContent(stream, encoding: .binary)
    }

    /// Creates a new PKCS#7 MIME part from encrypted/signed data.
    ///
    /// - Parameters:
    ///   - contentData: The raw CMS content data.
    ///   - smimeType: The S/MIME content type.
    public convenience init(_ contentData: Data, smimeType: SecureMimeType) {
        self.init(Array(contentData), smimeType: smimeType)
    }

    /// The default content type for PKCS#7 MIME.
    private static var defaultContentType: ContentType {
        let ct = try! ContentType("application", "pkcs7-mime")
        ct.parameters["name"] = "smime.p7m"
        return ct
    }

    /// The S/MIME type of this content.
    ///
    /// This corresponds to the `smime-type` parameter of the Content-Type header.
    public var smimeType: SecureMimeType {
        get {
            SecureMimeType(smimeType: contentType.parameters["smime-type"])
        }
        set {
            if newValue == .unknown {
                contentType.parameters["smime-type"] = nil
            } else {
                contentType.parameters["smime-type"] = newValue.rawValue
            }

            // Update the filename extension based on type
            switch newValue {
            case .envelopedData, .authEnvelopedData:
                contentType.parameters["name"] = "smime.p7m"
            case .signedData:
                contentType.parameters["name"] = "smime.p7m"
            case .compressedData:
                contentType.parameters["name"] = "smime.p7z"
            case .certsOnly:
                contentType.parameters["name"] = "smime.p7c"
            case .unknown:
                break
            }
        }
    }

    /// Gets the raw content bytes.
    ///
    /// - Returns: The raw CMS content bytes.
    /// - Throws: `SecureMimeError` if the content cannot be read.
    public func getContentBytes() throws -> [UInt8] {
        guard let content = content else {
            throw SecureMimeError.invalidSignatureData("No content")
        }
        return try readAllBytes(content: content)
    }

    /// Accepts a MIME visitor.
    ///
    /// - Parameter visitor: The visitor to accept.
    public override func accept(_ visitor: MimeVisitor) {
        visitor.visit(self)
    }

    // MARK: - Static Factory Methods

    /// Signs the entity and returns an `ApplicationPkcs7Mime` (signed-data).
    ///
    /// - Parameters:
    ///   - entity: The MIME entity to sign.
    ///   - signer: The CMS signer to use.
    ///   - context: The S/MIME context to use. Defaults to `DefaultSecureMimeContext.shared`.
    /// - Returns: A new `ApplicationPkcs7Mime` containing the signed content.
    /// - Throws: `SecureMimeError` if signing fails.
    @available(macOS 11.0, iOS 14, tvOS 14, watchOS 7, macCatalyst 14, *)
    public static func sign(
        _ entity: MimeEntity,
        signer: CmsSigner,
        context: SecureMimeContext = DefaultSecureMimeContext.shared
    ) throws -> ApplicationPkcs7Mime {
        let contentBytes = try context.serializeEntity(entity)
        let signatureBytes = try context.sign(signer, content: contentBytes, detached: false)
        return ApplicationPkcs7Mime(signatureBytes, smimeType: .signedData)
    }

    /// Asynchronously signs the entity and returns an `ApplicationPkcs7Mime` (signed-data).
    ///
    /// - Parameters:
    ///   - entity: The MIME entity to sign.
    ///   - signer: The CMS signer to use.
    ///   - context: The S/MIME context to use. Defaults to `DefaultSecureMimeContext.shared`.
    /// - Returns: A new `ApplicationPkcs7Mime` containing the signed content.
    /// - Throws: `SecureMimeError` if signing fails.
    @available(macOS 11.0, iOS 14, tvOS 14, watchOS 7, macCatalyst 14, *)
    public static func signAsync(
        _ entity: MimeEntity,
        signer: CmsSigner,
        context: SecureMimeContext = DefaultSecureMimeContext.shared
    ) async throws -> ApplicationPkcs7Mime {
        let contentBytes = try context.serializeEntity(entity)
        let signatureBytes = try await context.signAsync(signer, content: contentBytes, detached: false)
        return ApplicationPkcs7Mime(signatureBytes, smimeType: .signedData)
    }

    /// Encrypts the entity and returns an `ApplicationPkcs7Mime` (enveloped-data).
    ///
    /// - Parameters:
    ///   - recipients: The recipients who will be able to decrypt the message.
    ///   - entity: The MIME entity to encrypt.
    ///   - context: The S/MIME context to use. Defaults to `DefaultSecureMimeContext.shared`.
    /// - Returns: A new `ApplicationPkcs7Mime` containing the encrypted content.
    /// - Throws: `SecureMimeError` if encryption fails.
    @available(macOS 11.0, iOS 14, tvOS 14, watchOS 7, macCatalyst 14, *)
    public static func encrypt(
        _ entity: MimeEntity,
        recipients: CmsRecipientCollection,
        context: SecureMimeContext = DefaultSecureMimeContext.shared
    ) throws -> ApplicationPkcs7Mime {
        return try context.encrypt(recipients: recipients, entity: entity)
    }

    /// Asynchronously encrypts the entity and returns an `ApplicationPkcs7Mime` (enveloped-data).
    ///
    /// - Parameters:
    ///   - recipients: The recipients who will be able to decrypt the message.
    ///   - entity: The MIME entity to encrypt.
    ///   - context: The S/MIME context to use. Defaults to `DefaultSecureMimeContext.shared`.
    /// - Returns: A new `ApplicationPkcs7Mime` containing the encrypted content.
    /// - Throws: `SecureMimeError` if encryption fails.
    @available(macOS 11.0, iOS 14, tvOS 14, watchOS 7, macCatalyst 14, *)
    public static func encryptAsync(
        _ entity: MimeEntity,
        recipients: CmsRecipientCollection,
        context: SecureMimeContext = DefaultSecureMimeContext.shared
    ) async throws -> ApplicationPkcs7Mime {
        // Since context.encrypt is not async yet, we wrap it
        // TODO: Update SecureMimeContext to support async encrypt
        return try context.encrypt(recipients: recipients, entity: entity)
    }
}
