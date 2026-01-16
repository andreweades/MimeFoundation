//
// MimeFilter.swift
//
// Ported from MimeKit (C#) to Swift.
//

public protocol MimeFilter: AnyObject {
    func filter(_ input: [UInt8], startIndex: Int, length: Int, flush: Bool) -> [UInt8]
    func reset()
}
