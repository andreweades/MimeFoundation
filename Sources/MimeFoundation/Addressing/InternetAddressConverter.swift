//
// InternetAddressConverter.swift
//
// Ported from MimeKit (C#) to Swift.
//

import Foundation

public struct InternetAddressConverter: Sendable {
    private let options: ParserOptions

    public init(options: ParserOptions = .default) {
        self.options = options
    }

    public func canConvertFrom(_ sourceType: Any.Type) -> Bool {
        sourceType == String.self
    }

    public func canConvertTo(_ destinationType: Any.Type) -> Bool {
        destinationType == String.self
    }

    public func convertFrom(_ value: Any) throws -> InternetAddress {
        guard let text = value as? String else {
            throw ConverterError.notSupported
        }
        return try InternetAddress.parsed(from: text, options: options)
    }

    public func convertTo(_ value: Any, destinationType: Any.Type) throws -> Any {
        guard destinationType == String.self, let address = value as? InternetAddress else {
            throw ConverterError.notSupported
        }
        return address.toString(encode: false)
    }

    public func isValid(_ value: Any?) -> Bool {
        guard let text = value as? String else {
            return false
        }
        return (try? InternetAddress.parsed(from: text, options: options)) != nil
    }

    public static func register(_ options: ParserOptions? = nil) async throws {
        try await InternetAddressConverterRegistry.shared.register(options ?? .default)
    }

    public static func registeredConverter() async -> InternetAddressConverter {
        await InternetAddressConverterRegistry.shared.converter()
    }
}

private actor InternetAddressConverterRegistry {
    static let shared = InternetAddressConverterRegistry()
    private var options: ParserOptions? = nil
    private var isRegistered = false

    func register(_ options: ParserOptions) throws {
        guard !isRegistered else {
            throw ConverterError.alreadyRegistered
        }
        isRegistered = true
        self.options = options
    }

    func converter() -> InternetAddressConverter {
        InternetAddressConverter(options: options ?? .default)
    }
}
