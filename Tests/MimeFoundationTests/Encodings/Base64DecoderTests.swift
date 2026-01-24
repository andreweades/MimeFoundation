import Testing
@testable import MimeFoundation

@Suite
struct Base64DecoderTests {
    private let base64EncodedPatterns = [
        "VGhpcyBpcyB0aGUgcGxhaW4gdGV4dCBtZXNzYWdlIQ==",
        "VGhpcyBpcyBhIHRleHQgd2hpY2ggaGFzIHRvIGJlIHBhZGRlZCBvbmNlLi4=",
        "VGhpcyBpcyBhIHRleHQgd2hpY2ggaGFzIHRvIGJlIHBhZGRlZCB0d2ljZQ==",
        "VGhpcyBpcyBhIHRleHQgd2hpY2ggd2lsbCBub3QgYmUgcGFkZGVk",
        " &% VGhp\r\ncyBp\r\ncyB0aGUgcGxhaW4g  \tdGV4dCBtZ?!XNzY*WdlIQ=="
    ]

    private let base64DecodedPatterns = [
        "This is the plain text message!",
        "This is a text which has to be padded once..",
        "This is a text which has to be padded twice",
        "This is a text which will not be padded",
        "This is the plain text message!"
    ]

    private let base64EncodedLongPatterns = [
        "AAECAwQFBgcICQoLDA0ODxAREhMUFRYXGBkaGxwdHh8gISIjJCU" +
        "mJygpKissLS4vMDEyMzQ1Njc4OTo7PD0+P0BBQkNERUZHSElKS0" +
        "xNTk9QUVJTVFVWV1hZWltcXV5fYGFiY2RlZmdoaWprbG1ub3Bxc" +
        "nN0dXZ3eHl6e3x9fn+AgYKDhIWGh4iJiouMjY6PkJGSk5SVlpeY" +
        "mZqbnJ2en6ChoqOkpaanqKmqq6ytrq+wsbKztLW2t7i5uru8vb6" +
        "/wMHCw8TFxsfIycrLzM3Oz9DR0tPU1dbX2Nna29zd3t/g4eLj5O" +
        "Xm5+jp6uvs7e7v8PHy8/T19vf4+fr7/P3+/w==",

        "AQIDBAUGBwgJCgsMDQ4PEBESExQVFhcYGRobHB0eHyAhIiMkJSY" +
        "nKCkqKywtLi8wMTIzNDU2Nzg5Ojs8PT4/QEFCQ0RFRkdISUpLTE" +
        "1OT1BRUlNUVVZXWFlaW1xdXl9gYWJjZGVmZ2hpamtsbW5vcHFyc" +
        "3R1dnd4eXp7fH1+f4CBgoOEhYaHiImKi4yNjo+QkZKTlJWWl5iZ" +
        "mpucnZ6foKGio6SlpqeoqaqrrK2ur7CxsrO0tba3uLm6u7y9vr/" +
        "AwcLDxMXGx8jJysvMzc7P0NHS09TV1tfY2drb3N3e3+Dh4uPk5e" +
        "bn6Onq6+zt7u/w8fLz9PX29/j5+vv8/f7/AA==",

        "AgMEBQYHCAkKCwwNDg8QERITFBUWFxgZGhscHR4fICEiIyQlJic" +
        "oKSorLC0uLzAxMjM0NTY3ODk6Ozw9Pj9AQUJDREVGR0hJSktMTU" +
        "5PUFFSU1RVVldYWVpbXF1eX2BhYmNkZWZnaGlqa2xtbm9wcXJzd" +
        "HV2d3h5ent8fX5/gIGCg4SFhoeIiYqLjI2Oj5CRkpOUlZaXmJma" +
        "m5ydnp+goaKjpKWmp6ipqqusra6vsLGys7S1tre4ubq7vL2+v8D" +
        "BwsPExcbHyMnKy8zNzs/Q0dLT1NXW19jZ2tvc3d7f4OHi4+Tl5u" +
        "fo6err7O3u7/Dx8vP09fb3+Pn6+/z9/v8AAQ=="
    ]

    private let base64EncodedPatternsExtraPadding = [
        "VGhpcyBpcyB0aGUgcGxhaW4gdGV4dCBtZXNzYWdlIQ===",
        "VGhpcyBpcyB0aGUgcGxhaW4gdGV4dCBtZXNzYWdlIQ====",
        "VGhpcyBpcyB0aGUgcGxhaW4gdGV4dCBtZXNzYWdlIQ=====",
        "VGhpcyBpcyB0aGUgcGxhaW4gdGV4dCBtZXNzYWdlIQ======"
    ]

    @Test func argumentExceptions() {
        MimeDecoderTestsBase.assertArgumentExceptions(Base64Decoder())
    }

    @Test func encoding() {
        let decoder = Base64Decoder()
        #expect(decoder.encoding == .base64)
    }

    @Test func clone() {
        let decoder = Base64Decoder()
        MimeDecoderTestsBase.cloneAndAssert(decoder, sample: MimeDecoderTestsBase.wikipediaUnix)
    }

    @Test func reset() {
        let decoder = Base64Decoder()
        MimeDecoderTestsBase.resetAndAssert(decoder, sample: MimeDecoderTestsBase.wikipediaUnix)
    }

    @Test func decodePatterns() {
        for enableHwAccel in [true, false] {
            let decoder = Base64Decoder()
            decoder.enableHardwareAcceleration = enableHwAccel
            var output: [UInt8]? = [UInt8](repeating: 0, count: 4096)

            for (index, pattern) in base64EncodedPatterns.enumerated() {
                decoder.reset()
                let buf = Array(pattern.utf8)
                let n = try! decoder.decode(buf, startIndex: 0, length: buf.count, output: &output)
                let actual = String(decoding: output!.prefix(n), as: UTF8.self)
                #expect(actual == base64DecodedPatterns[index])
            }

            for (index, pattern) in base64EncodedLongPatterns.enumerated() {
                decoder.reset()
                let buf = Array(pattern.utf8)
                let n = try! decoder.decode(buf, startIndex: 0, length: buf.count, output: &output)
                for i in 0..<n {
                    #expect(output![i] == UInt8(truncatingIfNeeded: i + index))
                }
            }

            for pattern in base64EncodedPatternsExtraPadding {
                decoder.reset()
                let buf = Array(pattern.utf8)
                let n = try! decoder.decode(buf, startIndex: 0, length: buf.count, output: &output)
                let actual = String(decoding: output!.prefix(n), as: UTF8.self)
                #expect(actual == base64DecodedPatterns[0])
            }
        }
    }

    @Test func decodeTwoBlocks() {
        let input = "VGhpcyBpcyB0aGUgcGF5bG9hZCBvZiB0aGUgZmlyc3QgYmFzZTY0LWVuY29kZWQgYmxvY2sgb2Yg\r\ndGV4dC4=\r\nQW5kIHRoaXMgaXMgdGhlIHBheWxvYWQgb2YgdGhlIHNlY29uZCBiYXNlNjQtZW5jb2RlZCBibG9j\r\nayBvZiB0ZXh0Lg==\r\n"
        let expected = "This is the payload of the first base64-encoded block of text.And this is the payload of the second base64-encoded block of text."
        let data = Array(input.utf8)

        for enableHwAccel in [true, false] {
            let decoder = Base64Decoder()
            decoder.enableHardwareAcceleration = enableHwAccel
            var output: [UInt8]? = [UInt8](repeating: 0, count: decoder.estimateOutputLength(data.count))
            let n = try! decoder.decode(data, startIndex: 0, length: data.count, output: &output)
            let actual = String(decoding: output!.prefix(n), as: UTF8.self)
            #expect(actual == expected)
        }
    }

    @Test func decode() {
        let bufferSizes = [4096, 1024, 16, 1]
        for bufferSize in bufferSizes {
            let decoder = Base64Decoder()
            decoder.enableHardwareAcceleration = false
            MimeDecoderTestsBase.testDecoder(decoder, rawData: MimeDecoderTestsBase.photo, encodedFile: "photo.b64", bufferSize: bufferSize)
            let decoderAlt = Base64Decoder()
            decoderAlt.enableHardwareAcceleration = true
            MimeDecoderTestsBase.testDecoder(decoderAlt, rawData: MimeDecoderTestsBase.photo, encodedFile: "photo.b64", bufferSize: bufferSize)
        }
    }
}
