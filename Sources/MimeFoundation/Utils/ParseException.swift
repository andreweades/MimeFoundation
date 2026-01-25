//
// ParseException.swift
//
// Ported from MimeKit (C#) to Swift.
//

public struct ParseException: Error, Equatable, Sendable {
    public let message: String
    public let tokenIndex: Int
    public let errorIndex: Int

    public init(_ message: String, tokenIndex: Int, errorIndex: Int) {
        self.message = message
        self.tokenIndex = tokenIndex
        self.errorIndex = errorIndex
    }
}
