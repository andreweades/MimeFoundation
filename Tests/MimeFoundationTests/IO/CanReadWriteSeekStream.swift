//
// CanReadWriteSeekStream.swift
//

import MimeFoundation

final class CanReadWriteSeekStream: MimeStream {
    let canRead: Bool
    let canWrite: Bool
    let canSeek: Bool
    let canTimeout: Bool

    var position: Int {
        get { 15 }
        set { _ = try? seek(newValue, origin: .begin) }
    }

    var length: Int { 17 }

    var readTimeout: Int {
        get { 0 }
        set { }
    }

    var writeTimeout: Int {
        get { 0 }
        set { }
    }

    init(_ canRead: Bool, _ canWrite: Bool, _ canSeek: Bool, _ canTimeout: Bool = false) {
        self.canRead = canRead
        self.canWrite = canWrite
        self.canSeek = canSeek
        self.canTimeout = canTimeout
    }

    func read(_ buffer: inout [UInt8], offset: Int, count: Int) throws -> Int {
        throw StreamError.notSupported
    }

    func write(_ buffer: [UInt8], offset: Int, count: Int) throws {
        throw StreamError.notSupported
    }

    func seek(_ offset: Int, origin: SeekOrigin) throws -> Int {
        throw StreamError.notSupported
    }

    func flush() throws {}

    func close() {}
}
