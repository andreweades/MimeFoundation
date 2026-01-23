//
// RfcComplianceMode.swift
//
// Ported from MimeKit (C#) to Swift.
//

public enum RfcComplianceMode: Int, Sendable {
    case looser = -1
    case loose = 0
    case strict = 1
}
