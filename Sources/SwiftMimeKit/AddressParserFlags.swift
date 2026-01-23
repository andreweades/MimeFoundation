//
// AddressParserFlags.swift
//
// Ported from MimeKit (C#) to Swift.
//

struct AddressParserFlags: OptionSet {
    let rawValue: Int

    static let allowMailboxAddress = AddressParserFlags(rawValue: 1 << 0)
    static let allowGroupAddress = AddressParserFlags(rawValue: 1 << 1)
    static let throwOnError = AddressParserFlags(rawValue: 1 << 2)
    static let internalFlag = AddressParserFlags(rawValue: 1 << 3)

    static let tryParse: AddressParserFlags = [.allowMailboxAddress, .allowGroupAddress]
    static let internalTryParse: AddressParserFlags = [.tryParse, .internalFlag]
    static let parse: AddressParserFlags = [.tryParse, .throwOnError]
}
