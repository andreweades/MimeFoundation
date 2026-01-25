//
// PassThroughEncoder.swift
//
// Ported from MimeKit (C#) to Swift.
//

public final class PassThroughEncoder: MimeEncoder {
    private let passthroughEncoding: ContentEncoding

    public init(encoding: ContentEncoding) {
        self.passthroughEncoding = encoding
    }

    public var encoding: ContentEncoding {
        passthroughEncoding
    }

    public func copy() -> any MimeEncoder {
        PassThroughEncoder(encoding: passthroughEncoding)
    }

    public func estimateOutputLength(_ inputLength: Int) -> Int {
        inputLength
    }

    public func encode(_ input: [UInt8], startIndex: Int, length: Int, output: inout [UInt8]) throws -> Int {
        try validateArguments(input, startIndex: startIndex, length: length, output: output)

        if length > 0 {
            let slice = input[startIndex..<(startIndex + length)]
            output.replaceSubrange(0..<length, with: slice)
        }

        return length
    }

    public func flush(_ input: [UInt8], startIndex: Int, length: Int, output: inout [UInt8]) throws -> Int {
        try encode(input, startIndex: startIndex, length: length, output: &output)
    }

    public func reset() {}

    private func validateArguments(_ input: [UInt8], startIndex: Int, length: Int, output: [UInt8]) throws {
        if startIndex < 0 || startIndex > input.count {
            throw MimeCodingError.startIndexOutOfRange
        }
        if length < 0 || length > (input.count - startIndex) {
            throw MimeCodingError.lengthOutOfRange
        }
        if output.count < estimateOutputLength(length) {
            throw MimeCodingError.outputTooSmall
        }
    }
}
