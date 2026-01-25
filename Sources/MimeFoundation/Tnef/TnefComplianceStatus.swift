//
// TnefComplianceStatus.swift
//
// Ported from MimeKit (C#) to Swift.
//

import Foundation

/// A bitfield of potential TNEF compliance issues.
public struct TnefComplianceStatus: OptionSet, Sendable {
    public let rawValue: Int

    public init(rawValue: Int) {
        self.rawValue = rawValue
    }

    /// The TNEF stream has no errors.
    public static let compliant                = TnefComplianceStatus([])

    /// The TNEF stream has too many attributes.
    public static let attributeOverflow        = TnefComplianceStatus(rawValue: 1 << 0)

    /// The TNEF stream has one or more invalid attributes.
    public static let invalidAttribute         = TnefComplianceStatus(rawValue: 1 << 1)

    /// The TNEF stream has one or more attributes with invalid checksums.
    public static let invalidAttributeChecksum = TnefComplianceStatus(rawValue: 1 << 2)

    /// The TNEF stream has one or more attributes with an invalid length.
    public static let invalidAttributeLength   = TnefComplianceStatus(rawValue: 1 << 3)

    /// The TNEF stream has one or more attributes with an invalid level.
    public static let invalidAttributeLevel    = TnefComplianceStatus(rawValue: 1 << 4)

    /// The TNEF stream has one or more attributes with an invalid value.
    public static let invalidAttributeValue    = TnefComplianceStatus(rawValue: 1 << 5)

    /// The TNEF stream has one or more attributes with an invalid date value.
    public static let invalidDate              = TnefComplianceStatus(rawValue: 1 << 6)

    /// The TNEF stream has one or more invalid MessageClass attributes.
    public static let invalidMessageClass      = TnefComplianceStatus(rawValue: 1 << 7)

    /// The TNEF stream has one or more invalid MessageCodepage attributes.
    public static let invalidMessageCodepage   = TnefComplianceStatus(rawValue: 1 << 8)

    /// The TNEF stream has one or more invalid property lengths.
    public static let invalidPropertyLength    = TnefComplianceStatus(rawValue: 1 << 9)

    /// The TNEF stream has one or more invalid row counts.
    public static let invalidRowCount          = TnefComplianceStatus(rawValue: 1 << 10)

    /// The TNEF stream has an invalid signature value.
    public static let invalidTnefSignature     = TnefComplianceStatus(rawValue: 1 << 11)

    /// The TNEF stream has an invalid version value.
    public static let invalidTnefVersion       = TnefComplianceStatus(rawValue: 1 << 12)

    /// The TNEF stream is nested too deeply.
    public static let nestingTooDeep           = TnefComplianceStatus(rawValue: 1 << 13)

    /// The TNEF stream is truncated.
    public static let streamTruncated          = TnefComplianceStatus(rawValue: 1 << 14)

    /// The TNEF stream has one or more unsupported property types.
    public static let unsupportedPropertyType  = TnefComplianceStatus(rawValue: 1 << 15)
}
