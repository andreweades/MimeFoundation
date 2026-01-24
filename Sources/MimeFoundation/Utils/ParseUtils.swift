//
// ParseUtils.swift
//
// Ported from MimeKit (C#) to Swift.
//

import Foundation

enum ParseUtils {
    static func tryParseInt32(_ text: [UInt8], index: inout Int, endIndex: Int, value: inout Int) -> Bool {
        let startIndex = index
        value = 0

        while index < endIndex {
            let byte = text[index]
            if byte < 0x30 || byte > 0x39 {
                break
            }
            let digit = Int(byte - 0x30)
            if value > Int(Int32.max) / 10 {
                return false
            }
            if value == Int(Int32.max) / 10 && digit > Int(Int32.max % 10) {
                return false
            }
            value = (value * 10) + digit
            index += 1
        }

        return index > startIndex
    }

    static func skipWhiteSpace(_ text: [UInt8], index: inout Int, endIndex: Int) -> Bool {
        let startIndex = index
        while index < endIndex && ByteClassification.isWhitespace(text[index]) {
            index += 1
        }
        return index > startIndex
    }

    static func skipComment(_ text: [UInt8], index: inout Int, endIndex: Int) -> Bool {
        var escaped = false
        var depth = 1
        index += 1

        while index < endIndex && depth > 0 {
            if text[index] == 0x5C { // '\\'
                escaped.toggle()
            } else if !escaped {
                if text[index] == 0x28 { // '('
                    depth += 1
                } else if text[index] == 0x29 { // ')'
                    depth -= 1
                }
            } else {
                escaped = false
            }
            index += 1
        }

        return depth == 0
    }

    static func skipComment(_ text: String, index: inout Int, endIndex: Int) -> Bool {
        var escaped = false
        var depth = 1
        index += 1

        while index < endIndex && depth > 0 {
            let ch = text[text.index(text.startIndex, offsetBy: index)]
            if ch == "\\" {
                escaped.toggle()
            } else if !escaped {
                if ch == "(" {
                    depth += 1
                } else if ch == ")" {
                    depth -= 1
                }
            } else {
                escaped = false
            }
            index += 1
        }

        return depth == 0
    }

    static func skipCommentsAndWhiteSpace(_ text: [UInt8], index: inout Int, endIndex: Int, throwOnError: Bool) throws -> Bool {
        _ = skipWhiteSpace(text, index: &index, endIndex: endIndex)

        while index < endIndex && text[index] == 0x28 { // '('
            let startIndex = index
            if !skipComment(text, index: &index, endIndex: endIndex) {
                if throwOnError {
                    throw ParseException("Incomplete comment token at offset \(startIndex)", tokenIndex: startIndex, errorIndex: index)
                }
                return false
            }
            _ = skipWhiteSpace(text, index: &index, endIndex: endIndex)
        }

        return true
    }

    static func skipQuoted(_ text: [UInt8], index: inout Int, endIndex: Int, throwOnError: Bool) throws -> Bool {
        let startIndex = index
        var escaped = false

        index += 1
        while index < endIndex {
            if text[index] == 0x5C { // '\\'
                escaped.toggle()
            } else if !escaped {
                if text[index] == 0x22 { // '"'
                    break
                }
            } else {
                escaped = false
            }
            index += 1
        }

        if index >= endIndex {
            if throwOnError {
                throw ParseException("Incomplete quoted-string token at offset \(startIndex)", tokenIndex: startIndex, errorIndex: index)
            }
            return false
        }

        index += 1
        return true
    }

    static func skipAtom(_ text: [UInt8], index: inout Int, endIndex: Int) -> Bool {
        let start = index
        while index < endIndex && ByteClassification.isAtom(text[index]) {
            index += 1
        }
        return index > start
    }

    static func skipPhraseAtom(_ text: [UInt8], index: inout Int, endIndex: Int) -> Bool {
        let start = index
        while index < endIndex && ByteClassification.isPhraseAtom(text[index]) {
            index += 1
        }
        return index > start
    }

    static func skipToken(_ text: [UInt8], index: inout Int, endIndex: Int) -> Bool {
        let start = index
        while index < endIndex && ByteClassification.isToken(text[index]) {
            index += 1
        }
        return index > start
    }

    static func skipWord(_ text: [UInt8], index: inout Int, endIndex: Int, throwOnError: Bool) throws -> Bool {
        if text[index] == 0x22 {
            return try skipQuoted(text, index: &index, endIndex: endIndex, throwOnError: throwOnError)
        }
        if ByteClassification.isAtom(text[index]) {
            return skipAtom(text, index: &index, endIndex: endIndex)
        }
        return false
    }

    static func isSentinel(_ c: UInt8, _ sentinels: [UInt8]) -> Bool {
        for sentinel in sentinels where c == sentinel {
            return true
        }
        return false
    }

    private static func tryParseDotAtom(
        _ text: [UInt8],
        index: inout Int,
        endIndex: Int,
        sentinels: [UInt8],
        throwOnError: Bool,
        tokenType: String,
        dotAtom: inout String?
    ) throws -> Bool {
        var token = ValueStringBuilder(initialCapacity: 128)
        let startIndex = index
        var comment = 0
        dotAtom = nil

        repeat {
            if !ByteClassification.isAtom(text[index]) {
                if throwOnError {
                    throw ParseException("Invalid \(tokenType) token at offset \(startIndex)", tokenIndex: startIndex, errorIndex: index)
                }
                return false
            }

            let start = index
            while index < endIndex && ByteClassification.isAtom(text[index]) {
                index += 1
            }

            do {
                let value = try CharsetUtils.getString(text, start: start, length: index - start, encoding: .utf8)
                token.append(value)
            } catch {
                if throwOnError {
                    throw ParseException("Internationalized \(tokenType)s may only contain UTF-8 characters.", tokenIndex: start, errorIndex: start)
                }
                return false
            }

            comment = index
            if !(try skipCommentsAndWhiteSpace(text, index: &index, endIndex: endIndex, throwOnError: throwOnError)) {
                return false
            }

            if index >= endIndex || text[index] != 0x2E { // '.'
                index = comment
                break
            }

            index += 1
            if !(try skipCommentsAndWhiteSpace(text, index: &index, endIndex: endIndex, throwOnError: throwOnError)) {
                return false
            }

            if index >= endIndex || isSentinel(text[index], sentinels) {
                break
            }

            token.append(".")
        } while true

        dotAtom = token.asString()
        return true
    }

    private static func tryParseDomainLiteral(_ text: [UInt8], index: inout Int, endIndex: Int, throwOnError: Bool, domain: inout String?) throws -> Bool {
        var token = ValueStringBuilder(initialCapacity: 128)
        let startIndex = index
        domain = nil

        index += 1
        token.append("[")
        _ = skipWhiteSpace(text, index: &index, endIndex: endIndex)

        repeat {
            while index < endIndex && ByteClassification.isDomain(text[index]) {
                token.append(Character(UnicodeScalar(text[index])))
                index += 1
            }

            _ = skipWhiteSpace(text, index: &index, endIndex: endIndex)

            if index >= endIndex {
                if throwOnError {
                    throw ParseException("Incomplete domain literal token at offset \(startIndex)", tokenIndex: startIndex, errorIndex: index)
                }
                return false
            }

            if text[index] == 0x5D { // ']'
                break
            }

            if !ByteClassification.isDomain(text[index]) {
                if throwOnError {
                    throw ParseException("Invalid domain literal token at offset \(startIndex)", tokenIndex: startIndex, errorIndex: index)
                }
                return false
            }
        } while true

        token.append("]")
        index += 1
        domain = token.asString()
        return true
    }

    static func tryParseDomain(_ text: [UInt8], index: inout Int, endIndex: Int, sentinels: [UInt8], throwOnError: Bool, domain: inout String?) throws -> Bool {
        if text[index] == 0x5B {
            return try tryParseDomainLiteral(text, index: &index, endIndex: endIndex, throwOnError: throwOnError, domain: &domain)
        }

        return try tryParseDotAtom(text, index: &index, endIndex: endIndex, sentinels: sentinels, throwOnError: throwOnError, tokenType: "domain", dotAtom: &domain)
    }

    static func tryParseMsgId(_ text: [UInt8], index: inout Int, endIndex: Int, requireAngleAddr: Bool, throwOnError: Bool, msgid: inout String?) throws -> Bool {
        var squareBrackets = false
        var angleAddr = false
        msgid = nil

        if !(try skipCommentsAndWhiteSpace(text, index: &index, endIndex: endIndex, throwOnError: throwOnError)) {
            return false
        }

        if index >= endIndex || (requireAngleAddr && text[index] != 0x3C) {
            if throwOnError {
                throw ParseException("No msg-id token found.", tokenIndex: index, errorIndex: index)
            }
            return false
        }

        let tokenIndex = index

        if text[index] == 0x3C {
            angleAddr = true
            index += 1
        }

        _ = skipWhiteSpace(text, index: &index, endIndex: endIndex)

        if index >= endIndex {
            if throwOnError {
                throw ParseException("Incomplete msg-id token at offset \(tokenIndex)", tokenIndex: tokenIndex, errorIndex: index)
            }
            return false
        }

        var token = ValueStringBuilder(initialCapacity: 128)

        if text[index] == 0x5B {
            squareBrackets = true
        }

        repeat {
            let start = index

            if text[index] == 0x22 {
                if !(try skipQuoted(text, index: &index, endIndex: endIndex, throwOnError: throwOnError)) {
                    return false
                }
            } else {
                while index < endIndex && text[index] != 0x2E && text[index] != 0x40 && text[index] != 0x3E && !ByteClassification.isWhitespace(text[index]) {
                    index += 1
                }
            }

            do {
                let word = try CharsetUtils.getString(text, start: start, length: index - start, encoding: .utf8)
                token.append(word)
            } catch {
                if throwOnError {
                    throw ParseException("Internationalized local-part tokens may only contain UTF-8 characters.", tokenIndex: start, errorIndex: start)
                }
                return false
            }

            _ = skipWhiteSpace(text, index: &index, endIndex: endIndex)

            if index >= endIndex {
                if angleAddr {
                    if throwOnError {
                        throw ParseException("Incomplete msg-id at offset \(tokenIndex)", tokenIndex: tokenIndex, errorIndex: index)
                    }
                    return false
                }
                break
            }

            if text[index] == 0x40 || text[index] == 0x3E {
                break
            }

            if text[index] == 0x2E {
                token.append(".")
                index += 1
                _ = skipWhiteSpace(text, index: &index, endIndex: endIndex)
            }

            if index >= endIndex {
                if throwOnError {
                    throw ParseException("Incomplete msg-id at offset \(tokenIndex)", tokenIndex: tokenIndex, errorIndex: index)
                }
                return false
            }
        } while true

        if index < endIndex && text[index] == 0x40 {
            token.append("@")
            index += 1

            while index < endIndex && text[index] == 0x40 {
                index += 1
            }

            if !(try skipCommentsAndWhiteSpace(text, index: &index, endIndex: endIndex, throwOnError: throwOnError)) {
                return false
            }

            if index < endIndex && text[index] != 0x3E {
                repeat {
                    var domain: String? = nil
                    if !(try tryParseDomain(text, index: &index, endIndex: endIndex, sentinels: [0x3E, 0x40], throwOnError: throwOnError, domain: &domain)) {
                        return false
                    }

                    if let domainValue = domain {
                        var decodedDomain = domainValue
                        if isIdnEncoded(decodedDomain) {
                            decodedDomain = MailboxAddress.idnMapping.decode(decodedDomain)
                        }
                        token.append(decodedDomain)
                    }

                    if index >= endIndex || text[index] != 0x40 {
                        break
                    }

                    token.append("@")
                    index += 1
                } while true

                if !(try skipCommentsAndWhiteSpace(text, index: &index, endIndex: endIndex, throwOnError: throwOnError)) {
                    return false
                }
            }
        }

        if squareBrackets && index < endIndex && text[index] == 0x5D {
            token.append("]")
            index += 1
        }

        if angleAddr && (index >= endIndex || text[index] != 0x3E) {
            if throwOnError {
                throw ParseException("Incomplete msg-id token at offset \(tokenIndex)", tokenIndex: tokenIndex, errorIndex: index)
            }
            return false
        }

        if index < endIndex && text[index] == 0x3E {
            index += 1
        }

        msgid = token.asString()
        return true
    }

    static func isInternational(_ value: String, startIndex: Int, count: Int) -> Bool {
        let endIndex = startIndex + count
        let scalars = Array(value.unicodeScalars)
        guard startIndex >= 0, count >= 0, endIndex <= scalars.count else {
            return false
        }
        for i in startIndex..<endIndex {
            if scalars[i].value > 127 {
                return true
            }
        }
        return false
    }

    static func isInternational(_ value: String, startIndex: Int) -> Bool {
        return isInternational(value, startIndex: startIndex, count: value.unicodeScalars.count - startIndex)
    }

    static func isInternational(_ value: String) -> Bool {
        return isInternational(value, startIndex: 0, count: value.unicodeScalars.count)
    }

    static func isIdnEncoded(_ value: String) -> Bool {
        if value.hasPrefix("xn--") {
            return true
        }
        return value.range(of: ".xn--") != nil
    }
}
