//
// TextFormat.swift
//
// Ported from MimeKit (C#) to Swift.
//

/// An enumeration of text formats.
///
/// Represents the various text formats that can be used for message content.
public enum TextFormat: Int, Sendable, CaseIterable {
    /// The plain text format.
    case plain

    /// The flowed text format (as described in RFC 3676).
    case flowed

    /// The HTML text format.
    case html

    /// The enriched text format.
    case enriched

    /// The rich text format.
    case richText

    /// The compressed rich text format.
    case compressedRichText
}
