//
// MimeFilterBase.swift
//
// Ported from MimeKit (C#) to Swift.
//

import Foundation

open class MimeFilterBase: MimeFilter {
    private var preload: [UInt8] = []
    private var preloadLength: Int = 0
    private var inputBuffer: [UInt8] = []
    private var outputBuffer: [UInt8] = []

    public init() {}

    open func reset() {
        preloadLength = 0
    }

    open func filter(_ input: [UInt8], startIndex: Int, length: Int, outputIndex: inout Int, outputLength: inout Int) -> [UInt8] {
        try? validateArguments(input, startIndex: startIndex, length: length)
        var start = startIndex
        var count = length
        let prepared = prefilter(input, startIndex: &start, length: &count)
        return filter(prepared, startIndex: start, length: count, outputIndex: &outputIndex, outputLength: &outputLength, flush: false)
    }

    open func flush(_ input: [UInt8], startIndex: Int, length: Int, outputIndex: inout Int, outputLength: inout Int) -> [UInt8] {
        try? validateArguments(input, startIndex: startIndex, length: length)
        var start = startIndex
        var count = length
        let prepared = prefilter(input, startIndex: &start, length: &count)
        return filter(prepared, startIndex: start, length: count, outputIndex: &outputIndex, outputLength: &outputLength, flush: true)
    }

    open func filter(_ input: [UInt8], startIndex: Int, length: Int, outputIndex: inout Int, outputLength: inout Int, flush: Bool) -> [UInt8] {
        outputIndex = startIndex
        outputLength = length
        return input
    }

    internal func ensureOutputSize(_ need: Int, preserve: Bool) {
        if outputBuffer.count < need {
            let size = (need + 63) & ~63
            if preserve && !outputBuffer.isEmpty {
                var newBuffer = outputBuffer
                newBuffer.append(contentsOf: repeatElement(0, count: size - outputBuffer.count))
                outputBuffer = newBuffer
            } else {
                outputBuffer = Array(repeating: 0, count: size)
            }
        }
    }

    internal var output: [UInt8] {
        outputBuffer
    }

    internal func saveRemainingInput(_ input: [UInt8], startIndex: Int, length: Int) {
        if length == 0 {
            preloadLength = 0
            return
        }
        if preload.count < length {
            preload = Array(repeating: 0, count: length)
        }
        preload.replaceSubrange(0..<length, with: input[startIndex..<(startIndex + length)])
        preloadLength = length
    }

    private func prefilter(_ input: [UInt8], startIndex: inout Int, length: inout Int) -> [UInt8] {
        if preloadLength == 0 {
            return input
        }
        let totalLength = length + preloadLength
        if inputBuffer.count < totalLength {
            inputBuffer = Array(repeating: 0, count: (totalLength + 63) & ~63)
        }
        if preloadLength > 0 {
            inputBuffer.replaceSubrange(0..<preloadLength, with: preload[0..<preloadLength])
        }
        inputBuffer.replaceSubrange(preloadLength..<(preloadLength + length), with: input[startIndex..<(startIndex + length)])
        length = totalLength
        startIndex = 0
        preloadLength = 0
        return inputBuffer
    }

    private func validateArguments(_ input: [UInt8], startIndex: Int, length: Int) throws {
        if startIndex < 0 || startIndex > input.count {
            throw StreamError.outOfRange
        }
        if length < 0 || length > (input.count - startIndex) {
            throw StreamError.outOfRange
        }
    }
}
