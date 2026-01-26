//
// TnefComplianceStatus.swift
//
// Ported from MimeKit (C#) to Swift.
//

import Foundation

/// A bitfield of potential TNEF compliance issues.
///
/// This option set tracks any compliance issues encountered while parsing a TNEF stream.
/// Multiple flags can be set simultaneously to indicate multiple issues.
public struct TnefComplianceStatus: OptionSet, Sendable {
    /// The raw integer value of the compliance status.
    public let rawValue: Int

    /// Initialize a new instance of the ``TnefComplianceStatus`` struct.
    ///
    /// - Parameter rawValue: The raw integer value representing the compliance flags.
    public init(rawValue: Int) {
        self.rawValue = rawValue
    }

    /// The TNEF stream has no errors.
    ///
    /// This value indicates that the TNEF stream is fully compliant with the specification.
    public static let compliant                = TnefComplianceStatus([])

    /// The TNEF stream has too many attributes.
    ///
    /// This error occurs when the number of attributes in the TNEF stream exceeds
    /// the maximum allowed limit.
    public static let attributeOverflow        = TnefComplianceStatus(rawValue: 1 << 0)

    /// The TNEF stream has one or more invalid attributes.
    ///
    /// This error occurs when an attribute tag is not recognized or is malformed.
    public static let invalidAttribute         = TnefComplianceStatus(rawValue: 1 << 1)

    /// The TNEF stream has one or more attributes with invalid checksums.
    ///
    /// This error occurs when the checksum for an attribute does not match
    /// the computed checksum of the attribute data.
    public static let invalidAttributeChecksum = TnefComplianceStatus(rawValue: 1 << 2)

    /// The TNEF stream has one or more attributes with an invalid length.
    ///
    /// This error occurs when the specified length of an attribute is invalid
    /// or exceeds the remaining data in the stream.
    public static let invalidAttributeLength   = TnefComplianceStatus(rawValue: 1 << 3)

    /// The TNEF stream has one or more attributes with an invalid level.
    ///
    /// This error occurs when an attribute has a level value that is not
    /// ``TnefAttributeLevel/message`` or ``TnefAttributeLevel/attachment``.
    public static let invalidAttributeLevel    = TnefComplianceStatus(rawValue: 1 << 4)

    /// The TNEF stream has one or more attributes with an invalid value.
    ///
    /// This error occurs when the value of an attribute cannot be parsed
    /// or does not match the expected format.
    public static let invalidAttributeValue    = TnefComplianceStatus(rawValue: 1 << 5)

    /// The TNEF stream has one or more attributes with an invalid date value.
    ///
    /// This error occurs when a date attribute contains an invalid or
    /// unparseable date/time value.
    public static let invalidDate              = TnefComplianceStatus(rawValue: 1 << 6)

    /// The TNEF stream has one or more invalid MessageClass attributes.
    ///
    /// This error occurs when the MessageClass attribute contains an
    /// invalid or unrecognized value.
    public static let invalidMessageClass      = TnefComplianceStatus(rawValue: 1 << 7)

    /// The TNEF stream has one or more invalid MessageCodepage attributes.
    ///
    /// This error occurs when the MessageCodepage attribute specifies an
    /// invalid or unsupported code page.
    public static let invalidMessageCodepage   = TnefComplianceStatus(rawValue: 1 << 8)

    /// The TNEF stream has one or more invalid property lengths.
    ///
    /// This error occurs when a MAPI property has an invalid length value.
    public static let invalidPropertyLength    = TnefComplianceStatus(rawValue: 1 << 9)

    /// The TNEF stream has one or more invalid row counts.
    ///
    /// This error occurs when the row count in a recipient table or
    /// other tabular data is invalid.
    public static let invalidRowCount          = TnefComplianceStatus(rawValue: 1 << 10)

    /// The TNEF stream has an invalid signature value.
    ///
    /// This error occurs when the TNEF signature bytes at the start of
    /// the stream do not match the expected value (0x223E9F78).
    public static let invalidTnefSignature     = TnefComplianceStatus(rawValue: 1 << 11)

    /// The TNEF stream has an invalid version value.
    ///
    /// This error occurs when the TNEF version number in the stream
    /// is not recognized or is too old/new to be supported.
    public static let invalidTnefVersion       = TnefComplianceStatus(rawValue: 1 << 12)

    /// The TNEF stream is nested too deeply.
    ///
    /// This error occurs when embedded TNEF data exceeds the maximum
    /// allowed nesting depth.
    public static let nestingTooDeep           = TnefComplianceStatus(rawValue: 1 << 13)

    /// The TNEF stream is truncated.
    ///
    /// This error occurs when the TNEF stream ends unexpectedly before
    /// all expected data has been read.
    public static let streamTruncated          = TnefComplianceStatus(rawValue: 1 << 14)

    /// The TNEF stream has one or more unsupported property types.
    ///
    /// This error occurs when the stream contains MAPI properties with
    /// types that are not supported by the parser.
    public static let unsupportedPropertyType  = TnefComplianceStatus(rawValue: 1 << 15)
}
