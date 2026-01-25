//
// MessageIdListTests.swift
//

import Testing
import MimeFoundation

@Test("MessageIdList argument exceptions")
func messageIdListArgumentExceptions() throws {
    let list = MessageIdList()
    var array: [String] = []

    // Index out of range for copyTo
    #expect(throws: MessageIdListError.self) {
        try list.copyTo(&array, startingAt: -1)
    }

    // Index out of range for insert
    #expect(throws: MessageIdListError.self) {
        try list.insert("item", at: -1)
    }

    // Index out of range for setItem
    #expect(throws: MessageIdListError.self) {
        try list.setItem(at: 0, "id")
    }

    // Index out of range for remove
    #expect(throws: MessageIdListError.self) {
        try list.remove(at: -1)
    }
}

@Test("MessageIdList basic functionality")
func messageIdListBasic() throws {
    let list = MessageIdList()

    #expect(!list.isReadOnly)
    #expect(list.count == 0)

    list.add("id2@localhost")
    #expect(list.count == 1)
    #expect(list[0] == "id2@localhost")

    try list.insert("id0@localhost", at: 0)
    try list.insert("id1@localhost", at: 1)

    #expect(list.count == 3)
    #expect(list[0] == "id0@localhost")
    #expect(list[1] == "id1@localhost")
    #expect(list[2] == "id2@localhost")

    let clone = list.copy()
    #expect(clone.count == 3)
    #expect(clone[0] == "id0@localhost")
    #expect(clone[1] == "id1@localhost")
    #expect(clone[2] == "id2@localhost")

    #expect(list.contains("id1@localhost"))
    #expect(list.indexOf("id1@localhost") == 1)

    var array: [String] = []
    try list.copyTo(&array, startingAt: 0)
    list.clear()
    #expect(list.count == 0)

    list.addRange(array)
    #expect(list.count == array.count)

    #expect(list.remove("id2@localhost"))
    #expect(list.count == 2)
    #expect(list[0] == "id0@localhost")
    #expect(list[1] == "id1@localhost")

    try list.remove(at: 0)
    #expect(list.count == 1)
    #expect(list[0] == "id1@localhost")

    try list.setItem(at: 0, "id@localhost")
    #expect(list.count == 1)
    #expect(list[0] == "id@localhost")
}

@Test("MessageIdList enumeration")
func messageIdListEnumeration() {
    let list = MessageIdList()
    for i in 0..<5 {
        list.add("\(i)@example.com")
    }

    var index = 0
    for msgid in list {
        #expect(msgid == "\(index)@example.com")
        index += 1
    }
}
