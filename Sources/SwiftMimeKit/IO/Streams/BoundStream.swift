//
// BoundStream.swift
//
// Ported from MimeKit (C#) to Swift.
//

import Foundation

public final class BoundStream: ResizableStream {
    public let baseStream: MimeStream
    public let startBoundary: Int
    public private(set) var endBoundary: Int
    private let leaveOpen: Bool

    private var currentPosition: Int = 0
    private var closed = false
    private var eos = false

    public init(_ baseStream: MimeStream?, startBoundary: Int, endBoundary: Int, leaveOpen: Bool) throws {
        guard let baseStream else {
            throw StreamError.invalidArgument
        }
        if startBoundary < 0 {
            throw StreamError.outOfRange
        }
        if endBoundary >= 0 && endBoundary < startBoundary {
            throw StreamError.outOfRange
        }

        self.baseStream = baseStream
        self.startBoundary = startBoundary
        self.endBoundary = endBoundary < 0 ? -1 : endBoundary
        self.leaveOpen = leaveOpen
    }

    public var canRead: Bool { baseStream.canRead }
    public var canWrite: Bool { baseStream.canWrite }
    public var canSeek: Bool { baseStream.canSeek }
    public var canTimeout: Bool { baseStream.canTimeout }

    public var readTimeout: Int {
        get { baseStream.readTimeout }
        set { baseStream.readTimeout = newValue }
    }

    public var writeTimeout: Int {
        get { baseStream.writeTimeout }
        set { baseStream.writeTimeout = newValue }
    }

    public var position: Int {
        get { currentPosition }
        set {
            let newPosition = max(0, newValue)
            _ = try? seek(newPosition, origin: .begin)
        }
    }

    public var length: Int {
        if endBoundary >= 0 {
            return max(0, endBoundary - startBoundary)
        }
        return max(0, baseStream.length - startBoundary)
    }

    public func read(_ buffer: inout [UInt8], offset: Int, count: Int) throws -> Int {
        try ensureOpen()
        guard canRead else {
            throw StreamError.notSupported
        }
        guard offset >= 0, count >= 0, offset + count <= buffer.count else {
            throw StreamError.invalidArgument
        }
        if count == 0 {
            return 0
        }
        if endBoundary >= 0 {
            if currentPosition >= length || eos {
                return 0
            }
        }

        if canSeek {
            _ = try baseStream.seek(startBoundary + currentPosition, origin: .begin)
        }

        var available = count
        if endBoundary >= 0 {
            let remaining = length - currentPosition
            if remaining <= 0 {
                eos = true
                return 0
            }
            available = min(available, remaining)
        }

        let nread = try baseStream.read(&buffer, offset: offset, count: available)
        currentPosition += nread
        if nread == 0 {
            eos = true
        }
        return nread
    }

    public func write(_ buffer: [UInt8], offset: Int, count: Int) throws {
        try ensureOpen()
        guard canWrite else {
            throw StreamError.notSupported
        }
        guard offset >= 0, count >= 0, offset + count <= buffer.count else {
            throw StreamError.invalidArgument
        }

        if endBoundary >= 0 && currentPosition + count > length {
            throw StreamError.outOfRange
        }

        if canSeek {
            _ = try baseStream.seek(startBoundary + currentPosition, origin: .begin)
        }

        try baseStream.write(buffer, offset: offset, count: count)
        currentPosition += count
        eos = false
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
            base = length
        }
        let newPosition = base + offset
        guard newPosition >= 0 else {
            throw StreamError.outOfRange
        }
        if endBoundary >= 0, newPosition > length {
            throw StreamError.outOfRange
        }
        currentPosition = newPosition
        eos = false
        if canSeek {
            _ = try baseStream.seek(startBoundary + currentPosition, origin: .begin)
        }
        return currentPosition
    }

    public func flush() throws {
        try ensureOpen()
        try baseStream.flush()
    }

    public func close() {
        closed = true
        if !leaveOpen {
            baseStream.close()
        }
    }

    public func setLength(_ length: Int) throws {
        try ensureOpen()
        guard length >= 0 else {
            throw StreamError.outOfRange
        }
        if endBoundary == -1 || startBoundary + length > endBoundary {
            if let resizable = baseStream as? ResizableStream {
                if startBoundary + length > baseStream.length {
                    try resizable.setLength(startBoundary + length)
                }
                endBoundary = startBoundary + length
            } else {
                throw StreamError.notSupported
            }
        } else {
            endBoundary = startBoundary + length
        }
        if currentPosition > self.length {
            currentPosition = self.length
        }
    }

    private func ensureOpen() throws {
        if closed {
            throw StreamError.closed
        }
    }
}
