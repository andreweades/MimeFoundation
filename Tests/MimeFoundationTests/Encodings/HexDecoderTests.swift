import Testing
@testable import MimeFoundation

@Suite
struct HexDecoderTests {
    @Test func argumentExceptions() {
        MimeDecoderTestsBase.assertArgumentExceptions(HexDecoder())
    }

    @Test func encoding() {
        let decoder = HexDecoder()
        #expect(decoder.encoding == .default)
    }

    @Test func clone() {
        MimeDecoderTestsBase.cloneAndAssert(HexDecoder(), sample: MimeDecoderTestsBase.wikipediaUnix)
    }

    @Test func reset() {
        MimeDecoderTestsBase.resetAndAssert(HexDecoder(), sample: MimeDecoderTestsBase.wikipediaUnix)
    }

    @Test func decodeHebrew() {
        let input = "This should decode: (%ED%E5%EC%F9 %EF%E1 %E9%EC%E8%F4%F0) while %X1%S1%Z1 should not"
        let decoder = HexDecoder()
        var output = [UInt8](repeating: 0, count: 1024)

        let buf = Array(input.utf8)
        let n = try! decoder.decode(buf, startIndex: 0, length: buf.count, output: &output)

        let expectedBytes: [UInt8] =
            Array("This should decode: (".utf8) +
            [0xED, 0xE5, 0xEC, 0xF9, 0x20, 0xEF, 0xE1, 0x20, 0xE9, 0xEC, 0xE8, 0xF4, 0xF0] +
            Array(") while %X1%S1%Z1 should not".utf8)

        #expect(Array(output.prefix(n)) == expectedBytes)
    }

    @Test func decodeAttrSpecials() {
        let input = "%20%09%0D%0AABCabc123!%40#$%25^&%2A%28%29_+`-%3D%5B%5D%5C{}|%3B%3A%27%22%2C.%2F%3C%3E%3F"
        let expected = " \t\r\nABCabc123!@#$%^&*()_+`-=[]\\{}|;:'\",./<>?"
        let decoder = HexDecoder()
        var output = [UInt8](repeating: 0, count: 1024)

        let buf = Array(input.utf8)
        let n = try! decoder.decode(buf, startIndex: 0, length: buf.count, output: &output)
        let actual = String(decoding: output.prefix(n), as: UTF8.self)
        #expect(actual == expected)
    }
}
