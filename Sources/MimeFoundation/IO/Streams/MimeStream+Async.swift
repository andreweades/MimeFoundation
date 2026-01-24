//
// MimeStream+Async.swift
//
// Ported from MimeKit (C#) to Swift.
//

import Foundation

public extension MimeStream {
    func readAsync(_ buffer: inout [UInt8], offset: Int, count: Int) async throws -> Int {
        try read(&buffer, offset: offset, count: count)
    }

    func writeAsync(_ buffer: [UInt8], offset: Int, count: Int) async throws {
        try write(buffer, offset: offset, count: count)
    }

    func flushAsync() async throws {
        try flush()
    }

    func copyTo(_ destination: MimeStream, bufferSize: Int = 4096) throws {
        var buffer = [UInt8](repeating: 0, count: bufferSize)
        while true {
            let nread = try read(&buffer, offset: 0, count: buffer.count)
            if nread == 0 {
                break
            }
            try destination.write(buffer, offset: 0, count: nread)
        }
    }

    func copyToAsync(_ destination: MimeStream, bufferSize: Int = 4096) async throws {
        var buffer = [UInt8](repeating: 0, count: bufferSize)
        while true {
            let nread = try await readAsync(&buffer, offset: 0, count: buffer.count)
            if nread == 0 {
                break
            }
            try await destination.writeAsync(buffer, offset: 0, count: nread)
        }
    }
}
