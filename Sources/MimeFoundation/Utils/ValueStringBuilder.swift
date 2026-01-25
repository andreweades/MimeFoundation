//
// ValueStringBuilder.swift
//
// Ported from MimeKit (C#) to Swift.
//

public struct ValueStringBuilder: CustomStringConvertible {
    private var buffer: String

    public init() {
        buffer = ""
    }

    public init(initialCapacity: Int) {
        buffer = ""
        if initialCapacity > 0 {
            buffer.reserveCapacity(initialCapacity)
        }
    }

    public var length: Int {
        buffer.count
    }

    public var description: String {
        buffer
    }

    public subscript(index: Int) -> Character {
        get {
            let strIndex = buffer.index(buffer.startIndex, offsetBy: index)
            return buffer[strIndex]
        }
        set {
            let strIndex = buffer.index(buffer.startIndex, offsetBy: index)
            buffer.replaceSubrange(strIndex...strIndex, with: String(newValue))
        }
    }

    public mutating func clear() {
        buffer.removeAll(keepingCapacity: true)
    }

    public mutating func dispose() {
        buffer.removeAll(keepingCapacity: false)
    }

    public mutating func append(_ character: Character) {
        buffer.append(character)
    }

    public mutating func append(_ string: String?) {
        guard let string = string, !string.isEmpty else {
            return
        }
        buffer.append(string)
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
        // Clamping/Precondition logic
        precondition(index >= 0 && index <= buffer.count, "index out of range")
        let strIndex = buffer.index(buffer.startIndex, offsetBy: index)
        buffer.insert(contentsOf: string, at: strIndex)
    }

    public func asString() -> String {
        buffer
    }

    public mutating func toString() -> String {
        let result = buffer
        clear()
        return result
    }
}
