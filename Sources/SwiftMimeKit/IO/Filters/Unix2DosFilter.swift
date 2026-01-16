//
// Unix2DosFilter.swift
//
// Ported from MimeKit (C#) to Swift.
//

public final class Unix2DosFilter: MimeFilter {
    private let ensureNewLine: Bool
    private var previous: UInt8 = 0

    public init(ensureNewLine: Bool = false) {
        self.ensureNewLine = ensureNewLine
    }

    public func filter(_ input: [UInt8], startIndex: Int, length: Int, flush: Bool) -> [UInt8] {
        var output: [UInt8] = []
        output.reserveCapacity(length * 2 + (flush && ensureNewLine ? 2 : 0))

        let end = startIndex + length
        var index = startIndex

        while index < end {
            let byte = input[index]
            index += 1

            if byte == 0x0A {
                if previous != 0x0D {
                    output.append(0x0D)
                }
                output.append(byte)
            } else {
                output.append(byte)
            }

            previous = byte
        }

        if flush && ensureNewLine && previous != 0x0A {
            if previous != 0x0D {
                output.append(0x0D)
            }
            output.append(0x0A)
            previous = 0x0A
        }

        return output
    }

    public func reset() {
        previous = 0
    }
}
