//
// OptimizedOrdinalIgnoreCaseComparer.swift
//
// Ported from MimeKit (C#) to Swift.
//

public enum OptimizedOrdinalComparerError: Error, Equatable, Sendable {
    case nilString
}

public struct OptimizedOrdinalIgnoreCaseComparer: Sendable {
    public init() {}

    public func equals(_ lhs: String, _ rhs: String) -> Bool {
        let left = Array(lhs.utf16)
        let right = Array(rhs.utf16)

        if left.count != right.count {
            return false
        }

        for index in 0..<left.count {
            if Self.toUpper(left[index]) != Self.toUpper(right[index]) {
                return false
            }
        }

        return true
    }

    public func getHashCode(_ string: String?) throws -> Int {
        guard let string else {
            throw OptimizedOrdinalComparerError.nilString
        }

        return hashCode(string)
    }

    private func hashCode(_ string: String) -> Int {
        let units = Array(string.utf16)
        var hash1: UInt32 = 5381
        var hash2: UInt32 = hash1
        var index = 0

        while index < units.count {
            var value = UInt32(Self.toUpper(units[index]))
            hash1 = ((hash1 << 5) &+ hash1) ^ value
            index += 1

            if index >= units.count {
                break
            }

            value = UInt32(Self.toUpper(units[index]))
            hash2 = ((hash2 << 5) &+ hash2) ^ value
            index += 1
        }

        let result = hash1 &+ (hash2 &* 1_566_083_941)
        return Int(bitPattern: UInt(result))
    }

    private static func toUpper(_ codeUnit: UInt16) -> UInt16 {
        if codeUnit >= 0x61 && codeUnit <= 0x7A {
            return codeUnit - 0x20
        }

        return codeUnit
    }
}
