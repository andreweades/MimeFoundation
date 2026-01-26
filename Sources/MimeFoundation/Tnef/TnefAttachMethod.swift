//
// TnefAttachMethod.swift
//
// Ported from MimeKit (C#) to Swift.
//

/// The TNEF attach method.
///
/// The ``TnefAttachMethod`` enum contains a list of possible values for
/// the ``TnefPropertyId/attachMethod`` property. This property specifies
/// how the attachment data is stored in the TNEF stream.
public enum TnefAttachMethod: Int, Sendable {
    /// No AttachMethod specified.
    ///
    /// The attachment method is not specified or unknown.
    case none            = 0

    /// The attachment is a binary blob and SHOULD appear in the
    /// ``TnefAttributeTag/attachData`` attribute.
    ///
    /// This is the most common attachment method, where the attachment
    /// content is stored directly as binary data.
    case byValue         = 1

    /// The attachment is an embedded TNEF message stream and MUST appear
    /// in the ``TnefPropertyId/attachData`` property of the
    /// ``TnefAttributeTag/attachment`` attribute.
    ///
    /// This method is used when the attachment is itself another TNEF-encoded
    /// message, typically used for forwarded messages.
    case embeddedMessage = 5

    /// The attachment is an OLE stream and MUST appear
    /// in the ``TnefPropertyId/attachData`` property of the
    /// ``TnefAttributeTag/attachment`` attribute.
    ///
    /// This method is used for OLE (Object Linking and Embedding) objects,
    /// which are typically Microsoft Office documents or other embedded objects.
    case ole             = 6
}
