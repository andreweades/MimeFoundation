//
// Base64Decoder.swift
//
// Ported from MimeKit (C#) to Swift.
//

public final class Base64Decoder: MimeDecoder {
    private static let base64Rank: [UInt8] = {
        var table = Array(repeating: UInt8(0xFF), count: 256)
        let alphabet = Array("ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/".utf8)
        for (index, value) in alphabet.enumerated() {
            table[Int(value)] = UInt8(index)
        }
        table[Int(0x3D)] = 0
        return table
    }()

    public var enableHardwareAcceleration: Bool = false

    private var previous: Int = 0
    private var saved: UInt32 = 0
    private var bytes: UInt8 = 0

    public init() {}

    public var encoding: ContentEncoding {
        .base64
    }

    public func clone() -> any MimeDecoder {
        let clone = Base64Decoder()
        clone.enableHardwareAcceleration = enableHardwareAcceleration
        clone.previous = previous
        clone.saved = saved
        clone.bytes = bytes
        return clone
    }

    public func estimateOutputLength(_ inputLength: Int) -> Int {
        return ((inputLength / 4) * 3) + 3
    }

    public func decode(_ input: [UInt8]?, startIndex: Int, length: Int, output: inout [UInt8]?) throws -> Int {
        try validateArguments(input, startIndex: startIndex, length: length, output: output)
        guard let input = input else {
            throw MimeCodingError.inputNil
        }
        guard var outputBuffer = output else {
            throw MimeCodingError.outputNil
        }

        var outIndex = 0
        var index = startIndex
        let end = startIndex + length

        while index < end {
            let c = input[index]
            index += 1
            let rank = Base64Decoder.base64Rank[Int(c)]
            if rank != 0xFF {
                previous = (previous << 8) | Int(c)
                saved = (saved << 6) | UInt32(rank)
                bytes &+= 1

                if bytes == 4 {
                    if (previous & 0x00FF0000) != (Int(0x3D) << 16) {
                        outputBuffer[outIndex] = UInt8((saved >> 16) & 0xFF)
                        outIndex += 1
                        if (previous & 0x0000FF00) != (Int(0x3D) << 8) {
                            outputBuffer[outIndex] = UInt8((saved >> 8) & 0xFF)
                            outIndex += 1
                            if (previous & 0x000000FF) != Int(0x3D) {
                                outputBuffer[outIndex] = UInt8(saved & 0xFF)
                                outIndex += 1
                            }
                        }
                    }
                    saved = 0
                    bytes = 0
                }
            }
        }

        output = outputBuffer
        return outIndex
    }

    public func reset() {
        previous = 0
        saved = 0
        bytes = 0
    }

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
