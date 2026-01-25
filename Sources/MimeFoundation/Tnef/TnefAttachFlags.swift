//
// TnefAttachFlags.swift
//
// Ported from MimeKit (C#) to Swift.
//

import Foundation

/// The TNEF attach flags.
public struct TnefAttachFlags: OptionSet, Sendable {
    public let rawValue: Int

    public init(rawValue: Int) {
        self.rawValue = rawValue
    }

    /// No AttachFlags set.
    public static let none            = TnefAttachFlags([])

    /// The attachment is invisible in HTML bodies.
    public static let invisibleInHtml = TnefAttachFlags(rawValue: 1)

    /// The attachment is invisible in RTF bodies.
    public static let invisibleInRtf  = TnefAttachFlags(rawValue: 2)

    /// The attachment is referenced (and rendered) by the HTML body.
    public static let renderedInBody  = TnefAttachFlags(rawValue: 4)
}
