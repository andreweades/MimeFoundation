//
// MessageImportance.swift
//
// Ported from MimeKit (C#) to Swift.
//

/// An enumeration of message importance values.
///
/// Indicates the importance of a message as specified in the Importance header.
public enum MessageImportance: Sendable {
    /// The message is of low importance.
    case low

    /// The message is of normal importance.
    case normal

    /// The message is of high importance.
    case high
}
