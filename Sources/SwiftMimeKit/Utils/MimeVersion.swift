//
// MimeVersion.swift
//
// Ported from MimeKit (C#) to Swift.
//

public struct MimeVersion: Equatable, CustomStringConvertible {
    public let components: [Int]

    public init?(components: [Int]) {
        guard (2...4).contains(components.count) else {
            return nil
        }
        self.components = components
    }

    public var description: String {
        components.map(String.init).joined(separator: ".")
    }
}
