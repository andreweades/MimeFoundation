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
// FilteredStreamTests.swift
//

import Foundation
import Testing
@testable import MimeFoundation

@Suite
struct FilteredStreamTests {
    @Test("FilteredStream closed throws")
    func filteredStreamClosed() throws {
        let source = MemoryStream([], writable: true)
        let filtered = try FilteredStream(source)
        filtered.close()

        var buffer = [UInt8](repeating: 0, count: 8)
        #expect(throws: StreamError.closed) { _ = try filtered.read(&buffer, offset: 0, count: buffer.count) }
        #expect(throws: StreamError.closed) { try filtered.write(buffer, offset: 0, count: buffer.count) }
        #expect(throws: StreamError.closed) { try filtered.add(PassThroughFilter()) }
        #expect(throws: StreamError.closed) { _ = try filtered.contains(PassThroughFilter()) }
        #expect(throws: StreamError.closed) { _ = try filtered.remove(PassThroughFilter()) }
        #expect(throws: StreamError.closed) { try filtered.flush() }
    }

    @Test("FilteredStream capabilities")
    func filteredStreamCapabilities() throws {
        var buffer = [UInt8](repeating: 0, count: 8)

        do {
            let filtered = try FilteredStream(CanReadWriteSeekStream(true, false, false))
            #expect(filtered.canRead)
            #expect(!filtered.canWrite)
            #expect(!filtered.canSeek)
            #expect(!filtered.canTimeout)
            #expect(throws: StreamError.notSupported) { _ = try filtered.read(&buffer, offset: 0, count: buffer.count) }
            #expect(throws: StreamError.notSupported) { try filtered.write(buffer, offset: 0, count: buffer.count) }
            #expect(throws: StreamError.notSupported) { _ = try filtered.seek(0, origin: .end) }
        }

        do {
            let filtered = try FilteredStream(CanReadWriteSeekStream(false, true, false))
            #expect(!filtered.canRead)
            #expect(filtered.canWrite)
            #expect(!filtered.canSeek)
            #expect(!filtered.canTimeout)
            #expect(throws: StreamError.notSupported) { _ = try filtered.read(&buffer, offset: 0, count: buffer.count) }
            #expect(throws: StreamError.notSupported) { try filtered.write(buffer, offset: 0, count: buffer.count) }
            #expect(throws: StreamError.notSupported) { _ = try filtered.seek(0, origin: .end) }
        }

        do {
            let filtered = try FilteredStream(CanReadWriteSeekStream(false, false, true))
            #expect(!filtered.canRead)
            #expect(!filtered.canWrite)
            #expect(!filtered.canSeek)
            #expect(!filtered.canTimeout)
            #expect(throws: StreamError.notSupported) { _ = try filtered.read(&buffer, offset: 0, count: buffer.count) }
            #expect(throws: StreamError.notSupported) { try filtered.write(buffer, offset: 0, count: buffer.count) }
            #expect(throws: StreamError.notSupported) { _ = try filtered.seek(0, origin: .end) }
        }
    }

    @Test("FilteredStream timeouts")
    func filteredStreamTimeouts() throws {
        let filtered = try FilteredStream(TimeoutStream())
        #expect(filtered.readTimeout == 0)
        #expect(filtered.writeTimeout == 0)
        filtered.readTimeout = 25
        filtered.writeTimeout = 50
        #expect(filtered.readTimeout == 25)
        #expect(filtered.writeTimeout == 50)
    }

    @Test("FilteredStream add/remove/contains")
    func filteredStreamFilters() throws {
        let filtered = try FilteredStream(MemoryStream([], writable: true))
        let filter = PassThroughFilter()
        #expect(throws: StreamError.invalidArgument) { try filtered.add(nil) }
        #expect(throws: StreamError.invalidArgument) { _ = try filtered.contains(nil) }
        #expect(throws: StreamError.invalidArgument) { _ = try filtered.remove(nil) }

        try filtered.add(filter)
        #expect(try filtered.contains(filter))
        #expect(try filtered.remove(filter))
        #expect(!(try filtered.contains(filter)))
    }

    @Test("FilteredStream read decodes")
    func filteredStreamRead() throws {
        let original = try TestHelper.loadData(relativePath: "encoders/photo.jpg")
        let encoded = try TestHelper.loadData(relativePath: "encoders/photo.b64")

        let source = MemoryStream(encoded, writable: false)
        let filtered = try FilteredStream(source)
        try filtered.add(DecoderFilter(Base64Decoder()))

        let decoded = MemoryStream([], writable: true)
        try filtered.copyTo(decoded)

        #expect(decoded.toByteArray() == original)
    }

    @Test("FilteredStream read async decodes")
    func filteredStreamReadAsync() async throws {
        let original = try TestHelper.loadData(relativePath: "encoders/photo.jpg")
        let encoded = try TestHelper.loadData(relativePath: "encoders/photo.b64")

        let source = MemoryStream(encoded, writable: false)
        let filtered = try FilteredStream(source)
        try filtered.add(DecoderFilter(Base64Decoder()))

        let decoded = MemoryStream([], writable: true)
        try await filtered.copyToAsync(decoded)

        #expect(decoded.toByteArray() == original)
    }

    @Test("FilteredStream write decodes")
    func filteredStreamWrite() throws {
        let original = try TestHelper.loadData(relativePath: "encoders/photo.jpg")
        let encoded = try TestHelper.loadData(relativePath: "encoders/photo.b64")

        let decoded = MemoryStream([], writable: true)
        let filtered = try FilteredStream(decoded)
        try filtered.add(DecoderFilter(Base64Decoder()))

        try filtered.write(encoded, offset: 0, count: encoded.count)
        try filtered.flush()

        #expect(decoded.toByteArray() == original)
    }

    @Test("FilteredStream write async decodes")
    func filteredStreamWriteAsync() async throws {
        let original = try TestHelper.loadData(relativePath: "encoders/photo.jpg")
        let encoded = try TestHelper.loadData(relativePath: "encoders/photo.b64")

        let decoded = MemoryStream([], writable: true)
        let filtered = try FilteredStream(decoded)
        try filtered.add(DecoderFilter(Base64Decoder()))

        try await filtered.writeAsync(encoded, offset: 0, count: encoded.count)
        try await filtered.flushAsync()

        #expect(decoded.toByteArray() == original)
    }
}
