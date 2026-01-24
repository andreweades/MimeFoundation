//
// Dos2UnixFilter.swift
//
// Ported from MimeKit (C#) to Swift.
//

public final class Dos2UnixFilter: MimeFilterBase {
    private let ensureNewLine: Bool
    private var previous: UInt8 = 0

    public init(_ ensureNewLine: Bool = false) {
        self.ensureNewLine = ensureNewLine
        super.init()
    }

    private func filterBytes(_ input: [UInt8], output: inout [UInt8], flush: Bool) -> Int {
        var outputIndex = 0
        for byte in input {
            if byte == UInt8(ascii: "\n") {
                output[outputIndex] = byte
                outputIndex += 1
            } else {
                if previous == UInt8(ascii: "\r") {
                    output[outputIndex] = previous
                    outputIndex += 1
                }
                if byte != UInt8(ascii: "\r") {
                    output[outputIndex] = byte
                    outputIndex += 1
                }
            }
            previous = byte
        }

        if flush && ensureNewLine && previous != UInt8(ascii: "\n") {
            output[outputIndex] = UInt8(ascii: "\n")
            outputIndex += 1
            previous = UInt8(ascii: "\n")
        }

        return outputIndex
    }

    public override func filter(_ input: [UInt8], startIndex: Int, length: Int, outputIndex: inout Int, outputLength: inout Int, flush: Bool) -> [UInt8] {
        let slice = Array(input[startIndex..<(startIndex + length)])
        let extra = previous == UInt8(ascii: "\r") ? 1 : 0
        ensureOutputSize(length + extra + (flush && ensureNewLine ? 1 : 0), preserve: false)
        var out = output
        outputLength = filterBytes(slice, output: &out, flush: flush)
        outputIndex = 0
        return out
    }

    public override func reset() {
        previous = 0
        super.reset()
    }
}
