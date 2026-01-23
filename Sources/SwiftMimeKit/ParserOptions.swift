//
// ParserOptions.swift
//
// Ported from MimeKit (C#) to Swift.
//

import Foundation

public struct ParserOptions: Sendable {
    public static var `default`: ParserOptions { ParserOptions() }

    public enum Error: Swift.Error, Equatable {
        case nilMimeType
        case invalidMimeType
    }

    public typealias MimeEntityFactory = @Sendable (ContentType) -> MimeEntity

    public var addressParserComplianceMode: RfcComplianceMode
    public var parameterComplianceMode: RfcComplianceMode
    public var rfc2047ComplianceMode: RfcComplianceMode
    public var allowUnquotedCommasInAddresses: Bool
    public var allowAddressesWithoutDomain: Bool
    public var maxAddressGroupDepth: Int
    public var maxMimeDepth: Int
    public var respectContentLength: Bool
    public var charsetEncoding: String.Encoding
    private var mimeTypeFactories: [String: MimeEntityFactory]

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
        self.mimeTypeFactories = [:]
    }

    public func clone() -> ParserOptions {
        self
    }

    public mutating func registerMimeType(_ mimeType: String?, factory: @escaping MimeEntityFactory) throws {
        guard let mimeType else {
            throw Error.nilMimeType
        }
        let trimmed = mimeType.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            throw Error.invalidMimeType
        }
        var parsed: ContentType?
        guard ContentType.tryParse(trimmed, contentType: &parsed), let contentType = parsed else {
            throw Error.invalidMimeType
        }
        let key = contentType.mimeType.lowercased()
        mimeTypeFactories[key] = factory
    }

    internal func makeEntity(for contentType: ContentType) -> MimeEntity? {
        let key = contentType.mimeType.lowercased()
        return mimeTypeFactories[key]?(contentType)
    }
}
