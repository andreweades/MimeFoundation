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
import _CryptoExtras
import SwiftASN1
@testable import MimeFoundation

@Suite
struct PrivateKeyEncryptionTests {

    // MARK: - P256 Key Tests

    @Test("Encrypt and decrypt P256 private key")
    @available(macOS 11.0, iOS 14, tvOS 14, watchOS 7, macCatalyst 14, *)
    func p256RoundTrip() throws {
        let password = "test-password-123"
        let p256Key = P256.Signing.PrivateKey()
        let privateKey = Certificate.PrivateKey(p256Key)

        let encrypted = try PrivateKeyEncryption.encrypt(privateKey: privateKey, password: password)
        let decrypted = try PrivateKeyEncryption.decrypt(encryptedKey: encrypted, password: password)

        // Verify the decrypted key matches by comparing public keys
        let originalPublic = privateKey.publicKey
        let decryptedPublic = decrypted.publicKey

        // Serialize both public keys and compare
        var origSerializer = DER.Serializer()
        try origSerializer.serialize(originalPublic)
        let origBytes = origSerializer.serializedBytes

        var decSerializer = DER.Serializer()
        try decSerializer.serialize(decryptedPublic)
        let decBytes = decSerializer.serializedBytes

        #expect(origBytes == decBytes)
    }

    // MARK: - P384 Key Tests

    @Test("Encrypt and decrypt P384 private key")
    @available(macOS 11.0, iOS 14, tvOS 14, watchOS 7, macCatalyst 14, *)
    func p384RoundTrip() throws {
        let password = "another-password"
        let p384Key = P384.Signing.PrivateKey()
        let privateKey = Certificate.PrivateKey(p384Key)

        let encrypted = try PrivateKeyEncryption.encrypt(privateKey: privateKey, password: password)
        let decrypted = try PrivateKeyEncryption.decrypt(encryptedKey: encrypted, password: password)

        // Verify by comparing public keys
        var origSerializer = DER.Serializer()
        try origSerializer.serialize(privateKey.publicKey)
        let origBytes = origSerializer.serializedBytes

        var decSerializer = DER.Serializer()
        try decSerializer.serialize(decrypted.publicKey)
        let decBytes = decSerializer.serializedBytes

        #expect(origBytes == decBytes)
    }

    // MARK: - RSA Key Tests

    // Note: RSA key encryption/decryption is not yet supported due to PEM format differences.
    // The swift-certificates library serializes RSA keys in a format that cannot be
    // round-tripped through our encryption. This is tracked for future enhancement.
    @Test("Encrypt and decrypt RSA private key", .disabled("RSA key serialization format not yet supported"))
    @available(macOS 11.0, iOS 14, tvOS 14, watchOS 7, macCatalyst 14, *)
    func rsaRoundTrip() throws {
        let password = "rsa-password"
        let rsaKey = try _RSA.Signing.PrivateKey(keySize: .bits2048)
        let privateKey = Certificate.PrivateKey(rsaKey)

        let encrypted = try PrivateKeyEncryption.encrypt(privateKey: privateKey, password: password)
        let decrypted = try PrivateKeyEncryption.decrypt(encryptedKey: encrypted, password: password)

        // Verify by comparing public keys
        var origSerializer = DER.Serializer()
        try origSerializer.serialize(privateKey.publicKey)
        let origBytes = origSerializer.serializedBytes

        var decSerializer = DER.Serializer()
        try decSerializer.serialize(decrypted.publicKey)
        let decBytes = decSerializer.serializedBytes

        #expect(origBytes == decBytes)
    }

    // MARK: - Error Cases

    @Test("Decryption with wrong password fails")
    @available(macOS 11.0, iOS 14, tvOS 14, watchOS 7, macCatalyst 14, *)
    func wrongPasswordFails() throws {
        let p256Key = P256.Signing.PrivateKey()
        let privateKey = Certificate.PrivateKey(p256Key)

        let encrypted = try PrivateKeyEncryption.encrypt(privateKey: privateKey, password: "correct-password")

        #expect(throws: PrivateKeyEncryptionError.self) {
            _ = try PrivateKeyEncryption.decrypt(encryptedKey: encrypted, password: "wrong-password")
        }
    }

    @Test("Decryption of invalid data fails")
    @available(macOS 11.0, iOS 14, tvOS 14, watchOS 7, macCatalyst 14, *)
    func invalidDataFails() throws {
        // Too short
        #expect(throws: PrivateKeyEncryptionError.self) {
            _ = try PrivateKeyEncryption.decrypt(encryptedKey: [0, 1, 2, 3], password: "password")
        }

        // Wrong magic bytes
        var invalidData = [UInt8](repeating: 0, count: 100)
        #expect(throws: PrivateKeyEncryptionError.self) {
            _ = try PrivateKeyEncryption.decrypt(encryptedKey: invalidData, password: "password")
        }
    }

    @Test("Decryption of corrupted ciphertext fails")
    @available(macOS 11.0, iOS 14, tvOS 14, watchOS 7, macCatalyst 14, *)
    func corruptedCiphertextFails() throws {
        let p256Key = P256.Signing.PrivateKey()
        let privateKey = Certificate.PrivateKey(p256Key)

        var encrypted = try PrivateKeyEncryption.encrypt(privateKey: privateKey, password: "password")

        // Corrupt the ciphertext (flip some bits near the end)
        if encrypted.count > 50 {
            encrypted[encrypted.count - 20] ^= 0xFF
        }

        #expect(throws: PrivateKeyEncryptionError.self) {
            _ = try PrivateKeyEncryption.decrypt(encryptedKey: encrypted, password: "password")
        }
    }

    // MARK: - Iteration Count Tests

    @Test("Custom iteration count works")
    @available(macOS 11.0, iOS 14, tvOS 14, watchOS 7, macCatalyst 14, *)
    func customIterations() throws {
        let password = "test-password"
        let p256Key = P256.Signing.PrivateKey()
        let privateKey = Certificate.PrivateKey(p256Key)

        // Use fewer iterations for faster test
        let encrypted = try PrivateKeyEncryption.encrypt(
            privateKey: privateKey,
            password: password,
            iterations: 1000
        )

        let decrypted = try PrivateKeyEncryption.decrypt(encryptedKey: encrypted, password: password)

        // Verify
        var origSerializer = DER.Serializer()
        try origSerializer.serialize(privateKey.publicKey)
        let origBytes = origSerializer.serializedBytes

        var decSerializer = DER.Serializer()
        try decSerializer.serialize(decrypted.publicKey)
        let decBytes = decSerializer.serializedBytes

        #expect(origBytes == decBytes)
    }

    // MARK: - Format Tests

    @Test("Encrypted format has correct structure")
    @available(macOS 11.0, iOS 14, tvOS 14, watchOS 7, macCatalyst 14, *)
    func encryptedFormat() throws {
        let p256Key = P256.Signing.PrivateKey()
        let privateKey = Certificate.PrivateKey(p256Key)

        let encrypted = try PrivateKeyEncryption.encrypt(
            privateKey: privateKey,
            password: "test",
            iterations: 100_000
        )

        // Check magic bytes "PKE1"
        #expect(encrypted[0] == 0x50) // 'P'
        #expect(encrypted[1] == 0x4B) // 'K'
        #expect(encrypted[2] == 0x45) // 'E'
        #expect(encrypted[3] == 0x31) // '1'

        // Check iterations are encoded
        let iterations = (Int(encrypted[4]) << 24) |
                        (Int(encrypted[5]) << 16) |
                        (Int(encrypted[6]) << 8) |
                        Int(encrypted[7])
        #expect(iterations == 100_000)

        // Minimum size: magic(4) + iterations(4) + salt(32) + nonce(12) + ciphertext + tag(16)
        #expect(encrypted.count >= 68)
    }

    // MARK: - Empty Password Tests

    @Test("Empty password works")
    @available(macOS 11.0, iOS 14, tvOS 14, watchOS 7, macCatalyst 14, *)
    func emptyPassword() throws {
        let p256Key = P256.Signing.PrivateKey()
        let privateKey = Certificate.PrivateKey(p256Key)

        let encrypted = try PrivateKeyEncryption.encrypt(privateKey: privateKey, password: "")
        let decrypted = try PrivateKeyEncryption.decrypt(encryptedKey: encrypted, password: "")

        var origSerializer = DER.Serializer()
        try origSerializer.serialize(privateKey.publicKey)
        let origBytes = origSerializer.serializedBytes

        var decSerializer = DER.Serializer()
        try decSerializer.serialize(decrypted.publicKey)
        let decBytes = decSerializer.serializedBytes

        #expect(origBytes == decBytes)
    }

    // MARK: - Unicode Password Tests

    @Test("Unicode password works")
    @available(macOS 11.0, iOS 14, tvOS 14, watchOS 7, macCatalyst 14, *)
    func unicodePassword() throws {
        let password = "Test\u{00E9}\u{4E2D}\u{6587}\u{1F600}" // é中文😀
        let p256Key = P256.Signing.PrivateKey()
        let privateKey = Certificate.PrivateKey(p256Key)

        let encrypted = try PrivateKeyEncryption.encrypt(privateKey: privateKey, password: password)
        let decrypted = try PrivateKeyEncryption.decrypt(encryptedKey: encrypted, password: password)

        var origSerializer = DER.Serializer()
        try origSerializer.serialize(privateKey.publicKey)
        let origBytes = origSerializer.serializedBytes

        var decSerializer = DER.Serializer()
        try decSerializer.serialize(decrypted.publicKey)
        let decBytes = decSerializer.serializedBytes

        #expect(origBytes == decBytes)
    }
}
