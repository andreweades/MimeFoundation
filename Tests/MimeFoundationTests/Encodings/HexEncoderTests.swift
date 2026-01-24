import Testing
@testable import MimeFoundation

@Suite
struct HexEncoderTests {
    @Test func argumentExceptions() {
        MimeEncoderTestsBase.assertArgumentExceptions(HexEncoder())
    }

    @Test func encoding() {
        let encoder = HexEncoder()
        #expect(encoder.encoding == .default)
    }

    @Test func clone() {
        MimeEncoderTestsBase.cloneAndAssert(HexEncoder(), sample: MimeEncoderTestsBase.wikipediaUnix)
    }

    @Test func reset() {
        MimeEncoderTestsBase.resetAndAssert(HexEncoder(), sample: MimeEncoderTestsBase.wikipediaUnix)
    }

    @Test func encodeHebrew() {
        let expected = "%ED%E5%EC%F9%20%EF%E1%20%E9%EC%E8%F4%F0"
        let inputBytes: [UInt8] = [0xED, 0xE5, 0xEC, 0xF9, 0x20, 0xEF, 0xE1, 0x20, 0xE9, 0xEC, 0xE8, 0xF4, 0xF0]
        let encoder = HexEncoder()
        var output = [UInt8](repeating: 0, count: 1024)

        let n = try! encoder.encode(inputBytes, startIndex: 0, length: inputBytes.count, output: &output)
        let actual = String(decoding: output.prefix(n), as: UTF8.self)
        #expect(actual == expected)

        encoder.reset()
        let n2 = try! encoder.flush(inputBytes, startIndex: 0, length: inputBytes.count, output: &output)
        let actual2 = String(decoding: output.prefix(n2), as: UTF8.self)
        #expect(actual2 == expected)
    }

    @Test func encodeAttrSpecials() {
        let expected = "%20%09%0D%0AABCabc123!%40#$%25^&%2A%28%29_+`-%3D%5B%5D%5C{}|%3B%3A%27%22%2C.%2F%3C%3E%3F"
        let input = " \t\r\nABCabc123!@#$%^&*()_+`-=[]\\{}|;:'\",./<>?"
        let encoder = HexEncoder()
        var output = [UInt8](repeating: 0, count: 1024)

        let buf = Array(input.utf8)
        let n = try! encoder.encode(buf, startIndex: 0, length: buf.count, output: &output)
        let actual = String(decoding: output.prefix(n), as: UTF8.self)
        #expect(actual == expected)

        encoder.reset()
        let n2 = try! encoder.flush(buf, startIndex: 0, length: buf.count, output: &output)
        let actual2 = String(decoding: output.prefix(n2), as: UTF8.self)
        #expect(actual2 == expected)
    }
}
