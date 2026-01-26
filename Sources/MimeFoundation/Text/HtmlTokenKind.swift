//
// HtmlTokenKind.swift
//
// Ported from MimeKit (C#) to Swift.
//

/// The kinds of tokens that the ``HtmlTokenizer`` can emit.
///
/// Represents the different types of tokens that can be produced during HTML tokenization.
public enum HtmlTokenKind: Sendable {
    /// A token consisting of character data.
    case data

    /// An HTML comment token.
    case comment

    /// An HTML tag token.
    case tag
}
