//
// MimeStream.swift
//
// Ported from MimeKit (C#) to Swift.
//

import Foundation

public enum SeekOrigin {
    case begin
    case current
    case end
}

public enum StreamError: Error {
    case notSupported
    case invalidArgument
    case outOfRange
    case closed
}

public protocol MimeStream: AnyObject {
    var canRead: Bool { get }
    var canWrite: Bool { get }
    var canSeek: Bool { get }
    var canTimeout: Bool { get }
    var readTimeout: Int { get set }
    var writeTimeout: Int { get set }
    var position: Int { get set }
    var length: Int { get }

    func read(_ buffer: inout [UInt8], offset: Int, count: Int) throws -> Int
    func write(_ buffer: [UInt8], offset: Int, count: Int) throws
    func seek(_ offset: Int, origin: SeekOrigin) throws -> Int
    func flush() throws
    func close()
}
