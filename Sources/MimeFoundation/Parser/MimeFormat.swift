//
// MimeFormat.swift
//
// Ported from MimeKit (C#) to Swift.
//

public enum MimeFormat: UInt8, Sendable {
    case entity = 0
    case mbox = 1
}

public extension MimeFormat {
    static var `default`: MimeFormat { .entity }
}
