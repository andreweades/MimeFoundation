//
// ResizableStream.swift
//
// Ported from MimeKit (C#) to Swift.
//

/// A protocol for streams that support resizing their length.
///
/// ``ResizableStream`` extends ``MimeStream`` to provide the ability to
/// explicitly set the stream's length, which may involve truncating or
/// expanding the stream's storage.
///
/// ## Overview
///
/// Streams that conform to this protocol allow their length to be changed
/// programmatically. When the length is reduced, data beyond the new length
/// is discarded. When the length is increased, the new space is typically
/// filled with zeros.
public protocol ResizableStream: MimeStream {
    /// Sets the length of the stream.
    ///
    /// If the specified value is less than the current length, the stream is truncated.
    /// If the specified value is larger than the current length, the stream is expanded
    /// and the new bytes are typically initialized to zero.
    ///
    /// - Parameter length: The desired length of the stream in bytes.
    ///
    /// - Throws: ``StreamError/closed`` if the stream has been closed,
    ///   ``StreamError/notSupported`` if the stream does not support resizing,
    ///   or ``StreamError/outOfRange`` if `length` is negative.
    func setLength(_ length: Int) throws
}
