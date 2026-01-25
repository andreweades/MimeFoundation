//
// MailboxAddress.swift
//
// Ported from MimeKit (C#) to Swift.
//

import Foundation

public class MailboxAddress: InternetAddress, Hashable {
    private static let emptySentinels: [UInt8] = []

    public static let idnMapping: PunycodeCoding = Punycode()

    private var addressStorage: String
    private var atIndex: Int

    public private(set) var route: DomainList

    internal init(encoding: String.Encoding, name: String?, route: DomainList, address: String, at: Int) {
        self.route = route
        self.addressStorage = address
        self.atIndex = at
        super.init(encoding: encoding, name: name)
        self.route.changed = { [weak self] _ in
            self?.onChanged()
        }
    }

    internal init(encoding: String.Encoding, name: String?, address: String, at: Int) {
        self.route = DomainList()
        self.addressStorage = address
        self.atIndex = at
        super.init(encoding: encoding, name: name)
        self.route.changed = { [weak self] _ in
            self?.onChanged()
        }
    }

    public init(encoding: String.Encoding, name: String?, route: [String], address: String) {
        self.route = DomainList(route)
        self.addressStorage = ""
        self.atIndex = -1
        super.init(encoding: encoding, name: name)
        self.route.changed = { [weak self] _ in
            self?.onChanged()
        }
        self.address = address
    }

    public init(name: String?, route: [String], address: String) {
        self.route = DomainList(route)
        self.addressStorage = ""
        self.atIndex = -1
        super.init(encoding: .utf8, name: name)
        self.route.changed = { [weak self] _ in
            self?.onChanged()
        }
        self.address = address
    }

    public init(encoding: String.Encoding, name: String?, address: String) {
        self.route = DomainList()
        self.addressStorage = ""
        self.atIndex = -1
        super.init(encoding: encoding, name: name)
        self.route.changed = { [weak self] _ in
            self?.onChanged()
        }
        self.address = address
    }

    public init(name: String?, address: String) {
        self.route = DomainList()
        self.addressStorage = ""
        self.atIndex = -1
        super.init(encoding: .utf8, name: name)
        self.route.changed = { [weak self] _ in
            self?.onChanged()
        }
        self.address = address
    }

    public var address: String {
        get { addressStorage }
        set {
            do {
                try setAddress(newValue)
            } catch {
                return
            }
        }
    }

    public func setAddress(_ value: String) throws {
        if value == addressStorage {
            return
        }

        if value.isEmpty {
            addressStorage = value
            atIndex = -1
            onChanged()
            return
        }

        let buffer = CharsetUtils.getBytes(value, encoding: .utf8)
        var index = 0
        let endIndex = buffer.count
        var addrspec: String? = nil
        var at = -1
        _ = try InternetAddress.tryParseAddrspec(buffer, index: &index, endIndex: endIndex, sentinels: MailboxAddress.emptySentinels, compliance: ParserOptions.default.addressParserComplianceMode, throwOnError: true, addrspec: &addrspec, at: &at)
        _ = try? ParseUtils.skipCommentsAndWhiteSpace(buffer, index: &index, endIndex: endIndex, throwOnError: false)

        if index != endIndex {
            let ch = Character(UnicodeScalar(Int(buffer[index]))!)
            throw ParseException("Unexpected '\(ch)' token at offset \(index)", tokenIndex: index, errorIndex: index)
        }

        addressStorage = addrspec ?? value
        atIndex = at
        onChanged()
    }

    public var localPart: String {
        if atIndex == -1 {
            return addressStorage
        }
        return String(addressStorage.prefix(atIndex))
    }

    public var domain: String {
        if atIndex == -1 {
            return ""
        }
        return String(addressStorage.suffix(addressStorage.count - atIndex - 1))
    }

    public var isInternational: Bool {
        guard !addressStorage.isEmpty else {
            return false
        }
        if ParseUtils.isInternational(addressStorage) {
            return true
        }
        for domain in route {
            if ParseUtils.isInternational(domain) {
                return true
            }
        }
        return false
    }

    public override func copy() -> InternetAddress {
        let copiedRoute = DomainList(route)
        return MailboxAddress(encoding: encoding, name: name, route: copiedRoute, address: addressStorage, at: atIndex)
    }

    public func getAddress(_ idnEncode: Bool) -> String {
        if idnEncode {
            return MailboxAddress.encodeAddrspec(addressStorage, atIndex: atIndex)
        }
        return addressStorage
    }

    internal override func encode(_ options: FormatOptions, builder: inout String, firstToken: inout Bool, lineLength: inout Int) {
        var routeValue = route.encode(options)
        if !routeValue.isEmpty {
            routeValue += ":"
        }

        let addrspec = getAddress(!options.international)

        if let name = name, !name.isEmpty {
            let formattedName: String
            if !options.international {
                formattedName = Rfc2047.encodePhraseAsString(options, encoding, name)
            } else {
                formattedName = InternetAddress.encodeInternationalizedPhrase(name)
            }

            if lineLength + formattedName.count > options.maxLineLength {
                if formattedName.count > options.maxLineLength {
                    StringBuilderUtils.appendFolded(&builder, options: options, firstToken: &firstToken, value: formattedName, lineLength: &lineLength)
                } else {
                    if !firstToken && lineLength > 1 {
                        StringBuilderUtils.lineWrap(&builder, options: options)
                        lineLength = 1
                    }
                    lineLength += formattedName.count
                    builder.append(formattedName)
                }
            } else {
                lineLength += formattedName.count
                builder.append(formattedName)
            }

            if (lineLength + routeValue.count + addrspec.count + 3) > options.maxLineLength {
                builder.append(options.newLine)
                builder.append("\t<")
                lineLength = 2
            } else {
                builder.append(" <")
                lineLength += 2
            }

            lineLength += routeValue.count
            builder.append(routeValue)

            lineLength += addrspec.count + 1
            builder.append(addrspec)
            builder.append(">")
        } else if !routeValue.isEmpty {
            if !firstToken && (lineLength + routeValue.count + addrspec.count + 2) > options.maxLineLength {
                builder.append(options.newLine)
                builder.append("\t<")
                lineLength = 2
            } else {
                builder.append("<")
                lineLength += 1
            }

            lineLength += routeValue.count
            builder.append(routeValue)

            lineLength += addrspec.count + 1
            builder.append(addrspec)
            builder.append(">")
        } else {
            if !firstToken && (lineLength + addrspec.count) > options.maxLineLength {
                StringBuilderUtils.lineWrap(&builder, options: options)
                lineLength = 1
            }
            lineLength += addrspec.count
            builder.append(addrspec)
        }
    }

    public override func formatted(with options: FormatOptions = .default, encoded: Bool = false) -> String {
        if encoded {
            var builder = ""
            var lineLength = 0
            var firstToken = true
            self.encode(options, builder: &builder, firstToken: &firstToken, lineLength: &lineLength)
            return builder
        }

        var routeValue = route.description
        if !routeValue.isEmpty {
            routeValue += ":"
        }

        if let name = name, !name.isEmpty {
            return MimeUtils.quote(name) + " <" + routeValue + addressStorage + ">"
        }

        if !routeValue.isEmpty {
            return "<" + routeValue + addressStorage + ">"
        }

        return addressStorage
    }

    internal override func isEqual(to other: InternetAddress?) -> Bool {
        guard let mailbox = other as? MailboxAddress else {
            return false
        }
        return name == mailbox.name && addressStorage == mailbox.address && route.description == mailbox.route.description
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(addressStorage.lowercased())
    }

    // MARK: Addrspec helpers

    private static func encodeAddrspec(_ addrspec: String, atIndex: Int) -> String {
        guard atIndex != -1 else {
            return addrspec
        }
        if !ParseUtils.isInternational(addrspec, startIndex: atIndex + 1) {
            return addrspec
        }
        let local = String(addrspec.prefix(atIndex))
        let domain = idnMapping.encode(String(addrspec.suffix(addrspec.count - atIndex - 1)))
        return local + "@" + domain
    }

    public static func encodeAddrspec(_ addrspec: String) -> String {
        guard !addrspec.isEmpty else {
            return addrspec
        }

        let buffer = CharsetUtils.getBytes(addrspec, encoding: .utf8)
        var index = 0
        var parsed: String? = nil
        var at = -1
        if (try? InternetAddress.tryParseAddrspec(buffer, index: &index, endIndex: buffer.count, sentinels: emptySentinels, compliance: .looser, throwOnError: false, addrspec: &parsed, at: &at)) != true {
            return addrspec
        }

        return encodeAddrspec(parsed ?? addrspec, atIndex: at)
    }

    public static func decodeAddrspec(_ addrspec: String) -> String {
        guard !addrspec.isEmpty else {
            return addrspec
        }

        let buffer = CharsetUtils.getBytes(addrspec, encoding: .utf8)
        var index = 0
        var parsed: String? = nil
        var at = -1
        if (try? InternetAddress.tryParseAddrspec(buffer, index: &index, endIndex: buffer.count, sentinels: emptySentinels, compliance: .looser, throwOnError: false, addrspec: &parsed, at: &at)) != true {
            return addrspec
        }

        return parsed ?? addrspec
    }

    // MARK: Parsing APIs

    internal static func tryParse(_ options: ParserOptions, _ text: [UInt8], index: inout Int, endIndex: Int, throwOnError: Bool, mailbox: inout MailboxAddress?) throws -> Bool {
        var flags: AddressParserFlags = [.allowMailboxAddress]
        if throwOnError {
            flags.insert(.throwOnError)
        }

        var address: InternetAddress? = nil
        if !(try InternetAddress.tryParse(flags, options, text, index: &index, endIndex: endIndex, groupDepth: 0, address: &address)) {
            mailbox = nil
            return false
        }

        mailbox = address as? MailboxAddress
        return mailbox != nil
    }

    // MARK: - Swift-Idiomatic Parsing Initializers

    /// Throwing initializer - throws ParseException on failure.
    /// Use `try?` for optional behavior: `let mb = try? MailboxAddress(parsing: text)`
    public convenience init(parsing text: String, options: ParserOptions = .default) throws {
        let buffer = CharsetUtils.getBytes(text, encoding: .utf8)
        try self.init(parsing: buffer, options: options)
    }

    /// Throwing initializer - throws ParseException on failure.
    /// Use `try?` for optional behavior: `let mb = try? MailboxAddress(parsing: buffer)`
    public convenience init(parsing buffer: [UInt8], options: ParserOptions = .default) throws {
        var mailbox: MailboxAddress? = nil
        var index = 0
        let endIndex = buffer.count
        _ = try Self.tryParse(options, buffer, index: &index, endIndex: endIndex, throwOnError: true, mailbox: &mailbox)

        _ = try ParseUtils.skipCommentsAndWhiteSpace(buffer, index: &index, endIndex: endIndex, throwOnError: true)

        if index != endIndex {
            throw ParseException("Unexpected token at offset \(index)", tokenIndex: index, errorIndex: index)
        }

        guard let parsed = mailbox else {
            throw ParseException("Invalid mailbox address.", tokenIndex: 0, errorIndex: index)
        }

        self.init(encoding: parsed.encoding, name: parsed.name, route: parsed.route, address: parsed.address, at: parsed.atIndex)
    }
}
