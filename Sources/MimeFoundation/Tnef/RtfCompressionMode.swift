//
// RtfCompressionMode.swift
//
// Ported from MimeKit (C#) to Swift.
//

/// An RTF compression mode.
public enum RtfCompressionMode: Int, Sendable {
    /// The compression mode is not known.
    case unknown      = 0

    /// The RTF stream is not compressed.
    case uncompressed = 0x414C454D

    /// The RTF stream is compressed.
    case compressed   = 0x75465A4C
}
