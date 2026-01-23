//
// CharsetUtils.swift
//
// Ported from MimeKit (C#) to Swift.
//

import Foundation

public enum CharsetError: Error, Equatable {
    case invalidSequence
    case unsupportedEncoding
}

public enum CharsetUtils {
    public static let utf8: String.Encoding = .utf8
    public static let latin1: String.Encoding = .isoLatin1
    public static let ascii: String.Encoding = .ascii

    public static func getBytes(_ string: String, encoding: String.Encoding = .utf8) -> [UInt8] {
        Array(string.data(using: encoding) ?? Data())
    }

    public static func tryGetString(_ bytes: [UInt8], start: Int, length: Int, encoding: String.Encoding = .utf8) -> String? {
        let end = start + length
        guard start >= 0, length >= 0, end <= bytes.count else { return nil }
        let data = Data(bytes[start..<end])
        return String(data: data, encoding: encoding)
    }

    public static func getString(_ bytes: [UInt8], start: Int, length: Int, encoding: String.Encoding = .utf8) throws -> String {
        if let value = tryGetString(bytes, start: start, length: length, encoding: encoding) {
            return value
        }
        throw CharsetError.invalidSequence
    }

    public static func getEncoding(_ charset: String) -> String.Encoding? {
        let normalized = charset.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        if normalized.isEmpty {
            return nil
        }

        switch normalized {
        case "utf8", "utf-8", "unicode-1-1-utf-8":
            return .utf8
        case "us-ascii", "ascii", "ansi_x3.4-1968":
            return .ascii
        case "iso-8859-1", "latin1", "iso-ir-100":
            return .isoLatin1
        default:
            let cfEncoding = CFStringConvertIANACharSetNameToEncoding(normalized as CFString)
            if cfEncoding == kCFStringEncodingInvalidId {
                return nil
            }
            let nsEncoding = CFStringConvertEncodingToNSStringEncoding(cfEncoding)
            return String.Encoding(rawValue: nsEncoding)
        }
    }

    public static func getEncodingOrDefault(_ charset: String, fallback: String.Encoding) -> String.Encoding {
        return getEncoding(charset) ?? fallback
    }

    public static func getEncodingOrDefault(_ codepage: Int, fallback: String.Encoding) -> String.Encoding {
        if codepage == 0 {
            return fallback
        }

        let cfEncoding = CFStringConvertWindowsCodepageToEncoding(UInt32(codepage))
        if cfEncoding != kCFStringEncodingInvalidId {
            let nsEncoding = CFStringConvertEncodingToNSStringEncoding(cfEncoding)
            return String.Encoding(rawValue: nsEncoding)
        }

        switch codepage {
        case 65001:
            return .utf8
        case 20127:
            return .ascii
        case 28591:
            return .isoLatin1
        default:
            return fallback
        }
    }

    public static func getMimeCharset(_ encoding: String.Encoding) -> String {
        let cfEncoding = CFStringConvertNSStringEncodingToEncoding(encoding.rawValue)
        if let name = CFStringConvertEncodingToIANACharSetName(cfEncoding) {
            return (name as String).lowercased()
        }
        switch encoding {
        case .utf8:
            return "utf-8"
        case .ascii:
            return "us-ascii"
        case .isoLatin1:
            return "iso-8859-1"
        default:
            return "utf-8"
        }
    }

    public static func getMimeCharset(_ charset: String) -> String {
        if let encoding = getEncoding(charset) {
            return getMimeCharset(encoding)
        }
        return charset.lowercased()
    }

    public static func getCodepage(_ encoding: String.Encoding) -> Int {
        let cfEncoding = CFStringConvertNSStringEncodingToEncoding(encoding.rawValue)
        let codepage = CFStringConvertEncodingToWindowsCodepage(cfEncoding)
        if codepage != kCFStringEncodingInvalidId && codepage != 0 {
            return Int(codepage)
        }

        switch encoding {
        case .utf8:
            return 65001
        case .ascii:
            return 20127
        case .isoLatin1:
            return 28591
        default:
            return 65001
        }
    }

    public static func convertToUnicode(_ options: ParserOptions, _ bytes: [UInt8], start: Int, length: Int) -> String {
        if let value = tryGetString(bytes, start: start, length: length, encoding: .utf8) {
            return value
        }
        if let value = tryGetString(bytes, start: start, length: length, encoding: options.charsetEncoding) {
            return value
        }
        if let value = tryGetString(bytes, start: start, length: length, encoding: .isoLatin1) {
            return value
        }
        return String(decoding: bytes[start..<(start + length)], as: UTF8.self)
    }
}
