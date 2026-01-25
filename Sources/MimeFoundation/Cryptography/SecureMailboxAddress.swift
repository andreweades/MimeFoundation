//
// SecureMailboxAddress.swift
//
// Ported from MimeKit (C#) to Swift.
//

import Foundation

public enum SecureMailboxAddressError: Error {
    case nilFingerprint
    case invalidFingerprint
}

public final class SecureMailboxAddress: MailboxAddress {
    public let fingerprint: String

    public init(encoding: String.Encoding, name: String?, route: [String], address: String, fingerprint: String) throws {
        try SecureMailboxAddress.validateFingerprint(fingerprint)
        self.fingerprint = fingerprint
        super.init(encoding: encoding, name: name, route: route, address: address)
    }

    /// Internal initializer for cloning. Assumes fingerprint is already validated.
    private init(cloning encoding: String.Encoding, name: String?, route: [String], address: String, fingerprint: String) {
        self.fingerprint = fingerprint
        super.init(encoding: encoding, name: name, route: route, address: address)
    }

    public convenience init(name: String?, route: [String], address: String, fingerprint: String) throws {
        try self.init(encoding: .utf8, name: name, route: route, address: address, fingerprint: fingerprint)
    }

    public init(encoding: String.Encoding, name: String?, address: String, fingerprint: String) throws {
        try SecureMailboxAddress.validateFingerprint(fingerprint)
        self.fingerprint = fingerprint
        super.init(encoding: encoding, name: name, address: address)
    }

    public convenience init(name: String?, address: String, fingerprint: String) throws {
        try self.init(encoding: .utf8, name: name, address: address, fingerprint: fingerprint)
    }

    public convenience init(encoding: String.Encoding?, name: String?, route: [String]?, address: String?, fingerprint: String?) throws {
        guard let encoding else {
            throw MailboxAddressError.nilEncoding
        }
        guard let route else {
            throw MailboxAddressError.nilRoute
        }
        guard let address else {
            throw MailboxAddressError.nilAddress
        }
        guard let fingerprint else {
            throw SecureMailboxAddressError.nilFingerprint
        }
        try self.init(encoding: encoding, name: name, route: route, address: address, fingerprint: fingerprint)
    }

    public convenience init(name: String?, route: [String]?, address: String?, fingerprint: String?) throws {
        guard let route else {
            throw MailboxAddressError.nilRoute
        }
        guard let address else {
            throw MailboxAddressError.nilAddress
        }
        guard let fingerprint else {
            throw SecureMailboxAddressError.nilFingerprint
        }
        try self.init(name: name, route: route, address: address, fingerprint: fingerprint)
    }

    public convenience init(encoding: String.Encoding?, name: String?, address: String?, fingerprint: String?) throws {
        guard let encoding else {
            throw MailboxAddressError.nilEncoding
        }
        guard let address else {
            throw MailboxAddressError.nilAddress
        }
        guard let fingerprint else {
            throw SecureMailboxAddressError.nilFingerprint
        }
        try self.init(encoding: encoding, name: name, address: address, fingerprint: fingerprint)
    }

    public convenience init(name: String?, address: String?, fingerprint: String?) throws {
        guard let address else {
            throw MailboxAddressError.nilAddress
        }
        guard let fingerprint else {
            throw SecureMailboxAddressError.nilFingerprint
        }
        try self.init(name: name, address: address, fingerprint: fingerprint)
    }

    public override func copy() -> InternetAddress {
        let routes = Array(route)
        return SecureMailboxAddress(cloning: encoding, name: name, route: routes, address: address, fingerprint: fingerprint)
    }

    private static func validateFingerprint(_ fingerprint: String) throws {
        for byte in fingerprint.utf8 {
            if byte > 0x7F || !ByteClassification.isXDigit(byte) {
                throw SecureMailboxAddressError.invalidFingerprint
            }
        }
    }

    private static func validateFingerprint(_ fingerprint: String?) throws {
        guard let fingerprint else {
            throw SecureMailboxAddressError.nilFingerprint
        }
        try validateFingerprint(fingerprint)
    }
}
