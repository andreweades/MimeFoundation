//
// HeaderListCollectionTests.swift
//

import Testing
import MimeFoundation

@Test("HeaderListCollection argument exceptions")
func headerListCollectionArgumentExceptions() {
    let collection = HeaderListCollection()
    var array: [HeaderList]? = Array(repeating: HeaderList(), count: 10)

    #expect(throws: (any Error).self) {
        try collection.add(nil)
    }

    #expect(throws: (any Error).self) {
        _ = try collection.contains(nil)
    }

    var nilArray: [HeaderList]? = nil
    #expect(throws: (any Error).self) {
        try collection.copyTo(&nilArray, arrayIndex: 0)
    }

    #expect(throws: (any Error).self) {
        try collection.copyTo(&array, arrayIndex: -1)
    }

    #expect(throws: (any Error).self) {
        _ = try collection.remove(nil)
    }

    #expect(throws: (any Error).self) {
        _ = try collection.group(at: 0)
    }

    #expect(throws: (any Error).self) {
        try collection.replaceGroup(at: 0, with: HeaderList())
    }

    collection.add(HeaderList())

    #expect(throws: (any Error).self) {
        try collection.replaceGroup(at: 0, with: nil)
    }

    do {
        try collection.replaceGroup(at: 0, with: HeaderList())
    } catch {
        Issue.record("Unexpected error: \(error)")
    }
}

@Test("HeaderListCollection copyTo")
func headerListCollectionCopyTo() {
    let collection = HeaderListCollection()
    var array: [HeaderList]? = [HeaderList()]

    collection.add(HeaderList())

    do {
        try collection.copyTo(&array, arrayIndex: 0)
    } catch {
        Issue.record("Unexpected error: \(error)")
        return
    }

    #expect(array?[0] === collection[0])
}

@Test("HeaderListCollection remove")
func headerListCollectionRemove() {
    let collection = HeaderListCollection([HeaderList()])
    collection[0] = collection[0]

    #expect(collection.remove(HeaderList()) == false)
    #expect(collection.remove(collection[0]) == true)
}

@Test("HeaderListCollection enumerator")
func headerListCollectionEnumerator() {
    let collection = HeaderListCollection([HeaderList(), HeaderList(), HeaderList()])

    collection[0].add(.subject, "This is HeaderList #0")
    collection[1].add(.subject, "This is HeaderList #1")
    collection[2].add(.subject, "This is HeaderList #2")

    var index = 0
    for list in collection {
        #expect(list[.subject] == "This is HeaderList #\(index)")
        index += 1
    }

    index = 0
    for list in AnySequence(collection) {
        #expect(list[.subject] == "This is HeaderList #\(index)")
        index += 1
    }
}
