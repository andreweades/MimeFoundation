//
// TnefComplianceMode.swift
//
// Ported from MimeKit (C#) to Swift.
//

/// A TNEF compliance mode.
public enum TnefComplianceMode: Int, Sendable {
    /// Use a loose compliance mode, attempting to ignore invalid or corrupt data.
    case loose

    /// Use a very strict compliance mode, aborting the parser at the first sign of
    /// invalid or corrupted data.
    case strict
}
