//
// PassThroughFilter.swift
//
// Ported from MimeKit (C#) to Swift.
//

public final class PassThroughFilter: MimeFilterBase {
    public override func filter(_ input: [UInt8], startIndex: Int, length: Int, outputIndex: inout Int, outputLength: inout Int, flush: Bool) -> [UInt8] {
        outputIndex = startIndex
        outputLength = length
        return input
    }
}
