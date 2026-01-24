import Foundation
import Testing
@testable import MimeFoundation

@Suite
struct YEncodingTests {
    private static let dataDir = "yenc"

    private static func loadBody(relativePath: String) throws -> [UInt8] {
        let data = try TestHelper.loadData(relativePath: "\(Self.dataDir)/\(relativePath)")
        if let range = findHeaderSeparator(in: data) {
            return Array(data[(range.upperBound)..<data.count])
        }
        return data
    }

    private static func findHeaderSeparator(in data: [UInt8]) -> Range<Int>? {
        if data.count < 2 { return nil }
        for i in 0..<(data.count - 1) {
            if data[i] == 0x0A && data[i + 1] == 0x0A {
                return i..<(i + 2)
            }
            if i < data.count - 3,
               data[i] == 0x0D, data[i + 1] == 0x0A,
               data[i + 2] == 0x0D, data[i + 3] == 0x0A {
                return i..<(i + 4)
            }
        }
        return nil
    }

    private static func normalizeToUnix(_ data: [UInt8]) -> [UInt8] {
        let output = MemoryStream([], writable: true)
        let filtered = try! FilteredStream(output)
        try! filtered.add(Dos2UnixFilter())
        try! filtered.write(data, offset: 0, count: data.count)
        try! filtered.flush()
        return output.toByteArray()
    }

    private static func testYEncode(fileName: String, content: [UInt8], contentLength: Int, crc32: UInt32, expectedOutput: [UInt8]) {
        var encoded: [UInt8] = []
        let ybegin = Array("-- \n=ybegin line=128 size=\(contentLength) name=\(fileName) \n".utf8)
        let yend = Array("=yend size=\(contentLength) crc32=\(String(format: "%08x", crc32)) \n".utf8)
        let encoder = YEncoder()

        encoded.append(contentsOf: ybegin)
        let output = MemoryStream([], writable: true)
        let filtered = try! FilteredStream(output)
        try! filtered.add(EncoderFilter(encoder))
        try! filtered.write(content, offset: 0, count: contentLength)
        try! filtered.flush()
        encoded.append(contentsOf: output.toByteArray())
        encoded.append(contentsOf: yend)

        let checksum = UInt32(bitPattern: encoder.checksum) ^ 0xFFFF_FFFF
        #expect(checksum == crc32)
        #expect(encoded == expectedOutput)
    }

    private static func testYEncodeFlush(fileName: String, content: [UInt8], contentLength: Int, crc32: UInt32, expectedOutput: [UInt8]) {
        let ybegin = Array("-- \n=ybegin line=128 size=\(contentLength) name=\(fileName) \n".utf8)
        let yend = Array("=yend size=\(contentLength) crc32=\(String(format: "%08x", crc32)) \n".utf8)
        let encoder = YEncoder()

        let needed = encoder.estimateOutputLength(contentLength) + ybegin.count + yend.count
        var encoded = [UInt8](repeating: 0, count: needed)
        let encodedLength = try! encoder.flush(content, startIndex: 0, length: contentLength, output: &encoded)

        var combined = ybegin
        combined.append(contentsOf: encoded.prefix(encodedLength))
        combined.append(contentsOf: yend)

        let checksum = UInt32(bitPattern: encoder.checksum) ^ 0xFFFF_FFFF
        #expect(checksum == crc32)
        #expect(combined == expectedOutput)
    }

    @Test func yDecodeSimpleMessage() throws {
        let body = try Self.loadBody(relativePath: "simple.msg")

        let decoder = YDecoder()
        let output = MemoryStream([], writable: true)
        let filtered = try FilteredStream(output)
        try filtered.add(DecoderFilter(decoder))
        try filtered.write(body, offset: 0, count: body.count)
        try filtered.flush()

        let decoded = output.toByteArray()
        #expect(decoded.count == 584)
        let checksum = UInt32(bitPattern: decoder.checksum) ^ 0xFFFF_FFFF
        #expect(checksum == 0xDED2_9F4F)

        let expectedBody = Self.normalizeToUnix(body)
        Self.testYEncode(fileName: "testfile.txt", content: decoded, contentLength: decoded.count, crc32: 0xDED2_9F4F, expectedOutput: expectedBody)
        Self.testYEncodeFlush(fileName: "testfile.txt", content: decoded, contentLength: decoded.count, crc32: 0xDED2_9F4F, expectedOutput: expectedBody)
    }

    @Test func yDecodeMultiPart() throws {
        let expected = try TestHelper.loadData(relativePath: "\(Self.dataDir)/joystick.jpg")
        var decoded: [UInt8] = []

        do {
            let data = try TestHelper.loadData(relativePath: "\(Self.dataDir)/00000020.ntx")
            let decoder = YDecoder()
            let output = MemoryStream([], writable: true)
            let filtered = try FilteredStream(output)
            try filtered.add(DecoderFilter(decoder))
            for byte in data {
                try filtered.write([byte], offset: 0, count: 1)
            }
            try filtered.flush()
            let part = output.toByteArray()
            decoded.append(contentsOf: part)
            #expect(part.count == 11250)
            let checksum = UInt32(bitPattern: decoder.checksum) ^ 0xFFFF_FFFF
            #expect(checksum == 0xBFAE_5C0B)
        }

        do {
            let data = try TestHelper.loadData(relativePath: "\(Self.dataDir)/00000021.ntx")
            let decoder = YDecoder()
            let output = MemoryStream([], writable: true)
            let filtered = try FilteredStream(output)
            try filtered.add(DecoderFilter(decoder))
            for byte in data {
                try filtered.write([byte], offset: 0, count: 1)
            }
            try filtered.flush()
            let part = output.toByteArray()
            decoded.append(contentsOf: part)
            #expect(part.count == 8088)
            let checksum = UInt32(bitPattern: decoder.checksum) ^ 0xFFFF_FFFF
            #expect(checksum == 0xACA7_6043)
        }

        #expect(decoded.count == expected.count)
        #expect(decoded == expected)
    }

    @Test func yDecodeStateTransitions() throws {
        let data = try TestHelper.loadData(relativePath: "\(Self.dataDir)/state-changes.ntx")
        let decoder = YDecoder()
        let output = MemoryStream([], writable: true)
        let filtered = try FilteredStream(output)
        try filtered.add(DecoderFilter(decoder))
        for byte in data {
            try filtered.write([byte], offset: 0, count: 1)
        }
        try filtered.flush()

        let decoded = output.toByteArray()
        #expect(decoded.count == 584)
        let checksum = UInt32(bitPattern: decoder.checksum) ^ 0xFFFF_FFFF
        #expect(checksum == 0xDED2_9F4F)
    }

    @Test func yDecodeYPartStateTransitions() {
        let inputs = [
            "=ybegin part=1 line=128 size=19338 name=joystick.jpg\n=xcontent",
            "=ybegin part=1 line=128 size=19338 name=joystick.jpg\n=yxcontent",
            "=ybegin part=1 line=128 size=19338 name=joystick.jpg\n=ypxcontent",
            "=ybegin part=1 line=128 size=19338 name=joystick.jpg\n=ypaxcontent",
            "=ybegin part=1 line=128 size=19338 name=joystick.jpg\n=yparxcontent",
            "=ybegin part=1 line=128 size=19338 name=joystick.jpg\n=ypartxcontent",
            "=ybegin part=1 line=128 size=19338 name=joystick.jpg\n=ypart begin=1 end=11250\ncontent"
        ]

        let outputs = [
            "xcontent",
            "",
            "",
            "",
            "",
            "",
            "content"
        ]

        let decoder = YDecoder()
        var output = [UInt8](repeating: 0, count: 1024)

        for i in 0..<inputs.count {
            let input = Array(inputs[i].utf8)
            let n = try! decoder.decode(input, startIndex: 0, length: input.count, output: &output)
            var expectedChars = Array(outputs[i].utf8)
            for index in 0..<expectedChars.count {
                expectedChars[index] &-= 42
            }
            let expected = String(decoding: expectedChars, as: UTF8.self)
            let actual = String(decoding: output.prefix(n), as: UTF8.self)
            #expect(actual == expected)
            decoder.reset()
        }
    }
}
