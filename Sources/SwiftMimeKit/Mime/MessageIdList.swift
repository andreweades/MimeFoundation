//
// MessageIdList.swift
//
// Ported from MimeKit (C#) to Swift.
//

public enum MessageIdListError: Error, Equatable {
    case nilId
    case nilArray
    case indexOutOfRange
}

public final class MessageIdList: RandomAccessCollection, MutableCollection {
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
        set { items[position] = newValue }
    }

    public var count: Int { items.count }

    public func add(_ id: String?) throws {
        guard let id else { throw MessageIdListError.nilId }
        items.append(id)
    }

    public func addRange(_ ids: [String]?) throws {
        guard let ids else { throw MessageIdListError.nilArray }
        items.append(contentsOf: ids)
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
        items.insert(id, at: index)
    }

    public func setItem(at index: Int, _ id: String?) throws {
        guard let id else { throw MessageIdListError.nilId }
        guard index >= 0 && index < items.count else { throw MessageIdListError.indexOutOfRange }
        items[index] = id
    }

    @discardableResult
    public func remove(_ id: String?) throws -> Bool {
        guard let id else { throw MessageIdListError.nilId }
        guard let index = items.firstIndex(of: id) else { return false }
        items.remove(at: index)
        return true
    }

    public func remove(at index: Int) throws {
        guard index >= 0 && index < items.count else { throw MessageIdListError.indexOutOfRange }
        items.remove(at: index)
    }

    public func clear() {
        items.removeAll(keepingCapacity: true)
    }

    public func clone() -> MessageIdList {
        let clone = MessageIdList()
        clone.items = items
        return clone
    }
}
