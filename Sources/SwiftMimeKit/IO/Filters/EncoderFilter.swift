//
// EncoderFilter.swift
//
// Ported from MimeKit (C#) to Swift.
//

public final class EncoderFilter: MimeFilter {
    public let encoder: any MimeEncoder

    public init(encoder: any MimeEncoder) {
        self.encoder = encoder
    }

    public func filter(_ input: [UInt8], startIndex: Int, length: Int, flush: Bool) -> [UInt8] {
        let output = [UInt8](repeating: 0, count: encoder.estimateOutputLength(length))
        var outputOptional: [UInt8]? = output
        let count: Int

        if flush {
            count = try! encoder.flush(input, startIndex: startIndex, length: length, output: &outputOptional)
        } else {
            count = try! encoder.encode(input, startIndex: startIndex, length: length, output: &outputOptional)
        }

        let buffer = outputOptional ?? []
        return Array(buffer.prefix(count))
    }

    public func reset() {
        encoder.reset()
    }
}
