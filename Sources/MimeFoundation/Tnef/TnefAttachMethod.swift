//
// TnefAttachMethod.swift
//
// Ported from MimeKit (C#) to Swift.
//

/// The TNEF attach method.
public enum TnefAttachMethod: Int, Sendable {
    /// No AttachMethod specified.
    case none            = 0

    /// The attachment is a binary blob and SHOULD appear in the
    /// `TnefAttributeTag.attachData` attribute.
    case byValue         = 1

    /// The attachment is an embedded TNEF message stream and MUST appear
    /// in the `TnefPropertyId.attachData` property of the
    /// `TnefAttributeTag.attachment` attribute.
    case embeddedMessage = 5

    /// The attachment is an OLE stream and MUST appear
    /// in the `TnefPropertyId.attachData` property of the
    /// `TnefAttributeTag.attachment` attribute.
    case ole             = 6
}
