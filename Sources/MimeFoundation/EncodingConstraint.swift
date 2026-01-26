//
// EncodingConstraint.swift
//
// Ported from MimeKit (C#) to Swift.
//

/// A content encoding constraint.
///
/// Not all message transports support binary or 8-bit data, so it becomes
/// necessary to constrain the content encoding to a subset of the possible
/// Content-Transfer-Encoding values.
public enum EncodingConstraint: Sendable {
    /// There are no encoding constraints, the content may contain any byte.
    ///
    /// Use this when the transport supports binary data.
    case none

    /// The content may only contain bytes within the 7-bit ASCII range.
    ///
    /// Use this constraint for transports that only support 7-bit data,
    /// such as older SMTP servers.
    case sevenBit

    /// The content may contain bytes with the high bit set, but must not contain any zero-bytes.
    ///
    /// Use this constraint for transports that support the 8BITMIME extension.
    case eightBit
}
