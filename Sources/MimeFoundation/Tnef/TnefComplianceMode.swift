//
// TnefComplianceMode.swift
//
// Ported from MimeKit (C#) to Swift.
//

/// A TNEF compliance mode.
///
/// Controls how strictly the TNEF parser validates the input stream.
/// Use ``loose`` for maximum compatibility with malformed TNEF data,
/// or ``strict`` for strict validation.
public enum TnefComplianceMode: Int, Sendable {
    /// Use a loose compliance mode, attempting to ignore invalid or corrupt data.
    ///
    /// In loose mode, the parser will attempt to continue reading the TNEF stream
    /// even when it encounters invalid or corrupted data. This mode is recommended
    /// for processing real-world TNEF data that may not strictly conform to the
    /// specification.
    case loose

    /// Use a very strict compliance mode, aborting the parser at the first sign of
    /// invalid or corrupted data.
    ///
    /// In strict mode, the parser will throw a ``TnefException`` as soon as it
    /// encounters any invalid or corrupted data. This mode is useful for validating
    /// TNEF streams or debugging TNEF generation code.
    case strict
}
