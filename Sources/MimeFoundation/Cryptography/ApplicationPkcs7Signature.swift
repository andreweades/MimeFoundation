//
// ApplicationPkcs7Signature.swift
//
// MIME part for S/MIME detached signatures.
//

import Foundation

/// Represents an `application/pkcs7-signature` MIME part.
///
/// This class represents a detached S/MIME signature, typically used
/// as the second part of a `multipart/signed` message.
public class ApplicationPkcs7Signature: MimePart {

    /// Creates a new PKCS#7 signature part with the default content type.
    public convenience init() {
        self.init(ApplicationPkcs7Signature.defaultContentType)
        contentTransferEncoding = .base64
    }

    /// Creates a new PKCS#7 signature part from signature bytes.
    ///
    /// - Parameter signatureBytes: The raw CMS signature bytes.
    public convenience init(_ signatureBytes: [UInt8]) {
        self.init()
        let stream = MemoryStream(signatureBytes, writable: false)
        content = MimeContent(stream, encoding: .binary)
    }

    /// Creates a new PKCS#7 signature part from signature data.
    ///
    /// - Parameter signatureData: The raw CMS signature data.
    public convenience init(_ signatureData: Data) {
        self.init(Array(signatureData))
    }

    /// The default content type for PKCS#7 signatures.
    private static var defaultContentType: ContentType {
        let ct = try! ContentType("application", "pkcs7-signature")
        ct.parameters["name"] = "smime.p7s"
        return ct
    }

    /// Gets the raw signature bytes.
    ///
    /// - Returns: The raw CMS signature bytes.
    /// - Throws: `SecureMimeError` if the signature content cannot be read.
    public func getSignatureBytes() throws -> [UInt8] {
        guard let content = content else {
            throw SecureMimeError.invalidSignatureData("No signature content")
        }
        return try readAllBytes(content: content)
    }

    /// Accepts a MIME visitor.
    ///
    /// - Parameter visitor: The visitor to accept.
    public override func accept(_ visitor: MimeVisitor) {
        visitor.visit(self)
    }
}
