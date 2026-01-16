//
// HexDecoder.swift
//
// Ported from MimeKit (C#) to Swift.
//

public final class HexDecoder: MimeDecoder {
    private enum State {
        case passThrough
        case percent
        case decodeByte
    }

    private var state: State = .passThrough
    private var saved: UInt8 = 0

    public init() {}

    public var encoding: ContentEncoding {
        .default
    }

    public func clone() -> any MimeDecoder {
        let clone = HexDecoder()
        clone.state = state
        clone.saved = saved
        return clone
    }

    public func estimateOutputLength(_ inputLength: Int) -> Int {
        switch state {
        case .passThrough:
            return inputLength
        case .percent:
            return inputLength + 1
        case .decodeByte:
            return inputLength + 2
        }
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
            switch state {
            case .passThrough:
                while index < end {
                    let byte = input[index]
                    index += 1
                    if byte == 0x25 {
                        state = .percent
                        break
                    }
                    outputBuffer[outIndex] = byte
                    outIndex += 1
                }
            case .percent:
                if index < end {
                    saved = input[index]
                    index += 1
                    state = .decodeByte
                }
            case .decodeByte:
                if index < end {
                    let byte = input[index]
                    index += 1
                    if ByteClassification.isXDigit(byte) && ByteClassification.isXDigit(saved) {
                        let high = ByteClassification.toXDigit(saved)
                        let low = ByteClassification.toXDigit(byte)
                        outputBuffer[outIndex] = (high << 4) | low
                        outIndex += 1
                    } else {
                        outputBuffer[outIndex] = 0x25
                        outputBuffer[outIndex + 1] = saved
                        outputBuffer[outIndex + 2] = byte
                        outIndex += 3
                    }
                    state = .passThrough
                }
            }
        }

        output = outputBuffer
        return outIndex
    }

    public func reset() {
        state = .passThrough
        saved = 0
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
