import Testing
@testable import SwiftMimeKit

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
        var route: DomainList? = nil
        #expect(DomainList.tryParse("", route: &route) == false)
    }

    @Test
    func testParseWhiteSpace() {
        var route: DomainList? = nil
        #expect(DomainList.tryParse(" \t\r\n", route: &route) == false)
    }

    @Test
    func testParseAt() {
        var route: DomainList? = nil
        #expect(DomainList.tryParse("@", route: &route) == false)
    }

    @Test
    func testParseEmptyDomains() {
        var route: DomainList? = nil
        #expect(DomainList.tryParse("@domain1,,@domain2", route: &route) == true)
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
