//
// FilteredStream.swift
//
// Ported from MimeKit (C#) to Swift.
//

import Foundation

public final class FilteredStream {
    private var filters: [MimeFilter] = []
    private var buffer = Data()

    public init() {}

    public func add(_ filter: MimeFilter) {
        filters.append(filter)
    }

    public func write(_ data: [UInt8], startIndex: Int, length: Int) {
        let end = startIndex + length
        var chunk = Array(data[startIndex..<end])

        for filter in filters {
            chunk = filter.filter(chunk, startIndex: 0, length: chunk.count, flush: false)
        }

        buffer.append(contentsOf: chunk)
    }

    public func flush() {
        var chunk: [UInt8] = []

        for filter in filters {
            chunk = filter.filter(chunk, startIndex: 0, length: chunk.count, flush: true)
        }

        buffer.append(contentsOf: chunk)
    }

    public func reset() {
        buffer.removeAll(keepingCapacity: true)
        for filter in filters {
            filter.reset()
        }
    }

    public func toByteArray() -> [UInt8] {
        Array(buffer)
    }
}
