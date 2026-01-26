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
// CanReadWriteSeekStream.swift
//

import MimeFoundation

final class CanReadWriteSeekStream: MimeStream {
    let canRead: Bool
    let canWrite: Bool
    let canSeek: Bool
    let canTimeout: Bool

    var position: Int {
        get { 15 }
        set { _ = try? seek(newValue, origin: .begin) }
    }

    var length: Int { 17 }

    var readTimeout: Int {
        get { 0 }
        set { }
    }

    var writeTimeout: Int {
        get { 0 }
        set { }
    }

    init(_ canRead: Bool, _ canWrite: Bool, _ canSeek: Bool, _ canTimeout: Bool = false) {
        self.canRead = canRead
        self.canWrite = canWrite
        self.canSeek = canSeek
        self.canTimeout = canTimeout
    }

    func read(_ buffer: inout [UInt8], offset: Int, count: Int) throws -> Int {
        throw StreamError.notSupported
    }

    func write(_ buffer: [UInt8], offset: Int, count: Int) throws {
        throw StreamError.notSupported
    }

    func seek(_ offset: Int, origin: SeekOrigin) throws -> Int {
        throw StreamError.notSupported
    }

    func flush() throws {}

    func close() {}
}
