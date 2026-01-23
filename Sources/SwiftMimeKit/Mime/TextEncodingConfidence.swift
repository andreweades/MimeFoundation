//
// TextEncodingConfidence.swift
//
// Ported from MimeKit (C#) to Swift.
//

public enum TextEncodingConfidence: Int, Sendable {
    case undefined
    case irrelevant
    case tentative
    case certain
}
