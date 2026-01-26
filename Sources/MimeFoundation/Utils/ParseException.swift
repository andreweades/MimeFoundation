//
// ParseException.swift
//
// Ported from MimeKit (C#) to Swift.
//

/// An error that is thrown when a MIME parsing operation encounters invalid or malformed input.
///
/// `ParseException` provides detailed information about where parsing failed, including
/// both the position of the token being parsed and the exact position of the error within
/// the input buffer. This information is useful for diagnosing malformed MIME messages.
///
/// ## Error Positions
///
/// - `tokenIndex`: The position where the current token started. This helps identify
///   which part of the MIME structure was being parsed when the error occurred.
/// - `errorIndex`: The exact position where the parsing error was detected. This is
///   typically at or after `tokenIndex`.
///
/// ## Example
///
/// ```swift
/// do {
///     let address = try MailboxAddress.parse(buffer, startIndex: 0, length: buffer.count)
/// } catch let error as ParseException {
///     print("Parse error: \(error.message)")
///     print("Token started at: \(error.tokenIndex)")
///     print("Error at position: \(error.errorIndex)")
/// }
/// ```
public struct ParseException: Error, Equatable, Sendable {
    /// A human-readable description of the parsing error.
    ///
    /// This message describes what was expected or what went wrong during parsing.
    public let message: String

    /// The index into the input buffer where the token being parsed started.
    ///
    /// This represents the beginning position of the syntactic element (such as an
    /// email address, header field, or MIME boundary) that was being parsed when
    /// the error occurred.
    public let tokenIndex: Int

    /// The index into the input buffer where the error was detected.
    ///
    /// This is the exact position where parsing failed. It is typically at or
    /// after `tokenIndex`, pointing to the problematic character or the position
    /// where an expected character was missing.
    public let errorIndex: Int

    /// Creates a new parse exception with the specified error details.
    ///
    /// - Parameters:
    ///   - message: A description of the parsing error.
    ///   - tokenIndex: The position where the token being parsed started.
    ///   - errorIndex: The position where the error was detected.
    public init(_ message: String, tokenIndex: Int, errorIndex: Int) {
        self.message = message
        self.tokenIndex = tokenIndex
        self.errorIndex = errorIndex
    }
}
