//
// Rfc2047Base64Encoder.swift
//
// Ported from MimeKit (C#) to Swift.
//

public final class Rfc2047Base64Encoder: Rfc2047Encoder {
    private static let alphabet: [UInt8] = Array("ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/".utf8)

    public init() {}

    public var encoding: Character {
        "b"
    }

    public func estimateOutputLength(_ inputLength: Int) -> Int {
        ((inputLength + 2) / 3) * 4
    }

    public func encode(_ input: [UInt8], startIndex: Int, length: Int, output: inout [UInt8]) throws -> Int {
        try validateArguments(input, startIndex: startIndex, length: length, output: output)

        var outIndex = 0
        var index = startIndex
        let end = startIndex + length

        while index + 2 < end {
            let c1 = input[index]
            let c2 = input[index + 1]
            let c3 = input[index + 2]
            index += 3

            output[outIndex] = Self.alphabet[Int(c1 >> 2)]
            output[outIndex + 1] = Self.alphabet[Int((c2 >> 4) | ((c1 & 0x03) << 4))]
            output[outIndex + 2] = Self.alphabet[Int(((c2 & 0x0F) << 2) | (c3 >> 6))]
            output[outIndex + 3] = Self.alphabet[Int(c3 & 0x3F)]
            outIndex += 4
        }

        let remaining = end - index
        if remaining == 2 {
            let c1 = input[index]
            let c2 = input[index + 1]
            output[outIndex] = Self.alphabet[Int(c1 >> 2)]
            output[outIndex + 1] = Self.alphabet[Int((c2 >> 4) | ((c1 & 0x03) << 4))]
            output[outIndex + 2] = Self.alphabet[Int((c2 & 0x0F) << 2)]
            output[outIndex + 3] = 0x3D
            outIndex += 4
        } else if remaining == 1 {
            let c1 = input[index]
            output[outIndex] = Self.alphabet[Int(c1 >> 2)]
            output[outIndex + 1] = Self.alphabet[Int((c1 & 0x03) << 4)]
            output[outIndex + 2] = 0x3D
            output[outIndex + 3] = 0x3D
            outIndex += 4
        }

        return outIndex
    }

    private func validateArguments(_ input: [UInt8], startIndex: Int, length: Int, output: [UInt8]) throws {
        if startIndex < 0 || startIndex > input.count { throw MimeCodingError.startIndexOutOfRange }
        if length < 0 || length > (input.count - startIndex) { throw MimeCodingError.lengthOutOfRange }
        if output.count < estimateOutputLength(length) { throw MimeCodingError.outputTooSmall }
    }
}
