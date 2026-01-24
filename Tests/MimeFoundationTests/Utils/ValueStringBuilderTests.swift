import Testing
@testable import MimeFoundation

@Suite
struct ValueStringBuilderTests {
    @Test func ctorDefaultCanAppend() {
        var vsb = ValueStringBuilder()
        #expect(vsb.length == 0)

        vsb.append("a")
        #expect(vsb.length == 1)
        #expect(vsb.toString() == "a")
    }

    @Test func ctorInitialCapacityCanAppend() {
        var vsb = ValueStringBuilder(initialCapacity: 1)
        #expect(vsb.length == 0)

        vsb.append("a")
        #expect(vsb.length == 1)
        #expect(vsb.toString() == "a")
    }

    @Test func appendCharMatchesStringBuilder() {
        var sb = ""
        var vsb = ValueStringBuilder()

        for i in 1...100 {
            let scalar = UnicodeScalar(i)!
            let character = Character(scalar)
            sb.append(character)
            vsb.append(character)
        }

        #expect(vsb.length == sb.utf16.count)
        #expect(vsb.toString() == sb)
    }

    @Test func appendStringMatchesStringBuilder() {
        var sb = ""
        var vsb = ValueStringBuilder()

        for i in 1...100 {
            let string = String(i)
            sb.append(contentsOf: string)
            vsb.append(string)
        }

        #expect(vsb.length == sb.utf16.count)
        #expect(vsb.toString() == sb)
    }

    @Test func appendNullStringMatchesStringBuilder() {
        var sb = ""
        var vsb = ValueStringBuilder()

        sb.append("a")
        sb.append("b")

        vsb.append("a")
        vsb.append(nil as String?)
        vsb.append("b")

        #expect(vsb.length == sb.utf16.count)
        #expect(vsb.toString() == sb)
    }

    @Test func insertNullStringMatchesStringBuilder() {
        var sb = "b"
        var vsb = ValueStringBuilder()

        sb.insert(contentsOf: "a", at: sb.startIndex)

        vsb.append("b")
        vsb.insert(nil as String?, at: 0)
        vsb.insert("a", at: 0)

        #expect(vsb.length == sb.utf16.count)
        #expect(vsb.toString() == sb)
    }

    @Test func insertGrowsMatchesStringBuilder() {
        var vsb = ValueStringBuilder()

        vsb.append("s")
        vsb.insert("Make sure that the ValueStringBuilder's capacity grow", at: 0)

        #expect(vsb.toString() == "Make sure that the ValueStringBuilder's capacity grows")
    }

    @Test func indexer() {
        var vsb = ValueStringBuilder()

        vsb.append("foobar")

        #expect(vsb[3] == "b")
        vsb[3] = "c"
        #expect(vsb[3] == "c")
    }
}
