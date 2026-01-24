//
// HtmlWriterState.swift
//
// Ported from MimeKit (C#) to Swift.
//

public enum HtmlWriterState: Sendable {
    case `default`
    case tag
    case attribute
}
