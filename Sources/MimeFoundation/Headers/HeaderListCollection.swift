//
// HeaderListCollection.swift
//
// Ported from MimeKit (C#) to Swift.
//

import Foundation

public enum HeaderListCollectionError: Error, Sendable {
    case nilGroup
    case nilArray
    case indexOutOfRange
    case insufficientCapacity
}

public final class HeaderListCollection: RandomAccessCollection, MutableCollection, ExpressibleByArrayLiteral {
    public typealias Element = HeaderList
    public typealias Index = Int

    private var groups: [HeaderList]

    internal var changed: (() -> Void)?

    public init() {
        self.groups = []
    }

    public init(_ groups: [HeaderList]) {
        self.groups = []
        for group in groups {
            attach(group)
            self.groups.append(group)
        }
    }

    public convenience init(arrayLiteral elements: HeaderList...) {
        self.init(elements)
    }

    public var startIndex: Int { groups.startIndex }
    public var endIndex: Int { groups.endIndex }

    public func index(after i: Int) -> Int {
        groups.index(after: i)
    }

    public subscript(position: Int) -> HeaderList {
        get {
            precondition(position >= 0 && position < groups.count, "Index out of range")
            return groups[position]
        }
        set {
            precondition(position >= 0 && position < groups.count, "Index out of range")
            if groups[position] === newValue {
                return
            }
            detach(groups[position])
            attach(newValue)
            groups[position] = newValue
            onChanged()
        }
    }

    public var count: Int { groups.count }

    public var isReadOnly: Bool { false }

    public func group(at index: Int) throws -> HeaderList {
        guard index >= 0 && index < groups.count else {
            throw HeaderListCollectionError.indexOutOfRange
        }
        return groups[index]
    }

    public func replaceGroup(at index: Int, with group: HeaderList?) throws {
        guard index >= 0 && index < groups.count else {
            throw HeaderListCollectionError.indexOutOfRange
        }
        guard let group else {
            throw HeaderListCollectionError.nilGroup
        }
        if groups[index] === group {
            return
        }
        detach(groups[index])
        attach(group)
        groups[index] = group
        onChanged()
    }

    public func add(_ group: HeaderList) {
        attach(group)
        groups.append(group)
        onChanged()
    }

    public func add(_ group: HeaderList?) throws {
        guard let group else {
            throw HeaderListCollectionError.nilGroup
        }
        add(group)
    }

    public func clear() {
        for group in groups {
            detach(group)
        }
        groups.removeAll(keepingCapacity: true)
        onChanged()
    }

    public func contains(_ group: HeaderList) -> Bool {
        groups.contains { $0 === group }
    }

    public func contains(_ group: HeaderList?) throws -> Bool {
        guard let group else {
            throw HeaderListCollectionError.nilGroup
        }
        return contains(group)
    }

    public func copyTo(_ array: inout [HeaderList]?, arrayIndex: Int) throws {
        guard var target = array else {
            throw HeaderListCollectionError.nilArray
        }
        guard arrayIndex >= 0 else {
            throw HeaderListCollectionError.indexOutOfRange
        }
        guard arrayIndex + groups.count <= target.count else {
            throw HeaderListCollectionError.insufficientCapacity
        }
        for (offset, group) in groups.enumerated() {
            target[arrayIndex + offset] = group
        }
        array = target
    }

    public func remove(_ group: HeaderList) -> Bool {
        guard let index = groups.firstIndex(where: { $0 === group }) else {
            return false
        }
        detach(groups[index])
        groups.remove(at: index)
        onChanged()
        return true
    }

    public func remove(_ group: HeaderList?) throws -> Bool {
        guard let group else {
            throw HeaderListCollectionError.nilGroup
        }
        return remove(group)
    }

    private func attach(_ group: HeaderList) {
        group.changed = { [weak self] _, _ in
            self?.onChanged()
        }
    }

    private func detach(_ group: HeaderList) {
        group.changed = nil
    }

    private func onChanged() {
        changed?()
    }
}
