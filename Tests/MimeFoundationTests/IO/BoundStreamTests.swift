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
// BoundStreamTests.swift
//

import Testing
@testable import MimeFoundation

@Test("BoundStream can read/write/seek")
func boundStreamCapabilities() throws {
    var buffer = [UInt8](repeating: 0, count: 16)

    do {
        let base = CanReadWriteSeekStream(true, false, false)
        let bounded = try BoundStream(base, startBoundary: 0, endBoundary: -1, leaveOpen: false)
        #expect(bounded.canRead)
        #expect(!bounded.canWrite)
        #expect(!bounded.canSeek)
        #expect(!bounded.canTimeout)
        #expect(throws: StreamError.notSupported) { _ = try bounded.read(&buffer, offset: 0, count: buffer.count) }
        #expect(throws: StreamError.notSupported) { try bounded.write(buffer, offset: 0, count: buffer.count) }
        #expect(throws: StreamError.notSupported) { _ = try bounded.seek(0, origin: .end) }
    }

    do {
        let base = CanReadWriteSeekStream(false, true, false)
        let bounded = try BoundStream(base, startBoundary: 0, endBoundary: -1, leaveOpen: false)
        #expect(!bounded.canRead)
        #expect(bounded.canWrite)
        #expect(!bounded.canSeek)
        #expect(throws: StreamError.notSupported) { _ = try bounded.read(&buffer, offset: 0, count: buffer.count) }
        #expect(throws: StreamError.notSupported) { try bounded.write(buffer, offset: 0, count: buffer.count) }
        #expect(throws: StreamError.notSupported) { _ = try bounded.seek(0, origin: .end) }
    }

    do {
        let base = CanReadWriteSeekStream(false, false, true)
        let bounded = try BoundStream(base, startBoundary: 0, endBoundary: -1, leaveOpen: false)
        #expect(!bounded.canRead)
        #expect(!bounded.canWrite)
        #expect(bounded.canSeek)
        #expect(throws: StreamError.notSupported) { _ = try bounded.read(&buffer, offset: 0, count: buffer.count) }
        #expect(throws: StreamError.notSupported) { try bounded.write(buffer, offset: 0, count: buffer.count) }
        #expect(throws: StreamError.notSupported) { _ = try bounded.seek(0, origin: .end) }
    }
}

@Test("BoundStream get/set timeouts")
func boundStreamTimeouts() throws {
    let base = TimeoutStream()
    let bounded = try BoundStream(base, startBoundary: 0, endBoundary: -1, leaveOpen: false)
    #expect(bounded.readTimeout == 0)
    #expect(bounded.writeTimeout == 0)
    bounded.readTimeout = 10
    bounded.writeTimeout = 100
    #expect(bounded.readTimeout == 10)
    #expect(bounded.writeTimeout == 100)
}

@Test("BoundStream seek/read")
func boundStreamSeekRead() throws {
    let bytes = Array("This is some text...".utf8)
    let memory = MemoryStream(bytes, writable: true)
    let bounded = try BoundStream(memory, startBoundary: 5, endBoundary: -1, leaveOpen: true)

    var buffer = [UInt8](repeating: 0, count: 64)
    var nread = try bounded.read(&buffer, offset: 0, count: buffer.count)
    let text = String(decoding: buffer[0..<nread], as: UTF8.self)
    #expect(text == "is some text...")

    _ = try bounded.seek(-nread, origin: .end)
    nread = try bounded.read(&buffer, offset: 0, count: buffer.count)
    let text2 = String(decoding: buffer[0..<nread], as: UTF8.self)
    #expect(text2 == "is some text...")
}

@Test("BoundStream setLength")
func boundStreamSetLength() throws {
    let bytes = Array("This is some text...".utf8)
    let memory = MemoryStream(bytes, writable: true)
    let bounded = try BoundStream(memory, startBoundary: 0, endBoundary: -1, leaveOpen: true)
    try bounded.setLength(500)
    #expect(bounded.length == 500)
    #expect(memory.length == 500)

    let boundedFixed = try BoundStream(memory, startBoundary: 0, endBoundary: bytes.count, leaveOpen: true)
    try boundedFixed.setLength(5)
    #expect(boundedFixed.length == 5)
    #expect(memory.length >= bytes.count)
}
