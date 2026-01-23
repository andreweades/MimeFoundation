//
// EncoderFilter.swift
//
// Ported from MimeKit (C#) to Swift.
//

import Foundation

public final class EncoderFilter: MimeFilterBase {
    public let encoding: ContentEncoding
    private var encoder: MimeEncoder

    public init(_ encoder: MimeEncoder) {
        self.encoder = encoder
        self.encoding = encoder.encoding
    }

    public override func filter(_ input: [UInt8], startIndex: Int, length: Int, outputIndex: inout Int, outputLength: inout Int, flush: Bool) -> [UInt8] {
        ensureOutputSize(encoder.estimateOutputLength(length), preserve: false)
        var output = self.output
        var outputOptional: [UInt8]? = output
        let written = (try? encoder.encode(input, startIndex: startIndex, length: length, output: &outputOptional)) ?? 0
        outputIndex = 0
        outputLength = written
        return outputOptional ?? output
    }

    public override func flush(_ input: [UInt8], startIndex: Int, length: Int, outputIndex: inout Int, outputLength: inout Int) -> [UInt8] {
        ensureOutputSize(encoder.estimateOutputLength(length) + 8, preserve: false)
        var output = self.output
        var outputOptional: [UInt8]? = output
        let written = (try? encoder.flush(input, startIndex: startIndex, length: length, output: &outputOptional)) ?? 0
        outputIndex = 0
        outputLength = written
        return outputOptional ?? output
    }

    public override func reset() {
        encoder.reset()
        super.reset()
    }

    public static func create(_ encoding: ContentEncoding?) -> MimeFilter {
        guard let encoding else {
            return PassThroughFilter()
        }
        switch encoding {
        case .base64:
            return EncoderFilter(Base64Encoder())
        case .quotedPrintable:
            return EncoderFilter(QuotedPrintableEncoder())
        case .uuEncode:
            return EncoderFilter(UUEncoder())
        default:
            return PassThroughFilter()
        }
    }

    public static func create(_ encoding: String?) -> MimeFilter {
        guard let encoding else {
            return PassThroughFilter()
        }
        switch encoding.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() {
        case "base64":
            return EncoderFilter(Base64Encoder())
        case "quoted-printable":
            return EncoderFilter(QuotedPrintableEncoder())
        case "x-uuencode", "uuencode":
            return EncoderFilter(UUEncoder())
        case "7bit", "8bit", "binary":
            return PassThroughFilter()
        default:
            return PassThroughFilter()
        }
    }
}
