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

//
// HeaderListCollectionTests.swift
//

import Testing
import MimeFoundation

@Test("HeaderListCollection argument exceptions")
func headerListCollectionArgumentExceptions() throws {
    let collection = HeaderListCollection()
    var array: [HeaderList] = Array(repeating: HeaderList(), count: 10)

    #expect(throws: (any Error).self) {
        try collection.copyTo(&array, startingAt: -1)
    }

    #expect(throws: (any Error).self) {
        _ = try collection.group(at: 0)
    }

    #expect(throws: (any Error).self) {
        try collection.replaceGroup(at: 0, with: HeaderList())
    }

    collection.add(HeaderList())

    do {
        try collection.replaceGroup(at: 0, with: HeaderList())
    } catch {
        Issue.record("Unexpected error: \(error)")
    }
}

@Test("HeaderListCollection copyTo")
func headerListCollectionCopyTo() throws {
    let collection = HeaderListCollection()
    var array: [HeaderList] = [HeaderList()]

    collection.add(HeaderList())

    try collection.copyTo(&array, startingAt: 0)

    #expect(array[0] === collection[0])
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
