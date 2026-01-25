//
// MimeStream.swift
//
// Ported from MimeKit (C#) to Swift.
//

import Foundation

public enum SeekOrigin: Sendable {
    case begin
    case current
    case end
}

public enum StreamError: Error, Sendable {
    case notSupported
    case invalidArgument
    case outOfRange
    case closed
}

public protocol MimeStream: AnyObject {
    var canRead: Bool { get }
    var canWrite: Bool { get }
    var canSeek: Bool { get }
    var canTimeout: Bool { get }
    var readTimeout: Int { get set }
    var writeTimeout: Int { get set }
    var position: Int { get set }
    var length: Int { get }

    func read(_ buffer: inout [UInt8], offset: Int, count: Int) throws -> Int
    func write(_ buffer: [UInt8], offset: Int, count: Int) throws
    func seek(_ offset: Int, origin: SeekOrigin) throws -> Int
    func flush() throws
    func close()
}

// MARK: - Capability Marker Protocols

/// A stream that guarantees read capability at compile time.
///
/// Conforming types declare that their `canRead` property always returns `true`.
/// This enables APIs that require readable streams to be non-throwing when
/// the stream type is known at compile time.
///
/// ## Conforming to ReadableStream
///
/// Types should only conform to `ReadableStream` if they unconditionally support
/// reading. The `canRead` property must always return `true`:
///
/// ```swift
/// public final class MyReadableStream: MimeStream, ReadableStream {
///     public var canRead: Bool { true }  // Must always be true
///     // ...
/// }
/// ```
///
/// ## Example Usage
///
/// ```swift
/// func process(_ stream: some ReadableStream) {
///     // No need to check canRead - it's guaranteed by the type
///     var buffer = [UInt8](repeating: 0, count: 1024)
///     let bytesRead = try stream.read(&buffer, offset: 0, count: buffer.count)
/// }
/// ```
public protocol ReadableStream: MimeStream {}

/// A stream that guarantees write capability at compile time.
///
/// Conforming types declare that their `canWrite` property always returns `true`.
/// This enables APIs that require writable streams to be non-throwing when
/// the stream type is known at compile time.
///
/// ## Conforming to WritableStream
///
/// Types should only conform to `WritableStream` if they unconditionally support
/// writing. The `canWrite` property must always return `true`:
///
/// ```swift
/// public final class MyWritableStream: MimeStream, WritableStream {
///     public var canWrite: Bool { true }  // Must always be true
///     // ...
/// }
/// ```
public protocol WritableStream: MimeStream {}

/// A stream that guarantees seek capability at compile time.
///
/// Conforming types declare that their `canSeek` property always returns `true`.
/// This enables APIs that require seekable streams to be non-throwing when
/// the stream type is known at compile time.
///
/// ## Conforming to SeekableStream
///
/// Types should only conform to `SeekableStream` if they unconditionally support
/// seeking. The `canSeek` property must always return `true`:
///
/// ```swift
/// public final class MySeekableStream: MimeStream, SeekableStream {
///     public var canSeek: Bool { true }  // Must always be true
///     // ...
/// }
/// ```
public protocol SeekableStream: MimeStream {}

/// A stream suitable for use as MIME content storage.
///
/// This typealias combines `ReadableStream` and `SeekableStream`, representing
/// streams that can be used to store MIME content. MIME content requires both
/// reading (to access the content) and seeking (to reset position for re-reading).
///
/// ## Example Usage
///
/// ```swift
/// // MemoryStream conforms to ContentStream, so this doesn't throw
/// let content = MimeContent(MemoryStream(data))
///
/// // For unknown stream types, use the throwing initializer
/// let content = try MimeContent(stream: unknownStream)
/// ```
///
/// ## Conforming Types
///
/// - `MemoryStream`: Always readable and seekable
/// - `MemoryBlockStream`: Always readable, writable, and seekable
public typealias ContentStream = ReadableStream & SeekableStream
