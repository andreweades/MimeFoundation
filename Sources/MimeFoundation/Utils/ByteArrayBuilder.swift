//
// ByteArrayBuilder.swift
//
// Ported from MimeKit (C#) to Swift.
//

public enum ByteComparison: Sendable {
    case sensitive
    case insensitiveAscii
}

public struct ByteArrayBuilder {
    private var buffer: [UInt8]

    public init(initialCapacity: Int = 0) {
        buffer = []
        if initialCapacity > 0 {
            buffer.reserveCapacity(initialCapacity)
        }
    }

    public var length: Int {
        buffer.count
    }

    public mutating func clear() {
        buffer.removeAll(keepingCapacity: true)
    }

    public mutating func append(_ byte: UInt8) {
        buffer.append(byte)
    }

    public mutating func append(_ bytes: [UInt8], startIndex: Int, count: Int) {
        precondition(startIndex >= 0, "startIndex must be >= 0")
        precondition(count >= 0, "count must be >= 0")
        precondition(startIndex + count <= bytes.count, "startIndex + count exceeds buffer length")
        buffer.reserveCapacity(buffer.count + count)
        buffer.append(contentsOf: bytes[startIndex..<(startIndex + count)])
    }

    public func toArray() -> [UInt8] {
        buffer
    }

    public func equals(_ other: ArraySlice<UInt8>, comparison: ByteComparison = .sensitive) -> Bool {
        if other.count != buffer.count {
            return false
        }

        let otherStart = other.startIndex
        for index in 0..<buffer.count {
            let lhs = buffer[index]
            let rhs = other[otherStart + index]
            if comparison == .insensitiveAscii {
                let lhsNorm = (lhs >= 0x61 && lhs <= 0x7A) ? (lhs - 0x20) : lhs
                let rhsNorm = (rhs >= 0x61 && rhs <= 0x7A) ? (rhs - 0x20) : rhs
                if lhsNorm != rhsNorm {
                    return false
                }
            } else if lhs != rhs {
                return false
            }
        }

        return true
    }

    public mutating func dispose() {
        buffer.removeAll(keepingCapacity: false)
    }
}
