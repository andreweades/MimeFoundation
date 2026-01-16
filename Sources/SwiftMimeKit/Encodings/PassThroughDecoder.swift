//
// PassThroughDecoder.swift
//
// Ported from MimeKit (C#) to Swift.
//

public final class PassThroughDecoder: MimeDecoder {
    private let passthroughEncoding: ContentEncoding

    public init(encoding: ContentEncoding) {
        self.passthroughEncoding = encoding
    }

    public var encoding: ContentEncoding {
        passthroughEncoding
    }

    public func clone() -> any MimeDecoder {
        PassThroughDecoder(encoding: passthroughEncoding)
    }

    public func estimateOutputLength(_ inputLength: Int) -> Int {
        inputLength
    }

    public func decode(_ input: [UInt8]?, startIndex: Int, length: Int, output: inout [UInt8]?) throws -> Int {
        try validateArguments(input, startIndex: startIndex, length: length, output: output)
        guard let input = input else {
            throw MimeCodingError.inputNil
        }
        guard var outputBuffer = output else {
            throw MimeCodingError.outputNil
        }

        if length > 0 {
            let slice = input[startIndex..<(startIndex + length)]
            outputBuffer.replaceSubrange(0..<length, with: slice)
        }

        output = outputBuffer
        return length
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
