//
// AnonymizeFilter.swift
//
// Ported from MimeKit (C#) to Swift.
//

import Foundation

public final class AnonymizeFilter: MimeFilterBase {
    public override func filter(_ input: [UInt8], startIndex: Int, length: Int, outputIndex: inout Int, outputLength: inout Int, flush: Bool) -> [UInt8] {
        ensureOutputSize(length, preserve: false)
        var output = self.output
        outputIndex = 0

        let endIndex = startIndex + length
        var index = startIndex
        var outIndex = 0
        while index < endIndex {
            let byte = input[index]
            output[outIndex] = ByteClassification.isWhitespace(byte) ? byte : UInt8(ascii: "x")
            outIndex += 1
            index += 1
        }

        outputLength = outIndex
        return output
    }
}
