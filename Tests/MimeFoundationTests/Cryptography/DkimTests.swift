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
import Crypto
import _CryptoExtras
@testable import MimeFoundation

@Suite
struct DkimTests {
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

    private static func loadGmailPublicKey() throws -> DkimPublicKey {
        let url = TestHelper.dataURL(for: "dkim/gmail.pub")
        let pem = try String(contentsOf: url, encoding: .utf8)
        let base64 = pem
            .components(separatedBy: .newlines)
            .filter { !$0.hasPrefix("-----") && !$0.isEmpty }
            .joined()
        guard let der = Data(base64Encoded: base64, options: [.ignoreUnknownCharacters]) else {
            throw DkimVerifierError.invalidKey
        }
        let key = try _RSA.Signing.PublicKey(unsafeDERRepresentation: der)
        return .rsa(key)
    }

    private static func loadEd25519PrivateKey() throws -> DkimPrivateKey {
        guard let data = Data(base64Encoded: "nWGxne/9WmC6hEr0kuwsxERJxWl7MmkZcDusAxyuf2A=") else {
            throw DkimSignerError.invalidPrivateKey
        }
        let key = try Curve25519.Signing.PrivateKey(rawRepresentation: data)
        return .ed25519(key)
    }

    private static func createSigner(_ algorithm: DkimSignatureAlgorithm, headerAlgorithm: DkimCanonicalizationAlgorithm, bodyAlgorithm: DkimCanonicalizationAlgorithm) throws -> DkimSigner {
        let filePath = TestHelper.dataURL(for: "dkim/example.pem").path
        let signer = try DkimSigner(filePath: filePath, domain: "example.com", selector: "1433868189.example")
        signer.signatureAlgorithm = algorithm
        signer.headerCanonicalizationAlgorithm = headerAlgorithm
        signer.bodyCanonicalizationAlgorithm = bodyAlgorithm
        signer.agentOrUserIdentifier = "@eng.example.com"
        signer.queryMethod = "dns/txt"
        return signer
    }

    private static func loadMessage(_ name: String) throws -> MimeMessage {
        let data = try TestHelper.loadData(relativePath: "dkim/\(name)")
        return try MimeMessage.load(MemoryStream(data, writable: false))
    }

    private final class InMemoryDkimPublicKeyLocator: DkimPublicKeyLocatorBase {
        private var records: [String: String] = [:]

        func add(_ key: String, _ value: String) {
            records[key] = value
        }

        override func locatePublicKey(methods: String, domain: String, selector: String) throws -> DkimPublicKey {
            let query = "\(selector)._domainkey.\(domain)"
            guard let value = records[query] else {
                throw ParseException("Public key parameters not found in DNS TXT record.", tokenIndex: 0, errorIndex: 0)
            }
            return try Self.getPublicKey(value)
        }

        override func locatePublicKeyAsync(methods: String, domain: String, selector: String) async throws -> DkimPublicKey {
            try locatePublicKey(methods: methods, domain: domain, selector: selector)
        }
    }

    @Test("Dkim signatures expiration header value")
    func dkimSignaturesExpirationHeaderValue() throws {
        let signer = try Self.createSigner(.rsaSha1, headerAlgorithm: .simple, bodyAlgorithm: .simple)
        signer.signaturesExpireAfter = 24 * 60 * 60

        let headers: [HeaderId] = [.from, .to, .subject, .date]
        let message = MimeMessage()

        message.from.add(MailboxAddress(name: "", address: "mimekit@example.com"))
        message.to.add(MailboxAddress(name: "", address: "mimekit@example.com"))
        message.subject = "This is an empty message"
        message.date = DateTimeOffset(date: Date(), offsetMinutes: 0)
        let body = TextPart("plain")
        body.text = ""
        message.body = body

        try message.prepare(.sevenBit)
        try signer.sign(message, headers: headers)

        guard let headerValue = message.headers[.dkimSignature] else {
            Issue.record("Missing DKIM-Signature header")
            return
        }

        var timestamp: Int64?
        var expiration: Int64?
        for param in headerValue.split(separator: ";") {
            let trimmed = param.trimmingCharacters(in: .whitespacesAndNewlines)
            if trimmed.hasPrefix("t=") {
                timestamp = Int64(trimmed.dropFirst(2))
            } else if trimmed.hasPrefix("x=") {
                expiration = Int64(trimmed.dropFirst(2))
            }
        }

        #expect(timestamp != nil)
        #expect(expiration != nil)
        if let timestamp, let expiration {
            #expect(expiration - timestamp == 24 * 60 * 60)
        }
    }

    private static func verifyDkimBodyHash(_ message: MimeMessage, expectedHash: String) -> Bool {
        guard let value = message.headers[.dkimSignature] else { return false }
        for param in value.split(separator: ";") {
            let trimmed = param.trimmingCharacters(in: .whitespacesAndNewlines)
            if trimmed.hasPrefix("bh=") {
                return trimmed.dropFirst(3) == expectedHash
            }
        }
        return false
    }

    private static func testEmptyBody(signatureAlgorithm: DkimSignatureAlgorithm, bodyAlgorithm: DkimCanonicalizationAlgorithm, expectedHash: String) throws {
        let signer = try createSigner(signatureAlgorithm, headerAlgorithm: .simple, bodyAlgorithm: bodyAlgorithm)
        let headers: [HeaderId] = [.from, .to, .subject, .date]
        let verifier = DkimVerifier(publicKeyLocator: DummyPublicKeyLocator(try loadRsaPublicKey()))
        let message = MimeMessage()

        message.from.add(MailboxAddress(name: "", address: "mimekit@example.com"))
        message.to.add(MailboxAddress(name: "", address: "mimekit@example.com"))
        message.subject = "This is an empty message"
        message.date = DateTimeOffset(date: Date(), offsetMinutes: 0)
        let body = TextPart("plain")
        body.text = ""
        message.body = body

        try message.prepare(.sevenBit)
        try signer.sign(message, headers: headers)

        #expect(verifyDkimBodyHash(message, expectedHash: expectedHash))

        let dkimHeader = message.headers[0]

        if signatureAlgorithm == .rsaSha1 {
            #expect(try verifier.verify(message, dkimHeader) == false)
            verifier.enable(.rsaSha1)
        }

        #expect(try verifier.verify(message, dkimHeader) == true)
    }

    @Test("Empty body hashes and verification")
    func emptyBodyHashesAndVerification() throws {
        try Self.testEmptyBody(signatureAlgorithm: .rsaSha1, bodyAlgorithm: .simple, expectedHash: "uoq1oCgLlTqpdDX/iUbLy7J1Wic=")
        try Self.testEmptyBody(signatureAlgorithm: .rsaSha256, bodyAlgorithm: .simple, expectedHash: "frcCV1k9oG9oKj3dpUqdJg1PxRT2RSN/XKdLCPjaYaY=")
        try Self.testEmptyBody(signatureAlgorithm: .rsaSha1, bodyAlgorithm: .relaxed, expectedHash: "2jmj7l5rSw0yVb/vlWAYkK/YBwk=")
        try Self.testEmptyBody(signatureAlgorithm: .rsaSha256, bodyAlgorithm: .relaxed, expectedHash: "47DEQpj8HBSa+/TImW+5JCeuQeRkm5NMpJWZG3hSuFU=")
    }

    private static func testUnicode(signatureAlgorithm: DkimSignatureAlgorithm, bodyAlgorithm: DkimCanonicalizationAlgorithm, expectedHash: String) throws {
        let signer = try createSigner(signatureAlgorithm, headerAlgorithm: .simple, bodyAlgorithm: bodyAlgorithm)
        let headers: [HeaderId] = [.from, .to, .subject, .date]
        let verifier = DkimVerifier(publicKeyLocator: DummyPublicKeyLocator(try loadRsaPublicKey()))
        let message = MimeMessage()

        message.from.add(MailboxAddress(name: "", address: "mimekit@example.com"))
        message.to.add(MailboxAddress(name: "", address: "mimekit@example.com"))
        message.subject = "This is a unicode message"
        message.date = DateTimeOffset(date: Date(), offsetMinutes: 0)

        let builder = BodyBuilder()
        builder.textBody = " تست  "
        builder.htmlBody = "  <div> تست </div> "
        message.body = try builder.toMessageBody()

        if let multipart = message.body as? Multipart {
            try multipart.setBoundary("=-MultipartAlternativeBoundary")
            multipart[1].contentId = nil
        }

        try message.prepare(.eightBit)

        try signer.sign(message, headers: headers)

        let dkimHeader = message.headers[0]
        #expect(verifyDkimBodyHash(message, expectedHash: expectedHash))

        if signatureAlgorithm == .rsaSha1 {
            #expect(try verifier.verify(message, dkimHeader) == false)
            verifier.enable(.rsaSha1)
        }

        #expect(try verifier.verify(message, dkimHeader) == true)
    }

    @Test("Unicode body hashes and verification")
    func unicodeBodyHashesAndVerification() throws {
        try Self.testUnicode(signatureAlgorithm: .rsaSha1, bodyAlgorithm: .simple, expectedHash: "6GV1ZoyaprYbwRLXsr5+8zY5Jh0=")
        try Self.testUnicode(signatureAlgorithm: .rsaSha256, bodyAlgorithm: .simple, expectedHash: "BuW/GpCA9rAVDfStp0Dc2duuFhmwcxhy5jOeL+Xn+ew=")
        try Self.testUnicode(signatureAlgorithm: .rsaSha1, bodyAlgorithm: .relaxed, expectedHash: "bbT6nP0aAiAP5OMguA+mHgpzgh4=")
        try Self.testUnicode(signatureAlgorithm: .rsaSha256, bodyAlgorithm: .relaxed, expectedHash: "PEaN3fYH5NdIg4QzgaSS+ceYlSMRnYbqCPMxncx6gy0=")
    }

    @Test("DKIM format exceptions")
    func dkimFormatExceptions() throws {
        let message = try Self.loadMessage("gmail.msg")
        let verifier = DkimVerifier(publicKeyLocator: DummyPublicKeyLocator(try Self.loadGmailPublicKey()))

        guard let index = message.headers.firstIndex(where: { $0.id == .dkimSignature }) else {
            Issue.record("Missing DKIM-Signature header")
            return
        }

        let dkim = message.headers[index]
        let original = dkim.value

        dkim.value = String(original.dropFirst(4))
        #expect(throws: DkimVerifierError.self) {
            _ = try verifier.verify(message, dkim)
        }

        dkim.value = "v=x; " + original
        #expect(throws: DkimVerifierError.self) {
            _ = try verifier.verify(message, dkim)
        }

        dkim.value = original.replacingOccurrences(of: "from:", with: "")
        #expect(throws: DkimVerifierError.self) {
            _ = try verifier.verify(message, dkim)
        }

        dkim.value = "i=1; " + original
        #expect(throws: DkimVerifierError.self) {
            _ = try verifier.verify(message, dkim)
        }

        dkim.value = "i=user@domain; " + original
        #expect(throws: DkimVerifierError.self) {
            _ = try verifier.verify(message, dkim)
        }

        dkim.value = "l=abc; " + original
        #expect(throws: DkimVerifierError.self) {
            _ = try verifier.verify(message, dkim)
        }

        dkim.value = original.replacingOccurrences(of: "c=relaxed/relaxed;", with: "c=simple/complex;")
        #expect(throws: DkimVerifierError.self) {
            _ = try verifier.verify(message, dkim)
        }

        dkim.value = original.replacingOccurrences(of: "c=relaxed/relaxed;", with: "c=;")
        #expect(throws: DkimVerifierError.self) {
            _ = try verifier.verify(message, dkim)
        }

        dkim.value = original.replacingOccurrences(of: "c=relaxed/relaxed;", with: "c=relaxed/relaxed/extra;")
        #expect(throws: DkimVerifierError.self) {
            _ = try verifier.verify(message, dkim)
        }
    }

    @Test("Verify Google Mail DKIM signature")
    func verifyGoogleMailDkimSignature() throws {
        let message = try Self.loadMessage("gmail.msg")
        guard let index = message.headers.firstIndex(where: { $0.id == .dkimSignature }) else {
            Issue.record("Missing DKIM-Signature header")
            return
        }
        let verifier = DkimVerifier(publicKeyLocator: DummyPublicKeyLocator(try Self.loadGmailPublicKey()))
        #expect(try verifier.verify(message, message.headers[index]) == true)
    }

    @Test("Verify Google Mail DKIM signature async")
    func verifyGoogleMailDkimSignatureAsync() async throws {
        let message = try Self.loadMessage("gmail.msg")
        guard let index = message.headers.firstIndex(where: { $0.id == .dkimSignature }) else {
            Issue.record("Missing DKIM-Signature header")
            return
        }
        let verifier = DkimVerifier(publicKeyLocator: DummyPublicKeyLocator(try Self.loadGmailPublicKey()))
        #expect(try await verifier.verifyAsync(message, message.headers[index]) == true)
    }

    @Test("Verify Google multipart/related DKIM signature")
    func verifyGoogleMultipartRelatedDkimSignature() throws {
        let message = try Self.loadMessage("related.msg")
        guard let index = message.headers.firstIndex(where: { $0.id == .dkimSignature }) else {
            Issue.record("Missing DKIM-Signature header")
            return
        }
        let verifier = DkimVerifier(publicKeyLocator: DummyPublicKeyLocator(try Self.loadGmailPublicKey()))
        #expect(try verifier.verify(message, message.headers[index]) == true)
    }

    @Test("Verify Google multipart/related DKIM signature async")
    func verifyGoogleMultipartRelatedDkimSignatureAsync() async throws {
        let message = try Self.loadMessage("related.msg")
        guard let index = message.headers.firstIndex(where: { $0.id == .dkimSignature }) else {
            Issue.record("Missing DKIM-Signature header")
            return
        }
        let verifier = DkimVerifier(publicKeyLocator: DummyPublicKeyLocator(try Self.loadGmailPublicKey()))
        #expect(try await verifier.verifyAsync(message, message.headers[index]) == true)
    }

    @Test("Verify Google multipart without end boundary DKIM signature")
    func verifyGoogleMultipartWithoutEndBoundaryDkimSignature() throws {
        let message = try Self.loadMessage("multipart-no-end-boundary.msg")
        guard let index = message.headers.firstIndex(where: { $0.id == .dkimSignature }) else {
            Issue.record("Missing DKIM-Signature header")
            return
        }
        let verifier = DkimVerifier(publicKeyLocator: DummyPublicKeyLocator(try Self.loadGmailPublicKey()))
        #expect(try verifier.verify(message, message.headers[index]) == true)
    }

    @Test("Verify Google multipart without end boundary DKIM signature async")
    func verifyGoogleMultipartWithoutEndBoundaryDkimSignatureAsync() async throws {
        let message = try Self.loadMessage("multipart-no-end-boundary.msg")
        guard let index = message.headers.firstIndex(where: { $0.id == .dkimSignature }) else {
            Issue.record("Missing DKIM-Signature header")
            return
        }
        let verifier = DkimVerifier(publicKeyLocator: DummyPublicKeyLocator(try Self.loadGmailPublicKey()))
        #expect(try await verifier.verifyAsync(message, message.headers[index]) == true)
    }

    @Test("Sign RFC 8463 example")
    func signRfc8463Example() throws {
        let message = try Self.loadMessage("rfc8463-example.msg")
        let privateKey = try Self.loadEd25519PrivateKey()
        let signer = try DkimSigner(privateKey: privateKey, domain: "football.example.com", selector: "brisbane", algorithm: .ed25519Sha256)
        signer.headerCanonicalizationAlgorithm = .relaxed
        signer.bodyCanonicalizationAlgorithm = .relaxed
        signer.agentOrUserIdentifier = "@football.example.com"

        let headers = ["from", "to", "subject", "date", "message-id", "from", "subject", "date"]
        try signer.sign(message, headers: headers)

        guard let index = message.headers.firstIndex(where: { $0.id == .dkimSignature }) else {
            Issue.record("Missing DKIM-Signature header")
            return
        }

        let locator = InMemoryDkimPublicKeyLocator()
        let verifier = DkimVerifier(publicKeyLocator: locator)
        let dkim = message.headers[index]

        locator.add("brisbane._domainkey.football.example.com", "v=DKIM1; k=ed25519; p=11qYAYKxCrfVS/7TyWQHOg7hcvPapiMlrwIaaPcHURo=")
        locator.add("test._domainkey.football.example.com", "v=DKIM1; k=rsa; p=MIGfMA0GCSqGSIb3DQEBAQUAA4GNADCBiQKBgQDkHlOQoBTzWRiGs5V6NpP3idY6Wk08a5qhdR6wy5bdOKb2jLQiY/J16JYi0Qvx/byYzCNb3W91y3FutACDfzwQ/BC/e/8uBsCR+yz1Lxj+PL6lHvqMKrM3rG4hstT5QjvHO9PzoxZyVYLzBfO2EeC3Ip3G+2kryOTIKT+l/K4w3QIDAQAB")

        #expect(try verifier.verify(message, dkim) == true)
    }

    @Test("Verify RFC 8463 example")
    func verifyRfc8463Example() throws {
        let message = try Self.loadMessage("rfc8463-example.msg")
        let locator = InMemoryDkimPublicKeyLocator()
        let verifier = DkimVerifier(publicKeyLocator: locator)

        locator.add("brisbane._domainkey.football.example.com", "v=DKIM1; k=ed25519; p=11qYAYKxCrfVS/7TyWQHOg7hcvPapiMlrwIaaPcHURo=")
        locator.add("test._domainkey.football.example.com", "v=DKIM1; k=rsa; p=MIGfMA0GCSqGSIb3DQEBAQUAA4GNADCBiQKBgQDkHlOQoBTzWRiGs5V6NpP3idY6Wk08a5qhdR6wy5bdOKb2jLQiY/J16JYi0Qvx/byYzCNb3W91y3FutACDfzwQ/BC/e/8uBsCR+yz1Lxj+PL6lHvqMKrM3rG4hstT5QjvHO9PzoxZyVYLzBfO2EeC3Ip3G+2kryOTIKT+l/K4w3QIDAQAB")

        guard let lastIndex = message.headers.lastIndex(where: { $0.id == .dkimSignature }) else {
            Issue.record("Missing DKIM-Signature header")
            return
        }
        #expect(try verifier.verify(message, message.headers[lastIndex]) == true)

        guard let firstIndex = message.headers.firstIndex(where: { $0.id == .dkimSignature }) else {
            Issue.record("Missing DKIM-Signature header")
            return
        }
        #expect(try verifier.verify(message, message.headers[firstIndex]) == true)
    }

    @Test("Verify RFC 8463 example async")
    func verifyRfc8463ExampleAsync() async throws {
        let message = try Self.loadMessage("rfc8463-example.msg")
        let locator = InMemoryDkimPublicKeyLocator()
        let verifier = DkimVerifier(publicKeyLocator: locator)

        locator.add("brisbane._domainkey.football.example.com", "v=DKIM1; k=ed25519; p=11qYAYKxCrfVS/7TyWQHOg7hcvPapiMlrwIaaPcHURo=")
        locator.add("test._domainkey.football.example.com", "v=DKIM1; k=rsa; p=MIGfMA0GCSqGSIb3DQEBAQUAA4GNADCBiQKBgQDkHlOQoBTzWRiGs5V6NpP3idY6Wk08a5qhdR6wy5bdOKb2jLQiY/J16JYi0Qvx/byYzCNb3W91y3FutACDfzwQ/BC/e/8uBsCR+yz1Lxj+PL6lHvqMKrM3rG4hstT5QjvHO9PzoxZyVYLzBfO2EeC3Ip3G+2kryOTIKT+l/K4w3QIDAQAB")

        guard let lastIndex = message.headers.lastIndex(where: { $0.id == .dkimSignature }) else {
            Issue.record("Missing DKIM-Signature header")
            return
        }
        #expect(try await verifier.verifyAsync(message, message.headers[lastIndex]) == true)

        guard let firstIndex = message.headers.firstIndex(where: { $0.id == .dkimSignature }) else {
            Issue.record("Missing DKIM-Signature header")
            return
        }
        #expect(try await verifier.verifyAsync(message, message.headers[firstIndex]) == true)
    }

    private static func testDkimSignVerify(_ message: MimeMessage, signatureAlgorithm: DkimSignatureAlgorithm, headerAlgorithm: DkimCanonicalizationAlgorithm, bodyAlgorithm: DkimCanonicalizationAlgorithm) throws {
        let headers: [HeaderId] = [.from, .subject, .date]
        let verifier = DkimVerifier(publicKeyLocator: DummyPublicKeyLocator(try loadRsaPublicKey()))
        let signer = try createSigner(signatureAlgorithm, headerAlgorithm: headerAlgorithm, bodyAlgorithm: bodyAlgorithm)

        try signer.sign(message, headers: headers)
        let dkimHeader = message.headers[0]

        if signatureAlgorithm == .rsaSha1 {
            #expect(try verifier.verify(message, dkimHeader) == false)
            verifier.enable(.rsaSha1)
        }

        #expect(try verifier.verify(message, dkimHeader) == true)
        message.headers.remove(at: 0)
    }

    @Test("DKIM sign/verify JWZ mbox")
    func dkimSignVerifyJwzMbox() throws {
        let data = try TestHelper.loadData(relativePath: "mbox/jwz.mbox.txt")
        let stream = MemoryStream(data, writable: false)
        let parser = try MimeParser(stream, .mbox)
        var count = 0

        while !parser.isEndOfStream && count < 10 {
            let message = try parser.parseMessage()

            try Self.testDkimSignVerify(message, signatureAlgorithm: .rsaSha1, headerAlgorithm: .relaxed, bodyAlgorithm: .relaxed)
            try Self.testDkimSignVerify(message, signatureAlgorithm: .rsaSha256, headerAlgorithm: .relaxed, bodyAlgorithm: .simple)
            try Self.testDkimSignVerify(message, signatureAlgorithm: .rsaSha1, headerAlgorithm: .simple, bodyAlgorithm: .relaxed)
            try Self.testDkimSignVerify(message, signatureAlgorithm: .rsaSha256, headerAlgorithm: .simple, bodyAlgorithm: .simple)

            count += 1
        }
    }
}
