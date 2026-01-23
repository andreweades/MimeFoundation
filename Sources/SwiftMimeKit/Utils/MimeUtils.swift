//
// MimeUtils.swift
//
// Ported from MimeKit (C#) to Swift.
//

import Foundation

enum MimeUtils {
    private static let unquoteChars: [Character] = ["\r", "\n", "\t", "\\", "\""]

    static func quote(_ text: String) -> String {
        var builder = ValueStringBuilder(initialCapacity: (text.count * 2) + 2)
        builder.append("\"")
        for ch in text {
            if ch == "\\" || ch == "\"" {
                builder.append("\\")
            }
            builder.append(ch)
        }
        builder.append("\"")
        return builder.asString()
    }

    static func unquote(_ text: String, convertTabsToSpaces: Bool = false) -> String {
        guard text.firstIndex(where: { unquoteChars.contains($0) }) != nil else {
            return text
        }

        var builder = ValueStringBuilder(initialCapacity: text.count)
        var escaped = false
        var quoted = false

        for ch in text {
            switch ch {
            case "\r", "\n":
                escaped = false
            case "\t":
                builder.append(convertTabsToSpaces ? " " : "\t")
                escaped = false
            case "\\":
                if escaped {
                    builder.append("\\")
                }
                escaped.toggle()
            case "\"":
                if escaped {
                    builder.append("\"")
                    escaped = false
                } else {
                    quoted.toggle()
                }
            default:
                builder.append(ch)
                escaped = false
            }
        }

        _ = quoted
        return builder.asString()
    }

    static func unquote(_ bytes: [UInt8], startIndex: Int, length: Int, convertTabsToSpaces: Bool = false) -> [UInt8] {
        var builder = ByteArrayBuilder(initialCapacity: length)
        var escaped = false
        var quoted = false

        let end = startIndex + length
        guard startIndex >= 0, length >= 0, end <= bytes.count else {
            return []
        }

        for index in startIndex..<end {
            let byte = bytes[index]
            switch byte {
            case 0x0D, 0x0A:
                escaped = false
            case 0x09:
                builder.append(convertTabsToSpaces ? 0x20 : 0x09)
                escaped = false
            case 0x5C:
                if escaped {
                    builder.append(0x5C)
                }
                escaped.toggle()
            case 0x22:
                if escaped {
                    builder.append(0x22)
                    escaped = false
                } else {
                    quoted.toggle()
                }
            default:
                builder.append(byte)
                escaped = false
            }
        }

        _ = quoted
        return builder.toArray()
    }

    static func enumerateReferences(_ value: String) -> [String] {
        var references: [String] = []
        var index = value.startIndex

        func skipWhitespace() {
            while index < value.endIndex, value[index].isWhitespace {
                index = value.index(after: index)
            }
        }

        while index < value.endIndex {
            skipWhitespace()
            if index >= value.endIndex {
                break
            }

            if value[index] == "<" {
                let start = value.index(after: index)
                if let end = value[start...].firstIndex(of: ">") {
                    let ref = value[start..<end].trimmingCharacters(in: .whitespacesAndNewlines)
                    if !ref.isEmpty {
                        references.append(ref)
                    }
                    index = value.index(after: end)
                    continue
                }
            }

            let start = index
            while index < value.endIndex, !value[index].isWhitespace, value[index] != "<" {
                index = value.index(after: index)
            }
            let token = value[start..<index].trimmingCharacters(in: CharacterSet(charactersIn: "<> \t\r\n"))
            if !token.isEmpty, token.contains("@") {
                references.append(String(token))
            }
        }

        return references
    }

    static func generateMessageId(_ domain: String? = nil) -> String {
        let host = (domain?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false) ? domain! : "localhost"
        return "\(UUID().uuidString)@\(host)"
    }
}
