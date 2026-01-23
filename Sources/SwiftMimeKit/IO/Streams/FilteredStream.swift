//
// FilteredStream.swift
//
// Ported from MimeKit (C#) to Swift.
//

import Foundation

public final class FilteredStream: MimeStream {
    private enum Operation {
        case read
        case write
    }

    private let source: MimeStream
    private var filters: [MimeFilter] = []
    private var lastOp: Operation = .write
    private var filteredBuffer: [UInt8] = []
    private var filteredIndex: Int = 0
    private var filteredLength: Int = 0
    private var readBuffer: [UInt8] = Array(repeating: 0, count: 4096)
    private var flushed = false
    private var closed = false

    public init(_ source: MimeStream?) throws {
        guard let source else {
            throw StreamError.invalidArgument
        }
        self.source = source
    }

    public var canRead: Bool { source.canRead }
    public var canWrite: Bool { source.canWrite }
    public var canSeek: Bool { false }
    public var canTimeout: Bool { source.canTimeout }

    public var readTimeout: Int {
        get {
            guard canTimeout else { return 0 }
            return source.readTimeout
        }
        set {
            guard canTimeout else { return }
            source.readTimeout = newValue
        }
    }

    public var writeTimeout: Int {
        get {
            guard canTimeout else { return 0 }
            return source.writeTimeout
        }
        set {
            guard canTimeout else { return }
            source.writeTimeout = newValue
        }
    }

    public var position: Int {
        get { 0 }
        set { }
    }

    public var length: Int { 0 }

    public func add(_ filter: MimeFilter?) throws {
        try ensureOpen()
        guard let filter else {
            throw StreamError.invalidArgument
        }
        filters.append(filter)
    }

    public func remove(_ filter: MimeFilter?) throws -> Bool {
        try ensureOpen()
        guard let filter else {
            throw StreamError.invalidArgument
        }
        if let index = filters.firstIndex(where: { $0 === filter }) {
            filters.remove(at: index)
            return true
        }
        return false
    }

    public func contains(_ filter: MimeFilter?) throws -> Bool {
        try ensureOpen()
        guard let filter else {
            throw StreamError.invalidArgument
        }
        return filters.contains { $0 === filter }
    }

    public func read(_ buffer: inout [UInt8], offset: Int, count: Int) throws -> Int {
        try ensureOpen()
        guard canRead else {
            throw StreamError.notSupported
        }
        guard offset >= 0, count >= 0, offset + count <= buffer.count else {
            print("FilteredStream.write invalidArgument offset=\(offset) count=\(count) buffer.count=\(buffer.count)")
            throw StreamError.invalidArgument
        }
        if count == 0 {
            return 0
        }

        if lastOp != .read {
            resetFilters()
            filteredBuffer = []
            filteredIndex = 0
            filteredLength = 0
            flushed = false
            lastOp = .read
        }

        var written = 0
        while written < count {
            if filteredIndex < filteredLength {
                let available = min(count - written, filteredLength - filteredIndex)
                buffer.replaceSubrange((offset + written)..<(offset + written + available),
                                       with: filteredBuffer[filteredIndex..<(filteredIndex + available)])
                filteredIndex += available
                written += available
                continue
            }

            if flushed {
                break
            }

            let nread = try source.read(&readBuffer, offset: 0, count: readBuffer.count)
            if nread == 0 {
                applyFilters(input: [], startIndex: 0, length: 0, flush: true)
                flushed = true
            } else {
                applyFilters(input: readBuffer, startIndex: 0, length: nread, flush: false)
            }

            if filteredLength == 0 && flushed {
                break
            }
        }

        return written
    }

    public func write(_ buffer: [UInt8], offset: Int, count: Int) throws {
        try ensureOpen()
        guard canWrite else {
            throw StreamError.notSupported
        }
        guard offset >= 0, count >= 0, offset + count <= buffer.count else {
            print("FilteredStream.write invalidArgument offset=\(offset) count=\(count) buffer.count=\(buffer.count)")
            throw StreamError.invalidArgument
        }
        if count == 0 {
            return
        }

        if lastOp != .write {
            resetFilters()
            lastOp = .write
        }

        var outputBuffer = buffer
        var outputIndex = offset
        var outputLength = count

        for filter in filters {
            outputBuffer = filter.filter(outputBuffer, startIndex: outputIndex, length: outputLength, outputIndex: &outputIndex, outputLength: &outputLength)
        }

        if outputLength > 0 {
            try source.write(outputBuffer, offset: outputIndex, count: outputLength)
        }
    }

    public func seek(_ offset: Int, origin: SeekOrigin) throws -> Int {
        throw StreamError.notSupported
    }

    public func flush() throws {
        try ensureOpen()
        if lastOp == .write {
            var outputBuffer: [UInt8] = []
            var outputIndex = 0
            var outputLength = 0
            var startIndex = 0
            var length = 0

            for filter in filters {
                if outputBuffer.isEmpty {
                    outputBuffer = filter.flush([], startIndex: startIndex, length: length, outputIndex: &outputIndex, outputLength: &outputLength)
                } else {
                    outputBuffer = filter.flush(outputBuffer, startIndex: outputIndex, length: outputLength, outputIndex: &outputIndex, outputLength: &outputLength)
                }
                startIndex = outputIndex
                length = outputLength
            }

            if outputLength > 0 {
                try source.write(outputBuffer, offset: outputIndex, count: outputLength)
            }
        }
        try source.flush()
    }

    public func close() {
        closed = true
    }

    private func applyFilters(input: [UInt8], startIndex: Int, length: Int, flush: Bool) {
        var buffer = input
        var outIndex = startIndex
        var outLength = length

        for filter in filters {
            if flush {
                buffer = filter.flush(buffer, startIndex: outIndex, length: outLength, outputIndex: &outIndex, outputLength: &outLength)
            } else {
                buffer = filter.filter(buffer, startIndex: outIndex, length: outLength, outputIndex: &outIndex, outputLength: &outLength)
            }
        }

        filteredBuffer = buffer
        filteredIndex = outIndex
        filteredLength = outIndex + outLength
    }

    private func resetFilters() {
        for filter in filters {
            filter.reset()
        }
    }

    private func ensureOpen() throws {
        if closed {
            throw StreamError.closed
        }
    }
}
