//
// ValueStringBuilder.swift
//
// Ported from MimeKit (C#) to Swift.
//

public struct ValueStringBuilder: CustomStringConvertible {
    private var buffer: [UInt16]

    public init() {
        buffer = []
    }

    public init(initialCapacity: Int) {
        buffer = []
        if initialCapacity > 0 {
            buffer.reserveCapacity(initialCapacity)
        }
    }

    public var length: Int {
        buffer.count
    }

    public var description: String {
        asString()
    }

    public subscript(index: Int) -> Character {
        get {
            precondition(index >= 0 && index < buffer.count, "index out of range")
            let scalar = UnicodeScalar(buffer[index]) ?? UnicodeScalar(0xFFFD)!
            return Character(scalar)
        }
        set {
            precondition(index >= 0 && index < buffer.count, "index out of range")
            let units = Array(String(newValue).utf16)
            precondition(units.count == 1, "ValueStringBuilder only supports single UTF-16 code unit assignment")
            buffer[index] = units[0]
        }
    }

    public mutating func clear() {
        buffer.removeAll(keepingCapacity: true)
    }

    public mutating func dispose() {
        buffer.removeAll(keepingCapacity: false)
    }

    public mutating func append(_ character: Character) {
        let units = Array(String(character).utf16)
        if !units.isEmpty {
            buffer.append(contentsOf: units)
        }
    }

    public mutating func append(_ string: String?) {
        guard let string = string, !string.isEmpty else {
            return
        }
        buffer.append(contentsOf: string.utf16)
    }

    public mutating func appendJoin(separator: Character, values: [String]) {
        for (index, value) in values.enumerated() {
            if index > 0 {
                append(separator)
            }
            append(value)
        }
    }

    public mutating func insert(_ string: String?, at index: Int) {
        guard let string = string, !string.isEmpty else {
            return
        }
        precondition(index >= 0 && index <= buffer.count, "index out of range")
        let units = Array(string.utf16)
        buffer.insert(contentsOf: units, at: index)
    }

    public func asString() -> String {
        if buffer.isEmpty {
            return ""
        }
        return String(decoding: buffer, as: UTF16.self)
    }

    public mutating func toString() -> String {
        let result = asString()
        clear()
        return result
    }
}
