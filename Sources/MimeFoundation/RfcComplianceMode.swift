//
// RfcComplianceMode.swift
//
// Ported from MimeKit (C#) to Swift.
//

/// An RFC compliance mode.
///
/// This enumeration is used to control how strictly the parser adheres to the
/// RFC specifications when parsing MIME content.
public enum RfcComplianceMode: Int, Sendable {
    /// Attempt to be even more liberal in accepting broken and/or invalid formatting.
    ///
    /// This mode provides the maximum level of compatibility with malformed email content.
    case looser = -1

    /// Attempt to be more liberal accepting broken and/or invalid formatting.
    ///
    /// This is the default mode and provides good compatibility with existing
    /// (broken) mail clients and other mail software such as sloppily written scripts.
    case loose = 0

    /// Do not attempt to be overly liberal in accepting broken and/or invalid formatting.
    ///
    /// Use this mode when you need stricter RFC compliance and want to reject
    /// malformed content.
    case strict = 1
}
