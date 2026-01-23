//
// GroupAddress.swift
//
// Ported from MimeKit (C#) to Swift.
//

import Foundation

public final class GroupAddress: InternetAddress {
    public private(set) var members: InternetAddressList

    public init(encoding: String.Encoding, name: String?, members: InternetAddressList) {
        self.members = members
        super.init(encoding: encoding, name: name)
        self.members.changed = { [weak self] _ in
            self?.onChanged()
        }
    }

    public convenience init(name: String?, members: [InternetAddress]) {
        self.init(encoding: .utf8, name: name, members: InternetAddressList(members))
    }

    public override init(encoding: String.Encoding, name: String?) {
        self.members = InternetAddressList()
        super.init(encoding: encoding, name: name)
        self.members.changed = { [weak self] _ in
            self?.onChanged()
        }
    }

    public convenience init(name: String?) {
        self.init(encoding: .utf8, name: name)
    }

    public override func clone() -> InternetAddress {
        let clonedMembers = members.map { $0.clone() }
        return GroupAddress(encoding: encoding, name: name, members: InternetAddressList(clonedMembers))
    }

    internal override func encode(_ options: FormatOptions, builder: inout String, firstToken: inout Bool, lineLength: inout Int) {
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
        }

        builder.append(": ")
        lineLength += 2

        members.encode(options, builder: &builder, firstToken: false, lineLength: &lineLength)

        builder.append(";")
        lineLength += 1
    }

    public override func toString(_ options: FormatOptions, encode: Bool) -> String {
        if encode {
            var builder = ""
            var lineLength = 0
            var firstToken = true
            self.encode(options, builder: &builder, firstToken: &firstToken, lineLength: &lineLength)
            return builder
        }

        var builder = ""
        builder.append(name ?? "")
        builder.append(": ")
        for (index, address) in members.enumerated() {
            if index > 0 {
                builder.append(", ")
            }
            builder.append(address.description)
        }
        builder.append(";")
        return builder
    }

    public override func equals(_ other: InternetAddress?) -> Bool {
        guard let group = other as? GroupAddress else {
            return false
        }
        return name == group.name && members == group.members
    }

    // MARK: Parsing APIs

    internal static func tryParse(_ options: ParserOptions, _ text: [UInt8], index: inout Int, endIndex: Int, throwOnError: Bool, group: inout GroupAddress?) throws -> Bool {
        if let overflow = findGroupDepthOverflow(text, startIndex: index, endIndex: endIndex, maxDepth: options.maxAddressGroupDepth) {
            if throwOnError {
                throw ParseException("Exceeded maximum rfc822 group depth at offset \(overflow.tokenIndex)", tokenIndex: overflow.tokenIndex, errorIndex: overflow.errorIndex)
            }
            group = nil
            return false
        }
        var flags: AddressParserFlags = [.allowGroupAddress]
        if throwOnError {
            flags.insert(.throwOnError)
        }

        var address: InternetAddress? = nil
        if !(try InternetAddress.tryParse(flags, options, text, index: &index, endIndex: endIndex, groupDepth: 0, address: &address)) {
            group = nil
            return false
        }

        group = address as? GroupAddress
        return group != nil
    }

    private static func findGroupDepthOverflow(_ text: [UInt8], startIndex: Int, endIndex: Int, maxDepth: Int) -> (tokenIndex: Int, errorIndex: Int)? {
        if maxDepth <= 0 {
            return (startIndex, startIndex)
        }

        var depth = 0
        var tokenStart: Int? = nil
        var previousWasDelimiter = true
        var inQuote = false
        var escaped = false
        var commentDepth = 0
        var angleDepth = 0

        var index = startIndex
        while index < endIndex {
            let byte = text[index]

            if inQuote {
                if escaped {
                    escaped = false
                } else if byte == 0x5C { // '\\'
                    escaped = true
                } else if byte == 0x22 { // '\"'
                    inQuote = false
                }
                index += 1
                continue
            }

            if commentDepth > 0 {
                if byte == 0x28 { // '('
                    commentDepth += 1
                } else if byte == 0x29 { // ')'
                    commentDepth -= 1
                }
                index += 1
                continue
            }

            if angleDepth > 0 {
                if byte == 0x3C { // '<'
                    angleDepth += 1
                } else if byte == 0x3E { // '>'
                    angleDepth -= 1
                }
                index += 1
                continue
            }

            switch byte {
            case 0x22: // '\"'
                inQuote = true
                escaped = false
                previousWasDelimiter = true
                tokenStart = nil
            case 0x28: // '('
                commentDepth = 1
                previousWasDelimiter = true
                tokenStart = nil
            case 0x3C: // '<'
                angleDepth = 1
                previousWasDelimiter = true
                tokenStart = nil
            case 0x3A: // ':'
                if depth >= maxDepth {
                    let tokenIndex = tokenStart ?? index
                    return (tokenIndex, index)
                }
                depth += 1
                previousWasDelimiter = true
                tokenStart = nil
            case 0x3B: // ';'
                if depth > 0 {
                    depth -= 1
                }
                previousWasDelimiter = true
                tokenStart = nil
            case 0x2C: // ','
                previousWasDelimiter = true
                tokenStart = nil
            default:
                if ByteClassification.isWhitespace(byte) {
                    previousWasDelimiter = true
                    tokenStart = nil
                } else if previousWasDelimiter {
                    tokenStart = index
                    previousWasDelimiter = false
                }
            }

            index += 1
        }

        return nil
    }

    public static func tryParse(_ options: ParserOptions, _ buffer: [UInt8], startIndex: Int, length: Int, group: inout GroupAddress?) -> Bool {
        let endIndex = startIndex + length

        guard length >= 0, startIndex >= 0, endIndex <= buffer.count else {
            group = nil
            return false
        }

        var index = startIndex
        do {
            if !(try tryParse(options, buffer, index: &index, endIndex: endIndex, throwOnError: false, group: &group)) {
                group = nil
                return false
            }
            if (try? ParseUtils.skipCommentsAndWhiteSpace(buffer, index: &index, endIndex: endIndex, throwOnError: false)) != true {
                group = nil
                return false
            }
            if index != endIndex {
                group = nil
                return false
            }
        } catch {
            group = nil
            return false
        }

        return group != nil
    }

    public static func tryParse(_ buffer: [UInt8], group: inout GroupAddress?) -> Bool {
        tryParse(ParserOptions.default, buffer, startIndex: 0, length: buffer.count, group: &group)
    }

    public static func tryParse(_ buffer: [UInt8], startIndex: Int, group: inout GroupAddress?) -> Bool {
        tryParse(ParserOptions.default, buffer, startIndex: startIndex, length: buffer.count - startIndex, group: &group)
    }

    public static func tryParse(_ buffer: [UInt8], startIndex: Int, length: Int, group: inout GroupAddress?) -> Bool {
        tryParse(ParserOptions.default, buffer, startIndex: startIndex, length: length, group: &group)
    }

    public static func tryParse(_ options: ParserOptions, _ buffer: [UInt8], startIndex: Int, group: inout GroupAddress?) -> Bool {
        tryParse(options, buffer, startIndex: startIndex, length: buffer.count - startIndex, group: &group)
    }

    public static func tryParse(_ options: ParserOptions, _ buffer: [UInt8], group: inout GroupAddress?) -> Bool {
        tryParse(options, buffer, startIndex: 0, length: buffer.count, group: &group)
    }

    public static func tryParse(_ text: String, group: inout GroupAddress?) -> Bool {
        let buffer = CharsetUtils.getBytes(text, encoding: .utf8)
        return tryParse(ParserOptions.default, buffer, startIndex: 0, length: buffer.count, group: &group)
    }

    public static func tryParse(_ options: ParserOptions, _ text: String, group: inout GroupAddress?) -> Bool {
        let buffer = CharsetUtils.getBytes(text, encoding: .utf8)
        return tryParse(options, buffer, startIndex: 0, length: buffer.count, group: &group)
    }

    public override class func parse(_ options: ParserOptions, _ buffer: [UInt8], startIndex: Int, length: Int) throws -> GroupAddress {
        let endIndex = startIndex + length

        guard length >= 0, startIndex >= 0, endIndex <= buffer.count else {
            throw ParseException("Invalid buffer range.", tokenIndex: startIndex, errorIndex: startIndex)
        }

        var index = startIndex
        var group: GroupAddress? = nil
        _ = try tryParse(options, buffer, index: &index, endIndex: endIndex, throwOnError: true, group: &group)

        _ = try ParseUtils.skipCommentsAndWhiteSpace(buffer, index: &index, endIndex: endIndex, throwOnError: true)

        if index != endIndex {
            throw ParseException("Unexpected token at offset \(index)", tokenIndex: index, errorIndex: index)
        }

        if let group = group {
            return group
        }

        throw ParseException("Invalid group address.", tokenIndex: startIndex, errorIndex: index)
    }

    public override class func parse(_ buffer: [UInt8], startIndex: Int, length: Int) throws -> GroupAddress {
        try parse(ParserOptions.default, buffer, startIndex: startIndex, length: length)
    }

    public override class func parse(_ options: ParserOptions, _ buffer: [UInt8], startIndex: Int) throws -> GroupAddress {
        try parse(options, buffer, startIndex: startIndex, length: buffer.count - startIndex)
    }

    public override class func parse(_ buffer: [UInt8], startIndex: Int) throws -> GroupAddress {
        try parse(ParserOptions.default, buffer, startIndex: startIndex, length: buffer.count - startIndex)
    }

    public override class func parse(_ options: ParserOptions, _ buffer: [UInt8]) throws -> GroupAddress {
        try parse(options, buffer, startIndex: 0, length: buffer.count)
    }

    public override class func parse(_ buffer: [UInt8]) throws -> GroupAddress {
        try parse(ParserOptions.default, buffer, startIndex: 0, length: buffer.count)
    }

    public override class func parse(_ options: ParserOptions, _ text: String) throws -> GroupAddress {
        let buffer = CharsetUtils.getBytes(text, encoding: .utf8)
        return try parse(options, buffer, startIndex: 0, length: buffer.count)
    }

    public override class func parse(_ text: String) throws -> GroupAddress {
        let buffer = CharsetUtils.getBytes(text, encoding: .utf8)
        return try parse(ParserOptions.default, buffer, startIndex: 0, length: buffer.count)
    }
}
