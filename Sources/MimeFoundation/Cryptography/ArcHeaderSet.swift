//
// ArcHeaderSet.swift
//
// Ported from MimeKit (C#) to Swift.
//

import Foundation

/// A class that groups related ARC headers by instance number.
///
/// Each ARC chain instance (i=1, i=2, etc.) consists of three headers:
/// - ARC-Authentication-Results
/// - ARC-Message-Signature
/// - ARC-Seal
///
/// This class collects and tracks these three headers for a single instance.
public final class ArcHeaderSet {
    /// The ARC-Authentication-Results header for this instance.
    public internal(set) var arcAuthenticationResults: Header?

    /// The ARC-Message-Signature header for this instance.
    public internal(set) var arcMessageSignature: Header?

    /// The parsed parameters from the ARC-Message-Signature header.
    public internal(set) var arcMessageSignatureParameters: [String: String]?

    /// The ARC-Seal header for this instance.
    public internal(set) var arcSeal: Header?

    /// The parsed parameters from the ARC-Seal header.
    public internal(set) var arcSealParameters: [String: String]?

    /// Creates a new empty ARC header set.
    public init() {}

    /// Adds a header to this set.
    ///
    /// - Parameters:
    ///   - header: The header to add.
    ///   - parameters: The parsed parameters from the header (for AMS and AS headers).
    /// - Returns: `true` if the header was added successfully; `false` if a duplicate was detected.
    internal func add(header: Header, parameters: [String: String]? = nil) -> Bool {
        switch header.id {
        case .arcAuthenticationResults:
            if arcAuthenticationResults != nil {
                return false
            }
            arcAuthenticationResults = header
            return true

        case .arcMessageSignature:
            if arcMessageSignature != nil {
                return false
            }
            arcMessageSignature = header
            arcMessageSignatureParameters = parameters
            return true

        case .arcSeal:
            if arcSeal != nil {
                return false
            }
            arcSeal = header
            arcSealParameters = parameters
            return true

        default:
            return false
        }
    }

    /// Checks if all three required headers are present.
    public var isComplete: Bool {
        arcAuthenticationResults != nil && arcMessageSignature != nil && arcSeal != nil
    }

    /// Gets any validation errors for missing headers in this set.
    internal var missingHeaderErrors: ArcValidationErrors {
        var errors: ArcValidationErrors = []
        if arcAuthenticationResults == nil {
            errors.insert(.missingArcAuthenticationResults)
        }
        if arcMessageSignature == nil {
            errors.insert(.missingArcMessageSignature)
        }
        if arcSeal == nil {
            errors.insert(.missingArcSeal)
        }
        return errors
    }
}
