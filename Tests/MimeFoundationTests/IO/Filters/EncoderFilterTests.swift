//
// EncoderFilterTests.swift
//

import Testing
@testable import MimeFoundation

@Suite
struct EncoderFilterTests {
    private static func assertIsEncoderFilter(_ encoding: ContentEncoding, expected: ContentEncoding) {
        let filter = EncoderFilter.create(encoding)
        #expect(filter is EncoderFilter)
        if let encoder = filter as? EncoderFilter {
            #expect(encoder.encoding == expected)
        }
    }

    private static func assertIsEncoderFilter(_ encoding: String, expected: ContentEncoding) {
        let filter = EncoderFilter.create(encoding)
        #expect(filter is EncoderFilter)
        if let encoder = filter as? EncoderFilter {
            #expect(encoder.encoding == expected)
        }
    }

    @Test("EncoderFilter create")
    func encoderFilterCreate() {
        #expect(EncoderFilter.create(nil as ContentEncoding?) is PassThroughFilter)
        #expect(EncoderFilter.create(nil as String?) is PassThroughFilter)

        Self.assertIsEncoderFilter(.base64, expected: .base64)
        Self.assertIsEncoderFilter("base64", expected: .base64)

        #expect(EncoderFilter.create(.binary) is PassThroughFilter)
        #expect(EncoderFilter.create("binary") is PassThroughFilter)

        #expect(EncoderFilter.create(.default) is PassThroughFilter)
        #expect(EncoderFilter.create("x-invalid") is PassThroughFilter)

        #expect(EncoderFilter.create(.eightBit) is PassThroughFilter)
        #expect(EncoderFilter.create("8bit") is PassThroughFilter)

        Self.assertIsEncoderFilter(.quotedPrintable, expected: .quotedPrintable)
        Self.assertIsEncoderFilter("quoted-printable", expected: .quotedPrintable)

        #expect(EncoderFilter.create(.sevenBit) is PassThroughFilter)
        #expect(EncoderFilter.create("7bit") is PassThroughFilter)

        Self.assertIsEncoderFilter(.uuEncode, expected: .uuEncode)
        Self.assertIsEncoderFilter("x-uuencode", expected: .uuEncode)
        Self.assertIsEncoderFilter("uuencode", expected: .uuEncode)
    }
}
