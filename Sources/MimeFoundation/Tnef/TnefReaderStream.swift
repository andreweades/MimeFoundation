//
// TnefReaderStream.swift
//
// Ported from MimeKit (C#) to Swift.
//

import Foundation

class TnefReaderStream: MimeStream {
    private let valueEndOffset: Int
    private let dataEndOffset: Int
    private unowned let reader: TnefReader
    private var closed = false

    public init(reader: TnefReader, dataEndOffset: Int, valueEndOffset: Int) {
        self.reader = reader
        self.dataEndOffset = dataEndOffset
        self.valueEndOffset = valueEndOffset
    }

    public var canRead: Bool { !closed }
    public var canWrite: Bool { false }
    public var canSeek: Bool { false }
    public var canTimeout: Bool { false }

    public var readTimeout: Int { get { 0 } set { } }
    public var writeTimeout: Int { get { 0 } set { } }

    public var position: Int {
        get { fatalError("Seeking not supported") }
        set { fatalError("Seeking not supported") }
    }

    public var length: Int {
        fatalError("Seeking not supported")
    }

    public func read(_ buffer: inout [UInt8], offset: Int, count: Int) throws -> Int {
        if closed {
            throw StreamError.closed
        }

        let dataLeft = dataEndOffset - reader.streamOffset
        let n = min(dataLeft, count)

        let nread = n > 0 ? reader.readAttributeRawValue(&buffer, offset: offset, count: n) : 0

        let remainingDataLeft = dataLeft - nread

        if remainingDataLeft == 0 && valueEndOffset > reader.streamOffset {
            let valueLeft = valueEndOffset - reader.streamOffset
            var buf = [UInt8](repeating: 0, count: valueLeft)
            _ = reader.readAttributeRawValue(&buf, offset: 0, count: valueLeft)
        }

        return nread
    }

    public func write(_ buffer: [UInt8], offset: Int, count: Int) throws {
        throw StreamError.notSupported
    }

    public func seek(_ offset: Int, origin: SeekOrigin) throws -> Int {
        throw StreamError.notSupported
    }

    public func flush() throws {
        // No-op
    }

    public func close() {
        closed = true
    }
}
