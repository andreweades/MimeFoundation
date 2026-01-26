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

@Suite("DomainList")
struct DomainListTests {
    @Test
    func testBasicListFunctionality() {
        let list = DomainList()
        #expect(list.isReadOnly == false)
        #expect(list.count == 0)

        list.add("domain2")
        #expect(list.count == 1)
        #expect(list[0] == "domain2")

        list.insert("domain0", at: 0)
        list.insert("domain1", at: 1)
        #expect(list.count == 3)
        #expect(list[0] == "domain0")
        #expect(list[1] == "domain1")
        #expect(list[2] == "domain2")

        #expect(list.contains("domain1"))
        #expect(list.indexOf("domain1") == 1)

        var array: [String] = []
        list.copyTo(&array, at: 0)
        #expect(array.count == 3)
        list.clear()
        #expect(list.count == 0)

        for domain in array {
            list.add(domain)
        }
        #expect(list.count == array.count)

        #expect(list.remove("not-in-the-list") == false)
        #expect(list.remove("domain2") == true)
        #expect(list.count == 2)
        #expect(list[0] == "domain0")
        #expect(list[1] == "domain1")

        list.remove(at: 0)
        #expect(list.count == 1)
        #expect(list[0] == "domain1")

        list[0] = "domain"
        #expect(list.count == 1)
        #expect(list[0] == "domain")
    }

    @Test
    func testParseEmpty() {
        #expect((try? DomainList(parsing: "")) == nil)
    }

    @Test
    func testParseWhiteSpace() {
        #expect((try? DomainList(parsing: " \t\r\n")) == nil)
    }

    @Test
    func testParseAt() {
        #expect((try? DomainList(parsing: "@")) == nil)
    }

    @Test
    func testParseEmptyDomains() {
        let route = try? DomainList(parsing: "@domain1,,@domain2")
        #expect(route != nil)
        #expect(route?.count == 2)
        #expect(route?[0] == "domain1")
        #expect(route?[1] == "domain2")
    }

    @Test
    func testToString() {
        let route = DomainList(["route1", "  \t\t ", "route2"])
        #expect(route.toString() == "@route1,@route2")
    }
}
