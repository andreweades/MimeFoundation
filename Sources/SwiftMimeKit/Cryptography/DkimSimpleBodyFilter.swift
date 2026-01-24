//
// DkimSimpleBodyFilter.swift
//
// Ported from MimeKit (C#) to Swift.
//

final class DkimSimpleBodyFilter: DkimBodyFilter {
    override init() {
        super.init()
        lastWasNewLine = false
        isEmptyLine = true
        emptyLines = 0
    }

    override func filter(_ input: [UInt8], startIndex: Int, length: Int, outputIndex: inout Int, outputLength: inout Int, flush: Bool) -> [UInt8] {
        let need = length + emptyLines * 2 + 1
        ensureOutputSize(need, preserve: false)
        var output = output
        outputLength = filter(input[startIndex..<(startIndex + length)], output: &output)
        outputIndex = 0
        return output
    }

    override func reset() {
        lastWasNewLine = false
        isEmptyLine = true
        emptyLines = 0
        super.reset()
    }

    private func filter(_ input: ArraySlice<UInt8>, output: inout [UInt8]) -> Int {
        var count = 0
        var outputIndex = 0

        for c in input {
            if c == UInt8(ascii: "\r") {
                if !isEmptyLine {
                    output[outputIndex] = c
                    outputIndex += 1
                    count += 1
                }
            } else if c == UInt8(ascii: "\n") {
                if !isEmptyLine {
                    output[outputIndex] = c
                    outputIndex += 1
                    lastWasNewLine = true
                    isEmptyLine = true
                    emptyLines = 0
                    count += 1
                } else {
                    emptyLines += 1
                }
            } else {
                if emptyLines > 0 {
                    while emptyLines > 0 {
                        output[outputIndex] = UInt8(ascii: "\r")
                        outputIndex += 1
                        output[outputIndex] = UInt8(ascii: "\n")
                        outputIndex += 1
                        emptyLines -= 1
                        count += 2
                    }
                }

                lastWasNewLine = false
                isEmptyLine = false

                output[outputIndex] = c
                outputIndex += 1
                count += 1
            }
        }

        return count
    }
}
