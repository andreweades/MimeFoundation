//
// ParameterEncodingMethod.swift
//
// Ported from MimeKit (C#) to Swift.
//

public enum ParameterEncodingMethod: UInt8, Sendable {
    case `default` = 0
    case rfc2231 = 1
    case rfc2047 = 2
}
