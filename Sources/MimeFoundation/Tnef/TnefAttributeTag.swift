//
// TnefAttributeTag.swift
//
// Ported from MimeKit (C#) to Swift.
//

enum TnefAttributeType: Int {
    case triples = 0x00000000
    case string  = 0x00010000
    case text    = 0x00020000
    case date    = 0x00030000
    case short   = 0x00040000
    case long    = 0x00050000
    case byte    = 0x00060000
    case word    = 0x00070000
    case dword   = 0x00080000
    case max     = 0x00090000
}

/// A TNEF attribute tag.
public enum TnefAttributeTag: Int, Sendable {
    /// A Null TNEF attribute.
    case null                    = 0x00000000 // TnefAttributeType.triples | 0x0000

    /// The Owner TNEF attribute.
    case owner                   = 0x00060000 // TnefAttributeType.byte    | 0x0000

    /// The SentFor TNEF attribute.
    case sentFor                 = 0x00060001 // TnefAttributeType.byte    | 0x0001

    /// The Delegate TNEF attribute.
    case delegate                = 0x00060002 // TnefAttributeType.byte    | 0x0002

    /// The OriginalMessageClass TNEF attribute.
    case originalMessageClass    = 0x00070006 // TnefAttributeType.word    | 0x0006

    /// The DateStart TNEF attribute.
    case dateStart               = 0x00030006 // TnefAttributeType.date    | 0x0006

    /// The DateEnd TNEF attribute.
    case dateEnd                 = 0x00030007 // TnefAttributeType.date    | 0x0007

    /// The AidOwner TNEF attribute.
    case aidOwner                = 0x00050008 // TnefAttributeType.long    | 0x0008

    /// The RequestResponse TNEF attribute.
    case requestResponse         = 0x00040009 // TnefAttributeType.short   | 0x0009

    /// The From TNEF attribute.
    case from                    = 0x00008000 // TnefAttributeType.triples | 0x8000

    /// The Subject TNEF attribute.
    case subject                 = 0x00018004 // TnefAttributeType.string  | 0x8004

    /// The DateSent TNEF attribute.
    case dateSent                = 0x00038005 // TnefAttributeType.date    | 0x8005

    /// The DateReceived TNEF attribute.
    case dateReceived            = 0x00038006 // TnefAttributeType.date    | 0x8006

    /// The MessageStatus TNEF attribute.
    case messageStatus           = 0x00068007 // TnefAttributeType.byte    | 0x8007

    /// The MessageClass TNEF attribute.
    case messageClass            = 0x00078008 // TnefAttributeType.word    | 0x8008

    /// The MessageId TNEF attribute.
    case messageId               = 0x00018009 // TnefAttributeType.string  | 0x8009

    /// The ParentId TNEF attribute.
    case parentId                = 0x0001800A // TnefAttributeType.string  | 0x800A

    /// The ConversationId TNEF attribute.
    case conversationId          = 0x0001800B // TnefAttributeType.string  | 0x800B

    /// The Body TNEF attribute.
    case body                    = 0x0002800C // TnefAttributeType.text    | 0x800C

    /// The Priority TNEF attribute.
    case priority                = 0x0004800D // TnefAttributeType.short   | 0x800D

    /// The AttachData TNEF attribute.
    case attachData              = 0x0006800F // TnefAttributeType.byte    | 0x800F

    /// The AttachTitle TNEF attribute.
    case attachTitle             = 0x00018010 // TnefAttributeType.string  | 0x8010

    /// The AttachMetaFile TNEF attribute.
    case attachMetaFile          = 0x00068011 // TnefAttributeType.byte    | 0x8011

    /// The AttachCreateDate TNEF attribute.
    case attachCreateDate        = 0x00038012 // TnefAttributeType.date    | 0x8012

    /// The AttachModifyDate TNEF attribute.
    case attachModifyDate        = 0x00038013 // TnefAttributeType.date    | 0x8013

    /// The DateModified TNEF attribute.
    case dateModified            = 0x00038020 // TnefAttributeType.date    | 0x8020

    /// The AttachTransportFilename TNEF attribute.
    case attachTransportFilename = 0x00069001 // TnefAttributeType.byte    | 0x9001

    /// The AttachRenderData TNEF attribute.
    case attachRenderData        = 0x00069002 // TnefAttributeType.byte    | 0x9002

    /// The MapiProperties TNEF attribute.
    case mapiProperties          = 0x00069003 // TnefAttributeType.byte    | 0x9003

    /// The RecipientTable TNEF attribute.
    case recipientTable          = 0x00069004 // TnefAttributeType.byte    | 0x9004

    /// The Attachment TNEF attribute.
    case attachment              = 0x00069005 // TnefAttributeType.byte    | 0x9005

    /// The TnefVersion TNEF attribute.
    case tnefVersion             = 0x00089006 // TnefAttributeType.dword   | 0x9006

    /// The OemCodepage TNEF attribute.
    case oemCodepage             = 0x00069007 // TnefAttributeType.byte    | 0x9007
}
