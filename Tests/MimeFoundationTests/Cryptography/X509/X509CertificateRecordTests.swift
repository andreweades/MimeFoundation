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
struct X509CertificateRecordTests {

    // MARK: - Test Certificate Creation

    @available(macOS 11.0, iOS 14, tvOS 14, watchOS 7, macCatalyst 14, *)
    private static func createTestCertificate(
        email: String? = nil,
        dnsNames: [String] = [],
        isCA: Bool = false,
        keyUsage: KeyUsage? = nil
    ) throws -> (Certificate, Certificate.PrivateKey) {
        let privateKey = P256.Signing.PrivateKey()
        let certificatePrivateKey = Certificate.PrivateKey(privateKey)

        let name = try DistinguishedName {
            CommonName("Test Certificate")
            OrganizationName("MimeFoundation Tests")
        }

        let now = Date()
        let oneSecondAgo = now.addingTimeInterval(-1) // Ensure cert is already valid
        let oneYear: TimeInterval = 365 * 24 * 60 * 60

        let certificate = try Certificate(
            version: .v3,
            serialNumber: Certificate.SerialNumber(),
            publicKey: certificatePrivateKey.publicKey,
            notValidBefore: oneSecondAgo,
            notValidAfter: now.addingTimeInterval(oneYear),
            issuer: name,
            subject: name,
            signatureAlgorithm: .ecdsaWithSHA256,
            extensions: Certificate.Extensions {
                if isCA {
                    Critical(BasicConstraints.isCertificateAuthority(maxPathLength: nil))
                    Critical(KeyUsage(keyCertSign: true, cRLSign: true))
                } else {
                    Critical(BasicConstraints.notCertificateAuthority)
                    if let ku = keyUsage {
                        Critical(ku)
                    } else {
                        Critical(KeyUsage(digitalSignature: true))
                    }
                }
            },
            issuerPrivateKey: certificatePrivateKey
        )

        return (certificate, certificatePrivateKey)
    }

    // MARK: - Record Creation Tests

    @Test("X509CertificateRecord creation from certificate")
    @available(macOS 11.0, iOS 14, tvOS 14, watchOS 7, macCatalyst 14, *)
    func recordCreation() throws {
        let (cert, key) = try Self.createTestCertificate()

        let record = X509CertificateRecord(
            certificate: cert,
            privateKey: key,
            isTrusted: true
        )

        #expect(record.isTrusted == true)
        #expect(record.hasPrivateKey == true)
        #expect(record.id == 0)
    }

    @Test("X509CertificateRecord computes fingerprint")
    @available(macOS 11.0, iOS 14, tvOS 14, watchOS 7, macCatalyst 14, *)
    func fingerprintComputation() throws {
        let (cert, _) = try Self.createTestCertificate()
        let record = X509CertificateRecord(certificate: cert)

        let fingerprint = record.fingerprint
        #expect(fingerprint.count == 64) // SHA-256 = 32 bytes = 64 hex chars
        #expect(fingerprint == fingerprint.lowercased())
    }

    @Test("X509CertificateRecord extracts key usage")
    @available(macOS 11.0, iOS 14, tvOS 14, watchOS 7, macCatalyst 14, *)
    func keyUsageExtraction() throws {
        let ku = KeyUsage(digitalSignature: true, keyEncipherment: true)
        let (cert, _) = try Self.createTestCertificate(keyUsage: ku)
        let record = X509CertificateRecord(certificate: cert)

        #expect(record.keyUsage.contains(.digitalSignature))
        #expect(record.keyUsage.contains(.keyEncipherment))
        #expect(!record.keyUsage.contains(.keyCertSign))
    }

    @Test("X509CertificateRecord detects CA certificates")
    @available(macOS 11.0, iOS 14, tvOS 14, watchOS 7, macCatalyst 14, *)
    func caDetection() throws {
        let (caCert, _) = try Self.createTestCertificate(isCA: true)
        let caRecord = X509CertificateRecord(certificate: caCert, isTrusted: true)

        let (eeCert, _) = try Self.createTestCertificate(isCA: false)
        let eeRecord = X509CertificateRecord(certificate: eeCert)

        #expect(caRecord.isAnchor == true)
        #expect(eeRecord.isAnchor == false)
    }

    @Test("X509CertificateRecord validity checking")
    @available(macOS 11.0, iOS 14, tvOS 14, watchOS 7, macCatalyst 14, *)
    func validityChecking() throws {
        let (cert, _) = try Self.createTestCertificate()
        let record = X509CertificateRecord(certificate: cert)

        #expect(record.isValid == true)

        // Check at a specific time
        let pastDate = Date(timeIntervalSince1970: 0)
        #expect(record.isValid(at: pastDate) == false)
    }

    // MARK: - Equality Tests

    @Test("X509CertificateRecord equality based on fingerprint")
    @available(macOS 11.0, iOS 14, tvOS 14, watchOS 7, macCatalyst 14, *)
    func recordEquality() throws {
        let (cert, key) = try Self.createTestCertificate()

        let record1 = X509CertificateRecord(certificate: cert)
        let record2 = X509CertificateRecord(certificate: cert, privateKey: key, isTrusted: true)

        // Same fingerprint means equal, regardless of other properties
        #expect(record1 == record2)
        #expect(record1.hashValue == record2.hashValue)
    }
}
