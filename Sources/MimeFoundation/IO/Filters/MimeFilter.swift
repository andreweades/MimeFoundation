//
// MimeFilter.swift
//
// Ported from MimeKit (C#) to Swift.
//

/// A protocol for incrementally filtering data.
///
/// ``MimeFilter`` provides the fundamental interface for transforming data
/// as it passes through a stream. Filters can be chained together in a
/// ``FilteredStream`` to perform multiple transformations.
///
/// ## Overview
///
/// Filters are used throughout the MIME processing pipeline for operations such as:
/// - Encoding and decoding content (Base64, Quoted-Printable, etc.)
/// - Converting between character encodings
/// - Transforming line endings (Unix/DOS conversion)
/// - Analyzing content to determine optimal encoding
///
/// ## Implementing MimeFilter
///
/// When implementing a custom filter:
///
/// 1. The ``filter(_:startIndex:length:outputIndex:outputLength:)`` method should
///    process input data incrementally, potentially buffering incomplete sequences.
///
/// 2. The ``flush(_:startIndex:length:outputIndex:outputLength:)`` method should
///    process remaining input and output any buffered data, completing the filtering.
///
/// 3. The ``reset()`` method should clear all internal state, preparing the filter
///    for reuse with new data.
///
/// ## Built-in Filters
///
/// The library provides several filter implementations:
///
/// - ``EncoderFilter``: Encodes content using Base64, Quoted-Printable, or UUEncode
/// - ``DecoderFilter``: Decodes content from Base64, Quoted-Printable, or UUEncode
/// - ``CharsetFilter``: Converts text between different character encodings
/// - ``BestEncodingFilter``: Analyzes content to determine optimal encoding
/// - ``Unix2DosFilter``: Converts Unix line endings (LF) to DOS line endings (CRLF)
/// - ``Dos2UnixFilter``: Converts DOS line endings (CRLF) to Unix line endings (LF)
public protocol MimeFilter: AnyObject {
    /// Filters the specified input.
    ///
    /// Filters the specified input buffer starting at the given index,
    /// spanning across the specified number of bytes.
    ///
    /// - Parameters:
    ///   - input: The input buffer containing data to filter.
    ///   - startIndex: The starting index of the input buffer.
    ///   - length: The number of bytes of the input to filter.
    ///   - outputIndex: On return, contains the starting index of the output
    ///     in the returned buffer.
    ///   - outputLength: On return, contains the length of the output.
    ///
    /// - Returns: The output buffer containing the filtered data. The actual
    ///   filtered content starts at `outputIndex` and has length `outputLength`.
    ///
    /// ## Note
    ///
    /// The returned buffer may be the same as the input buffer or a different
    /// buffer managed by the filter. The caller should not assume ownership of
    /// the returned buffer beyond the current call.
    func filter(_ input: [UInt8], startIndex: Int, length: Int, outputIndex: inout Int, outputLength: inout Int) -> [UInt8]

    /// Filters the specified input, flushing all internally buffered data to the output.
    ///
    /// Filters the specified input buffer starting at the given index,
    /// spanning across the specified number of bytes. Any data buffered
    /// internally by the filter is also written to the output.
    ///
    /// This method should be called when no more input data is available,
    /// to ensure all buffered data is written out.
    ///
    /// - Parameters:
    ///   - input: The input buffer containing data to filter.
    ///   - startIndex: The starting index of the input buffer.
    ///   - length: The number of bytes of the input to filter.
    ///   - outputIndex: On return, contains the starting index of the output
    ///     in the returned buffer.
    ///   - outputLength: On return, contains the length of the output.
    ///
    /// - Returns: The output buffer containing the filtered data plus any
    ///   internally buffered data.
    func flush(_ input: [UInt8], startIndex: Int, length: Int, outputIndex: inout Int, outputLength: inout Int) -> [UInt8]

    /// Resets the filter to its initial state.
    ///
    /// Clears all internal state, including any buffered data, allowing the
    /// filter to be reused for processing new data.
    ///
    /// This method is called automatically when a ``FilteredStream`` switches
    /// between reading and writing modes.
    func reset()
}
