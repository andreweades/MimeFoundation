//
// Author: Jeffrey Stedfast <jestedfa@microsoft.com>
//
// Copyright (c) 2013-2026 .NET Foundation and Contributors
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.
//

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
