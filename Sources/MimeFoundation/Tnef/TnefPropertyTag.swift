//
// TnefPropertyTag.swift
//
// Ported from MimeKit (C#) to Swift.
//

/// A TNEF property tag.
public struct TnefPropertyTag: Equatable, Sendable {
    public let id: TnefPropertyId
    public let type: TnefPropertyType
    public let isMultiValued: Bool

    public init(_ id: TnefPropertyId, _ type: TnefPropertyType, _ isMultiValued: Bool = false) {
        self.id = id
        self.type = type
        self.isMultiValued = isMultiValued
    }

    public init(rawValue: Int32) {
        let typeValue = Int16(truncatingIfNeeded: rawValue & 0xFFFF)
        let idValue = Int16(truncatingIfNeeded: (rawValue >> 16) & 0xFFFF)
        
        self.isMultiValued = (typeValue & 0x1000) != 0
        self.type = TnefPropertyType(rawValue: typeValue & ~0x1000) ?? .unspecified
        self.id = TnefPropertyId(rawValue: idValue)
    }

    public var isNamed: Bool {
        let val = Int(id.rawValue)
        // Named properties have IDs in the range 0x8000 to 0xFFFE
        // 0x8000 as short is -32768. 0xFFFE as short is -2.
        return val >= Int(Int16(bitPattern: 0x8000)) && val <= Int(Int16(bitPattern: 0xFFFE))
    }

    public var valueTnefType: TnefPropertyType {
        type
    }

    public var rawValue: Int32 {
        let typeValue = Int32(type.rawValue) | (isMultiValued ? 0x1000 : 0)
        return (Int32(id.rawValue) << 16) | typeValue
    }

    public static let null = TnefPropertyTag(.null, .null)
}
