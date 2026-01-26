//
// NewLineFormat.swift
//
// Ported from MimeKit (C#) to Swift.
//

/// A new-line format.
///
/// There are two commonly used line-endings used by modern Operating Systems.
/// Unix-based systems such as Linux and macOS use a single character (`'\n'` aka LF)
/// to represent the end of line where-as Windows (or DOS) uses a sequence of two
/// characters (`"\r\n"` aka CRLF). Most text-based network protocols such as SMTP,
/// POP3, and IMAP use the CRLF sequence as well.
public enum NewLineFormat: UInt8, Sendable {
    /// The Unix new-line format (`"\n"`).
    ///
    /// This is the standard line ending used on Unix-based systems like Linux and macOS.
    case unix

    /// The DOS new-line format (`"\r\n"`).
    ///
    /// This is the standard line ending used on Windows systems and is also used
    /// by most text-based network protocols such as SMTP, POP3, and IMAP.
    case dos

    /// A mixed new-line format.
    ///
    /// This value indicates that some lines use Unix-based line endings and
    /// other lines use DOS-based line endings.
    case mixed
}
