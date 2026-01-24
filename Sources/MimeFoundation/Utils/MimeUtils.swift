//
// MimeUtils.swift
//
// Ported from MimeKit (C#) to Swift.
//

import Foundation

enum MimeUtilsError: Error, Equatable {
    case invalidArgument
}

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

        for scalar in text.unicodeScalars {
            switch scalar.value {
            case 0x0D, 0x0A:
                escaped = false
            case 0x09:
                builder.append(convertTabsToSpaces ? " " : "\t")
                escaped = false
            case 0x5C:
                if escaped {
                    builder.append("\\")
                }
                escaped.toggle()
            case 0x22:
                if escaped {
                    builder.append("\"")
                    escaped = false
                } else {
                    quoted.toggle()
                }
            default:
                builder.append(Character(scalar))
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
        let buffer = CharsetUtils.getBytes(value, encoding: .utf8)
        return enumerateReferences(buffer, startIndex: 0, length: buffer.count)
    }

    static func enumerateReferences(_ buffer: [UInt8], startIndex: Int, length: Int) -> [String] {
        var references: [String] = []
        let endIndex = startIndex + length
        var index = startIndex

        guard startIndex >= 0, length >= 0, endIndex <= buffer.count else {
            return []
        }

        while index < endIndex {
            do {
                _ = try ParseUtils.skipCommentsAndWhiteSpace(buffer, index: &index, endIndex: endIndex, throwOnError: false)
            } catch {
                break
            }

            if index >= endIndex {
                break
            }

            if buffer[index] == 0x3C {
                var msgid: String? = nil
                if (try? ParseUtils.tryParseMsgId(buffer, index: &index, endIndex: endIndex, requireAngleAddr: true, throwOnError: false, msgid: &msgid)) == true {
                    if let msgid {
                        references.append(msgid)
                    }
                } else {
                    index += 1
                }
            } else {
                if (try? ParseUtils.skipWord(buffer, index: &index, endIndex: endIndex, throwOnError: false)) != true {
                    index += 1
                }
            }
        }

        return references
    }

    static func parseMessageId(_ buffer: [UInt8], startIndex: Int, length: Int) -> String? {
        let endIndex = startIndex + length
        var index = startIndex
        var msgid: String? = nil

        guard startIndex >= 0, length >= 0, endIndex <= buffer.count else {
            return nil
        }

        _ = try? ParseUtils.tryParseMsgId(buffer, index: &index, endIndex: endIndex, requireAngleAddr: false, throwOnError: false, msgid: &msgid)
        return msgid
    }


    static func parseMessageId(_ text: String) -> String? {
        let buffer = CharsetUtils.getBytes(text, encoding: .utf8)
        return parseMessageId(buffer, startIndex: 0, length: buffer.count)
    }


    static func tryParseVersion(_ buffer: [UInt8], startIndex: Int, length: Int) -> MimeVersion? {
        let endIndex = startIndex + length
        var index = startIndex
        var values: [Int] = []

        guard startIndex >= 0, length >= 0, endIndex <= buffer.count else {
            return nil
        }

        while index < endIndex {
            do {
                if !(try ParseUtils.skipCommentsAndWhiteSpace(buffer, index: &index, endIndex: endIndex, throwOnError: false)) || index >= endIndex {
                    return nil
                }

                var value = 0
                if !ParseUtils.tryParseInt32(buffer, index: &index, endIndex: endIndex, value: &value) {
                    return nil
                }
                values.append(value)

                if !(try ParseUtils.skipCommentsAndWhiteSpace(buffer, index: &index, endIndex: endIndex, throwOnError: false)) {
                    return nil
                }

                if index >= endIndex {
                    break
                }

                if buffer[index] != 0x2E {
                    return nil
                }
                index += 1
            } catch {
                return nil
            }
        }

        return MimeVersion(components: values)
    }

    static func tryParseVersion(_ text: String) -> MimeVersion? {
        let buffer = CharsetUtils.getBytes(text, encoding: .utf8)
        return tryParseVersion(buffer, startIndex: 0, length: buffer.count)
    }

    static func appendQuoted(_ builder: inout String, _ text: String) {
        builder.append(quote(text))
    }

    static func generateMessageId(_ domain: String? = nil) -> String {
        let trimmed = domain?.trimmingCharacters(in: .whitespacesAndNewlines)
        let host = (trimmed?.isEmpty == false) ? trimmed! : "localhost"
        let encoded = MailboxAddress.idnMapping.encode(host).lowercased()
        return "\(UUID().uuidString)@\(encoded)"
    }

    static func generateMessageId(validating domain: String) throws -> String {
        let trimmed = domain.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            throw MimeUtilsError.invalidArgument
        }
        return generateMessageId(trimmed)
    }
}
