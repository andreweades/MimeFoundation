//
// ParserOptions.swift
//
// Ported from MimeKit (C#) to Swift.
//

import Foundation

public struct ParserOptions: Sendable {
    public static var `default`: ParserOptions { ParserOptions() }

    public var addressParserComplianceMode: RfcComplianceMode
    public var parameterComplianceMode: RfcComplianceMode
    public var rfc2047ComplianceMode: RfcComplianceMode
    public var allowUnquotedCommasInAddresses: Bool
    public var allowAddressesWithoutDomain: Bool
    public var maxAddressGroupDepth: Int
    public var maxMimeDepth: Int
    public var respectContentLength: Bool
    public var charsetEncoding: String.Encoding

    public init() {
        self.addressParserComplianceMode = .loose
        self.parameterComplianceMode = .loose
        self.rfc2047ComplianceMode = .loose
        self.allowUnquotedCommasInAddresses = true
        self.allowAddressesWithoutDomain = true
        self.maxAddressGroupDepth = 3
        self.maxMimeDepth = 1024
        self.respectContentLength = false
        self.charsetEncoding = CharsetUtils.utf8
    }

    public func clone() -> ParserOptions {
        self
    }
}
