//
// UUEncoder.swift
//
// Ported from MimeKit (C#) to Swift.
//

public final class UUEncoder: MimeEncoder {
    private static let maxInputPerLine = 45
    private static let maxOutputPerLine = ((maxInputPerLine / 3) * 4) + 2

    private var lineBuffer: [UInt8] = []
    private var savedBytes: [UInt8] = []
    private var uulen: Int = 0

    public init() {}

    public var encoding: ContentEncoding {
        .uuEncode
    }

    public func clone() -> any MimeEncoder {
        let clone = UUEncoder()
        clone.lineBuffer = lineBuffer
        clone.savedBytes = savedBytes
        clone.uulen = uulen
        return clone
    }

    public func estimateOutputLength(_ inputLength: Int) -> Int {
        (((inputLength + 2) / UUEncoder.maxInputPerLine) * UUEncoder.maxOutputPerLine) + UUEncoder.maxOutputPerLine + 2
    }

    public func encode(_ input: [UInt8], startIndex: Int, length: Int, output: inout [UInt8]) throws -> Int {
        try validateArguments(input, startIndex: startIndex, length: length, output: output)

        var outIndex = 0
        let end = startIndex + length
        var index = startIndex

        while index < end {
            savedBytes.append(input[index])
            index += 1

            if savedBytes.count == 3 {
                appendEncodedTriplet(savedBytes[0], savedBytes[1], savedBytes[2])
                savedBytes.removeAll(keepingCapacity: true)
                uulen += 3

                if uulen >= UUEncoder.maxInputPerLine {
                    outIndex = flushLine(into: &output, at: outIndex, lengthOverride: uulen)
                }
            }
        }

        return outIndex
    }

    public func flush(_ input: [UInt8], startIndex: Int, length: Int, output: inout [UInt8]) throws -> Int {
        try validateArguments(input, startIndex: startIndex, length: length, output: output)

        var outIndex = 0
        if length > 0 {
            outIndex = try encode(input, startIndex: startIndex, length: length, output: &output)
        }

        var uufill = 0
        if !savedBytes.isEmpty {
            while savedBytes.count < 3 {
                savedBytes.append(0)
                uufill += 1
            }
            appendEncodedTriplet(savedBytes[0], savedBytes[1], savedBytes[2])
            uulen += 3
            savedBytes.removeAll(keepingCapacity: true)
        }

        if uulen > 0 {
            let actualLength = uulen - uufill
            outIndex = flushLine(into: &output, at: outIndex, lengthOverride: actualLength)
        }

        output[outIndex] = encodeLength(0)
        output[outIndex + 1] = 0x0A
        outIndex += 2

        reset()
        return outIndex
    }

    public func reset() {
        savedBytes.removeAll(keepingCapacity: true)
        lineBuffer.removeAll(keepingCapacity: true)
        uulen = 0
    }

    private func appendEncodedTriplet(_ b0: UInt8, _ b1: UInt8, _ b2: UInt8) {
        lineBuffer.append(encodeValue((b0 >> 2) & 0x3F))
        lineBuffer.append(encodeValue(((b0 << 4) | ((b1 >> 4) & 0x0F)) & 0x3F))
        lineBuffer.append(encodeValue(((b1 << 2) | ((b2 >> 6) & 0x03)) & 0x3F))
        lineBuffer.append(encodeValue(b2 & 0x3F))
    }

    private func flushLine(into output: inout [UInt8], at index: Int, lengthOverride: Int) -> Int {
        var outIndex = index
        output[outIndex] = encodeLength(lengthOverride)
        outIndex += 1
        output.replaceSubrange(outIndex..<(outIndex + lineBuffer.count), with: lineBuffer)
        outIndex += lineBuffer.count
        output[outIndex] = 0x0A
        outIndex += 1
        lineBuffer.removeAll(keepingCapacity: true)
        uulen = 0
        return outIndex
    }

    private func encodeValue(_ value: UInt8) -> UInt8 {
        if value == 0 { return 0x60 }
        return value &+ 0x20
    }

    private func encodeLength(_ length: Int) -> UInt8 {
        let value = UInt8(length & 0xFF)
        return encodeValue(value)
    }

    private func validateArguments(_ input: [UInt8], startIndex: Int, length: Int, output: [UInt8]) throws {
        if startIndex < 0 || startIndex > input.count { throw MimeCodingError.startIndexOutOfRange }
        if length < 0 || length > (input.count - startIndex) { throw MimeCodingError.lengthOutOfRange }
        if output.count < estimateOutputLength(length) { throw MimeCodingError.outputTooSmall }
    }
}
