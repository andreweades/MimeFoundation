//
// DkimPublicKeyLocator.swift
//
// Ported from MimeKit (C#) to Swift.
//

import Foundation
import Crypto
import _CryptoExtras

public enum DkimPublicKeyLocatorError: Error, Equatable, Sendable {
    case invalidArgument
}

public protocol DkimPublicKeyLocator: AnyObject {
    func locatePublicKey(methods: String, domain: String, selector: String) throws -> DkimPublicKey
    func locatePublicKeyAsync(methods: String, domain: String, selector: String) async throws -> DkimPublicKey
}

open class DkimPublicKeyLocatorBase: DkimPublicKeyLocator {
    public init() {}

    open func locatePublicKey(methods: String, domain: String, selector: String) throws -> DkimPublicKey {
        fatalError("Subclasses must override locatePublicKey")
    }

    open func locatePublicKeyAsync(methods: String, domain: String, selector: String) async throws -> DkimPublicKey {
        try locatePublicKey(methods: methods, domain: domain, selector: selector)
    }

    static func getPublicKey(_ txt: String?) throws -> DkimPublicKey {
        guard let txt else {
            throw DkimPublicKeyLocatorError.invalidArgument
        }

        var algorithm = "rsa"
        var publicKeyBase64: String?
        var index = 0
        let length = txt.utf16.count

        while index < length {
            while index < length {
                let codeUnit = txt.utf16CodeUnit(at: index)
                if codeUnit != 0x20 && codeUnit != 0x09 && codeUnit != 0x0A && codeUnit != 0x0D {
                    break
                }
                index += 1
            }

            if index >= length {
                break
            }

            let keyStart = index
            while index < length, txt.utf16CodeUnit(at: index) != 0x3D {
                index += 1
            }
            if index >= length {
                break
            }

            let key = txt.sliceUtf16(keyStart, index)
            index += 1

            let valueStart = index
            while index < length, txt.utf16CodeUnit(at: index) != 0x3B {
                index += 1
            }

            let value = txt.sliceUtf16(valueStart, index)

            if key == "k" {
                switch value {
                case "rsa", "ed25519":
                    algorithm = value
                default:
                    throw ParseException("Unknown public key algorithm: \(value)", tokenIndex: valueStart, errorIndex: index)
                }
            } else if key == "p" {
                publicKeyBase64 = value.replacingOccurrences(of: " ", with: "")
            }

            index += 1
        }

        guard let publicKeyBase64, !publicKeyBase64.isEmpty else {
            throw ParseException("Public key parameters not found in DNS TXT record.", tokenIndex: 0, errorIndex: length)
        }

        guard let decoded = Data(base64Encoded: publicKeyBase64, options: [.ignoreUnknownCharacters]) else {
            throw ParseException("Public key parameters not found in DNS TXT record.", tokenIndex: 0, errorIndex: length)
        }

        if algorithm == "ed25519" {
            do {
                let key = try Curve25519.Signing.PublicKey(rawRepresentation: decoded)
                return .ed25519(key)
            } catch {
                throw ParseException("Public key parameters not found in DNS TXT record.", tokenIndex: 0, errorIndex: length)
            }
        }

        do {
            let key = try _RSA.Signing.PublicKey(unsafeDERRepresentation: decoded)
            return .rsa(key)
        } catch {
            throw ParseException("Public key parameters not found in DNS TXT record.", tokenIndex: 0, errorIndex: length)
        }
    }
}

private extension String {
    func sliceUtf16(_ start: Int, _ end: Int) -> String {
        guard start < end else { return "" }
        let startIndex = String.Index(utf16Offset: start, in: self)
        let endIndex = String.Index(utf16Offset: end, in: self)
        return String(self[startIndex..<endIndex]).trimmingCharacters(in: .whitespacesAndNewlines)
    }

    func utf16CodeUnit(at index: Int) -> UInt16 {
        let utf16Index = utf16.index(utf16.startIndex, offsetBy: index)
        return utf16[utf16Index]
    }
}
