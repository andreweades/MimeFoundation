//
// DomainList.swift
//
// Ported from MimeKit (C#) to Swift.
//

import Foundation

public final class DomainList: RandomAccessCollection, MutableCollection, CustomStringConvertible {
    public typealias Element = String
    public typealias Index = Int

    private static let domainSentinels: [UInt8] = [0x2C, 0x3A] // ',' ':'

    private var domains: [String]

    public var startIndex: Int { domains.startIndex }
    public var endIndex: Int { domains.endIndex }

    public init() {
        self.domains = []
    }

    public init(_ domains: [String]) {
        self.domains = domains
    }

    public init<S: Sequence>(_ domains: S) where S.Element == String {
        self.domains = Array(domains)
    }

    public subscript(position: Int) -> String {
        get { domains[position] }
        set {
            guard position >= 0 && position < domains.count else {
                fatalError("index out of range")
            }
            domains[position] = newValue
            onChanged()
        }
    }

    public func index(after i: Int) -> Int {
        domains.index(after: i)
    }

    public var count: Int { domains.count }

    public var isReadOnly: Bool { false }

    public func indexOf(_ domain: String) -> Int {
        domains.firstIndex(of: domain) ?? -1
    }

    public func contains(_ domain: String) -> Bool {
        domains.contains(domain)
    }

    public func add(_ domain: String) {
        domains.append(domain)
        onChanged()
    }

    public func insert(_ domain: String, at index: Int) {
        domains.insert(domain, at: index)
        onChanged()
    }

    public func remove(at index: Int) {
        domains.remove(at: index)
        onChanged()
    }

    @discardableResult
    public func remove(_ domain: String) -> Bool {
        guard let idx = domains.firstIndex(of: domain) else {
            return false
        }
        domains.remove(at: idx)
        onChanged()
        return true
    }

    public func clear() {
        domains.removeAll(keepingCapacity: true)
        onChanged()
    }

    public func copyTo(_ array: inout [String], at index: Int) {
        guard index >= 0 && index <= array.count else {
            return
        }
        array.insert(contentsOf: domains, at: index)
    }

    public var description: String {
        toString()
    }

    public func toString() -> String {
        var builder = ValueStringBuilder(initialCapacity: 128)
        for domain in domains {
            if domain.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                continue
            }
            if builder.length > 0 {
                builder.append(",")
            }
            builder.append("@")
            builder.append(domain)
        }
        return builder.asString()
    }

    internal func encode(_ options: FormatOptions) -> String {
        var builder = ValueStringBuilder(initialCapacity: 256)
        for domain in domains {
            if domain.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                continue
            }
            if builder.length > 0 {
                builder.append(",")
            }
            builder.append("@")
            if !options.international && ParseUtils.isInternational(domain) {
                let encoded = MailboxAddress.idnMapping.encode(domain)
                builder.append(encoded)
            } else {
                builder.append(domain)
            }
        }
        return builder.asString()
    }

    internal var changed: ((DomainList) -> Void)?

    private func onChanged() {
        changed?(self)
    }

    internal static func tryParse(_ buffer: [UInt8], index: inout Int, endIndex: Int, throwOnError: Bool, route: inout DomainList?) throws -> Bool {
        var domains: [String] = []
        let startIndex = index
        route = nil

        if index >= endIndex {
            if throwOnError {
                throw ParseException("Incomplete domain-list at offset: \(startIndex)", tokenIndex: startIndex, errorIndex: index)
            }
            return false
        }

        if buffer[index] != 0x40 {
            if throwOnError {
                throw ParseException("Invalid domain-list at offset: \(startIndex)", tokenIndex: startIndex, errorIndex: index)
            }
            return false
        }

        while index < endIndex {
            index += 1 // skip '@'
            if index >= endIndex {
                if throwOnError {
                    throw ParseException("Incomplete domain-list at offset: \(startIndex)", tokenIndex: startIndex, errorIndex: index)
                }
                return false
            }

            var domain: String? = nil
            if !(try ParseUtils.tryParseDomain(buffer, index: &index, endIndex: endIndex, sentinels: domainSentinels, throwOnError: throwOnError, domain: &domain)) {
                return false
            }

            if let domainValue = domain {
                domains.append(domainValue)
            }

            while true {
                if !(try ParseUtils.skipCommentsAndWhiteSpace(buffer, index: &index, endIndex: endIndex, throwOnError: throwOnError)) {
                    return false
                }

                if index >= endIndex || buffer[index] != 0x2C {
                    break
                }
                index += 1
            }

            if !(try ParseUtils.skipCommentsAndWhiteSpace(buffer, index: &index, endIndex: endIndex, throwOnError: throwOnError)) {
                return false
            }

            if index >= endIndex || buffer[index] != 0x40 {
                break
            }
        }

        route = DomainList(domains)
        return true
    }

    // MARK: - Swift-Idiomatic Parsing Initializers

    /// Throwing initializer - throws ParseException on failure.
    /// Use `try?` for optional behavior: `let dl = try? DomainList(parsing: text)`
    public convenience init(parsing text: String) throws {
        let buffer = CharsetUtils.getBytes(text, encoding: .utf8)
        try self.init(parsing: buffer)
    }

    /// Throwing initializer - throws ParseException on failure.
    /// Use `try?` for optional behavior: `let dl = try? DomainList(parsing: buffer)`
    public convenience init(parsing buffer: [UInt8]) throws {
        var result: DomainList? = nil
        var index = 0
        _ = try Self.tryParse(buffer, index: &index, endIndex: buffer.count,
                              throwOnError: true, route: &result)
        guard let parsed = result else {
            throw ParseException("Failed to parse domain list.", tokenIndex: 0, errorIndex: index)
        }
        self.init(parsed)
    }
}
