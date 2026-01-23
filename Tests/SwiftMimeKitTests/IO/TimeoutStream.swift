//
// TimeoutStream.swift
//

import SwiftMimeKit

final class TimeoutStream: MimeStream {
    let canRead: Bool = false
    let canWrite: Bool = false
    let canSeek: Bool = false
    let canTimeout: Bool = true

    var position: Int {
        get { 15 }
        set { _ = try? seek(newValue, origin: .begin) }
    }

    var length: Int { 17 }

    var readTimeout: Int = 0
    var writeTimeout: Int = 0

    func read(_ buffer: inout [UInt8], offset: Int, count: Int) throws -> Int {
        throw StreamError.notSupported
    }

    func write(_ buffer: [UInt8], offset: Int, count: Int) throws {
        throw StreamError.notSupported
    }

    func seek(_ offset: Int, origin: SeekOrigin) throws -> Int {
        throw StreamError.notSupported
    }

    func flush() throws {
        throw StreamError.notSupported
    }

    func close() {}
}
