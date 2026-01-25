//
// MimeContent.swift
//
// Ported from MimeKit (C#) to Swift.
//

import Foundation

public enum MimeContentError: Error, Sendable {
    case streamNotReadable
    case streamNotSeekable
    case disposed
}

public final class MimeContent {
    private static let bufferLength = 4096

    public let encoding: ContentEncoding
    public var newLineFormat: NewLineFormat?

    private var stream: MimeStream?

    /// Creates content from a stream with statically-known read and seek capabilities.
    /// This initializer cannot fail since the stream type guarantees the required capabilities.
    public init(_ stream: some ContentStream, encoding: ContentEncoding = .default) {
        self.encoding = encoding
        self.stream = stream
    }

    /// Creates content from any MimeStream, throwing if required capabilities are missing.
    /// Prefer using the non-throwing initializer with `ContentStream` when possible.
    public init(stream: MimeStream, encoding: ContentEncoding = .default) throws {
        guard stream.canRead else {
            throw MimeContentError.streamNotReadable
        }
        guard stream.canSeek else {
            throw MimeContentError.streamNotSeekable
        }
        self.encoding = encoding
        self.stream = stream
    }

    public func open() throws -> MimeStream {
        try checkDisposed()
        guard let stream else {
            throw MimeContentError.disposed
        }
        _ = try stream.seek(0, origin: .begin)
        let filtered = try FilteredStream(stream)
        let filter = DecoderFilter.create(encoding)
        _ = try filtered.add(filter)
        return filtered
    }

    public func writeTo(_ destination: MimeStream) throws {
        try checkDisposed()
        guard let source = stream else {
            throw MimeContentError.disposed
        }
        _ = try source.seek(0, origin: .begin)

        var buffer = [UInt8](repeating: 0, count: MimeContent.bufferLength)
        while true {
            let read = try source.read(&buffer, offset: 0, count: buffer.count)
            if read == 0 {
                break
            }
            try destination.write(buffer, offset: 0, count: read)
        }
    }

    public func writeToAsync(_ destination: MimeStream) async throws {
        try Task.checkCancellation()
        try checkDisposed()
        guard let source = stream else {
            throw MimeContentError.disposed
        }
        _ = try source.seek(0, origin: .begin)

        var buffer = [UInt8](repeating: 0, count: MimeContent.bufferLength)
        while true {
            try Task.checkCancellation()
            let read = try source.read(&buffer, offset: 0, count: buffer.count)
            if read == 0 {
                break
            }
            try destination.write(buffer, offset: 0, count: read)
        }
    }

    public func decodeTo(_ destination: MimeStream) throws {
        try checkDisposed()
        guard let source = stream else {
            throw MimeContentError.disposed
        }
        _ = try source.seek(0, origin: .begin)

        let filtered = try FilteredStream(source)
        let filter = DecoderFilter.create(encoding)
        _ = try filtered.add(filter)

        var buffer = [UInt8](repeating: 0, count: MimeContent.bufferLength)
        while true {
            let read = try filtered.read(&buffer, offset: 0, count: buffer.count)
            if read == 0 {
                break
            }
            try destination.write(buffer, offset: 0, count: read)
        }
    }

    public func decodeToAsync(_ destination: MimeStream) async throws {
        try Task.checkCancellation()
        try checkDisposed()
        guard let source = stream else {
            throw MimeContentError.disposed
        }
        _ = try source.seek(0, origin: .begin)

        let filtered = try FilteredStream(source)
        let filter = DecoderFilter.create(encoding)
        _ = try filtered.add(filter)

        var buffer = [UInt8](repeating: 0, count: MimeContent.bufferLength)
        while true {
            try Task.checkCancellation()
            let read = try filtered.read(&buffer, offset: 0, count: buffer.count)
            if read == 0 {
                break
            }
            try destination.write(buffer, offset: 0, count: read)
        }
    }

    private func checkDisposed() throws {
        if stream == nil {
            throw MimeContentError.disposed
        }
    }
}
