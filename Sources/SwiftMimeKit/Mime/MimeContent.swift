//
// MimeContent.swift
//
// Ported from MimeKit (C#) to Swift.
//

import Foundation

public enum MimeContentError: Error {
    case nilStream
    case streamNotReadable
    case streamNotSeekable
    case disposed
    case nilDestination
}

public final class MimeContent {
    private static let bufferLength = 4096

    public let encoding: ContentEncoding
    public var newLineFormat: NewLineFormat?

    private var stream: MimeStream?

    public init(_ stream: MimeStream?, encoding: ContentEncoding = .default) throws {
        guard let stream else {
            throw MimeContentError.nilStream
        }
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
        return stream
    }

    public func writeTo(_ destination: MimeStream?, cancellationToken: CancellationToken? = nil) throws {
        guard let destination else {
            throw MimeContentError.nilDestination
        }
        try checkDisposed()
        guard let source = stream else {
            throw MimeContentError.disposed
        }
        if cancellationToken?.isCancelled == true {
            throw OperationCanceledError()
        }
        _ = try source.seek(0, origin: .begin)

        var buffer = [UInt8](repeating: 0, count: MimeContent.bufferLength)
        while true {
            if cancellationToken?.isCancelled == true {
                throw OperationCanceledError()
            }
            let read = try source.read(&buffer, offset: 0, count: buffer.count)
            if read == 0 {
                break
            }
            try destination.write(buffer, offset: 0, count: read)
        }
    }

    public func writeToAsync(_ destination: MimeStream?, cancellationToken: CancellationToken? = nil) async throws {
        try writeTo(destination, cancellationToken: cancellationToken)
    }

    public func decodeTo(_ destination: MimeStream?, cancellationToken: CancellationToken? = nil) throws {
        try writeTo(destination, cancellationToken: cancellationToken)
    }

    public func decodeToAsync(_ destination: MimeStream?, cancellationToken: CancellationToken? = nil) async throws {
        try writeTo(destination, cancellationToken: cancellationToken)
    }

    private func checkDisposed() throws {
        if stream == nil {
            throw MimeContentError.disposed
        }
    }
}
