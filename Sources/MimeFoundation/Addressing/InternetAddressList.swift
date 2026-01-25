//
// InternetAddressList.swift
//
// Ported from MimeKit (C#) to Swift.
//

import Foundation

public final class InternetAddressList: RandomAccessCollection, MutableCollection, Equatable, Comparable, CustomStringConvertible {
    public typealias Element = InternetAddress
    public typealias Index = Int

    private var list: [InternetAddress]

    public init() {
        self.list = []
    }

    public init(_ addresses: [InternetAddress]) {
        self.list = []
        self.list.reserveCapacity(addresses.count)
        for address in addresses {
            address.changed = { [weak self] _ in
                self?.onChanged()
            }
            list.append(address)
        }
    }

    public convenience init<S: Sequence>(_ addresses: S) where S.Element == InternetAddress {
        self.init(Array(addresses))
    }

    public var startIndex: Int { list.startIndex }
    public var endIndex: Int { list.endIndex }

    public func index(after i: Int) -> Int { list.index(after: i) }

    public subscript(position: Int) -> InternetAddress {
        get { list[position] }
        set {
            list[position].changed = nil
            newValue.changed = { [weak self] _ in
                self?.onChanged()
            }
            list[position] = newValue
            onChanged()
        }
    }

    public var count: Int { list.count }

    public var isReadOnly: Bool { false }

    public func indexOf(_ address: InternetAddress) -> Int {
        list.firstIndex(where: { $0 == address }) ?? -1
    }

    public func insert(_ address: InternetAddress, at index: Int) {
        guard index >= 0 && index <= list.count else {
            return
        }
        address.changed = { [weak self] _ in
            self?.onChanged()
        }
        list.insert(address, at: index)
        onChanged()
    }

    public func remove(at index: Int) {
        guard index >= 0 && index < list.count else {
            return
        }
        list[index].changed = nil
        list.remove(at: index)
        onChanged()
    }

    public func add(_ address: InternetAddress) {
        address.changed = { [weak self] _ in
            self?.onChanged()
        }
        list.append(address)
        onChanged()
    }

    public func addRange(_ addresses: [InternetAddress]) {
        for address in addresses {
            add(address)
        }
    }

    public func contains(_ address: InternetAddress) -> Bool {
        list.contains(where: { $0 == address })
    }

    @discardableResult
    public func remove(_ address: InternetAddress) -> Bool {
        guard let index = list.firstIndex(where: { $0 == address }) else {
            return false
        }
        remove(at: index)
        return true
    }

    public func copyTo(_ array: inout [InternetAddress], at index: Int) {
        guard index >= 0 && index <= array.count else {
            return
        }
        array.insert(contentsOf: list, at: index)
    }

    public func clear() {
        for address in list {
            address.changed = nil
        }
        list.removeAll(keepingCapacity: true)
        onChanged()
    }

    public var mailboxes: [MailboxAddress] {
        var result: [MailboxAddress] = []
        for address in list {
            if let group = address as? GroupAddress {
                result.append(contentsOf: group.members.mailboxes)
            } else if let mailbox = address as? MailboxAddress {
                result.append(mailbox)
            }
        }
        return result
    }

    internal func encode(_ options: FormatOptions, builder: inout String, firstToken: Bool, lineLength: inout Int) {
        for (idx, address) in list.enumerated() {
            if idx > 0 {
                builder.append(", ")
                lineLength += 2
            }
            var first = firstToken && idx == 0
            address.encode(options, builder: &builder, firstToken: &first, lineLength: &lineLength)
        }
    }

    public func toString(_ options: FormatOptions, encode: Bool) -> String {
        if encode {
            var builder = ""
            var lineLength = 0
            let firstToken = true
            self.encode(options, builder: &builder, firstToken: firstToken, lineLength: &lineLength)
            return builder
        }

        var builder = ""
        for (idx, address) in list.enumerated() {
            if idx > 0 {
                builder.append(", ")
            }
            builder.append(address.formatted(with: options, encoded: false))
        }
        return builder
    }

    public var description: String {
        toString(FormatOptions.default, encode: false)
    }

    public static func == (lhs: InternetAddressList, rhs: InternetAddressList) -> Bool {
        if lhs.list.count != rhs.list.count {
            return false
        }
        for (a, b) in zip(lhs.list, rhs.list) {
            if a != b {
                return false
            }
        }
        return true
    }

    public static func < (lhs: InternetAddressList, rhs: InternetAddressList) -> Bool {
        let minCount = Swift.min(lhs.list.count, rhs.list.count)
        for i in 0..<minCount {
            if lhs.list[i] == rhs.list[i] {
                continue
            }
            return lhs.list[i] < rhs.list[i]
        }
        return lhs.list.count < rhs.list.count
    }

    internal var changed: ((InternetAddressList) -> Void)?

    private func onChanged() {
        changed?(self)
    }

    // MARK: Parsing

    internal static func tryParse(_ flags: AddressParserFlags, _ options: ParserOptions, _ text: [UInt8], index: inout Int, endIndex: Int, isGroup: Bool, groupDepth: Int, addresses: inout InternetAddressList?) -> Bool {
        let throwOnError = flags.contains(.throwOnError)
        var list: [InternetAddress] = []
        addresses = nil

        do {
            if !(try ParseUtils.skipCommentsAndWhiteSpace(text, index: &index, endIndex: endIndex, throwOnError: throwOnError)) {
                return false
            }
        } catch {
            return false
        }

        if index == endIndex {
            return false
        }

        while index < endIndex {
            if isGroup && text[index] == 0x3B {
                break
            }

            var address: InternetAddress? = nil
            do {
                if !(try InternetAddress.tryParse(flags, options, text, index: &index, endIndex: endIndex, groupDepth: groupDepth, address: &address)) {
                    if !flags.contains(.internalFlag) {
                        return false
                    }
                    while index < endIndex && text[index] != 0x2C && (!isGroup || text[index] != 0x3B) {
                        index += 1
                    }
                } else if let address = address {
                    list.append(address)
                }
            } catch {
                return false
            }

            var skippedComma = false
            repeat {
                do {
                    if !(try ParseUtils.skipCommentsAndWhiteSpace(text, index: &index, endIndex: endIndex, throwOnError: throwOnError)) {
                        return false
                    }
                } catch {
                    return false
                }

                if index >= endIndex {
                    break
                }

                if isGroup && text[index] == 0x3B {
                    break
                }

                if text[index] != 0x2C {
                    if skippedComma {
                        break
                    }
                    if options.addressParserComplianceMode == .strict {
                        return false
                    }
                    break
                }

                skippedComma = true
                index += 1
            } while true
        }

        addresses = InternetAddressList(list)
        return true
    }

    // MARK: - Swift-Idiomatic Parsing Initializers

    /// Throwing initializer - throws ParseException on failure.
    /// Use `try?` for optional behavior: `let list = try? InternetAddressList(parsing: text)`
    public convenience init(parsing text: String, options: ParserOptions = .default) throws {
        let buffer = CharsetUtils.getBytes(text, encoding: .utf8)
        try self.init(parsing: buffer, options: options)
    }

    /// Throwing initializer - throws ParseException on failure.
    /// Use `try?` for optional behavior: `let list = try? InternetAddressList(parsing: buffer)`
    public convenience init(parsing buffer: [UInt8], options: ParserOptions = .default) throws {
        var result: InternetAddressList? = nil
        var index = 0
        if !Self.tryParse(.tryParse, options, buffer, index: &index, endIndex: buffer.count,
                          isGroup: false, groupDepth: 0, addresses: &result) {
            throw ParseException("Invalid address list.", tokenIndex: 0, errorIndex: index)
        }
        if let result {
            self.init(Array(result))
        } else {
            self.init()
        }
    }
}
