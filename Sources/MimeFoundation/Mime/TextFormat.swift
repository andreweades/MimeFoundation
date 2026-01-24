//
// TextFormat.swift
//
// Ported from MimeKit (C#) to Swift.
//

public enum TextFormat: Int, Sendable, CaseIterable {
    case plain
    case flowed
    case html
    case enriched
    case richText
    case compressedRichText
}
