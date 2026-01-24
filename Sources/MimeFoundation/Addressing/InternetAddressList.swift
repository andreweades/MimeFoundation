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
            guard position >= 0 && position < list.count else {
                fatalError("index out of range")
            }
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
            builder.append(address.toString(options, encode: false))
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

    public func compareTo(_ other: InternetAddressList) -> Int {
        if self == other {
            return 0
        }
        return self < other ? -1 : 1
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

    public static func tryParse(_ options: ParserOptions, _ buffer: [UInt8], startIndex: Int, length: Int, addresses: inout InternetAddressList?) -> Bool {
        let endIndex = startIndex + length
        guard startIndex >= 0, length >= 0, endIndex <= buffer.count else {
            addresses = nil
            return false
        }
        var index = startIndex
        var list: InternetAddressList? = nil
        if !tryParse(.tryParse, options, buffer, index: &index, endIndex: endIndex, isGroup: false, groupDepth: 0, addresses: &list) {
            addresses = nil
            return false
        }
        addresses = list
        return true
    }

    public static func tryParse(_ buffer: [UInt8], addresses: inout InternetAddressList?) -> Bool {
        tryParse(ParserOptions.default, buffer, startIndex: 0, length: buffer.count, addresses: &addresses)
    }

    public static func tryParse(_ buffer: [UInt8], startIndex: Int, addresses: inout InternetAddressList?) -> Bool {
        tryParse(ParserOptions.default, buffer, startIndex: startIndex, length: buffer.count - startIndex, addresses: &addresses)
    }

    public static func tryParse(_ buffer: [UInt8], startIndex: Int, length: Int, addresses: inout InternetAddressList?) -> Bool {
        tryParse(ParserOptions.default, buffer, startIndex: startIndex, length: length, addresses: &addresses)
    }

    public static func tryParse(_ options: ParserOptions, _ buffer: [UInt8], startIndex: Int, addresses: inout InternetAddressList?) -> Bool {
        tryParse(options, buffer, startIndex: startIndex, length: buffer.count - startIndex, addresses: &addresses)
    }

    public static func tryParse(_ options: ParserOptions, _ buffer: [UInt8], addresses: inout InternetAddressList?) -> Bool {
        tryParse(options, buffer, startIndex: 0, length: buffer.count, addresses: &addresses)
    }

    public static func tryParse(_ text: String, addresses: inout InternetAddressList?) -> Bool {
        let buffer = CharsetUtils.getBytes(text, encoding: .utf8)
        return tryParse(ParserOptions.default, buffer, startIndex: 0, length: buffer.count, addresses: &addresses)
    }

    public static func tryParse(_ options: ParserOptions, _ text: String, addresses: inout InternetAddressList?) -> Bool {
        let buffer = CharsetUtils.getBytes(text, encoding: .utf8)
        return tryParse(options, buffer, startIndex: 0, length: buffer.count, addresses: &addresses)
    }

    public static func parse(_ options: ParserOptions, _ buffer: [UInt8], startIndex: Int, length: Int) throws -> InternetAddressList {
        var list: InternetAddressList? = nil
        if !tryParse(options, buffer, startIndex: startIndex, length: length, addresses: &list) {
            throw ParseException("Invalid address list.", tokenIndex: startIndex, errorIndex: startIndex)
        }
        return list ?? InternetAddressList()
    }

    public static func parse(_ buffer: [UInt8], startIndex: Int, length: Int) throws -> InternetAddressList {
        try parse(ParserOptions.default, buffer, startIndex: startIndex, length: length)
    }

    public static func parse(_ options: ParserOptions, _ buffer: [UInt8], startIndex: Int) throws -> InternetAddressList {
        try parse(options, buffer, startIndex: startIndex, length: buffer.count - startIndex)
    }

    public static func parse(_ buffer: [UInt8], startIndex: Int) throws -> InternetAddressList {
        try parse(ParserOptions.default, buffer, startIndex: startIndex, length: buffer.count - startIndex)
    }

    public static func parse(_ options: ParserOptions, _ buffer: [UInt8]) throws -> InternetAddressList {
        try parse(options, buffer, startIndex: 0, length: buffer.count)
    }

    public static func parse(_ buffer: [UInt8]) throws -> InternetAddressList {
        try parse(ParserOptions.default, buffer, startIndex: 0, length: buffer.count)
    }

    public static func parse(_ options: ParserOptions, _ text: String) throws -> InternetAddressList {
        let buffer = CharsetUtils.getBytes(text, encoding: .utf8)
        return try parse(options, buffer, startIndex: 0, length: buffer.count)
    }

    public static func parse(_ text: String) throws -> InternetAddressList {
        let buffer = CharsetUtils.getBytes(text, encoding: .utf8)
        return try parse(ParserOptions.default, buffer, startIndex: 0, length: buffer.count)
    }
}
