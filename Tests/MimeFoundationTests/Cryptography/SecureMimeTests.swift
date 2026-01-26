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
struct SecureMimeTests {
    // Helper to create a self-signed test certificate and private key
    @available(macOS 11.0, iOS 14, tvOS 14, watchOS 7, macCatalyst 14, *)
    private static func createTestCertificateAndKey() throws -> (Certificate, Certificate.PrivateKey) {
        let privateKey = P256.Signing.PrivateKey()
        let certificatePrivateKey = Certificate.PrivateKey(privateKey)

        let name = try DistinguishedName {
            CommonName("Test S/MIME Certificate")
            OrganizationName("MimeFoundation Tests")
            CountryName("US")
        }

        let now = Date()
        let oneYear: TimeInterval = 365 * 24 * 60 * 60

        let certificate = try Certificate(
            version: .v3,
            serialNumber: Certificate.SerialNumber(),
            publicKey: certificatePrivateKey.publicKey,
            notValidBefore: now,
            notValidAfter: now.addingTimeInterval(oneYear),
            issuer: name,
            subject: name,
            signatureAlgorithm: .ecdsaWithSHA256,
            extensions: Certificate.Extensions {
                Critical(
                    BasicConstraints.notCertificateAuthority
                )
                Critical(
                    KeyUsage(digitalSignature: true)
                )
            },
            issuerPrivateKey: certificatePrivateKey
        )

        return (certificate, certificatePrivateKey)
    }

    // MARK: - DigestAlgorithm Tests

    @Test("DigestAlgorithm micalg conversion")
    func digestAlgorithmMicalg() {
        #expect(DigestAlgorithm.sha256.micalg == "sha-256")
        #expect(DigestAlgorithm.sha384.micalg == "sha-384")
        #expect(DigestAlgorithm.sha512.micalg == "sha-512")
        #expect(DigestAlgorithm.sha1.micalg == "sha-1")
        #expect(DigestAlgorithm.md5.micalg == "md5")
        #expect(DigestAlgorithm.none.micalg == "")
    }

    @Test("DigestAlgorithm from micalg string")
    func digestAlgorithmFromMicalg() {
        #expect(DigestAlgorithm(micalg: "sha-256") == .sha256)
        #expect(DigestAlgorithm(micalg: "sha256") == .sha256)
        #expect(DigestAlgorithm(micalg: "SHA-256") == .sha256)
        #expect(DigestAlgorithm(micalg: "sha-384") == .sha384)
        #expect(DigestAlgorithm(micalg: "sha-512") == .sha512)
        #expect(DigestAlgorithm(micalg: "sha-1") == .sha1)
        #expect(DigestAlgorithm(micalg: "md5") == .md5)
        #expect(DigestAlgorithm(micalg: nil) == .none)
        #expect(DigestAlgorithm(micalg: "unknown") == .none)
    }

    @Test("DigestAlgorithm OID conversion")
    func digestAlgorithmOid() {
        #expect(DigestAlgorithm.sha256.oid == "2.16.840.1.101.3.4.2.1")
        #expect(DigestAlgorithm.sha384.oid == "2.16.840.1.101.3.4.2.2")
        #expect(DigestAlgorithm.sha512.oid == "2.16.840.1.101.3.4.2.3")
        #expect(DigestAlgorithm.sha1.oid == "1.3.14.3.2.26")
        #expect(DigestAlgorithm.md5.oid == "1.2.840.113549.2.5")
    }

    // MARK: - SecureMimeType Tests

    @Test("SecureMimeType from smime-type parameter")
    func secureMimeTypeFromParameter() {
        #expect(SecureMimeType(smimeType: "signed-data") == .signedData)
        #expect(SecureMimeType(smimeType: "enveloped-data") == .envelopedData)
        #expect(SecureMimeType(smimeType: "compressed-data") == .compressedData)
        #expect(SecureMimeType(smimeType: "certs-only") == .certsOnly)
        #expect(SecureMimeType(smimeType: "authenveloped-data") == .authEnvelopedData)
        #expect(SecureMimeType(smimeType: nil) == .unknown)
        #expect(SecureMimeType(smimeType: "unknown-type") == .unknown)
    }

    // MARK: - CmsSigner Tests

    @Test("CmsSigner creation with certificate and key")
    func cmsSignerCreation() throws {
        guard #available(macOS 11.0, iOS 14, tvOS 14, watchOS 7, macCatalyst 14, *) else {
            return
        }

        let (certificate, privateKey) = try Self.createTestCertificateAndKey()

        let signer = CmsSigner(
            certificate: certificate,
            privateKey: privateKey,
            digestAlgorithm: .sha256
        )

        #expect(signer.digestAlgorithm == .sha256)
        #expect(signer.certificateChain.isEmpty)
    }

    @Test("CmsSigner with certificate chain")
    func cmsSignerWithChain() throws {
        guard #available(macOS 11.0, iOS 14, tvOS 14, watchOS 7, macCatalyst 14, *) else {
            return
        }

        let (certificate, privateKey) = try Self.createTestCertificateAndKey()
        let (intermediateCert, _) = try Self.createTestCertificateAndKey()

        let signer = CmsSigner(
            certificate: certificate,
            privateKey: privateKey,
            certificateChain: [intermediateCert],
            digestAlgorithm: .sha384
        )

        #expect(signer.digestAlgorithm == .sha384)
        #expect(signer.certificateChain.count == 1)
    }

    // MARK: - ApplicationPkcs7Signature Tests

    @Test("ApplicationPkcs7Signature creation")
    func applicationPkcs7SignatureCreation() {
        let signature = ApplicationPkcs7Signature()

        #expect(signature.contentType.isMimeType("application", "pkcs7-signature"))
        #expect(signature.contentTransferEncoding == .base64)
    }

    @Test("ApplicationPkcs7Signature from bytes")
    func applicationPkcs7SignatureFromBytes() throws {
        let testBytes: [UInt8] = [0x30, 0x00] // Minimal DER sequence

        let signature = ApplicationPkcs7Signature(testBytes)

        #expect(signature.content != nil)
        let bytes = try signature.getSignatureBytes()
        #expect(bytes == testBytes)
    }

    // MARK: - MultipartSigned Tests

    @Test("MultipartSigned creation")
    func multipartSignedCreation() {
        guard #available(macOS 11.0, iOS 14, tvOS 14, watchOS 7, macCatalyst 14, *) else {
            return
        }

        let signed = MultipartSigned()

        #expect(signed.contentType.isMimeType("multipart", "signed"))
    }

    @Test("MultipartSigned create with signer")
    func multipartSignedCreateWithSigner() throws {
        guard #available(macOS 11.0, iOS 14, tvOS 14, watchOS 7, macCatalyst 14, *) else {
            return
        }

        let (certificate, privateKey) = try Self.createTestCertificateAndKey()

        let signer = CmsSigner(
            certificate: certificate,
            privateKey: privateKey,
            digestAlgorithm: .sha256
        )

        let textPart = TextPart("plain")
        textPart.text = "Hello, S/MIME World!"

        let signed = try MultipartSigned.create(textPart, signer: signer)

        #expect(signed.count == 2)
        #expect(signed.signatureProtocol == "application/pkcs7-signature")
        #expect(signed.micalg == "sha-256")
        #expect(signed.signedContent != nil)
        #expect(signed.signature != nil)
    }

    @Test("MultipartSigned round-trip serialization")
    func multipartSignedRoundTrip() throws {
        guard #available(macOS 11.0, iOS 14, tvOS 14, watchOS 7, macCatalyst 14, *) else {
            return
        }

        let (certificate, privateKey) = try Self.createTestCertificateAndKey()

        let signer = CmsSigner(
            certificate: certificate,
            privateKey: privateKey,
            digestAlgorithm: .sha256
        )

        let originalText = "This is the signed content."
        let textPart = TextPart("plain")
        textPart.text = originalText

        let signed = try MultipartSigned.create(textPart, signer: signer)

        // Serialize to bytes
        let stream = MemoryStream()
        try signed.writeTo(stream)
        let serialized = stream.toByteArray()

        // Parse back
        _ = try stream.seek(0, origin: .begin)
        let parsed = try MimeMessage.parseEntity(.default, serialized)

        #expect(parsed is MultipartSigned)

        if let parsedSigned = parsed as? MultipartSigned {
            #expect(parsedSigned.count == 2)
            #expect(parsedSigned.signatureProtocol == "application/pkcs7-signature")

            if let content = parsedSigned.signedContent as? TextPart {
                #expect(content.text?.contains("signed content") == true)
            }
        }
    }

    // MARK: - SecureMimeContext Tests

    @Test("SecureMimeContext sign content")
    func secureMimeContextSign() throws {
        guard #available(macOS 11.0, iOS 14, tvOS 14, watchOS 7, macCatalyst 14, *) else {
            return
        }

        let (certificate, privateKey) = try Self.createTestCertificateAndKey()

        let signer = CmsSigner(
            certificate: certificate,
            privateKey: privateKey,
            digestAlgorithm: .sha256
        )

        let context = DefaultSecureMimeContext()
        let content: [UInt8] = Array("Test content to sign".utf8)

        let signatureBytes = try context.sign(signer, content: content, detached: true)

        // Verify we got a CMS signature (should start with SEQUENCE tag 0x30)
        #expect(!signatureBytes.isEmpty)
        #expect(signatureBytes[0] == 0x30)
    }

    @Test("SecureMimeContext create signature part")
    func secureMimeContextCreateSignature() throws {
        guard #available(macOS 11.0, iOS 14, tvOS 14, watchOS 7, macCatalyst 14, *) else {
            return
        }

        let (certificate, privateKey) = try Self.createTestCertificateAndKey()

        let signer = CmsSigner(
            certificate: certificate,
            privateKey: privateKey,
            digestAlgorithm: .sha256
        )

        let context = DefaultSecureMimeContext()
        let textPart = TextPart("plain")
        textPart.text = "Content to sign"

        let signaturePart = try context.createSignature(signer, entity: textPart)

        #expect(signaturePart.contentType.isMimeType("application", "pkcs7-signature"))
        let signatureBytes = try signaturePart.getSignatureBytes()
        #expect(!signatureBytes.isEmpty)
    }

    // MARK: - DigitalSignature Tests

    @Test("DigitalSignatureCollection validity checks")
    func digitalSignatureCollectionValidity() throws {
        guard #available(macOS 11.0, iOS 14, tvOS 14, watchOS 7, macCatalyst 14, *) else {
            return
        }

        let (certificate, _) = try Self.createTestCertificateAndKey()

        let validSignature = DigitalSignature(
            signerCertificate: certificate,
            digestAlgorithm: .sha256,
            creationDate: Date(),
            isValid: true
        )

        let invalidSignature = DigitalSignature(
            signerCertificate: certificate,
            digestAlgorithm: .sha256,
            creationDate: Date(),
            isValid: false
        )

        let allValid = DigitalSignatureCollection([validSignature])
        #expect(allValid.allValid)
        #expect(allValid.anyValid)
        #expect(allValid.validSignatures.count == 1)
        #expect(allValid.invalidSignatures.isEmpty)

        let mixed = DigitalSignatureCollection([validSignature, invalidSignature])
        #expect(!mixed.allValid)
        #expect(mixed.anyValid)
        #expect(mixed.validSignatures.count == 1)
        #expect(mixed.invalidSignatures.count == 1)

        let allInvalid = DigitalSignatureCollection([invalidSignature])
        #expect(!allInvalid.allValid)
        #expect(!allInvalid.anyValid)
    }

    // MARK: - MimeVisitor Tests

    @Test("MimeVisitor visits ApplicationPkcs7Signature")
    func mimeVisitorVisitsSignature() {
        class TestVisitor: MimeVisitor {
            var visitedSignature = false

            func visit(_ signature: ApplicationPkcs7Signature) {
                visitedSignature = true
            }
        }

        let signature = ApplicationPkcs7Signature()
        let visitor = TestVisitor()
        signature.accept(visitor)

        #expect(visitor.visitedSignature)
    }

    @Test("MimeVisitor visits MultipartSigned")
    func mimeVisitorVisitsSigned() throws {
        guard #available(macOS 11.0, iOS 14, tvOS 14, watchOS 7, macCatalyst 14, *) else {
            return
        }

        class TestVisitor: MimeVisitor {
            var visitedSigned = false

            @available(macOS 11.0, iOS 14, tvOS 14, watchOS 7, macCatalyst 14, *)
            func visit(_ signed: MultipartSigned) {
                visitedSigned = true
            }
        }

        let signed = MultipartSigned()
        let visitor = TestVisitor()
        signed.accept(visitor)

        #expect(visitor.visitedSigned)
    }

    // MARK: - Parser Tests

    @Test("Parser creates MultipartSigned for multipart/signed")
    func parserCreatesMultipartSigned() throws {
        guard #available(macOS 11.0, iOS 14, tvOS 14, watchOS 7, macCatalyst 14, *) else {
            return
        }

        let (certificate, privateKey) = try Self.createTestCertificateAndKey()

        let signer = CmsSigner(
            certificate: certificate,
            privateKey: privateKey,
            digestAlgorithm: .sha256
        )

        let textPart = TextPart("plain")
        textPart.text = "Signed content"

        let signed = try MultipartSigned.create(textPart, signer: signer)

        // Serialize and re-parse
        let stream = MemoryStream()
        try signed.writeTo(stream)

        let parsed = try MimeMessage.parseEntity(.default, stream.toByteArray())

        #expect(parsed is MultipartSigned)
    }

    @Test("Parser creates ApplicationPkcs7Signature for application/pkcs7-signature")
    func parserCreatesApplicationPkcs7Signature() throws {
        let signature = ApplicationPkcs7Signature([0x30, 0x00])

        // Serialize and re-parse
        let stream = MemoryStream()
        try signature.writeTo(stream)

        let parsed = try MimeMessage.parseEntity(.default, stream.toByteArray())

        #expect(parsed is ApplicationPkcs7Signature)
    }

    // MARK: - ApplicationPkcs7Mime Tests

    @Test("ApplicationPkcs7Mime creation")
    func applicationPkcs7MimeCreation() {
        let mime = ApplicationPkcs7Mime()

        #expect(mime.contentType.isMimeType("application", "pkcs7-mime"))
        #expect(mime.contentTransferEncoding == .base64)
    }

    @Test("ApplicationPkcs7Mime with smime-type")
    func applicationPkcs7MimeWithSmimeType() {
        let mime = ApplicationPkcs7Mime(smimeType: .envelopedData)

        #expect(mime.smimeType == .envelopedData)
        #expect(mime.contentType.parameters["smime-type"] == "enveloped-data")
    }

    @Test("Parser creates ApplicationPkcs7Mime for application/pkcs7-mime")
    func parserCreatesApplicationPkcs7Mime() throws {
        let mime = ApplicationPkcs7Mime([0x30, 0x00], smimeType: .envelopedData)

        // Serialize and re-parse
        let stream = MemoryStream()
        try mime.writeTo(stream)

        let parsed = try MimeMessage.parseEntity(.default, stream.toByteArray())

        #expect(parsed is ApplicationPkcs7Mime)
        if let parsedMime = parsed as? ApplicationPkcs7Mime {
            #expect(parsedMime.smimeType == .envelopedData)
        }
    }

    // MARK: - CmsRecipient Tests

    @Test("CmsRecipient creation")
    func cmsRecipientCreation() throws {
        guard #available(macOS 11.0, iOS 14, tvOS 14, watchOS 7, macCatalyst 14, *) else {
            return
        }

        let (certificate, _) = try Self.createTestCertificateAndKey()

        let recipient = CmsRecipient(certificate: certificate)

        #expect(recipient.certificate == certificate)
    }

    @Test("CmsRecipientCollection operations")
    func cmsRecipientCollectionOperations() throws {
        guard #available(macOS 11.0, iOS 14, tvOS 14, watchOS 7, macCatalyst 14, *) else {
            return
        }

        let (cert1, _) = try Self.createTestCertificateAndKey()
        let (cert2, _) = try Self.createTestCertificateAndKey()

        var collection = CmsRecipientCollection()
        #expect(collection.isEmpty)

        collection.add(CmsRecipient(certificate: cert1))
        #expect(collection.count == 1)

        collection.add(certificate: cert2)
        #expect(collection.count == 2)
    }

    // MARK: - Encryption Context Tests

    @Test("DefaultSecureMimeContext does not support encryption")
    func defaultContextNoEncryption() throws {
        guard #available(macOS 11.0, iOS 14, tvOS 14, watchOS 7, macCatalyst 14, *) else {
            return
        }

        let context = DefaultSecureMimeContext()

        #expect(!context.supportsEncryption)
        #expect(!context.supportsDecryption)
    }

    #if os(macOS)
    @Test("AppleSecureMimeContext supports encryption on macOS")
    func appleContextSupportsEncryption() throws {
        guard #available(macOS 11.0, *) else {
            return
        }

        let context = AppleSecureMimeContext()

        #expect(context.supportsEncryption)
        #expect(context.supportsDecryption)
    }
    #endif

    @Test("MimeVisitor visits ApplicationPkcs7Mime")
    func mimeVisitorVisitsEncryptedMime() {
        class TestVisitor: MimeVisitor {
            var visitedEncrypted = false

            func visit(_ encryptedMime: ApplicationPkcs7Mime) {
                visitedEncrypted = true
            }
        }

        let mime = ApplicationPkcs7Mime()
        let visitor = TestVisitor()
        mime.accept(visitor)

        #expect(visitor.visitedEncrypted)
    }

    // MARK: - PKCS#12 Import Tests
    //
    // Note: Due to key format incompatibilities between Apple's Security framework
    // and swift-crypto, PKCS#12 import for CmsSigner currently only extracts
    // the certificate. For signing, users should convert their PKCS#12 to PEM:
    //   openssl pkcs12 -in file.p12 -nocerts -nodes -out key.pem
    //   openssl pkcs12 -in file.p12 -clcerts -nokeys -out cert.pem

    #if canImport(Security)
    /// Loads test PKCS#12 data from the test resources.
    private static func loadTestPkcs12() throws -> Data {
        let url = TestHelper.dataURL(for: "smime/test.p12")
        return try Data(contentsOf: url)
    }

    @Test("SecPKCS12Import extracts certificate from PKCS#12")
    func secPkcs12ImportCertificate() throws {
        guard #available(macOS 11.0, iOS 14, tvOS 14, watchOS 7, macCatalyst 14, *) else {
            return
        }

        let pkcs12Data = try Self.loadTestPkcs12()

        // Import using Security framework directly to verify the file is valid
        let options: [String: Any] = [
            kSecImportExportPassphrase as String: "test123"
        ]

        var items: CFArray?
        let status = SecPKCS12Import(pkcs12Data as CFData, options as CFDictionary, &items)

        #expect(status == errSecSuccess)
        let itemsArray = items as? [[String: Any]]
        #expect(itemsArray != nil)
        #expect(!itemsArray!.isEmpty)

        // Verify identity was extracted
        let identity = itemsArray![0][kSecImportItemIdentity as String]
        #expect(identity != nil)
    }

    @Test("SecPKCS12Import fails with wrong password")
    func secPkcs12ImportWrongPassword() throws {
        guard #available(macOS 11.0, iOS 14, tvOS 14, watchOS 7, macCatalyst 14, *) else {
            return
        }

        let pkcs12Data = try Self.loadTestPkcs12()

        let options: [String: Any] = [
            kSecImportExportPassphrase as String: "wrongpassword"
        ]

        var items: CFArray?
        let status = SecPKCS12Import(pkcs12Data as CFData, options as CFDictionary, &items)

        // Should fail with authentication error
        #expect(status != errSecSuccess)
    }

    @Test("CmsSigner from PEM files created alongside PKCS#12")
    func cmsSignerFromPemFiles() throws {
        guard #available(macOS 11.0, iOS 14, tvOS 14, watchOS 7, macCatalyst 14, *) else {
            return
        }

        // Load the PEM files that were created alongside the PKCS#12
        let certPath = TestHelper.dataURL(for: "smime/test-cert.pem").path
        let keyPath = TestHelper.dataURL(for: "smime/test-key.pem").path

        let signer = try CmsSigner(
            certificatePath: certPath,
            privateKeyPath: keyPath,
            digestAlgorithm: .sha256
        )

        #expect(signer.digestAlgorithm == .sha256)

        // Verify we can sign with it
        let context = DefaultSecureMimeContext()
        let content: [UInt8] = Array("Test content".utf8)
        let signature = try context.sign(signer, content: content, detached: true)

        #expect(!signature.isEmpty)
        #expect(signature[0] == 0x30) // DER SEQUENCE tag
    }

    @Test("CmsSigner from PEM can create MultipartSigned")
    func cmsSignerPemMultipartSigned() throws {
        guard #available(macOS 11.0, iOS 14, tvOS 14, watchOS 7, macCatalyst 14, *) else {
            return
        }

        let certPath = TestHelper.dataURL(for: "smime/test-cert.pem").path
        let keyPath = TestHelper.dataURL(for: "smime/test-key.pem").path

        let signer = try CmsSigner(
            certificatePath: certPath,
            privateKeyPath: keyPath,
            digestAlgorithm: .sha256
        )

        let textPart = TextPart("plain")
        textPart.text = "Signed with PEM certificate"

        let signed = try MultipartSigned.create(textPart, signer: signer)

        #expect(signed.count == 2)
        #expect(signed.signedContent != nil)
        #expect(signed.signature != nil)
    }

    @Test("Generate signed message for OpenSSL verification")
    func generateSignedMessageForOpenSSL() throws {
        guard #available(macOS 11.0, iOS 14, tvOS 14, watchOS 7, macCatalyst 14, *) else {
            return
        }

        // Load the PEM files
        let certPath = TestHelper.dataURL(for: "smime/test-cert.pem").path
        let keyPath = TestHelper.dataURL(for: "smime/test-key.pem").path

        let signer = try CmsSigner(
            certificatePath: certPath,
            privateKeyPath: keyPath,
            digestAlgorithm: .sha256
        )

        // Create a complete MIME message
        let message = MimeMessage()
        message.from.add(MailboxAddress(name: "Test Sender", address: "sender@example.com"))
        message.to.add(MailboxAddress(name: "Test Recipient", address: "recipient@example.com"))
        message.subject = "S/MIME Signed Test Message"

        let textPart = TextPart("plain")
        textPart.text = "This is a test message that has been digitally signed using S/MIME.\n\nIt should be verifiable with OpenSSL."

        // Sign the message
        let signed = try MultipartSigned.create(textPart, signer: signer)
        message.body = signed

        // Write to temp file for OpenSSL verification
        let tempDir = FileManager.default.temporaryDirectory
        let messagePath = tempDir.appendingPathComponent("signed-message.eml")
        let certDestPath = tempDir.appendingPathComponent("test-cert.pem")

        // Serialize the message
        let stream = MemoryStream()
        try message.writeTo(stream)
        let messageData = stream.toByteArray()

        try Data(messageData).write(to: messagePath)

        // Copy the certificate for verification (remove existing first)
        try? FileManager.default.removeItem(at: certDestPath)
        try FileManager.default.copyItem(
            at: URL(fileURLWithPath: certPath),
            to: certDestPath
        )

        print("""

        ============================================================
        Signed message written to: \(messagePath.path)
        Certificate written to: \(certDestPath.path)

        To verify with OpenSSL, run:
        openssl smime -verify -in "\(messagePath.path)" -CAfile "\(certDestPath.path)" -noverify

        Note: -noverify skips CA chain validation (self-signed cert)
        ============================================================

        """)

        // Basic verification that the message was created correctly
        #expect(message.body is MultipartSigned)
        #expect(messageData.count > 0)
    }
    #endif

    // MARK: - Encapsulated Signing Tests

    @Test("ApplicationPkcs7Mime encapsulated signing")
    func encapsulatedSigning() throws {
        guard #available(macOS 11.0, iOS 14, tvOS 14, watchOS 7, macCatalyst 14, *) else {
            return
        }

        let (certificate, privateKey) = try Self.createTestCertificateAndKey()
        let signer = CmsSigner(certificate: certificate, privateKey: privateKey, digestAlgorithm: .sha256)

        let cleartext = TextPart("plain")
        cleartext.text = "This is some text that we'll end up signing..."

        let signed = try ApplicationPkcs7Mime.sign(cleartext, signer: signer)

        #expect(signed.smimeType == .signedData)
        #expect(signed.contentType.mediaType == "application")
        #expect(signed.contentType.mediaSubtype == "pkcs7-mime")
        #expect(signed.contentType.parameters["smime-type"] == "signed-data")
        #expect(signed.contentType.parameters["name"] == "smime.p7m")
        
        let contentBytes = try signed.getContentBytes()
        #expect(!contentBytes.isEmpty)
        #expect(contentBytes[0] == 0x30) // SEQUENCE (CMS)
    }

    @Test("ApplicationPkcs7Mime encapsulated signing (async)")
    func encapsulatedSigningAsync() async throws {
        guard #available(macOS 11.0, iOS 14, tvOS 14, watchOS 7, macCatalyst 14, *) else {
            return
        }

        let (certificate, privateKey) = try Self.createTestCertificateAndKey()
        let signer = CmsSigner(certificate: certificate, privateKey: privateKey, digestAlgorithm: .sha256)

        let cleartext = TextPart("plain")
        cleartext.text = "This is some text that we'll end up signing..."

        let signed = try await ApplicationPkcs7Mime.signAsync(cleartext, signer: signer)

        #expect(signed.smimeType == .signedData)
        #expect(signed.contentType.parameters["smime-type"] == "signed-data")
    }

    // MARK: - Encryption Tests

    @Test("ApplicationPkcs7Mime encryption")
    func encryption() throws {
        guard #available(macOS 11.0, iOS 14, tvOS 14, watchOS 7, macCatalyst 14, *) else {
            return
        }

        let (certificate, _) = try Self.createTestCertificateAndKey()
        var recipients = CmsRecipientCollection()
        recipients.add(certificate: certificate)

        let cleartext = TextPart("plain")
        cleartext.text = "This is some text that we'll end up encrypting..."

        do {
            let encrypted = try ApplicationPkcs7Mime.encrypt(cleartext, recipients: recipients)
            #expect(encrypted.smimeType == .envelopedData)
            #expect(encrypted.contentType.parameters["smime-type"] == "enveloped-data")
            #expect(encrypted.contentType.parameters["name"] == "smime.p7m")
        } catch SecureMimeError.unsupportedAlgorithm {
            // Expected on non-macOS or DefaultContext
        } catch {
            // If it fails with another error, rethrow
            throw error
        }
    }
    
    @Test("ApplicationPkcs7Mime encryption (async)")
    func encryptionAsync() async throws {
        guard #available(macOS 11.0, iOS 14, tvOS 14, watchOS 7, macCatalyst 14, *) else {
            return
        }

        let (certificate, _) = try Self.createTestCertificateAndKey()
        var recipients = CmsRecipientCollection()
        recipients.add(certificate: certificate)

        let cleartext = TextPart("plain")
        cleartext.text = "This is some text that we'll end up encrypting..."

        do {
            let encrypted = try await ApplicationPkcs7Mime.encryptAsync(cleartext, recipients: recipients)
            #expect(encrypted.smimeType == .envelopedData)
        } catch SecureMimeError.unsupportedAlgorithm {
            // Expected
        } catch {
            throw error
        }
    }
}
