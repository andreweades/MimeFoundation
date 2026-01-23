//
// ArmoredFromFilter.swift
//
// Ported from MimeKit (C#) to Swift.
//

import Foundation

public final class ArmoredFromFilter: MimeFilterBase {
    private static let marker = Array("From ".utf8)
    private var midline = false

    public override func filter(_ input: [UInt8], startIndex: Int, length: Int, outputIndex: inout Int, outputLength: inout Int, flush: Bool) -> [UInt8] {
        let span = Array(input[startIndex..<(startIndex + length)])
        var fromOffsets: [Int] = []
        var endIndex = length
        var index = 0

        if midline {
            if let next = span[index...].firstIndex(of: UInt8(ascii: "\n")) {
                index = next - span.startIndex + 1
                midline = false
            } else {
                index = length
            }
        }

        while index < length {
            let slice = Array(span[index..<length])
            if let next = slice.firstIndex(of: UInt8(ascii: "\n")) {
                if next >= ArmoredFromFilter.marker.count {
                    if slice.starts(with: ArmoredFromFilter.marker) {
                        fromOffsets.append(index)
                    }
                }
                index += next + 1
            } else {
                if slice.count >= ArmoredFromFilter.marker.count {
                    if slice.starts(with: ArmoredFromFilter.marker) {
                        fromOffsets.append(index)
                    }
                } else if !flush, slice.elementsEqual(ArmoredFromFilter.marker.prefix(slice.count)) {
                    saveRemainingInput(input, startIndex: startIndex + index, length: slice.count)
                    endIndex = index
                    break
                }
                midline = true
                break
            }
        }

        if !fromOffsets.isEmpty {
            let need = endIndex + fromOffsets.count * 2
            ensureOutputSize(need, preserve: false)
            var output = output
            outputLength = 0
            outputIndex = 0
            index = 0

            for offset in fromOffsets {
                if index < offset {
                    let src = span[index..<offset]
                    output.replaceSubrange(outputLength..<(outputLength + src.count), with: src)
                    outputLength += src.count
                    index = offset
                }
                output[outputLength] = UInt8(ascii: "=")
                output[outputLength + 1] = UInt8(ascii: "4")
                output[outputLength + 2] = UInt8(ascii: "6")
                outputLength += 3
                index += 1
            }

            if index < endIndex {
                let src = span[index..<endIndex]
                output.replaceSubrange(outputLength..<(outputLength + src.count), with: src)
                outputLength += src.count
            }
            return output
        }

        outputIndex = startIndex
        outputLength = endIndex
        return input
    }

    public override func reset() {
        midline = false
        super.reset()
    }
}
