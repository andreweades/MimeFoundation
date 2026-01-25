//
// MemoryBlockStream.swift
//
// Ported from MimeKit (C#) to Swift.
//

public final class MemoryBlockStream: ResizableStream, ReadableStream, WritableStream, SeekableStream {
    private var storage: [UInt8] = []
    private var currentPosition: Int = 0
    private var closed = false

    public init() {}

    public var canRead: Bool { true }
    public var canWrite: Bool { true }
    public var canSeek: Bool { true }
    public var canTimeout: Bool { false }

    public var readTimeout: Int {
        get { 0 }
        set { }
    }

    public var writeTimeout: Int {
        get { 0 }
        set { }
    }

    public var position: Int {
        get { currentPosition }
        set {
            _ = try? seek(newValue, origin: .begin)
        }
    }

    public var length: Int { storage.count }

    public func read(_ buffer: inout [UInt8], offset: Int, count: Int) throws -> Int {
        try ensureOpen()
        guard offset >= 0, count >= 0, offset + count <= buffer.count else {
            throw StreamError.invalidArgument
        }
        if currentPosition >= storage.count {
            return 0
        }
        let available = storage.count - currentPosition
        let toRead = min(count, available)
        if toRead > 0 {
            buffer.replaceSubrange(offset..<(offset + toRead), with: storage[currentPosition..<(currentPosition + toRead)])
            currentPosition += toRead
        }
        return toRead
    }

    public func write(_ buffer: [UInt8], offset: Int, count: Int) throws {
        try ensureOpen()
        guard offset >= 0, count >= 0, offset + count <= buffer.count else {
            throw StreamError.invalidArgument
        }
        let requiredLength = currentPosition + count
        if requiredLength > storage.count {
            storage.append(contentsOf: repeatElement(0, count: requiredLength - storage.count))
        }
        storage.replaceSubrange(currentPosition..<(currentPosition + count), with: buffer[offset..<(offset + count)])
        currentPosition += count
    }

    public func seek(_ offset: Int, origin: SeekOrigin) throws -> Int {
        try ensureOpen()
        let base: Int
        switch origin {
        case .begin:
            base = 0
        case .current:
            base = currentPosition
        case .end:
            base = storage.count
        }
        let newPosition = base + offset
        guard newPosition >= 0, newPosition <= storage.count else {
            throw StreamError.outOfRange
        }
        currentPosition = newPosition
        return currentPosition
    }

    public func flush() throws {
        try ensureOpen()
    }

    public func close() {
        closed = true
    }

    public func setLength(_ length: Int) throws {
        try ensureOpen()
        guard length >= 0 else {
            throw StreamError.outOfRange
        }
        if length < storage.count {
            storage.removeLast(storage.count - length)
        } else if length > storage.count {
            storage.append(contentsOf: repeatElement(0, count: length - storage.count))
        }
        if currentPosition > length {
            currentPosition = length
        }
    }

    public func toArray() throws -> [UInt8] {
        try ensureOpen()
        return storage
    }

    private func ensureOpen() throws {
        if closed {
            throw StreamError.closed
        }
    }
}
