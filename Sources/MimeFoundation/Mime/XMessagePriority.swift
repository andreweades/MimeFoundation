//
// XMessagePriority.swift
//
// Ported from MimeKit (C#) to Swift.
//

public enum XMessagePriority: Int, Sendable {
    case highest = 1
    case high = 2
    case normal = 3
    case low = 4
    case lowest = 5
}
