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
