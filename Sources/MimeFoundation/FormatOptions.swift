//
// FormatOptions.swift
//
// Ported from MimeKit (C#) to Swift.
//

import Foundation

public struct FormatOptions: Sendable {
    public static let minimumLineLength = 60
    public static let maximumLineLength = 998
    public static let defaultMaxLineLength = 78

    public static var `default`: FormatOptions { FormatOptions() }

    public var maxLineLength: Int
    public var newLineFormat: NewLineFormat
    public var ensureNewLine: Bool
    public var international: Bool
    public var allowMixedHeaderCharsets: Bool
    public var parameterEncodingMethod: ParameterEncodingMethod
    public var alwaysQuoteParameterValues: Bool

    public init() {
        self.maxLineLength = Self.defaultMaxLineLength
        self.ensureNewLine = false
        self.international = false
        self.allowMixedHeaderCharsets = false
        self.parameterEncodingMethod = .rfc2231
        self.alwaysQuoteParameterValues = false
        let os = ProcessInfo.processInfo.environment["OS"]?.lowercased()
        self.newLineFormat = (os == "windows_nt") ? .dos : .unix
    }

    public var newLine: String {
        newLineFormat == .unix ? "\n" : "\r\n"
    }

    public var newLineBytes: [UInt8] {
        newLineFormat == .unix ? [0x0A] : [0x0D, 0x0A]
    }

    public func clone() -> FormatOptions {
        self
    }
}
