import Testing
@testable import SwiftMimeKit

@Suite
struct PackedByteArrayTests {
    @Test func argumentExceptions() {
        let packed = PackedByteArray()

        #expect(throws: PackedByteArrayError.nilBuffer) {
            try packed.copy(to: nil, startIndex: 0)
        }

        #expect(throws: PackedByteArrayError.indexOutOfRange) {
            try packed.copy(to: [UInt8](repeating: 0, count: 16), startIndex: -1)
        }
    }

    @Test func basicFunctionality() throws {
        let packed = PackedByteArray()
        var expected = [UInt8](repeating: 0, count: 1024)
        var buffer = [UInt8](repeating: 0, count: 1024)
        var index = 0

        let a = "A".utf8.first!
        let b = "B".utf8.first!

        for _ in 0..<257 {
            expected[index] = a
            packed.add(a)
            index += 1
        }

        for i in 1..<26 {
            let value = a + UInt8(i)
            expected[index] = value
            packed.add(value)
            index += 1
        }

        for _ in 0..<128 {
            expected[index] = b
            packed.add(b)
            index += 1
        }

        for i in 0..<26 {
            let value = a + UInt8(i)
            expected[index] = value
            packed.add(value)
            index += 1
        }

        for i in 0..<26 {
            let value = a + UInt8(i)
            expected[index] = value
            packed.add(value)
            index += 1
        }

        #expect(packed.count == index)

        try packed.copy(to: &buffer, startIndex: 0)

        for i in 0..<index {
            #expect(buffer[i] == expected[i], "buffer[\(i)]")
        }
    }
}
