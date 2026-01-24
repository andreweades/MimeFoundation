//
// ReadOneByteStream.swift
//
// Ported from MimeKit (C#) to Swift.
//

public final class ReadOneByteStream: MimeStream {
    private let baseStream: MimeStream

    public init(_ baseStream: MimeStream) {
        self.baseStream = baseStream
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
        get { baseStream.position }
        set { baseStream.position = newValue }
    }

    public var length: Int { baseStream.length }

    public func read(_ buffer: inout [UInt8], offset: Int, count: Int) throws -> Int {
        let toRead = min(count, 1)
        return try baseStream.read(&buffer, offset: offset, count: toRead)
    }

    public func write(_ buffer: [UInt8], offset: Int, count: Int) throws {
        try baseStream.write(buffer, offset: offset, count: count)
    }

    public func seek(_ offset: Int, origin: SeekOrigin) throws -> Int {
        try baseStream.seek(offset, origin: origin)
    }

    public func flush() throws {
        try baseStream.flush()
    }

    public func close() {
        baseStream.close()
    }
}
