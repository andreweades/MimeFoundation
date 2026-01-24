import Foundation
import Testing
import _CryptoExtras
@testable import SwiftMimeKit

@Suite
struct DkimSignerTests {
    private static func loadRsaPrivateKey() throws -> DkimPrivateKey {
        let url = TestHelper.dataURL(for: "dkim/example.pem")
        let pem = try String(contentsOf: url, encoding: .utf8)
        let key = try _RSA.Signing.PrivateKey(unsafePEMRepresentation: pem)
        return .rsa(key)
    }

    @Test("DkimSigner ctors")
    func dkimSignerCtors() throws {
        let filePath = TestHelper.dataURL(for: "dkim/example.pem").path
        _ = try DkimSigner(filePath: filePath, domain: "example.com", selector: "1433868189.example")

        let privateKey = try Self.loadRsaPrivateKey()
        _ = try DkimSigner(privateKey: privateKey, domain: "example.com", selector: "1433868189.example")
    }

    @Test("DkimSigner defaults")
    func dkimSignerDefaults() throws {
        let filePath = TestHelper.dataURL(for: "dkim/example.pem").path

        let privateKey = try Self.loadRsaPrivateKey()
        let signer1 = try DkimSigner(privateKey: privateKey, domain: "example.com", selector: "1433868189.example")
        #expect(signer1.signatureAlgorithm == .rsaSha256)

        let signer2 = try DkimSigner(filePath: filePath, domain: "example.com", selector: "1433868189.example")
        #expect(signer2.signatureAlgorithm == .rsaSha256)

        let data = try TestHelper.loadData(relativePath: "dkim/example.pem")
        let stream = MemoryStream(data)
        let signer3 = try DkimSigner(stream: stream, domain: "example.com", selector: "1433868189.example")
        #expect(signer3.signatureAlgorithm == .rsaSha256)
    }

    @Test("DkimSigner argument exceptions")
    func dkimSignerArgumentExceptions() throws {
        let filePath = TestHelper.dataURL(for: "dkim/example.pem").path
        let privateKey = try Self.loadRsaPrivateKey()

        #expect(throws: DkimSignerError.self) {
            _ = try DkimSigner(privateKey: privateKey, domain: "", selector: "selector")
        }
        #expect(throws: DkimSignerError.self) {
            _ = try DkimSigner(privateKey: privateKey, domain: "domain", selector: "")
        }
        #expect(throws: DkimSignerError.self) {
            _ = try DkimSigner(filePath: "", domain: "domain", selector: "selector")
        }
        #expect(throws: DkimSignerError.self) {
            _ = try DkimSigner(filePath: "/no/such/file.pem", domain: "domain", selector: "selector")
        }
        #expect(throws: DkimSignerError.self) {
            _ = try DkimSigner(privateKeyData: Data([0x00]), domain: "domain", selector: "selector")
        }
        #expect(throws: DkimSignerError.self) {
            _ = try DkimSigner(stream: MemoryStream([0x00]), domain: "domain", selector: "selector")
        }

        let signer = try DkimSigner(filePath: filePath, domain: "example.com", selector: "1433868189.example")
        let message = MimeMessage()
        message.from.add(MailboxAddress(name: "", address: "mimekit@example.com"))
        message.subject = "Test"
        let body = TextPart("plain")
        body.text = "Hello"
        message.body = body

        #expect(throws: DkimSignerError.self) {
            try signer.sign(message, headers: [.unknown, .from])
        }
        #expect(throws: DkimSignerError.self) {
            try signer.sign(message, headers: [.received, .from])
        }
        #expect(throws: DkimSignerError.self) {
            try signer.sign(message, headers: [.contentType])
        }
        #expect(throws: DkimSignerError.self) {
            try signer.sign(message, headers: ["", "From"])
        }
        #expect(throws: DkimSignerError.self) {
            try signer.sign(message, headers: ["Received", "From"])
        }
        #expect(throws: DkimSignerError.self) {
            try signer.sign(message, headers: ["Content-Type"])
        }
        #expect(throws: DkimSignerError.self) {
            try signer.sign(.default, message, headers: [.from, .unknown])
        }
        #expect(throws: DkimSignerError.self) {
            try signer.sign(.default, message, headers: ["From", ""])
        }
    }
}
