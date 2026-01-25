import Testing
@testable import MimeFoundation

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

        // getHashCode takes a non-optional String and case-insensitive
        let hash1 = comparer.getHashCode("abc")
        let hash2 = comparer.getHashCode("ABC")
        #expect(hash1 == hash2)
    }
}
