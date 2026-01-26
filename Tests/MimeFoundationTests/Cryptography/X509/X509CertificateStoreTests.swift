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
struct X509CertificateStoreTests {

    // MARK: - Test Certificate Creation

    @available(macOS 11.0, iOS 14, tvOS 14, watchOS 7, macCatalyst 14, *)
    private static func createTestCertificate(name: String = "Test") throws -> (Certificate, Certificate.PrivateKey) {
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
                Critical(BasicConstraints.notCertificateAuthority)
                Critical(KeyUsage(digitalSignature: true))
            },
            issuerPrivateKey: certificatePrivateKey
        )

        return (certificate, certificatePrivateKey)
    }

    // MARK: - Basic Operations

    @Test("Empty store has no certificates")
    @available(macOS 11.0, iOS 14, tvOS 14, watchOS 7, macCatalyst 14, *)
    func emptyStore() {
        let store = X509CertificateStore()

        #expect(store.isEmpty)
        #expect(store.count == 0)
        #expect(store.certificates.isEmpty)
    }

    @Test("Add and retrieve certificate")
    @available(macOS 11.0, iOS 14, tvOS 14, watchOS 7, macCatalyst 14, *)
    func addAndRetrieve() throws {
        let (cert, _) = try Self.createTestCertificate()
        let store = X509CertificateStore()

        store.add(cert)

        #expect(store.count == 1)
        #expect(store.contains(cert))

        let found = store.find(fingerprint: cert.sha256Fingerprint)
        #expect(found != nil)
    }

    @Test("Add certificate with private key")
    @available(macOS 11.0, iOS 14, tvOS 14, watchOS 7, macCatalyst 14, *)
    func addWithPrivateKey() throws {
        let (cert, key) = try Self.createTestCertificate()
        let store = X509CertificateStore()

        store.add(cert, privateKey: key)

        #expect(store.count == 1)

        let retrievedKey = store.privateKey(for: cert)
        #expect(retrievedKey != nil)
    }

    @Test("Add duplicate certificate is ignored")
    @available(macOS 11.0, iOS 14, tvOS 14, watchOS 7, macCatalyst 14, *)
    func addDuplicate() throws {
        let (cert, key) = try Self.createTestCertificate()
        let store = X509CertificateStore()

        store.add(cert)
        store.add(cert)
        store.add(cert, privateKey: key)

        #expect(store.count == 1)
    }

    @Test("Remove certificate")
    @available(macOS 11.0, iOS 14, tvOS 14, watchOS 7, macCatalyst 14, *)
    func removeCertificate() throws {
        let (cert, _) = try Self.createTestCertificate()
        let store = X509CertificateStore()

        store.add(cert)
        #expect(store.count == 1)

        let removed = store.remove(cert)
        #expect(removed == true)
        #expect(store.isEmpty)
    }

    @Test("Remove nonexistent certificate returns false")
    @available(macOS 11.0, iOS 14, tvOS 14, watchOS 7, macCatalyst 14, *)
    func removeNonexistent() throws {
        let (cert, _) = try Self.createTestCertificate()
        let store = X509CertificateStore()

        let removed = store.remove(cert)
        #expect(removed == false)
    }

    @Test("Remove all certificates")
    @available(macOS 11.0, iOS 14, tvOS 14, watchOS 7, macCatalyst 14, *)
    func removeAll() throws {
        let store = X509CertificateStore()

        for i in 1...5 {
            let (cert, _) = try Self.createTestCertificate(name: "Cert \(i)")
            store.add(cert)
        }

        #expect(store.count == 5)

        store.removeAll()
        #expect(store.isEmpty)
    }

    // MARK: - Finding Certificates

    @Test("Find certificates by predicate")
    @available(macOS 11.0, iOS 14, tvOS 14, watchOS 7, macCatalyst 14, *)
    func findByPredicate() throws {
        let store = X509CertificateStore()

        for i in 1...5 {
            let (cert, _) = try Self.createTestCertificate(name: "Cert \(i)")
            store.add(cert)
        }

        let found = store.find { cert in
            cert.subjectString.contains("Cert 3")
        }

        #expect(found.count == 1)
    }

    @Test("Find certificates with private keys")
    @available(macOS 11.0, iOS 14, tvOS 14, watchOS 7, macCatalyst 14, *)
    func findWithPrivateKeys() throws {
        let store = X509CertificateStore()

        let (cert1, key1) = try Self.createTestCertificate(name: "With Key")
        let (cert2, _) = try Self.createTestCertificate(name: "Without Key")

        store.add(cert1, privateKey: key1)
        store.add(cert2)

        let withKeys = store.certificatesWithPrivateKeys()
        #expect(withKeys.count == 1)
        #expect(withKeys.first?.sha256Fingerprint == cert1.sha256Fingerprint)
    }

    @Test("Find by fingerprint is case insensitive")
    @available(macOS 11.0, iOS 14, tvOS 14, watchOS 7, macCatalyst 14, *)
    func findFingerprintCaseInsensitive() throws {
        let (cert, _) = try Self.createTestCertificate()
        let store = X509CertificateStore()

        store.add(cert)

        let fingerprint = cert.sha256Fingerprint
        let found1 = store.find(fingerprint: fingerprint.lowercased())
        let found2 = store.find(fingerprint: fingerprint.uppercased())

        #expect(found1 != nil)
        #expect(found2 != nil)
    }

    // MARK: - Initialization Tests

    @Test("Initialize with certificates array")
    @available(macOS 11.0, iOS 14, tvOS 14, watchOS 7, macCatalyst 14, *)
    func initWithCertificates() throws {
        var certs: [Certificate] = []
        for i in 1...3 {
            let (cert, _) = try Self.createTestCertificate(name: "Cert \(i)")
            certs.append(cert)
        }

        let store = X509CertificateStore(certificates: certs)

        #expect(store.count == 3)
        for cert in certs {
            #expect(store.contains(cert))
        }
    }

    // MARK: - CertificateStore Integration

    @Test("Convert to CertificateStore")
    @available(macOS 11.0, iOS 14, tvOS 14, watchOS 7, macCatalyst 14, *)
    func asCertificateStore() throws {
        let store = X509CertificateStore()

        for i in 1...3 {
            let (cert, _) = try Self.createTestCertificate(name: "Cert \(i)")
            store.add(cert)
        }

        let certStore = store.asCertificateStore()
        // CertificateStore doesn't expose count, so we just verify it was created
        _ = certStore // Suppress unused warning
    }

    // MARK: - Thread Safety Tests

    @Test("Concurrent add operations")
    @available(macOS 11.0, iOS 14, tvOS 14, watchOS 7, macCatalyst 14, *)
    func concurrentAdd() async throws {
        let store = X509CertificateStore()

        // Create certificates first
        var certs: [Certificate] = []
        for i in 1...10 {
            let (cert, _) = try Self.createTestCertificate(name: "Cert \(i)")
            certs.append(cert)
        }

        // Add concurrently
        await withTaskGroup(of: Void.self) { group in
            for cert in certs {
                group.addTask {
                    store.add(cert)
                }
            }
        }

        #expect(store.count == 10)
    }

    @Test("Concurrent read and write operations")
    @available(macOS 11.0, iOS 14, tvOS 14, watchOS 7, macCatalyst 14, *)
    func concurrentReadWrite() async throws {
        let store = X509CertificateStore()

        // Pre-populate with some certificates
        for i in 1...5 {
            let (cert, _) = try Self.createTestCertificate(name: "Initial \(i)")
            store.add(cert)
        }

        // Concurrent reads and writes
        await withTaskGroup(of: Void.self) { group in
            // Readers
            for _ in 1...10 {
                group.addTask {
                    _ = store.count
                    _ = store.certificates
                }
            }

            // Writers
            for i in 1...5 {
                group.addTask {
                    if let (cert, _) = try? Self.createTestCertificate(name: "New \(i)") {
                        store.add(cert)
                    }
                }
            }
        }

        #expect(store.count == 10)
    }
}
