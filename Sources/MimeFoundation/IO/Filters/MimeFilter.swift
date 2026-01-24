//
// MimeFilter.swift
//
// Ported from MimeKit (C#) to Swift.
//

public protocol MimeFilter: AnyObject {
    func filter(_ input: [UInt8], startIndex: Int, length: Int, outputIndex: inout Int, outputLength: inout Int) -> [UInt8]
    func flush(_ input: [UInt8], startIndex: Int, length: Int, outputIndex: inout Int, outputLength: inout Int) -> [UInt8]
    func reset()
}
