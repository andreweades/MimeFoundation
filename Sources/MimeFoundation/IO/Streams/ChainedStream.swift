//
// ChainedStream.swift
//
// Ported from MimeKit (C#) to Swift.
//

import Foundation

public final class ChainedStream: ResizableStream {
    private var streams: [MimeStream] = []
    private var leaveOpen: [Bool] = []
    private var currentPosition: Int = 0
    private var currentIndex: Int = 0
    private var eos = false
    private var closed = false

    public init() {}

    public func add(_ stream: MimeStream?, leaveOpen: Bool = false) throws {
        guard let stream else {
            throw StreamError.invalidArgument
        }
        streams.append(stream)
        self.leaveOpen.append(leaveOpen)
    }

    public var canRead: Bool {
        !streams.isEmpty && streams.allSatisfy { $0.canRead }
    }

    public var canWrite: Bool {
        !streams.isEmpty && streams.allSatisfy { $0.canWrite }
    }

    public var canSeek: Bool {
        !streams.isEmpty && streams.allSatisfy { $0.canSeek }
    }

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

    public var length: Int {
        streams.reduce(0) { $0 + $1.length }
    }

    public func read(_ buffer: inout [UInt8], offset: Int, count: Int) throws -> Int {
        try ensureOpen()
        guard canRead else {
            throw StreamError.notSupported
        }
        guard offset >= 0, count >= 0, offset + count <= buffer.count else {
            throw StreamError.invalidArgument
        }
        if count == 0 || eos {
            return 0
        }
        var totalRead = 0

        while currentIndex < streams.count {
            while totalRead < count {
                let nread = try streams[currentIndex].read(&buffer, offset: offset + totalRead, count: count - totalRead)
                if nread <= 0 {
                    break
                }
                totalRead += nread
            }

            if totalRead == count {
                break
            }

            currentIndex += 1
        }

        if totalRead > 0 {
            currentPosition += totalRead
        } else {
            eos = true
        }

        return totalRead
    }

    public func write(_ buffer: [UInt8], offset: Int, count: Int) throws {
        try ensureOpen()
        guard canWrite else {
            throw StreamError.notSupported
        }
        guard offset >= 0, count >= 0, offset + count <= buffer.count else {
            throw StreamError.invalidArgument
        }
        if count == 0 {
            return
        }

        if currentIndex >= streams.count {
            currentIndex = max(streams.count - 1, 0)
        }

        var totalWritten = 0

        while currentIndex < streams.count && totalWritten < count {
            var toWrite = count - totalWritten
            if currentIndex + 1 < streams.count {
                let remaining = streams[currentIndex].length - streams[currentIndex].position
                if remaining < toWrite {
                    toWrite = remaining
                }
            }

            try streams[currentIndex].write(buffer, offset: offset + totalWritten, count: toWrite)
            currentPosition += toWrite
            totalWritten += toWrite

            if totalWritten < count {
                try streams[currentIndex].flush()
                currentIndex += 1
            }
        }
    }

    public func seek(_ offset: Int, origin: SeekOrigin) throws -> Int {
        try ensureOpen()
        guard canSeek else {
            throw StreamError.notSupported
        }
        let real: Int
        switch origin {
        case .begin:
            real = offset
        case .current:
            real = currentPosition + offset
        case .end:
            real = length + offset
        }

        if real < 0 || real > length {
            throw StreamError.outOfRange
        }

        if real == currentPosition {
            return currentPosition
        }

        if real > currentPosition {
            while currentIndex < streams.count && currentPosition < real {
                let left = streams[currentIndex].length - streams[currentIndex].position
                let step = min(left, real - currentPosition)
                _ = try streams[currentIndex].seek(step, origin: .current)
                currentPosition += step
                if currentPosition < real {
                    currentIndex += 1
                }
            }
            eos = currentIndex >= streams.count
        } else {
            let maxIndex = min(streams.count - 1, currentIndex)
            var cur = 0
            currentPosition = 0

            while cur <= maxIndex {
                let len = streams[cur].length
                if real < currentPosition + len {
                    _ = try streams[cur].seek(real - currentPosition, origin: .begin)
                    currentPosition = real
                    break
                }
                currentPosition += len
                cur += 1
            }

            currentIndex = cur
            var reset = cur + 1
            while reset <= maxIndex {
                _ = try streams[reset].seek(0, origin: .begin)
                reset += 1
            }
            eos = false
        }

        return currentPosition
    }

    public func flush() throws {
        try ensureOpen()
        for stream in streams {
            try stream.flush()
        }
    }

    public func close() {
        closed = true
        for (index, stream) in streams.enumerated() where !leaveOpen[index] {
            stream.close()
        }
    }

    public func setLength(_ length: Int) throws {
        try ensureOpen()
        throw StreamError.notSupported
    }

    private func streamIndex(for position: Int) -> (Int, Int) {
        var remaining = position
        for (index, stream) in streams.enumerated() {
            let len = stream.length
            if remaining < len {
                return (index, remaining)
            }
            remaining -= len
        }
        return (streams.count, 0)
    }

    private func ensureOpen() throws {
        if closed {
            throw StreamError.closed
        }
    }
}
