//
// YEncoder.swift
//
// Ported from MimeKit (C#) to Swift.
//

public final class YEncoder: MimeEncoder {
    private let lineLength: Int
    private var octets: UInt8 = 0
    private var crc: Crc32

    public init(maxLineLength: Int = 128) throws {
        if maxLineLength < 60 || maxLineLength > 998 {
            throw MimeCodingError.lengthOutOfRange
        }
        self.lineLength = maxLineLength
        self.crc = Crc32(initialValue: -1)
        reset()
    }

    public convenience init() {
        try! self.init(maxLineLength: 128)
    }

    public var checksum: Int32 {
        crc.checksum
    }

    public var encoding: ContentEncoding {
        .default
    }

    public func clone() -> any MimeEncoder {
        let clone = try! YEncoder(maxLineLength: lineLength)
        clone.crc = crc.clone()
        clone.octets = octets
        return clone
    }

    public func estimateOutputLength(_ inputLength: Int) -> Int {
        (inputLength * 2) + (inputLength / lineLength) + 1
    }

    public func encode(_ input: [UInt8]?, startIndex: Int, length: Int, output: inout [UInt8]?) throws -> Int {
        try validateArguments(input, startIndex: startIndex, length: length, output: output)
        guard let input = input else { throw MimeCodingError.inputNil }
        guard var outputBuffer = output else { throw MimeCodingError.outputNil }

        var outIndex = 0
        let end = startIndex + length
        var index = startIndex

        while index < end {
            var c = input[index]
            index += 1

            _ = crc.update(c)
            c &+= 42

            if c == 0 || c == 0x09 || c == 0x0D || c == 0x0A || c == 0x3D || c == 0x2E {
                outputBuffer[outIndex] = 0x3D
                outputBuffer[outIndex + 1] = c &+ 64
                outIndex += 2
                octets &+= 2
            } else {
                outputBuffer[outIndex] = c
                outIndex += 1
                octets &+= 1
            }

            if Int(octets) >= lineLength {
                outputBuffer[outIndex] = 0x0A
                outIndex += 1
                octets = 0
            }
        }

        output = outputBuffer
        return outIndex
    }

    public func flush(_ input: [UInt8]?, startIndex: Int, length: Int, output: inout [UInt8]?) throws -> Int {
        try validateArguments(input, startIndex: startIndex, length: length, output: output)
        guard let input = input else { throw MimeCodingError.inputNil }
        guard var outputBuffer = output else { throw MimeCodingError.outputNil }

        var outIndex = 0
        if length > 0 {
            outIndex = try encode(input, startIndex: startIndex, length: length, output: &output)
            outputBuffer = output ?? outputBuffer
        }

        if octets > 0 {
            outputBuffer[outIndex] = 0x0A
            outIndex += 1
            octets = 0
        }

        output = outputBuffer
        return outIndex
    }

    public func reset() {
        crc.reset()
        octets = 0
    }

    private func validateArguments(_ input: [UInt8]?, startIndex: Int, length: Int, output: [UInt8]?) throws {
        guard let input = input else { throw MimeCodingError.inputNil }
        if startIndex < 0 || startIndex > input.count { throw MimeCodingError.startIndexOutOfRange }
        if length < 0 || length > (input.count - startIndex) { throw MimeCodingError.lengthOutOfRange }
        guard let output = output else { throw MimeCodingError.outputNil }
        if output.count < estimateOutputLength(length) { throw MimeCodingError.outputTooSmall }
    }
}
