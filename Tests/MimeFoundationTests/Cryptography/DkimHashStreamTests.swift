import Testing
@testable import MimeFoundation

@Suite
struct DkimHashStreamTests {
    @Test("DkimHashStream basic behavior")
    func dkimHashStreamBasics() throws {
        var buffer = [UInt8](repeating: 0, count: 128)
        let stream = DkimHashStream(.rsaSha1)

        #expect(stream.canRead == false)
        #expect(stream.canWrite == true)
        #expect(stream.canSeek == false)
        #expect(stream.canTimeout == false)

        #expect(throws: StreamError.notSupported) {
            _ = try stream.read(&buffer, offset: 0, count: buffer.count)
        }

        #expect(throws: StreamError.invalidArgument) {
            try stream.write(buffer, offset: -1, count: 0)
        }
        #expect(throws: StreamError.invalidArgument) {
            try stream.write(buffer, offset: 0, count: -1)
        }

        #expect(stream.position == 0)
        #expect(stream.length == 0)

        #expect(throws: StreamError.notSupported) {
            _ = try stream.seek(64, origin: .begin)
        }

        try stream.flush()
    }
}
