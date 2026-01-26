//
// Author: Jeffrey Stedfast <jestedfa@microsoft.com>
//
// Copyright (c) 2013-2026 .NET Foundation and Contributors
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.
//

import Foundation
import Testing
@_spi(CMS) import X509
import Crypto
@testable import MimeFoundation

@Suite
struct X509ChainValidatorTests {

    // MARK: - Certificate Creation Helpers

    @available(macOS 11.0, iOS 14, tvOS 14, watchOS 7, macCatalyst 14, *)
    private static func createRootCA(name: String = "Test Root CA") throws -> (Certificate, Certificate.PrivateKey) {
        let privateKey = P256.Signing.PrivateKey()
        let certificatePrivateKey = Certificate.PrivateKey(privateKey)

        let dn = try DistinguishedName {
            CommonName(name)
            OrganizationName("MimeFoundation Tests")
        }

        let now = Date()
        let oneSecondAgo = now.addingTimeInterval(-1)  // Ensure cert is already valid
        let tenYears: TimeInterval = 10 * 365 * 24 * 60 * 60

        let certificate = try Certificate(
            version: .v3,
            serialNumber: Certificate.SerialNumber(),
            publicKey: certificatePrivateKey.publicKey,
            notValidBefore: oneSecondAgo,
            notValidAfter: now.addingTimeInterval(tenYears),
            issuer: dn,
            subject: dn,
            signatureAlgorithm: .ecdsaWithSHA256,
            extensions: Certificate.Extensions {
                Critical(BasicConstraints.isCertificateAuthority(maxPathLength: nil))
                Critical(KeyUsage(keyCertSign: true, cRLSign: true))
            },
            issuerPrivateKey: certificatePrivateKey
        )

        return (certificate, certificatePrivateKey)
    }

    @available(macOS 11.0, iOS 14, tvOS 14, watchOS 7, macCatalyst 14, *)
    private static func createIntermediate(
        name: String = "Test Intermediate CA",
        issuer: Certificate,
        issuerKey: Certificate.PrivateKey
    ) throws -> (Certificate, Certificate.PrivateKey) {
        let privateKey = P256.Signing.PrivateKey()
        let certificatePrivateKey = Certificate.PrivateKey(privateKey)

        let dn = try DistinguishedName {
            CommonName(name)
            OrganizationName("MimeFoundation Tests")
        }

        let now = Date()
        let oneSecondAgo = now.addingTimeInterval(-1)  // Ensure cert is already valid
        let fiveYears: TimeInterval = 5 * 365 * 24 * 60 * 60

        let certificate = try Certificate(
            version: .v3,
            serialNumber: Certificate.SerialNumber(),
            publicKey: certificatePrivateKey.publicKey,
            notValidBefore: oneSecondAgo,
            notValidAfter: now.addingTimeInterval(fiveYears),
            issuer: issuer.subject,
            subject: dn,
            signatureAlgorithm: .ecdsaWithSHA256,
            extensions: Certificate.Extensions {
                Critical(BasicConstraints.isCertificateAuthority(maxPathLength: 0))
                Critical(KeyUsage(keyCertSign: true, cRLSign: true))
            },
            issuerPrivateKey: issuerKey
        )

        return (certificate, certificatePrivateKey)
    }

    @available(macOS 11.0, iOS 14, tvOS 14, watchOS 7, macCatalyst 14, *)
    private static func createLeaf(
        name: String = "Test Leaf",
        email: String? = nil,
        issuer: Certificate,
        issuerKey: Certificate.PrivateKey,
        notBefore: Date? = nil,
        notAfter: Date? = nil
    ) throws -> (Certificate, Certificate.PrivateKey) {
        let privateKey = P256.Signing.PrivateKey()
        let certificatePrivateKey = Certificate.PrivateKey(privateKey)

        let dn = try DistinguishedName {
            CommonName(name)
            OrganizationName("MimeFoundation Tests")
        }

        let now = Date()
        let oneSecondAgo = now.addingTimeInterval(-1)  // Ensure cert is already valid
        let oneYear: TimeInterval = 365 * 24 * 60 * 60

        let certificate = try Certificate(
            version: .v3,
            serialNumber: Certificate.SerialNumber(),
            publicKey: certificatePrivateKey.publicKey,
            notValidBefore: notBefore ?? oneSecondAgo,
            notValidAfter: notAfter ?? now.addingTimeInterval(oneYear),
            issuer: issuer.subject,
            subject: dn,
            signatureAlgorithm: .ecdsaWithSHA256,
            extensions: Certificate.Extensions {
                Critical(BasicConstraints.notCertificateAuthority)
                Critical(KeyUsage(digitalSignature: true))
                if let email = email {
                    SubjectAlternativeNames([.rfc822Name(email)])
                }
            },
            issuerPrivateKey: issuerKey
        )

        return (certificate, certificatePrivateKey)
    }

    // MARK: - Validation Tests

    @Test("Valid chain with direct root signing")
    @available(macOS 11.0, iOS 14, tvOS 14, watchOS 7, macCatalyst 14, *)
    func validChainDirectRoot() async throws {
        let (root, rootKey) = try Self.createRootCA()
        let (leaf, _) = try Self.createLeaf(issuer: root, issuerKey: rootKey)

        let trustRoots = CertificateStore([root])
        let validator = X509ChainValidator()

        let result = await validator.validate(
            leaf: leaf,
            intermediates: [],
            trustRoots: trustRoots
        )

        #expect(result.isValid)
        #expect(result.chain != nil)
        #expect(result.error == nil)
    }

    @Test("Valid chain with intermediate")
    @available(macOS 11.0, iOS 14, tvOS 14, watchOS 7, macCatalyst 14, *)
    func validChainWithIntermediate() async throws {
        let (root, rootKey) = try Self.createRootCA()
        let (intermediate, intermediateKey) = try Self.createIntermediate(issuer: root, issuerKey: rootKey)
        let (leaf, _) = try Self.createLeaf(issuer: intermediate, issuerKey: intermediateKey)

        let trustRoots = CertificateStore([root])
        let validator = X509ChainValidator()

        let result = await validator.validate(
            leaf: leaf,
            intermediates: [intermediate],
            trustRoots: trustRoots
        )

        #expect(result.isValid)
        #expect(result.chain != nil)
    }

    @Test("Expired certificate fails validation")
    @available(macOS 11.0, iOS 14, tvOS 14, watchOS 7, macCatalyst 14, *)
    func expiredCertificate() async throws {
        let (root, rootKey) = try Self.createRootCA()

        // Create a certificate that expired yesterday
        let yesterday = Date().addingTimeInterval(-24 * 60 * 60)
        let lastWeek = Date().addingTimeInterval(-7 * 24 * 60 * 60)

        let (leaf, _) = try Self.createLeaf(
            issuer: root,
            issuerKey: rootKey,
            notBefore: lastWeek,
            notAfter: yesterday
        )

        let trustRoots = CertificateStore([root])
        let validator = X509ChainValidator()

        let result = await validator.validate(
            leaf: leaf,
            intermediates: [],
            trustRoots: trustRoots
        )

        #expect(result.isValid == false)
        #expect(result.error != nil)
    }

    @Test("Not yet valid certificate fails validation")
    @available(macOS 11.0, iOS 14, tvOS 14, watchOS 7, macCatalyst 14, *)
    func notYetValidCertificate() async throws {
        let (root, rootKey) = try Self.createRootCA()

        // Create a certificate that starts tomorrow
        let tomorrow = Date().addingTimeInterval(24 * 60 * 60)
        let nextWeek = Date().addingTimeInterval(7 * 24 * 60 * 60)

        let (leaf, _) = try Self.createLeaf(
            issuer: root,
            issuerKey: rootKey,
            notBefore: tomorrow,
            notAfter: nextWeek
        )

        let trustRoots = CertificateStore([root])
        let validator = X509ChainValidator()

        let result = await validator.validate(
            leaf: leaf,
            intermediates: [],
            trustRoots: trustRoots
        )

        #expect(result.isValid == false)
        #expect(result.error != nil)
    }

    @Test("Missing intermediate fails validation")
    @available(macOS 11.0, iOS 14, tvOS 14, watchOS 7, macCatalyst 14, *)
    func missingIntermediate() async throws {
        let (root, rootKey) = try Self.createRootCA()
        let (intermediate, intermediateKey) = try Self.createIntermediate(issuer: root, issuerKey: rootKey)
        let (leaf, _) = try Self.createLeaf(issuer: intermediate, issuerKey: intermediateKey)

        let trustRoots = CertificateStore([root])
        let validator = X509ChainValidator()

        // Don't provide the intermediate
        let result = await validator.validate(
            leaf: leaf,
            intermediates: [],
            trustRoots: trustRoots
        )

        #expect(result.isValid == false)
    }

    @Test("Untrusted root fails validation")
    @available(macOS 11.0, iOS 14, tvOS 14, watchOS 7, macCatalyst 14, *)
    func untrustedRoot() async throws {
        let (root, rootKey) = try Self.createRootCA(name: "Untrusted Root")
        let (trustedRoot, _) = try Self.createRootCA(name: "Trusted Root")
        let (leaf, _) = try Self.createLeaf(issuer: root, issuerKey: rootKey)

        // Trust a different root
        let trustRoots = CertificateStore([trustedRoot])
        let validator = X509ChainValidator()

        let result = await validator.validate(
            leaf: leaf,
            intermediates: [],
            trustRoots: trustRoots
        )

        #expect(result.isValid == false)
    }

    // MARK: - Convenience Method Tests

    @Test("isCurrentlyValid helper")
    @available(macOS 11.0, iOS 14, tvOS 14, watchOS 7, macCatalyst 14, *)
    func isCurrentlyValidHelper() throws {
        let (root, rootKey) = try Self.createRootCA()
        let (validCert, _) = try Self.createLeaf(issuer: root, issuerKey: rootKey)

        #expect(X509ChainValidator.isCurrentlyValid(validCert))

        // Check at a past date
        let pastDate = Date(timeIntervalSince1970: 0)
        #expect(X509ChainValidator.isCurrentlyValid(validCert, at: pastDate) == false)
    }

    @Test("isSelfSigned helper")
    @available(macOS 11.0, iOS 14, tvOS 14, watchOS 7, macCatalyst 14, *)
    func isSelfSignedHelper() throws {
        let (root, rootKey) = try Self.createRootCA()
        let (leaf, _) = try Self.createLeaf(issuer: root, issuerKey: rootKey)

        #expect(X509ChainValidator.isSelfSigned(root))
        #expect(X509ChainValidator.isSelfSigned(leaf) == false)
    }

    // MARK: - Database Validation

    @Test("Validate using certificate database")
    @available(macOS 11.0, iOS 14, tvOS 14, watchOS 7, macCatalyst 14, *)
    func validateWithDatabase() async throws {
        let db = try SqliteCertificateDatabase(inMemory: true, password: "test")

        let (root, rootKey) = try Self.createRootCA()
        let (intermediate, intermediateKey) = try Self.createIntermediate(issuer: root, issuerKey: rootKey)
        let (leaf, _) = try Self.createLeaf(issuer: intermediate, issuerKey: intermediateKey)

        // Add root as trusted anchor
        try db.add(X509CertificateRecord(certificate: root, isTrusted: true))
        // Add intermediate (not trusted)
        try db.add(X509CertificateRecord(certificate: intermediate, isTrusted: false))

        let validator = X509ChainValidator()
        let result = await validator.validate(leaf: leaf, database: db)

        #expect(result.isValid)
    }

    // MARK: - Store Validation

    @Test("Validate using certificate store")
    @available(macOS 11.0, iOS 14, tvOS 14, watchOS 7, macCatalyst 14, *)
    func validateWithStore() async throws {
        let (root, rootKey) = try Self.createRootCA()
        let (leaf, _) = try Self.createLeaf(issuer: root, issuerKey: rootKey)

        let store = X509CertificateStore()
        store.add(root)
        store.add(leaf)

        let validator = X509ChainValidator()
        let result = await validator.validate(store: store, certificate: leaf)

        #expect(result.isValid)
    }

    // MARK: - ChainValidationResult Tests

    @Test("ChainValidationResult success factory")
    @available(macOS 11.0, iOS 14, tvOS 14, watchOS 7, macCatalyst 14, *)
    func resultSuccessFactory() throws {
        let (root, _) = try Self.createRootCA()

        let result = ChainValidationResult.success(chain: [root])

        #expect(result.isValid)
        #expect(result.chain?.count == 1)
        #expect(result.error == nil)
    }

    @Test("ChainValidationResult failure factory")
    @available(macOS 11.0, iOS 14, tvOS 14, watchOS 7, macCatalyst 14, *)
    func resultFailureFactory() {
        let result = ChainValidationResult.failure(.noTrustAnchor)

        #expect(result.isValid == false)
        #expect(result.chain == nil)
        #expect(result.error != nil)

        if case .noTrustAnchor = result.error {
            #expect(true)
        } else {
            #expect(false, "Expected noTrustAnchor error")
        }
    }

    // MARK: - Error Description Tests

    @Test("ChainValidationError descriptions")
    @available(macOS 11.0, iOS 14, tvOS 14, watchOS 7, macCatalyst 14, *)
    func errorDescriptions() {
        let errors: [ChainValidationError] = [
            .noTrustAnchor,
            .expired(certificate: "test", expiredAt: Date()),
            .notYetValid(certificate: "test", validFrom: Date()),
            .invalidSignature(certificate: "test", reason: "bad sig"),
            .pathBuildingFailed("no path"),
            .revoked(certificate: "test"),
            .invalidExtension(certificate: "test", extension: "basicConstraints", reason: "missing"),
            .invalidKeyUsage(certificate: "test", requiredUsage: "digitalSignature"),
            .nameMismatch(certificate: "test", expectedName: "example.com"),
            .validationFailed("generic error")
        ]

        for error in errors {
            #expect(!error.description.isEmpty)
            #expect(!error.localizedDescription.isEmpty)
        }
    }
}
