//
// QuotedPrintableDecoder.swift
//
// Ported from MimeKit (C#) to Swift.
//

public final class QuotedPrintableDecoder: MimeDecoder {
    private enum State {
        case passThrough
        case equalSign
        case softBreak
        case decodeByte
    }

    private let rfc2047: Bool
    private var state: State = .passThrough
    private var saved: UInt8 = 0

    public init(rfc2047: Bool) {
        self.rfc2047 = rfc2047
    }

    public convenience init() {
        self.init(rfc2047: false)
    }

    public var encoding: ContentEncoding {
        .quotedPrintable
    }

    public func copy() -> any MimeDecoder {
        let copied = QuotedPrintableDecoder(rfc2047: rfc2047)
        copied.state = state
        copied.saved = saved
        return copied
    }

    public func estimateOutputLength(_ inputLength: Int) -> Int {
        switch state {
        case .passThrough:
            return inputLength
        case .equalSign:
            return inputLength + 1
        case .softBreak, .decodeByte:
            return inputLength + 2
        }
    }

    public func decode(_ input: [UInt8], startIndex: Int, length: Int, output: inout [UInt8]) throws -> Int {
        try validateArguments(input, startIndex: startIndex, length: length, output: output)

        var outIndex = 0
        var index = startIndex
        let end = startIndex + length

        while index < end {
            switch state {
            case .passThrough:
                while index < end {
                    let c = input[index]
                    index += 1

                    if c == 0x3D {
                        state = .equalSign
                        break
                    } else if rfc2047 && c == 0x5F {
                        output[outIndex] = 0x20
                        outIndex += 1
                    } else {
                        output[outIndex] = c
                        outIndex += 1
                    }
                }
            case .equalSign:
                if index >= end { break }
                let c = input[index]
                index += 1

                if ByteClassification.isXDigit(c) {
                    state = .decodeByte
                    saved = c
                } else if c == 0x3D {
                    output[outIndex] = 0x3D
                    outIndex += 1
                } else if c == 0x0D {
                    state = .softBreak
                } else if c == 0x0A {
                    state = .passThrough
                } else {
                    state = .passThrough
                    output[outIndex] = 0x3D
                    output[outIndex + 1] = c
                    outIndex += 2
                }
            case .softBreak:
                state = .passThrough
                if index >= end { break }
                let c = input[index]
                index += 1
                if c != 0x0A {
                    output[outIndex] = 0x3D
                    output[outIndex + 1] = 0x0D
                    output[outIndex + 2] = c
                    outIndex += 3
                }
            case .decodeByte:
                if index >= end { break }
                let c = input[index]
                index += 1
                if ByteClassification.isXDigit(c) {
                    let high = ByteClassification.toXDigit(saved)
                    let low = ByteClassification.toXDigit(c)
                    output[outIndex] = (high << 4) | low
                    outIndex += 1
                } else {
                    output[outIndex] = 0x3D
                    output[outIndex + 1] = saved
                    output[outIndex + 2] = c
                    outIndex += 3
                }
                state = .passThrough
            }
        }

        return outIndex
    }

    public func reset() {
        state = .passThrough
        saved = 0
    }

    private func validateArguments(_ input: [UInt8], startIndex: Int, length: Int, output: [UInt8]) throws {
        if startIndex < 0 || startIndex > input.count { throw MimeCodingError.startIndexOutOfRange }
        if length < 0 || length > (input.count - startIndex) { throw MimeCodingError.lengthOutOfRange }
        if output.count < estimateOutputLength(length) { throw MimeCodingError.outputTooSmall }
    }
}
