//
// DkimRelaxedBodyFilter.swift
//
// Ported from MimeKit (C#) to Swift.
//

final class DkimRelaxedBodyFilter: DkimBodyFilter {
    private var lwsp = false
    private var cr = false

    override init() {
        super.init()
        lastWasNewLine = true
        isEmptyLine = true
    }

    override func filter(_ input: [UInt8], startIndex: Int, length: Int, outputIndex: inout Int, outputLength: inout Int, flush: Bool) -> [UInt8] {
        let need = length + (lwsp ? 1 : 0) + (emptyLines * 2) + (cr ? 1 : 0) + 1
        ensureOutputSize(need, preserve: false)
        var output = output
        outputLength = filter(input[startIndex..<(startIndex + length)], output: &output)
        outputIndex = 0
        return output
    }

    override func reset() {
        lastWasNewLine = true
        isEmptyLine = true
        emptyLines = 0
        lwsp = false
        cr = false
        super.reset()
    }

    private func filter(_ input: ArraySlice<UInt8>, output: inout [UInt8]) -> Int {
        var count = 0
        var outputIndex = 0

        for c in input {
            if c == UInt8(ascii: "\n") {
                if isEmptyLine {
                    emptyLines += 1
                } else {
                    if cr {
                        output[outputIndex] = UInt8(ascii: "\r")
                        outputIndex += 1
                        count += 1
                    }

                    output[outputIndex] = UInt8(ascii: "\n")
                    outputIndex += 1
                    lastWasNewLine = true
                    isEmptyLine = true
                    count += 1
                }

                lwsp = false
                cr = false
            } else {
                if cr {
                    output[outputIndex] = UInt8(ascii: "\r")
                    outputIndex += 1
                    count += 1
                    cr = false
                }

                if c == UInt8(ascii: "\r") {
                    lwsp = false
                    cr = true
                } else if ByteClassification.isBlank(c) {
                    lwsp = true
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

                    if lwsp {
                        output[outputIndex] = UInt8(ascii: " ")
                        outputIndex += 1
                        lwsp = false
                        count += 1
                    }

                    lastWasNewLine = false
                    isEmptyLine = false

                    output[outputIndex] = c
                    outputIndex += 1
                    count += 1
                }
            }
        }

        return count
    }
}
