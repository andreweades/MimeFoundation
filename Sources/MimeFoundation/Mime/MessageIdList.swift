//
// MessageIdList.swift
//
// Ported from MimeKit (C#) to Swift.
//

public enum MessageIdListError: Error, Equatable, Sendable {
    case nilId
    case nilArray
    case indexOutOfRange
}

public final class MessageIdList: RandomAccessCollection, MutableCollection, CustomStringConvertible {
    public typealias Element = String
    public typealias Index = Int

    private var items: [String] = []

    public init() {}

    public var isReadOnly: Bool { false }

    public var startIndex: Int { items.startIndex }
    public var endIndex: Int { items.endIndex }

    public func index(after i: Int) -> Int { items.index(after: i) }

    public subscript(position: Int) -> String {
        get { items[position] }
        set {
            let normalized = MessageIdList.normalize(newValue)
            if items[position] == normalized {
                return
            }
            items[position] = normalized
            onChanged()
        }
    }

    public var count: Int { items.count }

    public func add(_ id: String?) throws {
        guard let id else { throw MessageIdListError.nilId }
        items.append(MessageIdList.normalize(id))
        onChanged()
    }

    public func addRange(_ ids: [String]?) throws {
        guard let ids else { throw MessageIdListError.nilArray }
        items.append(contentsOf: ids.map { MessageIdList.normalize($0) })
        onChanged()
    }

    public func contains(_ id: String?) throws -> Bool {
        guard let id else { throw MessageIdListError.nilId }
        return items.contains(id)
    }

    public func copyTo(_ array: inout [String]?, at index: Int) throws {
        guard array != nil else { throw MessageIdListError.nilArray }
        guard index >= 0 && index <= (array?.count ?? 0) else { throw MessageIdListError.indexOutOfRange }
        array!.insert(contentsOf: items, at: index)
    }

    public func indexOf(_ id: String?) throws -> Int {
        guard let id else { throw MessageIdListError.nilId }
        return items.firstIndex(of: id) ?? -1
    }

    public func insert(_ id: String?, at index: Int) throws {
        guard let id else { throw MessageIdListError.nilId }
        guard index >= 0 && index <= items.count else { throw MessageIdListError.indexOutOfRange }
        items.insert(MessageIdList.normalize(id), at: index)
        onChanged()
    }

    public func setItem(at index: Int, _ id: String?) throws {
        guard let id else { throw MessageIdListError.nilId }
        guard index >= 0 && index < items.count else { throw MessageIdListError.indexOutOfRange }
        let normalized = MessageIdList.normalize(id)
        if items[index] == normalized {
            return
        }
        items[index] = normalized
        onChanged()
    }

    @discardableResult
    public func remove(_ id: String?) throws -> Bool {
        guard let id else { throw MessageIdListError.nilId }
        guard let index = items.firstIndex(of: id) else { return false }
        items.remove(at: index)
        onChanged()
        return true
    }

    public func remove(at index: Int) throws {
        guard index >= 0 && index < items.count else { throw MessageIdListError.indexOutOfRange }
        items.remove(at: index)
        onChanged()
    }

    public func clear() {
        items.removeAll(keepingCapacity: true)
        onChanged()
    }

    public func copy() -> MessageIdList {
        let copied = MessageIdList()
        copied.items = items
        return copied
    }

    @available(*, deprecated, renamed: "copy()")
    public func clone() -> MessageIdList {
        copy()
    }

    public func toString() -> String {
        var builder = ""
        for (index, item) in items.enumerated() {
            if index > 0 {
                builder.append(" ")
            }
            builder.append("<")
            builder.append(item)
            builder.append(">")
        }
        return builder
    }

    public var description: String {
        toString()
    }

    internal var changed: ((MessageIdList) -> Void)?

    private func onChanged() {
        changed?(self)
    }

    private static func normalize(_ value: String) -> String {
        guard value.count >= 2, value.first == "<", value.last == ">" else {
            return value
        }
        let start = value.index(after: value.startIndex)
        let end = value.index(before: value.endIndex)
        return String(value[start..<end])
    }
}
