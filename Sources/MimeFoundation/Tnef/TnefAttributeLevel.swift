//
// TnefAttributeLevel.swift
//
// Ported from MimeKit (C#) to Swift.
//

/// A TNEF attribute level.
public enum TnefAttributeLevel: Int, Sendable {
    /// The attribute is a message-level attribute.
    case message    = 1

    /// The attribute is an attachment-level attribute.
    case attachment = 2
}
