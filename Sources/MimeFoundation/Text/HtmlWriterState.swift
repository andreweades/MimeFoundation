//
// HtmlWriterState.swift
//
// Ported from MimeKit (C#) to Swift.
//

/// An enumeration of possible states of an ``HtmlWriter``.
///
/// Represents the current writing context of an HTML writer.
public enum HtmlWriterState: Sendable {
    /// The ``HtmlWriter`` is not within a tag. In this state, the ``HtmlWriter``
    /// can only write a tag or text.
    case `default`

    /// The ``HtmlWriter`` is inside a tag but has not started to write an attribute. In this
    /// state, the ``HtmlWriter`` can write an attribute, another tag, or text.
    case tag

    /// The ``HtmlWriter`` is inside an attribute. In this state, the ``HtmlWriter``
    /// can append a value to the current attribute, start the next attribute, or write another tag or text.
    case attribute
}
