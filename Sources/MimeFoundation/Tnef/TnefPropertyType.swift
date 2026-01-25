//
// TnefPropertyType.swift
//
// Ported from MimeKit (C#) to Swift.
//

/// The type of value that a TNEF property contains.
public enum TnefPropertyType: Int16, Sendable {
    /// The type of the property is unspecified.
    case unspecified = 0

    /// The property has a null value.
    case null        = 1

    /// The property has a signed 16-bit value.
    case i2          = 2

    /// The property has a signed 32-bit value.
    case long        = 3

    /// The property has a 32-bit floating point value.
    case r4          = 4

    /// The property has a 64-bit floating point value.
    case double      = 5

    /// The property has a 64-bit integer value representing 1/10000th of a monetary unit.
    case currency    = 6

    /// The property has a 64-bit integer value specifying the number of 100ns periods since Jan 1, 1601.
    case appTime     = 7

    /// The property has a 32-bit error value.
    case error       = 10

    /// The property has a boolean value.
    case boolean     = 11

    /// The property has an embedded object value.
    case object      = 13

    /// The property has a signed 64-bit value.
    case i8          = 20

    /// The property has a null-terminated 8-bit character string value.
    case string8     = 30

    /// The property has a null-terminated unicode character string value.
    case unicode     = 31

    /// The property has a 64-bit integer value specifying the number of 100ns periods since Jan 1, 1601.
    case sysTime     = 64

    /// The property has an OLE GUID value.
    case classId     = 72

    /// The property has a binary blob value.
    case binary      = 258

    /// A flag indicating that the property contains multiple values.
    case multiValued = 4096
}
