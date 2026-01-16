//
// DecoderFilter.swift
//
// Ported from MimeKit (C#) to Swift.
//

public final class DecoderFilter: MimeFilter {
    public let decoder: any MimeDecoder

    public init(decoder: any MimeDecoder) {
        self.decoder = decoder
    }

    public func filter(_ input: [UInt8], startIndex: Int, length: Int, flush: Bool) -> [UInt8] {
        let output = [UInt8](repeating: 0, count: decoder.estimateOutputLength(length))
        var outputOptional: [UInt8]? = output
        let count = try! decoder.decode(input, startIndex: startIndex, length: length, output: &outputOptional)
        let buffer = outputOptional ?? []
        return Array(buffer.prefix(count))
    }

    public func reset() {
        decoder.reset()
    }
}
