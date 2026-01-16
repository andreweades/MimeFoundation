//
// ByteClassification.swift
//
// Ported from MimeKit (C#) to Swift.
//

enum ByteClassification {
    private static let attributeSpecials: Set<UInt8> = [0x2A, 0x27, 0x25]
    private static let tokenSpecials: Set<UInt8> = [
        0x28, 0x29, 0x3C, 0x3E,
        0x40, 0x2C, 0x3B, 0x3A,
        0x5C, 0x22, 0x2F, 0x5B,
        0x5D, 0x3F, 0x3D
    ]

    static func isAttr(_ byte: UInt8) -> Bool {
        if byte <= 0x20 || byte >= 0x7F {
            return false
        }

        if attributeSpecials.contains(byte) || tokenSpecials.contains(byte) {
            return false
        }

        return true
    }

    static func isXDigit(_ byte: UInt8) -> Bool {
        switch byte {
        case 0x30...0x39, 0x41...0x46, 0x61...0x66:
            return true
        default:
            return false
        }
    }

    static func toXDigit(_ byte: UInt8) -> UInt8 {
        switch byte {
        case 0x30...0x39:
            return byte - 0x30
        case 0x41...0x46:
            return byte - 0x41 + 10
        case 0x61...0x66:
            return byte - 0x61 + 10
        default:
            return 0
        }
    }
}
