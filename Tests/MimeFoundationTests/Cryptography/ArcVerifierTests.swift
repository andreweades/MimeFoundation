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
import _CryptoExtras
@testable import MimeFoundation

@Suite
struct ArcVerifierTests {
    private final class DummyPublicKeyLocator: DkimPublicKeyLocator {
        private let key: DkimPublicKey

        init(_ key: DkimPublicKey) {
            self.key = key
        }

        func locatePublicKey(methods: String, domain: String, selector: String) throws -> DkimPublicKey {
            key
        }

        func locatePublicKeyAsync(methods: String, domain: String, selector: String) async throws -> DkimPublicKey {
            key
        }
    }

    private static func loadRsaPublicKey() throws -> DkimPublicKey {
        let url = TestHelper.dataURL(for: "dkim/example.pub")
        let pem = try String(contentsOf: url, encoding: .utf8)
        let key = try _RSA.Signing.PublicKey(unsafePEMRepresentation: pem)
        return .rsa(key)
    }

    private static func loadRsaPrivateKey() throws -> DkimPrivateKey {
        let url = TestHelper.dataURL(for: "dkim/example.pem")
        let pem = try String(contentsOf: url, encoding: .utf8)
        let key = try _RSA.Signing.PrivateKey(unsafePEMRepresentation: pem)
        return .rsa(key)
    }

    @Test("ArcVerifier defaults")
    func arcVerifierDefaults() throws {
        let publicKey = try Self.loadRsaPublicKey()
        let verifier = ArcVerifier(publicKeyLocator: DummyPublicKeyLocator(publicKey))

        #expect(verifier.minimumRsaKeyLength == 1024)
        #expect(verifier.isEnabled(.rsaSha1) == false)
        #expect(verifier.isEnabled(.rsaSha256) == true)
        #expect(verifier.isEnabled(.ed25519Sha256) == true)
    }

    @Test("ArcVerifier enable/disable")
    func arcVerifierEnableDisable() throws {
        let publicKey = try Self.loadRsaPublicKey()
        let verifier = ArcVerifier(publicKeyLocator: DummyPublicKeyLocator(publicKey))

        #expect(verifier.isEnabled(.rsaSha1) == false)
        verifier.enable(.rsaSha1)
        #expect(verifier.isEnabled(.rsaSha1) == true)
        verifier.disable(.rsaSha1)
        #expect(verifier.isEnabled(.rsaSha1) == false)
    }

    // MARK: - ArcHeaderValidationResult Tests

    @Test("ArcHeaderValidationResult properties")
    func arcHeaderValidationResultProperties() throws {
        let header = Header(.arcSeal, value: "test")
        let result = ArcHeaderValidationResult(header: header, signature: .pass)

        #expect(result.header.id == .arcSeal)
        #expect(result.signature == .pass)
    }

    // MARK: - ArcValidationResult Tests

    @Test("ArcValidationResult none")
    func arcValidationResultNone() {
        let result = ArcValidationResult.none

        #expect(result.messageSignature == nil)
        #expect(result.seals.isEmpty)
        #expect(result.chain == .none)
        #expect(result.chainErrors.isEmpty)
    }

    @Test("ArcValidationResult properties")
    func arcValidationResultProperties() throws {
        let amsHeader = Header(.arcMessageSignature, value: "test")
        let asHeader = Header(.arcSeal, value: "test")

        let messageSignature = ArcHeaderValidationResult(header: amsHeader, signature: .pass)
        let seal = ArcHeaderValidationResult(header: asHeader, signature: .pass)

        let result = ArcValidationResult(
            messageSignature: messageSignature,
            seals: [seal],
            chain: .pass,
            chainErrors: []
        )

        #expect(result.messageSignature?.header.id == .arcMessageSignature)
        #expect(result.messageSignature?.signature == .pass)
        #expect(result.seals.count == 1)
        #expect(result.seals[0].header.id == .arcSeal)
        #expect(result.chain == .pass)
        #expect(result.chainErrors.isEmpty)
    }

    // MARK: - GetArcHeaderSets Tests

    @Test("GetArcHeaderSets with no ARC headers")
    func getArcHeaderSetsEmpty() throws {
        let message = MimeMessage()
        message.from.add(MailboxAddress(name: "Test", address: "test@example.com"))
        message.subject = "Test"
        let body = TextPart("plain")
        body.text = "Hello"
        message.body = body

        let result = try ArcVerifier.getArcHeaderSets(message: message, throwOnError: false)

        #expect(result.count == 0)
        #expect(result.sets.isEmpty)
        #expect(result.errors.isEmpty)
        #expect(result.result == .none)
    }

    @Test("GetArcHeaderSets with broken AAR - unparsable")
    func getArcHeaderSetsBrokenAarUnparsable() throws {
        let message = MimeMessage()
        message.from.add(MailboxAddress(name: "Test", address: "test@example.com"))
        message.body = TextPart("plain")

        // Add invalid AAR (missing required fields)
        let aar = Header(.arcAuthenticationResults, value: "!!invalid!!")
        message.headers.insert(aar, at: 0)

        let result = try ArcVerifier.getArcHeaderSets(message: message, throwOnError: false)
        #expect(result.errors.contains(.invalidArcAuthenticationResults))
    }

    @Test("GetArcHeaderSets with broken AAR - missing instance")
    func getArcHeaderSetsBrokenAarMissingInstance() throws {
        let message = MimeMessage()
        message.from.add(MailboxAddress(name: "Test", address: "test@example.com"))
        message.body = TextPart("plain")

        // Add AAR without instance
        let aar = Header(.arcAuthenticationResults, value: "example.com; spf=pass")
        message.headers.insert(aar, at: 0)

        let result = try ArcVerifier.getArcHeaderSets(message: message, throwOnError: false)
        #expect(result.errors.contains(.invalidArcAuthenticationResults))
    }

    @Test("GetArcHeaderSets with broken AMS - unparsable")
    func getArcHeaderSetsBrokenAmsUnparsable() throws {
        let message = MimeMessage()
        message.from.add(MailboxAddress(name: "Test", address: "test@example.com"))
        message.body = TextPart("plain")

        // Add invalid AMS
        let ams = Header(.arcMessageSignature, value: "!!invalid!!")
        message.headers.insert(ams, at: 0)

        let result = try ArcVerifier.getArcHeaderSets(message: message, throwOnError: false)
        #expect(result.errors.contains(.invalidArcMessageSignature))
    }

    @Test("GetArcHeaderSets with broken AMS - missing instance")
    func getArcHeaderSetsBrokenAmsMissingInstance() throws {
        let message = MimeMessage()
        message.from.add(MailboxAddress(name: "Test", address: "test@example.com"))
        message.body = TextPart("plain")

        // Add AMS without instance
        let ams = Header(.arcMessageSignature, value: "a=rsa-sha256; d=example.com; s=selector; c=relaxed/relaxed; h=from; bh=hash; b=sig")
        message.headers.insert(ams, at: 0)

        let result = try ArcVerifier.getArcHeaderSets(message: message, throwOnError: false)
        #expect(result.errors.contains(.invalidArcMessageSignature))
    }

    @Test("GetArcHeaderSets with broken AMS - invalid instance")
    func getArcHeaderSetsBrokenAmsInvalidInstance() throws {
        let message = MimeMessage()
        message.from.add(MailboxAddress(name: "Test", address: "test@example.com"))
        message.body = TextPart("plain")

        // Add AMS with invalid instance (0 or negative)
        let ams = Header(.arcMessageSignature, value: "i=0; a=rsa-sha256; d=example.com; s=selector; c=relaxed/relaxed; h=from; bh=hash; b=sig")
        message.headers.insert(ams, at: 0)

        let result = try ArcVerifier.getArcHeaderSets(message: message, throwOnError: false)
        #expect(result.errors.contains(.invalidArcMessageSignature))
    }

    @Test("GetArcHeaderSets with broken AS - unparsable")
    func getArcHeaderSetsBrokenAsUnparsable() throws {
        let message = MimeMessage()
        message.from.add(MailboxAddress(name: "Test", address: "test@example.com"))
        message.body = TextPart("plain")

        // Add invalid AS
        let seal = Header(.arcSeal, value: "!!invalid!!")
        message.headers.insert(seal, at: 0)

        let result = try ArcVerifier.getArcHeaderSets(message: message, throwOnError: false)
        #expect(result.errors.contains(.invalidArcSeal))
    }

    @Test("GetArcHeaderSets with broken AS - missing instance")
    func getArcHeaderSetsBrokenAsMissingInstance() throws {
        let message = MimeMessage()
        message.from.add(MailboxAddress(name: "Test", address: "test@example.com"))
        message.body = TextPart("plain")

        // Add AS without instance
        let seal = Header(.arcSeal, value: "a=rsa-sha256; d=example.com; s=selector; cv=none; t=1234567890; b=sig")
        message.headers.insert(seal, at: 0)

        let result = try ArcVerifier.getArcHeaderSets(message: message, throwOnError: false)
        #expect(result.errors.contains(.invalidArcSeal))
    }

    @Test("GetArcHeaderSets with broken AS - invalid instance")
    func getArcHeaderSetsBrokenAsInvalidInstance() throws {
        let message = MimeMessage()
        message.from.add(MailboxAddress(name: "Test", address: "test@example.com"))
        message.body = TextPart("plain")

        // Add AS with invalid instance
        let seal = Header(.arcSeal, value: "i=-1; a=rsa-sha256; d=example.com; s=selector; cv=none; t=1234567890; b=sig")
        message.headers.insert(seal, at: 0)

        let result = try ArcVerifier.getArcHeaderSets(message: message, throwOnError: false)
        #expect(result.errors.contains(.invalidArcSeal))
    }

    @Test("GetArcHeaderSets with broken AS - invalid cv")
    func getArcHeaderSetsBrokenAsInvalidCv() throws {
        let message = MimeMessage()
        message.from.add(MailboxAddress(name: "Test", address: "test@example.com"))
        message.body = TextPart("plain")

        // Add AS with invalid cv value
        let seal = Header(.arcSeal, value: "i=1; a=rsa-sha256; d=example.com; s=selector; cv=invalid; t=1234567890; b=sig")
        message.headers.insert(seal, at: 0)

        let result = try ArcVerifier.getArcHeaderSets(message: message, throwOnError: false)
        #expect(result.errors.contains(.invalidArcSealChainValidationValue))
    }

    @Test("GetArcHeaderSets with missing cv")
    func getArcHeaderSetsMissingCv() throws {
        let message = MimeMessage()
        message.from.add(MailboxAddress(name: "Test", address: "test@example.com"))
        message.body = TextPart("plain")

        // Add AS without cv
        let seal = Header(.arcSeal, value: "i=1; a=rsa-sha256; d=example.com; s=selector; t=1234567890; b=sig")
        message.headers.insert(seal, at: 0)

        let result = try ArcVerifier.getArcHeaderSets(message: message, throwOnError: false)
        #expect(result.errors.contains(.missingArcSealChainValidationValue))
    }

    @Test("GetArcHeaderSets with cv=fail returns fail result")
    func getArcHeaderSetsCvFail() throws {
        let message = MimeMessage()
        message.from.add(MailboxAddress(name: "Test", address: "test@example.com"))
        message.body = TextPart("plain")

        // Add AS with cv=fail (instance 2+)
        let seal = Header(.arcSeal, value: "i=2; a=rsa-sha256; d=example.com; s=selector; cv=fail; t=1234567890; b=sig")
        message.headers.insert(seal, at: 0)

        let result = try ArcVerifier.getArcHeaderSets(message: message, throwOnError: false)
        #expect(result.result == .fail)
    }

    @Test("GetArcHeaderSets with missing headers")
    func getArcHeaderSetsMissingHeaders() throws {
        let message = MimeMessage()
        message.from.add(MailboxAddress(name: "Test", address: "test@example.com"))
        message.body = TextPart("plain")

        // Add only AAR for instance 1 (missing AMS and AS)
        let aar = Header(.arcAuthenticationResults, value: "i=1; example.com; spf=pass")
        message.headers.insert(aar, at: 0)

        let result = try ArcVerifier.getArcHeaderSets(message: message, throwOnError: false)
        #expect(result.errors.contains(.missingArcMessageSignature))
        #expect(result.errors.contains(.missingArcSeal))
    }

    @Test("GetArcHeaderSets with duplicate headers")
    func getArcHeaderSetsDuplicateHeaders() throws {
        let message = MimeMessage()
        message.from.add(MailboxAddress(name: "Test", address: "test@example.com"))
        message.body = TextPart("plain")

        // Add duplicate AAR for instance 1
        let aar1 = Header(.arcAuthenticationResults, value: "i=1; example.com; spf=pass")
        let aar2 = Header(.arcAuthenticationResults, value: "i=1; example.com; dkim=pass")
        message.headers.insert(aar1, at: 0)
        message.headers.insert(aar2, at: 0)

        let result = try ArcVerifier.getArcHeaderSets(message: message, throwOnError: false)
        #expect(result.errors.contains(.duplicateArcAuthenticationResults))
    }

    @Test("GetArcHeaderSets with instance 1 cv not none")
    func getArcHeaderSetsInstance1CvNotNone() throws {
        let message = MimeMessage()
        message.from.add(MailboxAddress(name: "Test", address: "test@example.com"))
        message.body = TextPart("plain")

        // Add AS instance 1 with cv=pass (should be cv=none)
        let seal = Header(.arcSeal, value: "i=1; a=rsa-sha256; d=example.com; s=selector; cv=pass; t=1234567890; b=sig")
        message.headers.insert(seal, at: 0)

        let result = try ArcVerifier.getArcHeaderSets(message: message, throwOnError: false)
        #expect(result.errors.contains(.invalidArcSealChainValidationValue))
    }

    @Test("GetArcHeaderSets with complete valid chain")
    func getArcHeaderSetsValidChain() throws {
        let message = MimeMessage()
        message.from.add(MailboxAddress(name: "Test", address: "test@example.com"))
        message.body = TextPart("plain")

        // Add complete ARC set for instance 1
        let aar = Header(.arcAuthenticationResults, value: "i=1; example.com; spf=pass")
        let ams = Header(.arcMessageSignature, value: "i=1; a=rsa-sha256; d=example.com; s=selector; c=relaxed/relaxed; h=from; bh=hash; b=sig")
        let seal = Header(.arcSeal, value: "i=1; a=rsa-sha256; d=example.com; s=selector; cv=none; t=1234567890; b=sig")

        message.headers.insert(seal, at: 0)
        message.headers.insert(ams, at: 0)
        message.headers.insert(aar, at: 0)

        let result = try ArcVerifier.getArcHeaderSets(message: message, throwOnError: false)
        #expect(result.count == 1)
        #expect(result.sets.count == 1)
        #expect(result.errors.isEmpty)
        #expect(result.result == .pass)
        #expect(result.sets[0].arcAuthenticationResults != nil)
        #expect(result.sets[0].arcMessageSignature != nil)
        #expect(result.sets[0].arcSeal != nil)
    }

    // MARK: - ArcValidationErrors Tests

    @Test("ArcValidationErrors OptionSet")
    func arcValidationErrorsOptionSet() {
        var errors: ArcValidationErrors = []
        #expect(errors.isEmpty)

        errors.insert(.duplicateArcAuthenticationResults)
        #expect(errors.contains(.duplicateArcAuthenticationResults))
        #expect(!errors.contains(.duplicateArcMessageSignature))

        errors.insert(.duplicateArcMessageSignature)
        #expect(errors.contains(.duplicateArcAuthenticationResults))
        #expect(errors.contains(.duplicateArcMessageSignature))

        errors.remove(.duplicateArcAuthenticationResults)
        #expect(!errors.contains(.duplicateArcAuthenticationResults))
        #expect(errors.contains(.duplicateArcMessageSignature))
    }

    // MARK: - Full Chain Verification Tests

    @Test("Verify message with no ARC chain returns none")
    func verifyNoArcChain() throws {
        let publicKey = try Self.loadRsaPublicKey()
        let verifier = ArcVerifier(publicKeyLocator: DummyPublicKeyLocator(publicKey))

        let message = MimeMessage()
        message.from.add(MailboxAddress(name: "Test", address: "test@example.com"))
        message.subject = "Test"
        let body = TextPart("plain")
        body.text = "Hello"
        message.body = body

        let result = try verifier.verify(message: message)
        #expect(result.chain == .none)
        #expect(result.messageSignature == nil)
        #expect(result.seals.isEmpty)
    }

    @Test("Sign and verify ARC chain")
    func signAndVerifyArcChain() throws {
        let privateKey = try Self.loadRsaPrivateKey()
        let publicKey = try Self.loadRsaPublicKey()

        // Create signer
        let signer = try DummyArcSigner(privateKey: privateKey, domain: "example.com", selector: "1433868189.example")
        signer.srvId = "example.com"
        signer.testTimestamp = 1234567890
        signer.headerCanonicalizationAlgorithm = .relaxed
        signer.bodyCanonicalizationAlgorithm = .relaxed

        // Create message
        let message = MimeMessage()
        message.from.add(MailboxAddress(name: "Test", address: "test@example.com"))
        message.to.add(MailboxAddress(name: "Recipient", address: "recipient@example.com"))
        message.subject = "Test Message"
        let body = TextPart("plain")
        body.text = "Hello, World!"
        message.body = body

        // Sign the message
        try signer.sign(message: message, headers: ["From", "To", "Subject"])

        // Create verifier
        let verifier = ArcVerifier(publicKeyLocator: DummyPublicKeyLocator(publicKey))

        // Verify the chain
        let result = try verifier.verify(message: message)

        #expect(result.chain == .pass)
        #expect(result.messageSignature?.signature == .pass)
        #expect(result.seals.count == 1)
        #expect(result.seals[0].signature == .pass)
        #expect(result.chainErrors.isEmpty)
    }

    @Test("Verify async returns same result as sync")
    func verifyAsyncSameAsSync() async throws {
        let privateKey = try Self.loadRsaPrivateKey()
        let publicKey = try Self.loadRsaPublicKey()

        // Create signer
        let signer = try DummyArcSigner(privateKey: privateKey, domain: "example.com", selector: "1433868189.example")
        signer.srvId = "example.com"
        signer.testTimestamp = 1234567890
        signer.headerCanonicalizationAlgorithm = .relaxed
        signer.bodyCanonicalizationAlgorithm = .relaxed

        // Create message
        let message = MimeMessage()
        message.from.add(MailboxAddress(name: "Test", address: "test@example.com"))
        message.subject = "Test Message"
        let body = TextPart("plain")
        body.text = "Hello!"
        message.body = body

        // Sign the message
        try signer.sign(message: message, headers: ["From", "Subject"])

        // Create verifier
        let verifier = ArcVerifier(publicKeyLocator: DummyPublicKeyLocator(publicKey))

        // Verify sync
        let syncResult = try verifier.verify(message: message)

        // Verify async
        let asyncResult = try await verifier.verifyAsync(message: message)

        #expect(syncResult.chain == asyncResult.chain)
        #expect(syncResult.messageSignature?.signature == asyncResult.messageSignature?.signature)
        #expect(syncResult.seals.count == asyncResult.seals.count)
    }
}
