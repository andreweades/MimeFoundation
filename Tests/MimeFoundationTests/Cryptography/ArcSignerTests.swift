import Foundation
import Testing
import _CryptoExtras
@testable import MimeFoundation

/// A concrete test implementation of ArcSigner for testing purposes.
final class DummyArcSigner: ArcSigner {
    var publicKeyLocator: DkimPublicKeyLocator?
    var srvId: String = ""
    var testTimestamp: Int64 = 0

    override func generateArcAuthenticationResults(options: FormatOptions, message: MimeMessage) -> AuthenticationResults? {
        var results = AuthenticationResults(srvId)
        // Copy results from existing Authentication-Results headers
        for header in message.headers where header.id == .authenticationResults {
            if let authres = try? AuthenticationResults(parsing: header.value),
               authres.authenticationServiceIdentifier == srvId {
                for result in authres.results {
                    if !results.results.contains(where: { $0.method == result.method }) {
                        results.results.append(result)
                    }
                }
            }
        }
        return results
    }

    override func getTimestamp() -> Int64 {
        testTimestamp != 0 ? testTimestamp : super.getTimestamp()
    }
}

@Suite
struct ArcSignerTests {
    private static func loadRsaPrivateKey() throws -> DkimPrivateKey {
        let url = TestHelper.dataURL(for: "dkim/example.pem")
        let pem = try String(contentsOf: url, encoding: .utf8)
        let key = try _RSA.Signing.PrivateKey(unsafePEMRepresentation: pem)
        return .rsa(key)
    }

    @Test("ArcSigner constructor exceptions")
    func arcSignerConstructorExceptions() throws {
        let privateKey = try Self.loadRsaPrivateKey()

        #expect(throws: DkimSignerError.self) {
            _ = try DummyArcSigner(privateKey: privateKey, domain: "", selector: "selector")
        }
        #expect(throws: DkimSignerError.self) {
            _ = try DummyArcSigner(privateKey: privateKey, domain: "domain", selector: "")
        }
    }

    @Test("ArcSigner default property values")
    func arcSignerDefaults() throws {
        let privateKey = try Self.loadRsaPrivateKey()
        let signer = try DummyArcSigner(privateKey: privateKey, domain: "example.com", selector: "selector")

        #expect(signer.signatureAlgorithm == .rsaSha256)
        #expect(signer.bodyCanonicalizationAlgorithm == .simple)
        #expect(signer.headerCanonicalizationAlgorithm == .simple)
        #expect(signer.signaturesExpireAfter == nil)
    }

    @Test("ArcSigner sign with HeaderId array")
    func arcSignerSignWithHeaderIds() throws {
        let privateKey = try Self.loadRsaPrivateKey()
        let signer = try DummyArcSigner(privateKey: privateKey, domain: "example.com", selector: "1433868189.example")
        signer.srvId = "example.com"
        signer.testTimestamp = 1234567890

        let message = MimeMessage()
        message.from.add(MailboxAddress(name: "Test", address: "test@example.com"))
        message.to.add(MailboxAddress(name: "Recipient", address: "recipient@example.com"))
        message.subject = "Test Message"
        let body = TextPart("plain")
        body.text = "Hello, World!"
        message.body = body

        try signer.sign(message: message, headers: [.from, .to, .subject, .date])

        // Check that ARC headers were added
        let aarHeaders = message.headers.filter { $0.id == .arcAuthenticationResults }
        let amsHeaders = message.headers.filter { $0.id == .arcMessageSignature }
        let asHeaders = message.headers.filter { $0.id == .arcSeal }

        #expect(aarHeaders.count == 1)
        #expect(amsHeaders.count == 1)
        #expect(asHeaders.count == 1)

        // Verify instance numbers
        let aar = try AuthenticationResults(parsing: aarHeaders[0].value)
        #expect(aar.instance == 1)

        // Verify AMS contains i=1
        #expect(amsHeaders[0].value.contains("i=1"))

        // Verify AS contains i=1 and cv=none
        #expect(asHeaders[0].value.contains("i=1"))
        #expect(asHeaders[0].value.contains("cv=none"))
    }

    @Test("ArcSigner sign with String array")
    func arcSignerSignWithStrings() throws {
        let privateKey = try Self.loadRsaPrivateKey()
        let signer = try DummyArcSigner(privateKey: privateKey, domain: "example.com", selector: "1433868189.example")
        signer.srvId = "example.com"
        signer.testTimestamp = 1234567890

        let message = MimeMessage()
        message.from.add(MailboxAddress(name: "Test", address: "test@example.com"))
        message.to.add(MailboxAddress(name: "Recipient", address: "recipient@example.com"))
        message.subject = "Test Message"
        let body = TextPart("plain")
        body.text = "Hello, World!"
        message.body = body

        try signer.sign(message: message, headers: ["From", "To", "Subject", "Date"])

        // Check that ARC headers were added
        let aarHeaders = message.headers.filter { $0.id == .arcAuthenticationResults }
        let amsHeaders = message.headers.filter { $0.id == .arcMessageSignature }
        let asHeaders = message.headers.filter { $0.id == .arcSeal }

        #expect(aarHeaders.count == 1)
        #expect(amsHeaders.count == 1)
        #expect(asHeaders.count == 1)
    }

    @Test("ArcSigner sign with existing ARC chain")
    func arcSignerSignWithExistingChain() throws {
        let privateKey = try Self.loadRsaPrivateKey()
        let signer = try DummyArcSigner(privateKey: privateKey, domain: "example.com", selector: "1433868189.example")
        signer.srvId = "example.com"
        signer.testTimestamp = 1234567890

        let message = MimeMessage()
        message.from.add(MailboxAddress(name: "Test", address: "test@example.com"))
        message.to.add(MailboxAddress(name: "Recipient", address: "recipient@example.com"))
        message.subject = "Test Message"
        let body = TextPart("plain")
        body.text = "Hello, World!"
        message.body = body

        // Add first ARC set (simulating an existing chain)
        let existingAar = Header(.arcAuthenticationResults, value: "i=1; example.com; spf=pass")
        let existingAms = Header(.arcMessageSignature, value: "i=1; a=rsa-sha256; d=example.com; s=selector; c=relaxed/relaxed; h=from:to:subject; bh=base64hash; b=signature")
        let existingAs = Header(.arcSeal, value: "i=1; a=rsa-sha256; d=example.com; s=selector; cv=none; t=1234567890; b=signature")

        message.headers.insert(existingAs, at: 0)
        message.headers.insert(existingAms, at: 0)
        message.headers.insert(existingAar, at: 0)

        // Sign again (should create i=2)
        try signer.sign(message: message, headers: ["From", "To", "Subject"])

        // Check that new ARC headers were added
        let aarHeaders = message.headers.filter { $0.id == .arcAuthenticationResults }
        let amsHeaders = message.headers.filter { $0.id == .arcMessageSignature }
        let asHeaders = message.headers.filter { $0.id == .arcSeal }

        #expect(aarHeaders.count == 2)
        #expect(amsHeaders.count == 2)
        #expect(asHeaders.count == 2)

        // The newest headers should be first (i=2)
        let newAar = try AuthenticationResults(parsing: aarHeaders[0].value)
        #expect(newAar.instance == 2)

        // Verify new AS has cv=pass
        #expect(asHeaders[0].value.contains("i=2"))
        #expect(asHeaders[0].value.contains("cv=pass"))
    }

    @Test("ArcSigner header validation")
    func arcSignerHeaderValidation() throws {
        let privateKey = try Self.loadRsaPrivateKey()
        let signer = try DummyArcSigner(privateKey: privateKey, domain: "example.com", selector: "selector")
        signer.srvId = "example.com"

        let message = MimeMessage()
        message.from.add(MailboxAddress(name: "Test", address: "test@example.com"))
        message.subject = "Test"
        let body = TextPart("plain")
        body.text = "Hello"
        message.body = body

        // Should throw for empty header names
        #expect(throws: DkimSignerError.self) {
            try signer.sign(message: message, headers: ["", "From"])
        }

        // Should throw for unknown HeaderId
        #expect(throws: DkimSignerError.self) {
            try signer.sign(message: message, headers: [.unknown, .from])
        }

        // Should throw for headers in arcShouldNotInclude
        #expect(throws: DkimSignerError.self) {
            try signer.sign(message: message, headers: ["Return-Path", "From"])
        }
        #expect(throws: DkimSignerError.self) {
            try signer.sign(message: message, headers: ["Received", "From"])
        }
        #expect(throws: DkimSignerError.self) {
            try signer.sign(message: message, headers: ["ARC-Seal", "From"])
        }
        #expect(throws: DkimSignerError.self) {
            try signer.sign(message: message, headers: [.arcSeal, .from])
        }
    }

    @Test("ArcSigner arcShouldNotInclude contents")
    func arcSignerShouldNotInclude() {
        let shouldNotInclude = ArcSigner.arcShouldNotInclude
        #expect(shouldNotInclude.contains("return-path"))
        #expect(shouldNotInclude.contains("received"))
        #expect(shouldNotInclude.contains("comments"))
        #expect(shouldNotInclude.contains("keywords"))
        #expect(shouldNotInclude.contains("bcc"))
        #expect(shouldNotInclude.contains("resent-bcc"))
        #expect(shouldNotInclude.contains("arc-authentication-results"))
        #expect(shouldNotInclude.contains("arc-message-signature"))
        #expect(shouldNotInclude.contains("arc-seal"))
    }
}
