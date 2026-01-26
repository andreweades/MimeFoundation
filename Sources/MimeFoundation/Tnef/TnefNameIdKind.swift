//
// TnefNameIdKind.swift
//
// Ported from MimeKit (C#) to Swift.
//

/// The kind of TNEF name identifier.
///
/// Named properties in MAPI can be identified either by an integer identifier
/// or by a string name. This enumeration specifies which type of identifier
/// is used for a particular named property.
public enum TnefNameIdKind: Int, Sendable {
    /// The property name is an integer.
    ///
    /// The named property is identified by an integer value in the ``TnefNameId/id`` property.
    case id

    /// The property name is a string.
    ///
    /// The named property is identified by a string value in the ``TnefNameId/name`` property.
    case name
}
