//
// TnefNameId.swift
//
// Ported from MimeKit (C#) to Swift.
//

import Foundation

/// A TNEF name identifier.
public struct TnefNameId: Equatable, Sendable {
    public let kind: TnefNameIdKind
    public let name: String?
    public let guid: UUID
    public let id: Int32

    /// Initialize a new instance of the `TnefNameId` struct.
    public init(propertySetGuid: UUID, id: Int32) {
        self.kind = .id
        self.guid = propertySetGuid
        self.id = id
        self.name = nil
    }

    /// Initialize a new instance of the `TnefNameId` struct.
    public init(propertySetGuid: UUID, name: String) {
        self.kind = .name
        self.guid = propertySetGuid
        self.name = name
        self.id = 0
    }

    public init() {
        self.kind = .id
        self.guid = UUID(uuidString: "00000000-0000-0000-0000-000000000000")!
        self.id = 0
        self.name = nil
    }
}
