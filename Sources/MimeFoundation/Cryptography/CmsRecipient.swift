//
// CmsRecipient.swift
//
// Represents a recipient for CMS encryption operations.
//

import Foundation
#if canImport(Security)
import Security
#endif
@_spi(CMS) import X509

/// Represents a recipient for CMS encryption operations.
///
/// A recipient is identified by their certificate, which contains the
/// public key used to encrypt the message encryption key.
@available(macOS 11.0, iOS 14, tvOS 14, watchOS 7, macCatalyst 14, *)
public struct CmsRecipient: Sendable {
    /// The recipient's certificate.
    public let certificate: Certificate

    /// Creates a new CMS recipient with the specified certificate.
    ///
    /// - Parameter certificate: The recipient's X.509 certificate.
    public init(certificate: Certificate) {
        self.certificate = certificate
    }

    /// Creates a CMS recipient from a PEM-encoded certificate.
    ///
    /// - Parameter pemEncoded: The PEM-encoded certificate string.
    /// - Throws: `SecureMimeError` if the certificate cannot be parsed.
    public init(pemEncoded: String) throws {
        do {
            self.certificate = try Certificate(pemEncoded: pemEncoded)
        } catch {
            throw SecureMimeError.invalidCertificate(String(describing: error))
        }
    }

    /// Creates a CMS recipient from DER-encoded certificate data.
    ///
    /// - Parameter derEncoded: The DER-encoded certificate bytes.
    /// - Throws: `SecureMimeError` if the certificate cannot be parsed.
    public init(derEncoded: [UInt8]) throws {
        do {
            self.certificate = try Certificate(derEncoded: derEncoded)
        } catch {
            throw SecureMimeError.invalidCertificate(String(describing: error))
        }
    }

    #if canImport(Security)
    /// Creates a CMS recipient from a SecCertificate.
    ///
    /// - Parameter secCertificate: The Security framework certificate.
    /// - Throws: `SecureMimeError` if the certificate cannot be converted.
    public init(secCertificate: SecCertificate) throws {
        do {
            self.certificate = try Certificate(secCertificate)
        } catch {
            throw SecureMimeError.invalidCertificate(String(describing: error))
        }
    }

    /// Converts this recipient's certificate to a SecCertificate.
    ///
    /// - Returns: The Security framework certificate.
    /// - Throws: `SecureMimeError` if conversion fails.
    public func toSecCertificate() throws -> SecCertificate {
        do {
            return try SecCertificate.makeWithCertificate(certificate)
        } catch {
            throw SecureMimeError.invalidCertificate(String(describing: error))
        }
    }
    #endif
}

/// A collection of CMS recipients for encryption operations.
@available(macOS 11.0, iOS 14, tvOS 14, watchOS 7, macCatalyst 14, *)
public struct CmsRecipientCollection: Sendable, RandomAccessCollection, ExpressibleByArrayLiteral {
    public typealias Element = CmsRecipient
    public typealias Index = Int

    private var recipients: [CmsRecipient]

    /// Creates an empty recipient collection.
    public init() {
        self.recipients = []
    }

    /// Creates a recipient collection from an array of recipients.
    ///
    /// - Parameter recipients: The recipients to include.
    public init(_ recipients: [CmsRecipient]) {
        self.recipients = recipients
    }

    /// Creates a recipient collection from an array literal.
    public init(arrayLiteral elements: CmsRecipient...) {
        self.recipients = elements
    }

    /// The start index of the collection.
    public var startIndex: Int { recipients.startIndex }

    /// The end index of the collection.
    public var endIndex: Int { recipients.endIndex }

    /// Returns the index after the given index.
    public func index(after i: Int) -> Int { recipients.index(after: i) }

    /// Accesses the recipient at the specified index.
    public subscript(position: Int) -> CmsRecipient {
        recipients[position]
    }

    /// The number of recipients in the collection.
    public var count: Int { recipients.count }

    /// Adds a recipient to the collection.
    ///
    /// - Parameter recipient: The recipient to add.
    public mutating func add(_ recipient: CmsRecipient) {
        recipients.append(recipient)
    }

    /// Adds a recipient with the specified certificate.
    ///
    /// - Parameter certificate: The recipient's certificate.
    public mutating func add(certificate: Certificate) {
        recipients.append(CmsRecipient(certificate: certificate))
    }
}
