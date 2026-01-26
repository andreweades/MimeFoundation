//
// TnefAttributeLevel.swift
//
// Ported from MimeKit (C#) to Swift.
//

/// A TNEF attribute level.
///
/// TNEF attributes can exist at either the message level or attachment level.
/// This enumeration identifies which level an attribute belongs to.
public enum TnefAttributeLevel: Int, Sendable {
    /// The attribute is a message-level attribute.
    ///
    /// Message-level attributes contain information about the message as a whole,
    /// such as the subject, sender, recipients, and message body.
    case message    = 1

    /// The attribute is an attachment-level attribute.
    ///
    /// Attachment-level attributes contain information about individual attachments,
    /// such as the filename, content type, and attachment data.
    case attachment = 2
}
