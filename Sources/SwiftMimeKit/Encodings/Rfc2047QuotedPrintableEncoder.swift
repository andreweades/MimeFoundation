//
// Rfc2047QuotedPrintableEncoder.swift
//
// Ported from MimeKit (C#) to Swift.
//

public final class Rfc2047QuotedPrintableEncoder: Rfc2047Encoder {
    private static let hexAlphabet: [UInt8] = Array("0123456789ABCDEF".utf8)
    private let mode: QEncodeMode

    public init(mode: QEncodeMode) {
        self.mode = mode
    }

    public var encoding: Character {
        "q"
    }

    public func estimateOutputLength(_ inputLength: Int) -> Int {
        inputLength * 3
    }

    public func encode(_ input: [UInt8]?, startIndex: Int, length: Int, output: inout [UInt8]?) throws -> Int {
        try validateArguments(input, startIndex: startIndex, length: length, output: output)
        guard let input = input else { throw MimeCodingError.inputNil }
        guard var outputBuffer = output else { throw MimeCodingError.outputNil }

        var outIndex = 0
        let end = startIndex + length
        var index = startIndex

        while index < end {
            let c = input[index]
            index += 1

            if c == 0x20 {
                outputBuffer[outIndex] = 0x5F
                outIndex += 1
            } else if isSafe(c) {
                outputBuffer[outIndex] = c
                outIndex += 1
            } else {
                outputBuffer[outIndex] = 0x3D
                outputBuffer[outIndex + 1] = Self.hexAlphabet[Int((c >> 4) & 0x0F)]
                outputBuffer[outIndex + 2] = Self.hexAlphabet[Int(c & 0x0F)]
                outIndex += 3
            }
        }

        output = outputBuffer
        return outIndex
    }

    private func isSafe(_ byte: UInt8) -> Bool {
        switch mode {
        case .phrase:
            return ByteClassification.isEncodedPhraseSafe(byte)
        case .text:
            return ByteClassification.isEncodedWordSafe(byte)
        }
    }

    private func validateArguments(_ input: [UInt8]?, startIndex: Int, length: Int, output: [UInt8]?) throws {
        guard let input = input else { throw MimeCodingError.inputNil }
        if startIndex < 0 || startIndex > input.count { throw MimeCodingError.startIndexOutOfRange }
        if length < 0 || length > (input.count - startIndex) { throw MimeCodingError.lengthOutOfRange }
        guard let output = output else { throw MimeCodingError.outputNil }
        if output.count < estimateOutputLength(length) { throw MimeCodingError.outputTooSmall }
    }
}
