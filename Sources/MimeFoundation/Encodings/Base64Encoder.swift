//
// Base64Encoder.swift
//
// Ported from MimeKit (C#) to Swift.
//

public final class Base64Encoder: MimeEncoder {
    private static let alphabet: [UInt8] = Array("ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/".utf8)

    public var enableHardwareAcceleration: Bool = false

    private let quartetsPerLine: Int
    private var quartets: Int = 0
    private var saved1: UInt8 = 0
    private var saved2: UInt8 = 0
    private var saved: Int = 0

    public convenience init() {
        self.init(uncheckedMaxLineLength: 76)
    }

    public init(maxLineLength: Int) throws {
        if maxLineLength < FormatOptions.minimumLineLength || maxLineLength > FormatOptions.maximumLineLength {
            throw MimeCodingError.lengthOutOfRange
        }
        quartetsPerLine = maxLineLength / 4
    }

    /// Internal initializer that skips validation. Used for cloning and known-valid defaults.
    private init(uncheckedMaxLineLength: Int) {
        quartetsPerLine = uncheckedMaxLineLength / 4
    }

    public var encoding: ContentEncoding {
        .base64
    }

    public func copy() -> any MimeEncoder {
        let copied = Base64Encoder(uncheckedMaxLineLength: quartetsPerLine * 4)
        copied.enableHardwareAcceleration = enableHardwareAcceleration
        copied.quartets = quartets
        copied.saved1 = saved1
        copied.saved2 = saved2
        copied.saved = saved
        return copied
    }

    public func estimateOutputLength(_ inputLength: Int) -> Int {
        let maxLineLength = (quartetsPerLine * 4) + 1
        let maxInputPerLine = quartetsPerLine * 3
        return (((inputLength + 2) / maxInputPerLine) * maxLineLength) + maxLineLength
    }

    public func encode(_ input: [UInt8], startIndex: Int, length: Int, output: inout [UInt8]) throws -> Int {
        try validateArguments(input, startIndex: startIndex, length: length, output: output)

        var outIndex = 0
        var index = startIndex
        let end = startIndex + length

        func writeQuartet(_ c1: UInt8, _ c2: UInt8, _ c3: UInt8) {
            output[outIndex] = Self.alphabet[Int(c1 >> 2)]
            output[outIndex + 1] = Self.alphabet[Int((c2 >> 4) | ((c1 & 0x03) << 4))]
            output[outIndex + 2] = Self.alphabet[Int(((c2 & 0x0F) << 2) | (c3 >> 6))]
            output[outIndex + 3] = Self.alphabet[Int(c3 & 0x3F)]
            outIndex += 4
            quartets += 1
            if quartets >= quartetsPerLine {
                output[outIndex] = 0x0A
                outIndex += 1
                quartets = 0
            }
        }

        if saved > 0 {
            if saved == 1 {
                if index + 1 < end {
                    let c1 = saved1
                    let c2 = input[index]
                    let c3 = input[index + 1]
                    index += 2
                    saved = 0
                    writeQuartet(c1, c2, c3)
                } else if index < end {
                    saved2 = input[index]
                    saved = 2
                    index += 1
                }
            } else if saved == 2 {
                if index < end {
                    let c1 = saved1
                    let c2 = saved2
                    let c3 = input[index]
                    index += 1
                    saved = 0
                    writeQuartet(c1, c2, c3)
                }
            }
        }

        while index + 2 < end {
            let c1 = input[index]
            let c2 = input[index + 1]
            let c3 = input[index + 2]
            index += 3
            writeQuartet(c1, c2, c3)
        }

        let remaining = end - index
        if remaining == 1 {
            saved1 = input[index]
            saved = 1
        } else if remaining == 2 {
            saved1 = input[index]
            saved2 = input[index + 1]
            saved = 2
        }

        return outIndex
    }

    public func flush(_ input: [UInt8], startIndex: Int, length: Int, output: inout [UInt8]) throws -> Int {
        try validateArguments(input, startIndex: startIndex, length: length, output: output)

        var outIndex = 0
        if length > 0 {
            outIndex = try encode(input, startIndex: startIndex, length: length, output: &output)
        }

        if saved >= 1 {
            let c1 = saved1
            let c2 = saved2
            output[outIndex] = Self.alphabet[Int(c1 >> 2)]
            output[outIndex + 1] = Self.alphabet[Int((c2 >> 4) | ((c1 & 0x03) << 4))]
            if saved == 2 {
                output[outIndex + 2] = Self.alphabet[Int((c2 & 0x0F) << 2)]
            } else {
                output[outIndex + 2] = 0x3D
            }
            output[outIndex + 3] = 0x3D
            outIndex += 4
            quartets += 1
            saved = 0
        }

        if quartets > 0 {
            output[outIndex] = 0x0A
            outIndex += 1
            quartets = 0
        }

        return outIndex
    }

    public func reset() {
        quartets = 0
        saved1 = 0
        saved2 = 0
        saved = 0
    }

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
