//
// UUDecoder.swift
//
// Ported from MimeKit (C#) to Swift.
//

public final class UUDecoder: MimeDecoder {
    private enum State {
        case expectBegin
        case b
        case be
        case beg
        case begi
        case begin
        case expectPayload
        case payload
        case ended
    }

    private let payloadOnly: Bool
    private var state: State
    private var nsaved: UInt8 = 0
    private var uulen: Int = 0
    private var saved: UInt32 = 0

    public init(payloadOnly: Bool = false) {
        self.payloadOnly = payloadOnly
        self.state = payloadOnly ? .payload : .expectBegin
    }

    public var encoding: ContentEncoding {
        .uuEncode
    }

    public func clone() -> any MimeDecoder {
        let clone = UUDecoder(payloadOnly: payloadOnly)
        clone.state = state
        clone.nsaved = nsaved
        clone.uulen = uulen
        clone.saved = saved
        return clone
    }

    public func estimateOutputLength(_ inputLength: Int) -> Int {
        inputLength + 3
    }

    public func decode(_ input: [UInt8], startIndex: Int, length: Int, output: inout [UInt8]) throws -> Int {
        try validateArguments(input, startIndex: startIndex, length: length, output: output)

        if state == .ended {
            return 0
        }

        var lastWasEoln = uulen == 0
        var index = startIndex
        let end = startIndex + length
        var outIndex = 0

        if state != .payload {
            index = scanBeginMarker(input, startIndex: index, end: end)
            if index >= end { return 0 }
        }

        while index < end {
            let byte = input[index]
            index += 1

            if byte == 0x0D {
                continue
            }

            if byte == 0x0A {
                lastWasEoln = true
                continue
            }

            if uulen == 0 || lastWasEoln {
                uulen = decodeValue(byte)
                lastWasEoln = false
                if uulen == 0 {
                    state = .ended
                    break
                }
                continue
            }

            if uulen > 0 {
                saved = (saved << 8) | UInt32(byte)
                nsaved &+= 1

                if nsaved == 4 {
                    let b0 = UInt8((saved >> 24) & 0xFF)
                    let b1 = UInt8((saved >> 16) & 0xFF)
                    let b2 = UInt8((saved >> 8) & 0xFF)
                    let b3 = UInt8(saved & 0xFF)

                    let d0 = decodeValue(b0)
                    let d1 = decodeValue(b1)
                    let d2 = decodeValue(b2)
                    let d3 = decodeValue(b3)

                    if uulen >= 3 {
                        output[outIndex] = UInt8((d0 << 2) | (d1 >> 4))
                        output[outIndex + 1] = UInt8(truncatingIfNeeded: (d1 << 4) | (d2 >> 2))
                        output[outIndex + 2] = UInt8(truncatingIfNeeded: (d2 << 6) | d3)
                        outIndex += 3
                        uulen -= 3
                    } else {
                        if uulen >= 1 {
                            output[outIndex] = UInt8((d0 << 2) | (d1 >> 4))
                            outIndex += 1
                            uulen -= 1
                        }
                        if uulen >= 1 {
                            output[outIndex] = UInt8(truncatingIfNeeded: (d1 << 4) | (d2 >> 2))
                            outIndex += 1
                            uulen -= 1
                        }
                    }

                    nsaved = 0
                    saved = 0
                }
            } else {
                break
            }
        }

        return outIndex
    }

    public func reset() {
        state = payloadOnly ? .payload : .expectBegin
        nsaved = 0
        saved = 0
        uulen = 0
    }

    private func scanBeginMarker(_ input: [UInt8], startIndex: Int, end: Int) -> Int {
        var index = startIndex
        while index < end {
            if state == .expectBegin {
                if nsaved != 0 && nsaved != 0x0A {
                    while index < end && input[index] != 0x0A { index += 1 }
                    if index == end {
                        nsaved = input[end - 1]
                        return index
                    }
                    nsaved = input[index]
                    index += 1
                    if index == end { return index }
                }

                nsaved = input[index]
                index += 1
                if nsaved != 0x62 { continue }
                state = .b
                if index == end { return index }
            }

            if state == .b {
                nsaved = input[index]
                index += 1
                if nsaved != 0x65 { state = .expectBegin; continue }
                state = .be
                if index == end { return index }
            }

            if state == .be {
                nsaved = input[index]
                index += 1
                if nsaved != 0x67 { state = .expectBegin; continue }
                state = .beg
                if index == end { return index }
            }

            if state == .beg {
                nsaved = input[index]
                index += 1
                if nsaved != 0x69 { state = .expectBegin; continue }
                state = .begi
                if index == end { return index }
            }

            if state == .begi {
                nsaved = input[index]
                index += 1
                if nsaved != 0x6E { state = .expectBegin; continue }
                state = .begin
                if index == end { return index }
            }

            if state == .begin {
                nsaved = input[index]
                index += 1
                if nsaved != 0x20 { state = .expectBegin; continue }
                state = .expectPayload
                if index == end { return index }
            }

            if state == .expectPayload {
                while index < end && input[index] != 0x0A { index += 1 }
                if index == end { return index }
                state = .payload
                nsaved = 0
                return index + 1
            }
        }
        return index
    }

    private func decodeValue(_ byte: UInt8) -> Int {
        if byte == 0x60 { return 0 }
        return Int((byte &- 0x20) & 0x3F)
    }

    private func validateArguments(_ input: [UInt8], startIndex: Int, length: Int, output: [UInt8]) throws {
        if startIndex < 0 || startIndex > input.count { throw MimeCodingError.startIndexOutOfRange }
        if length < 0 || length > (input.count - startIndex) { throw MimeCodingError.lengthOutOfRange }
        if output.count < estimateOutputLength(length) { throw MimeCodingError.outputTooSmall }
    }
}
