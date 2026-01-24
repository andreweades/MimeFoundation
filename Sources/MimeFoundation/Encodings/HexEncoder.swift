//
// HexEncoder.swift
//
// Ported from MimeKit (C#) to Swift.
//

public final class HexEncoder: MimeEncoder {
    private static let alphabet: [UInt8] = Array("0123456789ABCDEF".utf8)

    public init() {}

    public var encoding: ContentEncoding {
        .default
    }

    public func clone() -> any MimeEncoder {
        HexEncoder()
    }

    public func estimateOutputLength(_ inputLength: Int) -> Int {
        inputLength * 3
    }

    public func encode(_ input: [UInt8]?, startIndex: Int, length: Int, output: inout [UInt8]?) throws -> Int {
        try validateArguments(input, startIndex: startIndex, length: length, output: output)
        guard let input = input else {
            throw MimeCodingError.inputNil
        }
        guard var outputBuffer = output else {
            throw MimeCodingError.outputNil
        }

        var outIndex = 0
        let end = startIndex + length
        var index = startIndex

        while index < end {
            let byte = input[index]
            index += 1
            if ByteClassification.isAttr(byte) {
                outputBuffer[outIndex] = byte
                outIndex += 1
            } else {
                outputBuffer[outIndex] = 0x25
                outputBuffer[outIndex + 1] = Self.alphabet[Int((byte >> 4) & 0x0F)]
                outputBuffer[outIndex + 2] = Self.alphabet[Int(byte & 0x0F)]
                outIndex += 3
            }
        }

        output = outputBuffer
        return outIndex
    }

    public func flush(_ input: [UInt8]?, startIndex: Int, length: Int, output: inout [UInt8]?) throws -> Int {
        try encode(input, startIndex: startIndex, length: length, output: &output)
    }

    public func reset() {}

    private func validateArguments(_ input: [UInt8]?, startIndex: Int, length: Int, output: [UInt8]?) throws {
        guard let input = input else {
            throw MimeCodingError.inputNil
        }
        if startIndex < 0 || startIndex > input.count {
            throw MimeCodingError.startIndexOutOfRange
        }
        if length < 0 || length > (input.count - startIndex) {
            throw MimeCodingError.lengthOutOfRange
        }
        guard let output = output else {
            throw MimeCodingError.outputNil
        }
        if output.count < estimateOutputLength(length) {
            throw MimeCodingError.outputTooSmall
        }
    }
}
