import Testing
@testable import SwiftMimeKit

@Suite
struct DkimSignatureStreamTests {
    private final class DummySignatureContext: DkimSignatureContext {
        func update(_ buffer: [UInt8], offset: Int, count: Int) {
        }

        func generateSignature() throws -> [UInt8] {
            []
        }

        func verify(signature: [UInt8]) throws -> Bool {
            true
        }
    }

    @Test("DkimSignatureStream basic behavior")
    func dkimSignatureStreamBasics() throws {
        var buffer = [UInt8](repeating: 0, count: 128)

        #expect(throws: StreamError.invalidArgument) {
            _ = try DkimSignatureStream(nil)
        }

        let stream = try DkimSignatureStream(DummySignatureContext())
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

        #expect(throws: StreamError.invalidArgument) {
            _ = try stream.verifySignature(nil)
        }

        try stream.flush()
    }
}
