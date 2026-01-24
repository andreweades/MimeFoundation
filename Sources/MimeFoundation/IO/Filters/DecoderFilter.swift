//
// DecoderFilter.swift
//
// Ported from MimeKit (C#) to Swift.
//

import Foundation

public final class DecoderFilter: MimeFilterBase {
    public let encoding: ContentEncoding
    private var decoder: MimeDecoder

    public init(_ decoder: MimeDecoder) {
        self.decoder = decoder
        self.encoding = decoder.encoding
    }

    public override func filter(_ input: [UInt8], startIndex: Int, length: Int, outputIndex: inout Int, outputLength: inout Int, flush: Bool) -> [UInt8] {
        ensureOutputSize(decoder.estimateOutputLength(length), preserve: false)
        var output = self.output
        let written = (try? decoder.decode(input, startIndex: startIndex, length: length, output: &output)) ?? 0
        outputIndex = 0
        outputLength = written
        return output
    }

    public override func reset() {
        decoder.reset()
        super.reset()
    }

    public static func create(_ encoding: ContentEncoding?) -> MimeFilter {
        guard let encoding else {
            return PassThroughFilter()
        }
        switch encoding {
        case .base64:
            return DecoderFilter(Base64Decoder())
        case .quotedPrintable:
            return DecoderFilter(QuotedPrintableDecoder())
        case .uuEncode:
            return DecoderFilter(UUDecoder())
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
            return DecoderFilter(Base64Decoder())
        case "quoted-printable":
            return DecoderFilter(QuotedPrintableDecoder())
        case "x-uuencode", "uuencode":
            return DecoderFilter(UUDecoder())
        case "7bit", "8bit", "binary":
            return PassThroughFilter()
        default:
            return PassThroughFilter()
        }
    }
}
