//
// MeasuringStream.swift
//
// Ported from MimeKit (C#) to Swift.
//

public final class MeasuringStream: ResizableStream {
    private var currentPosition: Int = 0
    private var currentLength: Int = 0
    private var closed = false

    public init() {}

    public var canRead: Bool { false }
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

    public var length: Int { currentLength }

    public func read(_ buffer: inout [UInt8], offset: Int, count: Int) throws -> Int {
        try ensureOpen()
        throw StreamError.notSupported
    }

    public func write(_ buffer: [UInt8], offset: Int, count: Int) throws {
        try ensureOpen()
        guard offset >= 0, count >= 0, offset + count <= buffer.count else {
            throw StreamError.invalidArgument
        }
        let end = currentPosition + count
        if end > currentLength {
            currentLength = end
        }
        currentPosition = end
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
            base = currentLength
        }
        let newPosition = base + offset
        if newPosition < 0 || newPosition > currentLength {
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
        if length < 0 {
            throw StreamError.outOfRange
        }
        currentLength = length
        if currentPosition > currentLength {
            currentPosition = currentLength
        }
    }

    private func ensureOpen() throws {
        if closed {
            throw StreamError.closed
        }
    }
}
