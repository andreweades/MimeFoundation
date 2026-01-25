//
// TnefNameIdKind.swift
//
// Ported from MimeKit (C#) to Swift.
//

/// The kind of TNEF name identifier.
public enum TnefNameIdKind: Int, Sendable {
    /// The property name is an integer.
    case id

    /// The property name is a string.
    case name
}
