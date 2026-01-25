//
// HeaderList.swift
//
// Ported from MimeKit (C#) to Swift.
//

import Foundation

public enum HeaderListChangedAction {
    case added
    case removed
    case changed
    case cleared
}

public final class HeaderList: RandomAccessCollection, MutableCollection, CustomStringConvertible {
    public typealias Element = Header
    public typealias Index = Int

    private var headers: [Header]
    public var options: ParserOptions

    internal var changed: ((HeaderListChangedAction, Header?) -> Void)?

    public init(_ options: ParserOptions = .default) {
        self.headers = []
        self.options = options
    }

    public var startIndex: Int { headers.startIndex }
    public var endIndex: Int { headers.endIndex }

    public func index(after i: Int) -> Int { headers.index(after: i) }

    public subscript(position: Int) -> Header {
        get { headers[position] }
        set {
            headers[position].changed = nil
            attach(newValue)
            headers[position] = newValue
            onChanged(.changed, header: newValue)
        }
    }

    public subscript(_ id: HeaderId) -> String? {
        get {
            headers.first(where: { $0.id == id })?.value
        }
        set {
            guard id != .unknown else {
                return
            }
            if let value = newValue {
                if let index = headers.firstIndex(where: { $0.id == id }) {
                    headers[index].value = value
                } else {
                    add(Header(id, value: value))
                }
            } else {
                removeAll(id)
            }
        }
    }

    public subscript(field: String) -> String? {
        get {
            let key = field.lowercased()
            return headers.first(where: { $0.field.lowercased() == key })?.value
        }
        set {
            if let value = newValue {
                if let index = headers.firstIndex(where: { $0.field.caseInsensitiveCompare(field) == .orderedSame }) {
                    headers[index].value = value
                } else {
                    add(Header(field: field, value: value))
                }
            } else {
                removeAll(field: field)
            }
        }
    }

    public var count: Int { headers.count }

    public func add(_ header: Header) {
        attach(header)
        headers.append(header)
        onChanged(.added, header: header)
    }

    public func add(_ id: HeaderId, _ value: String, encoding: String.Encoding = .utf8) {
        add(Header(id, value: value, encoding: encoding))
    }

    public func insert(_ header: Header, at index: Int) {
        guard index >= 0 && index <= headers.count else {
            return
        }
        attach(header)
        headers.insert(header, at: index)
        onChanged(.added, header: header)
    }

    public func remove(at index: Int) {
        guard index >= 0 && index < headers.count else {
            return
        }
        let removed = headers.remove(at: index)
        removed.changed = nil
        onChanged(.removed, header: removed)
    }

    public func removeAll(_ id: HeaderId) {
        guard id != .unknown else {
            return
        }
        var removed: [Header] = []
        headers.removeAll { header in
            if header.id == id {
                removed.append(header)
                return true
            }
            return false
        }
        for header in removed {
            header.changed = nil
            onChanged(.removed, header: header)
        }
    }

    public func removeAll(field: String) {
        let key = field.lowercased()
        var removed: [Header] = []
        headers.removeAll { header in
            if header.field.lowercased() == key {
                removed.append(header)
                return true
            }
            return false
        }
        for header in removed {
            header.changed = nil
            onChanged(.removed, header: header)
        }
    }

    public func clear() {
        for header in headers {
            header.changed = nil
        }
        headers.removeAll(keepingCapacity: true)
        onChanged(.cleared, header: nil)
    }

    public func contains(_ id: HeaderId) -> Bool {
        headers.contains(where: { $0.id == id })
    }

    public func contains(field: String) -> Bool {
        headers.contains(where: { $0.field.caseInsensitiveCompare(field) == .orderedSame })
    }

    public func tryGetHeader(_ id: HeaderId) -> Header? {
        headers.first(where: { $0.id == id })
    }

    public func toString(_ options: FormatOptions = .default, encode: Bool = true) -> String {
        var builder = ""
        for (index, header) in headers.enumerated() {
            if index > 0 {
                builder.append(options.newLine)
            }
            builder.append(header.toString(options, encode: encode))
        }
        if options.ensureNewLine && !builder.isEmpty {
            builder.append(options.newLine)
        }
        return builder
    }

    public var description: String {
        toString(.default, encode: false)
    }

    private func attach(_ header: Header) {
        header.changed = { [weak self] header in
            self?.onChanged(.changed, header: header)
        }
    }

    private func onChanged(_ action: HeaderListChangedAction, header: Header?) {
        changed?(action, header)
    }
}
