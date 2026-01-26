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

import Testing
@testable import MimeFoundation

@Suite
struct DkimPublicKeyLocatorBaseTests {
    private final class TestDkimPublicKeyLocator: DkimPublicKeyLocatorBase {
        private var keys: [String: String?] = [:]

        func add(_ key: String, _ value: String?) {
            keys[key] = value
        }

        override func locatePublicKey(methods: String, domain: String, selector: String) throws -> DkimPublicKey {
            let query = "\(selector)._domainkey.\(domain)"
            if let value = keys[query] {
                return try Self.getPublicKey(value)
            }
            if keys.keys.contains(query) {
                return try Self.getPublicKey(nil)
            }
            throw ParseException("Public key parameters not found in DNS TXT record.", tokenIndex: 0, errorIndex: 0)
        }

        override func locatePublicKeyAsync(methods: String, domain: String, selector: String) async throws -> DkimPublicKey {
            try locatePublicKey(methods: methods, domain: domain, selector: selector)
        }
    }

    @Test("Argument exceptions")
    func argumentExceptions() throws {
        let locator = TestDkimPublicKeyLocator()
        locator.add("dummy._domainkey.example.org", nil)

        #expect(throws: DkimPublicKeyLocatorError.invalidArgument) {
            _ = try locator.locatePublicKey(methods: "dns/txt", domain: "example.org", selector: "dummy")
        }
    }

    @Test("Argument exceptions async")
    func argumentExceptionsAsync() async throws {
        let locator = TestDkimPublicKeyLocator()
        locator.add("dummy._domainkey.example.org", nil)

        await #expect(throws: DkimPublicKeyLocatorError.invalidArgument) {
            _ = try await locator.locatePublicKeyAsync(methods: "dns/txt", domain: "example.org", selector: "dummy")
        }
    }

    @Test("Parse exceptions")
    func parseExceptions() {
        let locator = TestDkimPublicKeyLocator()

        locator.add("empty._domainkey.example.org", "")
        locator.add("whitespace._domainkey.example.org", "     ")
        locator.add("no-k-or-p-params._domainkey.example.org", "v=DKIM1; x=abc; y=def")
        locator.add("no-p-param._domainkey.example.org", "v=DKIM1; k=rsa")
        locator.add("unknown-algorithm._domainkey.example.org", "v=DKIM1; k=dummy; p=MIGfMA0GCSqGSIb3DQEBAQUAA4GNADCBiQKBgQDkHlOQoBTzWRiGs5V6NpP3id")

        #expect(throws: ParseException.self) {
            _ = try locator.locatePublicKey(methods: "dns/txt", domain: "example.org", selector: "empty")
        }
        #expect(throws: ParseException.self) {
            _ = try locator.locatePublicKey(methods: "dns/txt", domain: "example.org", selector: "whitespace")
        }
        #expect(throws: ParseException.self) {
            _ = try locator.locatePublicKey(methods: "dns/txt", domain: "example.org", selector: "no-k-or-p-params")
        }
        #expect(throws: ParseException.self) {
            _ = try locator.locatePublicKey(methods: "dns/txt", domain: "example.org", selector: "no-p-param")
        }
        #expect(throws: ParseException.self) {
            _ = try locator.locatePublicKey(methods: "dns/txt", domain: "example.org", selector: "unknown-algorithm")
        }
    }

    @Test("Missing k param defaults to rsa")
    func missingKParamDefaultsToRsa() throws {
        let locator = TestDkimPublicKeyLocator()
        locator.add("no-k-param._domainkey.example.org", "v=DKIM1; p=MIGfMA0GCSqGSIb3DQEBAQUAA4GNADCBiQKBgQDkHlOQoBTzWRiGs5V6NpP3id Y6Wk08a5qhdR6wy5bdOKb2jLQiY/J16JYi0Qvx/byYzCNb3W91y3FutACDfzwQ/BC/e/8uBsCR+yz1Lx j+PL6lHvqMKrM3rG4hstT5QjvHO9PzoxZyVYLzBfO2EeC3Ip3G+2kryOTIKT+l/K4w3QIDAQAB")

        let key = try locator.locatePublicKey(methods: "dns/txt", domain: "example.org", selector: "no-k-param")
        switch key {
        case .rsa:
            break
        case .ed25519:
            Issue.record("Expected RSA key")
        }
    }
}
