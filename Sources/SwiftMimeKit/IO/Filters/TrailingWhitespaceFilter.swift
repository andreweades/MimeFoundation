//
// TrailingWhitespaceFilter.swift
//
// Ported from MimeKit (C#) to Swift.
//

public final class TrailingWhitespaceFilter: MimeFilterBase {
    private var pending: [UInt8] = []

    public override func filter(_ input: [UInt8], startIndex: Int, length: Int, outputIndex: inout Int, outputLength: inout Int, flush: Bool) -> [UInt8] {
        if length == 0 {
            if flush {
                pending.removeAll(keepingCapacity: true)
            }
            outputIndex = startIndex
            outputLength = length
            return input
        }

        ensureOutputSize(length + pending.count, preserve: false)
        var out = output
        var outIndex = 0

        for byte in input[startIndex..<(startIndex + length)] {
            if byte == UInt8(ascii: " ") || byte == UInt8(ascii: "\t") {
                pending.append(byte)
            } else if byte == UInt8(ascii: "\r") || byte == UInt8(ascii: "\n") {
                out[outIndex] = byte
                outIndex += 1
                pending.removeAll(keepingCapacity: true)
            } else {
                if !pending.isEmpty {
                    out.replaceSubrange(outIndex..<(outIndex + pending.count), with: pending)
                    outIndex += pending.count
                    pending.removeAll(keepingCapacity: true)
                }
                out[outIndex] = byte
                outIndex += 1
            }
        }

        outputIndex = 0
        outputLength = outIndex
        if flush {
            pending.removeAll(keepingCapacity: true)
        }
        return out
    }

    public override func reset() {
        pending.removeAll(keepingCapacity: true)
        super.reset()
    }
}
