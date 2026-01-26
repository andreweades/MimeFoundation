//
// ContentEncoding.swift
//
// Ported from MimeKit (C#) to Swift.
//

/// An enumeration of all supported content transfer encodings.
///
/// Some older mail software is unable to properly deal with data outside the ASCII range,
/// so it is sometimes necessary to encode the content of MIME entities.
///
/// - SeeAlso: ``MimePart/contentTransferEncoding``
public enum ContentEncoding: String, CaseIterable, Sendable {
    /// The default encoding (aka no encoding at all).
    case `default`

    /// The 7bit content transfer encoding.
    ///
    /// This encoding should be restricted to textual content in the US-ASCII range.
    case sevenBit

    /// The 8bit content transfer encoding.
    ///
    /// This encoding should be restricted to textual content outside the US-ASCII range
    /// but may not be supported by all transport services such as older SMTP servers
    /// that do not support the 8BITMIME extension.
    case eightBit

    /// The binary content transfer encoding.
    ///
    /// This encoding is simply unencoded binary data. Typically not supported by
    /// standard message transport services such as SMTP.
    case binary

    /// The base64 content transfer encoding.
    ///
    /// This encoding is typically used for encoding binary data or textual content
    /// in a largely 8bit charset encoding and is supported by all message transport services.
    case base64

    /// The quoted-printable content transfer encoding.
    ///
    /// This encoding is used for textual content that is in a charset that has a
    /// minority of characters outside the US-ASCII range (such as ISO-8859-1 and
    /// other single-byte charset encodings) and is supported by all message transport services.
    case quotedPrintable

    /// The uuencode content transfer encoding.
    ///
    /// This is an obsolete encoding meant for encoding binary data and has largely
    /// been superseded by ``base64``.
    case uuEncode
}
