//
// MimeFormat.swift
//
// Ported from MimeKit (C#) to Swift.
//

/// The format of the MIME stream.
///
/// This enumeration specifies the expected format of the MIME data being parsed.
public enum MimeFormat: UInt8, Sendable {
    /// The stream contains a single MIME entity or message.
    ///
    /// Use this format when parsing a standard email message or MIME entity
    /// from a stream that contains exactly one message.
    case entity = 0

    /// The stream is in the Unix mbox format and may contain more than a single message.
    ///
    /// The mbox format is a common file format for storing collections of email messages.
    /// Each message in an mbox file is preceded by a "From " line (the mbox marker).
    /// Use this format when parsing mbox files or streams containing multiple messages.
    case mbox = 1
}

public extension MimeFormat {
    /// The default stream format.
    ///
    /// The default format is ``entity``, indicating that the stream contains
    /// a single MIME entity or message.
    static var `default`: MimeFormat { .entity }
}
