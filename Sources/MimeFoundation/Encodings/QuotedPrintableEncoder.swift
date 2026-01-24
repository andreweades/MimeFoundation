//
// QuotedPrintableEncoder.swift
//
// Ported from MimeKit (C#) to Swift.
//

public final class QuotedPrintableEncoder: MimeEncoder {
    private static let hexAlphabet: [UInt8] = Array("0123456789ABCDEF".utf8)

    private let tripletsPerLine: Int
    private let maxLineLength: Int
    private var currentLineLength: Int = 0
    private var saved: Int = -1

    public convenience init() {
        self.init(uncheckedMaxLineLength: 76)
    }

    public init(maxLineLength: Int) throws {
        if maxLineLength < FormatOptions.minimumLineLength || maxLineLength > FormatOptions.maximumLineLength {
            throw MimeCodingError.lengthOutOfRange
        }

        let normalized = min(maxLineLength, 76)
        self.tripletsPerLine = normalized / 3
        self.maxLineLength = normalized
        reset()
    }

    /// Internal initializer that skips validation. Used for default init.
    private init(uncheckedMaxLineLength: Int) {
        let normalized = min(uncheckedMaxLineLength, 76)
        self.tripletsPerLine = normalized / 3
        self.maxLineLength = normalized
        reset()
    }

    private init(tripletsPerLine: Int, maxLineLength: Int, currentLineLength: Int, saved: Int) {
        self.tripletsPerLine = tripletsPerLine
        self.maxLineLength = maxLineLength
        self.currentLineLength = currentLineLength
        self.saved = saved
    }

    public var encoding: ContentEncoding {
        .quotedPrintable
    }

    public func clone() -> any MimeEncoder {
        QuotedPrintableEncoder(tripletsPerLine: tripletsPerLine,
                               maxLineLength: maxLineLength,
                               currentLineLength: currentLineLength,
                               saved: saved)
    }

    public func estimateOutputLength(_ inputLength: Int) -> Int {
        var length = inputLength
        if saved != -1 {
            length += 1
        }
        return ((length / tripletsPerLine) * (maxLineLength + 1)) + ((length % tripletsPerLine) * 3) + 2
    }

    public func encode(_ input: [UInt8], startIndex: Int, length: Int, output: inout [UInt8]) throws -> Int {
        try validateArguments(input, startIndex: startIndex, length: length, output: output)

        var outIndex = 0
        var index = startIndex
        let end = startIndex + length

        while index < end {
            let c = input[index]
            index += 1

            if c == 0x0D {
                if saved != -1 {
                    let b = UInt8(saved)
                    if ByteClassification.isBlank(b) || !ByteClassification.isQpSafe(b) {
                        output[outIndex] = 0x3D
                        output[outIndex + 1] = Self.hexAlphabet[Int((b >> 4) & 0x0F)]
                        output[outIndex + 2] = Self.hexAlphabet[Int(b & 0x0F)]
                        outIndex += 3
                        currentLineLength += 3
                    } else {
                        output[outIndex] = b
                        outIndex += 1
                        currentLineLength += 1
                    }
                }
                saved = Int(c)
            } else if c == 0x0A {
                if saved != -1 && saved != 0x0D {
                    let b = UInt8(saved)
                    if ByteClassification.isBlank(b) || !ByteClassification.isQpSafe(b) {
                        output[outIndex] = 0x3D
                        output[outIndex + 1] = Self.hexAlphabet[Int((b >> 4) & 0x0F)]
                        output[outIndex + 2] = Self.hexAlphabet[Int(b & 0x0F)]
                        outIndex += 3
                    } else {
                        output[outIndex] = b
                        outIndex += 1
                    }
                }

                output[outIndex] = 0x0A
                outIndex += 1
                currentLineLength = 0
                saved = -1
            } else {
                if saved != -1 {
                    let b = UInt8(saved)
                    if ByteClassification.isQpSafe(b) {
                        output[outIndex] = b
                        outIndex += 1
                        currentLineLength += 1
                    } else {
                        output[outIndex] = 0x3D
                        output[outIndex + 1] = Self.hexAlphabet[Int((b >> 4) & 0x0F)]
                        output[outIndex + 2] = Self.hexAlphabet[Int(b & 0x0F)]
                        outIndex += 3
                        currentLineLength += 3
                    }

                    if currentLineLength + 1 >= maxLineLength {
                        output[outIndex] = 0x3D
                        output[outIndex + 1] = 0x0A
                        outIndex += 2
                        currentLineLength = 0
                    }
                }
                saved = Int(c)
            }
        }

        return outIndex
    }

    public func flush(_ input: [UInt8], startIndex: Int, length: Int, output: inout [UInt8]) throws -> Int {
        try validateArguments(input, startIndex: startIndex, length: length, output: output)

        var outIndex = 0
        if length > 0 {
            outIndex = try encode(input, startIndex: startIndex, length: length, output: &output)
        }

        if saved != -1 {
            let c = UInt8(saved)
            if ByteClassification.isBlank(c) || !ByteClassification.isQpSafe(c) {
                output[outIndex] = 0x3D
                output[outIndex + 1] = Self.hexAlphabet[Int((c >> 4) & 0x0F)]
                output[outIndex + 2] = Self.hexAlphabet[Int(c & 0x0F)]
                outIndex += 3
            } else {
                output[outIndex] = c
                outIndex += 1
            }
            output[outIndex] = 0x3D
            output[outIndex + 1] = 0x0A
            outIndex += 2
        }

        reset()
        return outIndex
    }

    public func reset() {
        currentLineLength = 0
        saved = -1
    }

    private func validateArguments(_ input: [UInt8], startIndex: Int, length: Int, output: [UInt8]) throws {
        if startIndex < 0 || startIndex > input.count { throw MimeCodingError.startIndexOutOfRange }
        if length < 0 || length > (input.count - startIndex) { throw MimeCodingError.lengthOutOfRange }
        if output.count < estimateOutputLength(length) { throw MimeCodingError.outputTooSmall }
    }
}
