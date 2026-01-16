import Testing
@testable import SwiftMimeKit

@Suite
struct OptimizedOrdinalIgnoreCaseComparerTests {
    @Test func equals() {
        let comparer = OptimizedOrdinalIgnoreCaseComparer()

        #expect(!comparer.equals("abc", "a"))
        #expect(!comparer.equals("abc", "abd"))
        #expect(comparer.equals("abc", "abc"))
    }

    @Test func getHashCode() {
        let comparer = OptimizedOrdinalIgnoreCaseComparer()

        #expect(throws: OptimizedOrdinalComparerError.nilString) {
            try comparer.getHashCode(nil)
        }
    }
}
