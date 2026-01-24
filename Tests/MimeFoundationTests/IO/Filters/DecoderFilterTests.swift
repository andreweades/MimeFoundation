//
// DecoderFilterTests.swift
//

import Testing
@testable import MimeFoundation

@Suite
struct DecoderFilterTests {
    private static func assertIsDecoderFilter(_ encoding: ContentEncoding, expected: ContentEncoding) {
        let filter = DecoderFilter.create(encoding)
        #expect(filter is DecoderFilter)
        if let decoder = filter as? DecoderFilter {
            #expect(decoder.encoding == expected)
        }
    }

    private static func assertIsDecoderFilter(_ encoding: String, expected: ContentEncoding) {
        let filter = DecoderFilter.create(encoding)
        #expect(filter is DecoderFilter)
        if let decoder = filter as? DecoderFilter {
            #expect(decoder.encoding == expected)
        }
    }

    @Test("DecoderFilter create")
    func decoderFilterCreate() {
        #expect(DecoderFilter.create(nil as ContentEncoding?) is PassThroughFilter)
        #expect(DecoderFilter.create(nil as String?) is PassThroughFilter)

        Self.assertIsDecoderFilter(.base64, expected: .base64)
        Self.assertIsDecoderFilter("base64", expected: .base64)

        #expect(DecoderFilter.create(.binary) is PassThroughFilter)
        #expect(DecoderFilter.create("binary") is PassThroughFilter)

        #expect(DecoderFilter.create(.default) is PassThroughFilter)
        #expect(DecoderFilter.create("x-invalid") is PassThroughFilter)

        #expect(DecoderFilter.create(.eightBit) is PassThroughFilter)
        #expect(DecoderFilter.create("8bit") is PassThroughFilter)

        Self.assertIsDecoderFilter(.quotedPrintable, expected: .quotedPrintable)
        Self.assertIsDecoderFilter("quoted-printable", expected: .quotedPrintable)

        #expect(DecoderFilter.create(.sevenBit) is PassThroughFilter)
        #expect(DecoderFilter.create("7bit") is PassThroughFilter)

        Self.assertIsDecoderFilter(.uuEncode, expected: .uuEncode)
        Self.assertIsDecoderFilter("x-uuencode", expected: .uuEncode)
        Self.assertIsDecoderFilter("uuencode", expected: .uuEncode)
    }
}
