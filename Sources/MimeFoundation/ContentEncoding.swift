//
// ContentEncoding.swift
//
// Ported from MimeKit (C#) to Swift.
//

public enum ContentEncoding: String, CaseIterable, Sendable {
    case `default`
    case sevenBit
    case eightBit
    case binary
    case base64
    case quotedPrintable
    case uuEncode
}
