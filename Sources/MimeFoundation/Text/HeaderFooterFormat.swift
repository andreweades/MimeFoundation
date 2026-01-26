//
// HeaderFooterFormat.swift
//
// Ported from MimeKit (C#) to Swift.
//

/// An enumeration of possible header and footer formats.
///
/// Specifies whether the header or footer content in a text converter
/// is plain text or properly formatted HTML.
public enum HeaderFooterFormat: Int, Sendable {
    /// The header or footer contains plain text.
    case text

    /// The header or footer contains properly formatted HTML.
    case html
}
