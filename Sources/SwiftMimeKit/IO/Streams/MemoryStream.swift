//
// MemoryStream.swift
//
// Ported from MimeKit (C#) to Swift.
//

import Foundation

public final class MemoryStream: ResizableStream {
    private var storage: [UInt8]
    private var closed = false

    public let canRead: Bool
    public let canWrite: Bool
    public let canSeek: Bool
    public let canTimeout: Bool = false

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
            currentPosition = max(0, min(newValue, storage.count))
        }
    }

    public var length: Int { storage.count }

    private var currentPosition: Int

    public init(_ data: [UInt8] = [], writable: Bool = true) {
        self.storage = data
        self.canRead = true
        self.canWrite = writable
        self.canSeek = true
        self.currentPosition = 0
    }

    public func read(_ buffer: inout [UInt8], offset: Int, count: Int) throws -> Int {
        try ensureOpen()
        guard canRead else {
            throw StreamError.notSupported
        }
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
        guard canWrite else {
            throw StreamError.notSupported
        }
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
        guard canSeek else {
            throw StreamError.notSupported
        }
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

    public func close() {
        closed = true
    }

    public func toByteArray() -> [UInt8] {
        storage
    }

    private func ensureOpen() throws {
        if closed {
            throw StreamError.closed
        }
    }
}
