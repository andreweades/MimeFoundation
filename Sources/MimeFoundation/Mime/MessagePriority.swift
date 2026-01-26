//
// MessagePriority.swift
//
// Ported from MimeKit (C#) to Swift.
//

/// An enumeration of message priority values.
///
/// Indicates the priority of a message as specified in the Priority header.
public enum MessagePriority: Sendable {
    /// The message has non-urgent priority.
    case nonUrgent

    /// The message has normal priority.
    case normal

    /// The message has urgent priority.
    case urgent
}
