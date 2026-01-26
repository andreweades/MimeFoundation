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
struct SqliteCertificateDatabaseTests {

    // MARK: - Test Certificate Creation

    @available(macOS 11.0, iOS 14, tvOS 14, watchOS 7, macCatalyst 14, *)
    private static func createTestCertificate(
        name: String = "Test",
        isCA: Bool = false
    ) throws -> (Certificate, Certificate.PrivateKey) {
        let privateKey = P256.Signing.PrivateKey()
        let certificatePrivateKey = Certificate.PrivateKey(privateKey)

        let dn = try DistinguishedName {
            CommonName(name)
            OrganizationName("MimeFoundation Tests")
        }

        let now = Date()
        let oneYear: TimeInterval = 365 * 24 * 60 * 60

        let certificate = try Certificate(
            version: .v3,
            serialNumber: Certificate.SerialNumber(),
            publicKey: certificatePrivateKey.publicKey,
            notValidBefore: now,
            notValidAfter: now.addingTimeInterval(oneYear),
            issuer: dn,
            subject: dn,
            signatureAlgorithm: .ecdsaWithSHA256,
            extensions: Certificate.Extensions {
                if isCA {
                    Critical(BasicConstraints.isCertificateAuthority(maxPathLength: nil))
                    Critical(KeyUsage(keyCertSign: true, cRLSign: true))
                } else {
                    Critical(BasicConstraints.notCertificateAuthority)
                    Critical(KeyUsage(digitalSignature: true))
                }
            },
            issuerPrivateKey: certificatePrivateKey
        )

        return (certificate, certificatePrivateKey)
    }

    // MARK: - Database Creation Tests

    @Test("Create in-memory database")
    @available(macOS 11.0, iOS 14, tvOS 14, watchOS 7, macCatalyst 14, *)
    func createInMemoryDatabase() throws {
        let db = try SqliteCertificateDatabase(inMemory: true, password: "test")
        #expect(db.count == 0)
    }

    @Test("Create file-based database")
    @available(macOS 11.0, iOS 14, tvOS 14, watchOS 7, macCatalyst 14, *)
    func createFileDatabase() throws {
        let tempDir = FileManager.default.temporaryDirectory
        let dbPath = tempDir.appendingPathComponent("test-\(UUID().uuidString).db").path

        defer {
            try? FileManager.default.removeItem(atPath: dbPath)
        }

        let db = try SqliteCertificateDatabase(path: dbPath, password: "test")
        #expect(db.count == 0)
    }

    // MARK: - CRUD Operations

    @Test("Add and find certificate")
    @available(macOS 11.0, iOS 14, tvOS 14, watchOS 7, macCatalyst 14, *)
    func addAndFind() throws {
        let db = try SqliteCertificateDatabase(inMemory: true, password: "test")
        let (cert, _) = try Self.createTestCertificate()
        let record = X509CertificateRecord(certificate: cert)

        try db.add(record)

        let found = db.find(fingerprint: record.fingerprint)
        #expect(found != nil)
        #expect(found?.fingerprint == record.fingerprint)
    }

    @Test("Add certificate with private key")
    @available(macOS 11.0, iOS 14, tvOS 14, watchOS 7, macCatalyst 14, *)
    func addWithPrivateKey() throws {
        let db = try SqliteCertificateDatabase(inMemory: true, password: "test")
        let (cert, key) = try Self.createTestCertificate()
        let record = X509CertificateRecord(certificate: cert, privateKey: key)

        try db.add(record)

        let found = db.find(fingerprint: record.fingerprint)
        #expect(found?.hasPrivateKey == true)
    }

    @Test("Add duplicate certificate is ignored")
    @available(macOS 11.0, iOS 14, tvOS 14, watchOS 7, macCatalyst 14, *)
    func addDuplicate() throws {
        let db = try SqliteCertificateDatabase(inMemory: true, password: "test")
        let (cert, _) = try Self.createTestCertificate()
        let record = X509CertificateRecord(certificate: cert)

        try db.add(record)
        try db.add(record) // Should not throw or duplicate

        #expect(db.count == 1)
    }

    @Test("Update certificate record")
    @available(macOS 11.0, iOS 14, tvOS 14, watchOS 7, macCatalyst 14, *)
    func updateRecord() throws {
        let db = try SqliteCertificateDatabase(inMemory: true, password: "test")
        let (cert, _) = try Self.createTestCertificate()
        var record = X509CertificateRecord(certificate: cert, isTrusted: false)

        try db.add(record)

        // Update trusted status
        record.isTrusted = true
        try db.update(record)

        let found = db.find(fingerprint: record.fingerprint)
        #expect(found?.isTrusted == true)
    }

    @Test("Remove certificate")
    @available(macOS 11.0, iOS 14, tvOS 14, watchOS 7, macCatalyst 14, *)
    func removeCertificate() throws {
        let db = try SqliteCertificateDatabase(inMemory: true, password: "test")
        let (cert, _) = try Self.createTestCertificate()
        let record = X509CertificateRecord(certificate: cert)

        try db.add(record)
        #expect(db.count == 1)

        let removed = try db.remove(record)
        #expect(removed == true)
        #expect(db.count == 0)
    }

    @Test("Remove nonexistent certificate returns false")
    @available(macOS 11.0, iOS 14, tvOS 14, watchOS 7, macCatalyst 14, *)
    func removeNonexistent() throws {
        let db = try SqliteCertificateDatabase(inMemory: true, password: "test")
        let (cert, _) = try Self.createTestCertificate()
        let record = X509CertificateRecord(certificate: cert)

        let removed = try db.remove(record)
        #expect(removed == false)
    }

    // MARK: - Trust Anchors

    @Test("Find trusted anchors")
    @available(macOS 11.0, iOS 14, tvOS 14, watchOS 7, macCatalyst 14, *)
    func findTrustedAnchors() throws {
        let db = try SqliteCertificateDatabase(inMemory: true, password: "test")

        let (rootCert, _) = try Self.createTestCertificate(name: "Root CA", isCA: true)
        let (intermediateCert, _) = try Self.createTestCertificate(name: "Intermediate CA", isCA: true)
        let (leafCert, _) = try Self.createTestCertificate(name: "Leaf")

        try db.add(X509CertificateRecord(certificate: rootCert, isTrusted: true))
        try db.add(X509CertificateRecord(certificate: intermediateCert, isTrusted: false))
        try db.add(X509CertificateRecord(certificate: leafCert, isTrusted: false))

        let anchors = db.findTrustedAnchors()
        #expect(anchors.count == 1)
        #expect(anchors.first?.subjectName.contains("Root CA") == true)
    }

    // MARK: - All Records

    @Test("Get all records")
    @available(macOS 11.0, iOS 14, tvOS 14, watchOS 7, macCatalyst 14, *)
    func getAllRecords() throws {
        let db = try SqliteCertificateDatabase(inMemory: true, password: "test")

        for i in 1...5 {
            let (cert, _) = try Self.createTestCertificate(name: "Cert \(i)")
            try db.add(X509CertificateRecord(certificate: cert))
        }

        let all = db.allRecords()
        #expect(all.count == 5)
    }

    // MARK: - Private Key Encryption at Rest

    @Test("Private key is encrypted at rest")
    @available(macOS 11.0, iOS 14, tvOS 14, watchOS 7, macCatalyst 14, *)
    func privateKeyEncryption() throws {
        let tempDir = FileManager.default.temporaryDirectory
        let dbPath = tempDir.appendingPathComponent("test-\(UUID().uuidString).db").path

        defer {
            try? FileManager.default.removeItem(atPath: dbPath)
        }

        let (cert, key) = try Self.createTestCertificate()

        // Create database and add certificate with key
        do {
            let db = try SqliteCertificateDatabase(path: dbPath, password: "correct-password")
            try db.add(X509CertificateRecord(certificate: cert, privateKey: key))
        }

        // Reopen with correct password
        do {
            let db = try SqliteCertificateDatabase(path: dbPath, password: "correct-password")
            let found = db.find(fingerprint: cert.sha256Fingerprint)
            #expect(found?.hasPrivateKey == true)
        }

        // Reopen with wrong password - key should not be decryptable
        do {
            let db = try SqliteCertificateDatabase(path: dbPath, password: "wrong-password")
            let found = db.find(fingerprint: cert.sha256Fingerprint)
            // Certificate should be found but private key decryption should fail
            #expect(found != nil)
            #expect(found?.hasPrivateKey == false) // Decryption failed silently
        }
    }

    // MARK: - Find with Predicate

    @Test("Find with custom predicate")
    @available(macOS 11.0, iOS 14, tvOS 14, watchOS 7, macCatalyst 14, *)
    func findWithPredicate() throws {
        let db = try SqliteCertificateDatabase(inMemory: true, password: "test")

        let (ca1, _) = try Self.createTestCertificate(name: "CA 1", isCA: true)
        let (ca2, _) = try Self.createTestCertificate(name: "CA 2", isCA: true)
        let (leaf, _) = try Self.createTestCertificate(name: "Leaf")

        try db.add(X509CertificateRecord(certificate: ca1))
        try db.add(X509CertificateRecord(certificate: ca2))
        try db.add(X509CertificateRecord(certificate: leaf))

        let cas = db.find { $0.basicConstraints >= 0 }
        #expect(cas.count == 2)
    }

    // MARK: - S/MIME Algorithms

    @Test("Store and retrieve S/MIME algorithms")
    @available(macOS 11.0, iOS 14, tvOS 14, watchOS 7, macCatalyst 14, *)
    func smimeAlgorithms() throws {
        let db = try SqliteCertificateDatabase(inMemory: true, password: "test")
        let (cert, _) = try Self.createTestCertificate()

        var record = X509CertificateRecord(certificate: cert)
        record.algorithms = [.aes256cbc, .aes128cbc, .des3cbc]
        record.algorithmsUpdated = Date()

        try db.add(record)

        let found = db.find(fingerprint: record.fingerprint)
        #expect(found?.algorithms?.count == 3)
        #expect(found?.algorithms?.contains(.aes256cbc) == true)
    }

    // MARK: - Protocol Compliance

    @Test("Database conforms to protocol")
    @available(macOS 11.0, iOS 14, tvOS 14, watchOS 7, macCatalyst 14, *)
    func protocolCompliance() throws {
        let db: X509CertificateDatabaseProtocol = try SqliteCertificateDatabase(inMemory: true, password: "test")

        let (cert, _) = try Self.createTestCertificate()
        try db.add(X509CertificateRecord(certificate: cert))

        #expect(db.count == 1)
        #expect(db.find(cert) != nil)
    }
}
