//
// ByteClassification.swift
//
// Ported from MimeKit (C#) to Swift.
//

enum ByteClassification {
    private struct CharType: OptionSet {
        let rawValue: UInt16

        static let ascii = CharType(rawValue: 1 << 0)
        static let atom = CharType(rawValue: 1 << 1)
        static let attrChar = CharType(rawValue: 1 << 2)
        static let blank = CharType(rawValue: 1 << 3)
        static let control = CharType(rawValue: 1 << 4)
        static let domainSafe = CharType(rawValue: 1 << 5)
        static let encodedPhraseSafe = CharType(rawValue: 1 << 6)
        static let encodedWordSafe = CharType(rawValue: 1 << 7)
        static let quotedPrintableSafe = CharType(rawValue: 1 << 8)
        static let space = CharType(rawValue: 1 << 9)
        static let special = CharType(rawValue: 1 << 10)
        static let tokenSpecial = CharType(rawValue: 1 << 11)
        static let whitespace = CharType(rawValue: 1 << 12)
        static let xdigit = CharType(rawValue: 1 << 13)
        static let phraseAtom = CharType(rawValue: 1 << 14)
        static let fieldText = CharType(rawValue: 1 << 15)

        static let asciiAtom: CharType = [.ascii, .atom]
    }

    private static let atomSafe = Array("!#$%&'*+-/=?^_`{|}~".utf8)
    private static let attributeSpecials = Array("*'%".utf8)
    private static let encodedWordSpecials = Array("()<>@,;:\"/[]?.=_".utf8)
    private static let encodedPhraseSafeSet = Array("!*+-/".utf8)
    private static let specials = Array("()<>[]:;@\\,.\"".utf8)
    private static let tokenSpecials = Array("()<>@,;:\\\"/[]?=".utf8)
    private static let whitespace = Array(" \t\r\n".utf8)

    private static let table: [CharType] = {
        var table = Array(repeating: CharType(), count: 256)

        for i in 0..<256 {
            if i < 127 {
                if i < 32 {
                    table[i].insert([.control, .tokenSpecial])
                }
                if i > 32 {
                    table[i].insert(.attrChar)
                }
                if i >= 32 && i != 61 {
                    table[i].insert([.quotedPrintableSafe, .encodedWordSafe])
                }
                if (i >= 0x30 && i <= 0x39) || (i >= 0x61 && i <= 0x7A) || (i >= 0x41 && i <= 0x5A) {
                    table[i].insert([.encodedPhraseSafe, .atom, .phraseAtom])
                }
                if (i >= 0x30 && i <= 0x39) || (i >= 0x61 && i <= 0x66) || (i >= 0x41 && i <= 0x46) {
                    table[i].insert(.xdigit)
                }
                if i >= 33 && i != 58 {
                    table[i].insert(.fieldText)
                }
                if (i >= 33 && i <= 90) || i >= 94 {
                    table[i].insert(.domainSafe)
                }
                table[i].insert(.ascii)
            } else {
                if i == 127 {
                    table[i].insert(.ascii)
                } else {
                    table[i].insert([.atom, .phraseAtom])
                }
                table[i].insert([.control, .tokenSpecial])
            }
        }

        table[0x09].insert([.quotedPrintableSafe, .blank])
        table[0x20].insert([.space, .blank])

        func setFlags(_ values: [UInt8], _ flag: CharType) {
            for value in values {
                table[Int(value)].insert(flag)
            }
        }

        func removeFlags(_ values: [UInt8], _ flag: CharType) {
            for value in values {
                table[Int(value)].remove(flag)
            }
        }

        setFlags(whitespace, .whitespace)
        setFlags(atomSafe, [.atom, .phraseAtom])
        setFlags(tokenSpecials, .tokenSpecial)
        setFlags(specials, .special)
        removeFlags(specials, [.atom, .phraseAtom])
        removeFlags(encodedWordSpecials, .encodedWordSafe)
        removeFlags(attributeSpecials + tokenSpecials, .attrChar)
        setFlags(encodedPhraseSafeSet, .encodedPhraseSafe)

        table[0x5B].insert(.phraseAtom)
        table[0x5D].insert(.phraseAtom)
        table[0x29].insert(.phraseAtom)

        return table
    }()

    static func isAsciiAtom(_ byte: UInt8) -> Bool {
        table[Int(byte)].contains(.asciiAtom)
    }

    static func isPhraseAtom(_ byte: UInt8) -> Bool {
        table[Int(byte)].contains(.phraseAtom)
    }

    static func isAtom(_ byte: UInt8) -> Bool {
        table[Int(byte)].contains(.atom)
    }

    static func isAttr(_ byte: UInt8) -> Bool {
        table[Int(byte)].contains(.attrChar)
    }

    static func isBlank(_ byte: UInt8) -> Bool {
        table[Int(byte)].contains(.blank)
    }

    static func isCtrl(_ byte: UInt8) -> Bool {
        table[Int(byte)].contains(.control)
    }

    static func isDomain(_ byte: UInt8) -> Bool {
        table[Int(byte)].contains(.domainSafe)
    }

    static func isFieldText(_ byte: UInt8) -> Bool {
        table[Int(byte)].contains(.fieldText)
    }

    static func isQpSafe(_ byte: UInt8) -> Bool {
        table[Int(byte)].contains(.quotedPrintableSafe)
    }

    static func isToken(_ byte: UInt8) -> Bool {
        let flags = table[Int(byte)]
        return !flags.contains(.tokenSpecial) && !flags.contains(.whitespace) && !flags.contains(.control)
    }

    static func isWhitespace(_ byte: UInt8) -> Bool {
        table[Int(byte)].contains(.whitespace)
    }

    static func isXDigit(_ byte: UInt8) -> Bool {
        table[Int(byte)].contains(.xdigit)
    }

    static func isEncodedWordSafe(_ byte: UInt8) -> Bool {
        table[Int(byte)].contains(.encodedWordSafe)
    }

    static func isEncodedPhraseSafe(_ byte: UInt8) -> Bool {
        table[Int(byte)].contains(.encodedPhraseSafe)
    }

    static func toXDigit(_ byte: UInt8) -> UInt8 {
        if byte >= 0x41 {
            if byte >= 0x61 {
                return byte &- 0x61 &+ 0x0A
            }
            return byte &- 0x41 &+ 0x0A
        }
        return byte &- 0x30
    }
}
