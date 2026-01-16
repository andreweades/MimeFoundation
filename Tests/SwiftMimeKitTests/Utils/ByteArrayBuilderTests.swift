import Testing
@testable import SwiftMimeKit

@Suite
struct ByteArrayBuilderTests {
    @Test func ensureCapacity() {
        var builder = ByteArrayBuilder(initialCapacity: 1)

        for i in 0..<32 {
            builder.append(UInt8(i))
        }

        let array = builder.toArray()
        builder.dispose()

        #expect(array.count == 32)
        for i in 0..<array.count {
            #expect(Int(array[i]) == i)
        }
    }
}
