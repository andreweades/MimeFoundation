//
// PackedByteArray.swift
//
// Ported from MimeKit (C#) to Swift.
//

public enum PackedByteArrayError: Error, Equatable {
    case nilBuffer
    case indexOutOfRange
}

public final class PackedByteArray {
    private static let initialBufferSize = 64

    private var buffer: [UInt16]
    private var length: Int
    private var cursor: Int

    public init() {
        buffer = Array(repeating: 0, count: Self.initialBufferSize)
        length = 0
        cursor = -1
    }

    public var count: Int {
        length
    }

    public func clear() {
        cursor = -1
        length = 0
    }

    public func add(_ item: UInt8) {
        if cursor < 0 || item != UInt8(buffer[cursor] & 0x00FF) || (buffer[cursor] & 0xFF00) == 0xFF00 {
            ensureBufferSize(cursor + 2)
            cursor += 1
            buffer[cursor] = UInt16(1 << 8) | UInt16(item)
        } else {
            buffer[cursor] = buffer[cursor] & 0x00FF | (buffer[cursor] & 0xFF00) + 0x0100
        }

        length += 1
    }

    public func copy(to array: inout [UInt8], startIndex: Int) throws {
        if startIndex < 0 || startIndex + length > array.count {
            throw PackedByteArrayError.indexOutOfRange
        }

        var index = startIndex
        for i in 0...cursor {
            let count = Int((buffer[i] >> 8) & 0x00FF)
            let value = UInt8(buffer[i] & 0x00FF)

            if count > 0 {
                for _ in 0..<count {
                    array[index] = value
                    index += 1
                }
            }
        }
    }

    public func copy(to array: [UInt8]?, startIndex: Int) throws -> [UInt8] {
        guard var array = array else {
            throw PackedByteArrayError.nilBuffer
        }

        try copy(to: &array, startIndex: startIndex)
        return array
    }

    private func ensureBufferSize(_ size: Int) {
        if buffer.count > size {
            return
        }

        let ideal = (size + 63) & ~63
        var resized = Array(repeating: UInt16(0), count: ideal)
        if cursor >= 0 {
            resized.replaceSubrange(0...(cursor), with: buffer[0...(cursor)])
        }
        buffer = resized
    }
}
