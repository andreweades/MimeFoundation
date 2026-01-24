//
// InternetAddressListConverter.swift
//
// Ported from MimeKit (C#) to Swift.
//

import Foundation

public struct InternetAddressListConverter: Sendable {
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

    public func convertFrom(_ value: Any) throws -> InternetAddressList {
        guard let text = value as? String else {
            throw ConverterError.notSupported
        }
        return try InternetAddressList(parsing: text, options: options)
    }

    public func convertTo(_ value: Any, destinationType: Any.Type) throws -> Any {
        guard destinationType == String.self, let list = value as? InternetAddressList else {
            throw ConverterError.notSupported
        }
        return list.toString(FormatOptions.default, encode: false)
    }

    public func isValid(_ value: Any?) -> Bool {
        guard let text = value as? String else {
            return false
        }
        return (try? InternetAddressList(parsing: text, options: options)) != nil
    }

    public static func register(_ options: ParserOptions? = nil) async throws {
        try await InternetAddressListConverterRegistry.shared.register(options ?? .default)
    }

    public static func registeredConverter() async -> InternetAddressListConverter {
        await InternetAddressListConverterRegistry.shared.converter()
    }
}

private actor InternetAddressListConverterRegistry {
    static let shared = InternetAddressListConverterRegistry()
    private var options: ParserOptions? = nil
    private var isRegistered = false

    func register(_ options: ParserOptions) throws {
        guard !isRegistered else {
            throw ConverterError.alreadyRegistered
        }
        isRegistered = true
        self.options = options
    }

    func converter() -> InternetAddressListConverter {
        InternetAddressListConverter(options: options ?? .default)
    }
}
