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
}
