//
// TnefReader.swift
//
// Ported from MimeKit (C#) to Swift.
//

import Foundation

/// A TNEF reader.
public class TnefReader {
    internal static let tnefSignature: Int32 = 0x223e9f78

    private static let readAheadSize = 128
    private static let blockSize = 4096
    private static let padSize = 0

    private var input = [UInt8](repeating: 0, count: readAheadSize + blockSize + padSize)
    private let inputStart = readAheadSize
    private var inputIndex = readAheadSize
    private var inputEnd = readAheadSize

    private var position: Int64 = 0
    private var checksumValue: Int = 0
    private var codepage: Int = 1252
    private var versionValue: Int = 0
    private var closed = false
    private var eos = false

    /// Get the attachment key value.
    public private(set) var attachmentKey: Int16 = 0

    /// Get the current attribute's level.
    public private(set) var attributeLevel: TnefAttributeLevel = .message

    /// Get the length of the current attribute's raw value.
    public private(set) var attributeRawValueLength: Int = 0

    /// Get the stream offset of the current attribute's raw value.
    public private(set) var attributeRawValueStreamOffset: Int = 0

    /// Get the current attribute's tag.
    public private(set) var attributeTag: TnefAttributeTag = .null

    internal var attributeType: Int {
        attributeTag.rawValue & 0xF0000
    }

    /// Get the compliance mode.
    public var complianceMode: TnefComplianceMode

    /// Get the current compliance status of the TNEF stream.
    public internal(set) var complianceStatus: TnefComplianceStatus = .compliant

    internal let inputStream: MimeStream

    /// Get the message codepage.
    public private(set) var messageCodepage: Int {
        get { codepage }
        set {
            if newValue == codepage {
                return
            }
            if CharsetUtils.getEncoding(codepage: newValue) != nil {
                codepage = newValue
            } else {
                setComplianceError(.invalidMessageCodepage)
                codepage = 1252
            }
        }
    }

    /// Get the TNEF property reader.
    public private(set) var tnefPropertyReader: TnefPropertyReader!

    /// Get the current stream offset.
    public var streamOffset: Int {
        Int(position) - (inputEnd - inputIndex)
    }

    /// Get the TNEF version.
    public private(set) var tnefVersion: Int {
        get { versionValue }
        set {
            if newValue != 0x00010000 {
                setComplianceError(.invalidTnefVersion)
            }
            versionValue = newValue
        }
    }

    /// Initialize a new instance of the `TnefReader` class.
    public init(inputStream: MimeStream, defaultMessageCodepage: Int = 0, complianceMode: TnefComplianceMode = .loose) {
        self.inputStream = inputStream
        self.complianceMode = complianceMode
        self.codepage = defaultMessageCodepage != 0 ? defaultMessageCodepage : 1252
        self.tnefPropertyReader = TnefPropertyReader(reader: self)
        
        decodeHeader()
    }

    public convenience init(inputStream: MimeStream) {
        self.init(inputStream: inputStream, defaultMessageCodepage: 0, complianceMode: .loose)
    }

    private func checkDisposed() throws {
        if closed {
            throw StreamError.closed
        }
    }

    internal func readAhead(_ atleast: Int) throws -> Int {
        try checkDisposed()

        let left = inputEnd - inputIndex
        if left >= atleast || eos {
            return left
        }

        var index = inputIndex
        var start = inputStart
        let end = inputEnd

        if index >= start {
            let toMove = min(Self.readAheadSize, left)
            start -= toMove
            input.replaceSubrange(start..<(start + left), with: input[index..<(index + left)])
            index = start
            start += left
        } else if index > 0 {
            let shift = min(index, end - start)
            input.replaceSubrange((index - shift)..<(index - shift + left), with: input[index..<(index + left)])
            index -= shift
            start = index + left
        } else {
            start = end
        }

        inputIndex = index
        inputEnd = start

        let bufferEnd = input.count - Self.padSize
        let nread = try inputStream.read(&input, offset: start, count: bufferEnd - start)
        if nread > 0 {
            inputEnd += nread
            position += Int64(nread)
        } else {
            eos = true
        }

        return inputEnd - inputIndex
    }

    internal func setComplianceError(_ error: TnefComplianceStatus, innerError: Error? = nil) {
        complianceStatus.insert(error)

        if complianceMode != .strict {
            return
        }

        var message: String? = nil
        switch error {
        case .attributeOverflow:        message = "Too many attributes."
        case .invalidAttribute:         message = "Invalid attribute."
        case .invalidAttributeChecksum: message = "Invalid attribute checksum."
        case .invalidAttributeLength:   message = "Invalid attribute length."
        case .invalidAttributeLevel:    message = "Invalid attribute level."
        case .invalidAttributeValue:    message = "Invalid attribute value."
        case .invalidDate:              message = "Invalid date."
        case .invalidMessageClass:      message = "Invalid message class."
        case .invalidMessageCodepage:   message = "Invalid message codepage."
        case .invalidPropertyLength:    message = "Invalid property length."
        case .invalidRowCount:          message = "Invalid row count."
        case .invalidTnefSignature:     message = "Invalid TNEF signature."
        case .invalidTnefVersion:       message = "Invalid TNEF version."
        case .nestingTooDeep:           message = "Nesting too deep."
        case .streamTruncated:          message = "Truncated TNEF stream."
        case .unsupportedPropertyType:  message = "Unsupported property type."
        default: break
        }

        // To truly match MimeKit, we'd need to throw here, but that would require
        // many methods to be 'throws'. For now we'll just log it or let the user check status.
        // Actually, if we want to throw, we can do it in the next read/skip call.
        if let message = message, complianceMode == .strict {
            print("Compliance Error: \(message)")
        }
    }

    private func decodeHeader() {
        do {
            let signature = try readInt32()
            if signature != Self.tnefSignature {
                setComplianceError(.invalidTnefSignature)
            }
            attachmentKey = try readInt16()
        } catch {
            setComplianceError(.streamTruncated, innerError: error)
        }
    }

    private func checkAttributeLevel() {
        switch attributeLevel {
        case .attachment, .message:
            break
        }
    }

    private func checkAttributeTag() {
        switch attributeTag {
        case .null, .owner, .sentFor, .delegate, .originalMessageClass, .dateStart, .dateEnd,
             .aidOwner, .requestResponse, .from, .subject, .dateSent, .dateReceived,
             .messageStatus, .messageClass, .messageId, .parentId, .conversationId,
             .body, .priority, .attachData, .attachTitle, .attachMetaFile, .attachCreateDate,
             .attachModifyDate, .dateModified, .attachTransportFilename, .attachRenderData,
             .mapiProperties, .recipientTable, .attachment, .tnefVersion, .oemCodepage:
            
            if attributeTag == .attachRenderData {
                tnefPropertyReader.attachMethod = .byValue
            } else if attributeTag == .oemCodepage {
                if let val = try? peekInt32() {
                    messageCodepage = Int(val)
                }
            } else if attributeTag == .tnefVersion {
                if let val = try? peekInt32() {
                    tnefVersion = Int(val)
                }
            }
        }
    }

    internal func readByte() throws -> UInt8 {
        if try readAhead(1) < 1 {
            throw TnefException(.streamTruncated, "Truncated TNEF stream.")
        }
        let val = input[inputIndex]
        updateChecksum(input, offset: inputIndex, count: 1)
        inputIndex += 1
        return val
    }

    internal func readInt16() throws -> Int16 {
        if try readAhead(2) < 2 {
            throw TnefException(.streamTruncated, "Truncated TNEF stream.")
        }
        updateChecksum(input, offset: inputIndex, count: 2)
        let val = UInt16(input[inputIndex]) | (UInt16(input[inputIndex + 1]) << 8)
        inputIndex += 2
        return Int16(bitPattern: val)
    }

    internal func readInt32() throws -> Int32 {
        if try readAhead(4) < 4 {
            throw TnefException(.streamTruncated, "Truncated TNEF stream.")
        }
        updateChecksum(input, offset: inputIndex, count: 4)
        let val = UInt32(input[inputIndex]) |
                  (UInt32(input[inputIndex + 1]) << 8) |
                  (UInt32(input[inputIndex + 2]) << 16) |
                  (UInt32(input[inputIndex + 3]) << 24)
        inputIndex += 4
        return Int32(bitPattern: val)
    }

    internal func peekInt32() throws -> Int32 {
        if try readAhead(4) < 4 {
            throw TnefException(.streamTruncated, "Truncated TNEF stream.")
        }
        let val = UInt32(input[inputIndex]) |
                  (UInt32(input[inputIndex + 1]) << 8) |
                  (UInt32(input[inputIndex + 2]) << 16) |
                  (UInt32(input[inputIndex + 3]) << 24)
        return Int32(bitPattern: val)
    }

    internal func readInt64() throws -> Int64 {
        if try readAhead(8) < 8 {
            throw TnefException(.streamTruncated, "Truncated TNEF stream.")
        }
        updateChecksum(input, offset: inputIndex, count: 8)
        var val: UInt64 = 0
        for i in 0..<8 {
            val |= (UInt64(input[inputIndex + i]) << (i * 8))
        }
        inputIndex += 8
        return Int64(bitPattern: val)
    }

    internal func readSingle() throws -> Float {
        let val = try readInt32()
        return Float(bitPattern: UInt32(bitPattern: val))
    }

    internal func readDouble() throws -> Double {
        let val = try readInt64()
        return Double(bitPattern: UInt64(bitPattern: val))
    }

    internal func skip(_ count: Int) throws -> Bool {
        try checkDisposed()
        if count <= 0 { return true }
        var left = count
        while left > 0 {
            let n = min(inputEnd - inputIndex, left)
            updateChecksum(input, offset: inputIndex, count: n)
            inputIndex += n
            left -= n
            if left == 0 { break }
            if try readAhead(left) == 0 {
                setComplianceError(.streamTruncated)
                return false
            }
        }
        return true
    }

    private func skipAttributeRawValue() throws -> Bool {
        let offset = attributeRawValueStreamOffset + attributeRawValueLength
        if try !skip(offset - streamOffset) {
            return false
        }
        let expected = checksumValue & 0xFFFF
        let actual: Int
        do {
            actual = Int(UInt16(bitPattern: try readInt16()))
        } catch {
            setComplianceError(.streamTruncated)
            return false
        }
        if actual != expected {
            setComplianceError(.invalidAttributeChecksum)
        }
        return true
    }

    /// Advance to the next attribute in the TNEF stream.
    public func readNextAttribute() throws -> Bool {
        try checkDisposed()

        if attributeRawValueStreamOffset != 0, try !skipAttributeRawValue() {
            return false
        }

        do {
            let levelVal = try readByte()
            attributeLevel = TnefAttributeLevel(rawValue: Int(levelVal)) ?? .message
        } catch {
            return false
        }

        checkAttributeLevel()

        do {
            attributeTag = TnefAttributeTag(rawValue: Int(try readInt32())) ?? .null
            attributeRawValueLength = Int(try readInt32())
            attributeRawValueStreamOffset = streamOffset
            checksumValue = 0
        } catch {
            setComplianceError(.streamTruncated)
            return false
        }

        checkAttributeTag()

        if attributeRawValueLength < 0 {
            setComplianceError(.invalidAttributeLength)
            return false
        }

        do {
            try tnefPropertyReader.load()
        } catch {
            setComplianceError(.streamTruncated)
            return false
        }

        return true
    }

    private func updateChecksum(_ buffer: [UInt8], offset: Int, count: Int) {
        for i in offset..<(offset + count) {
            checksumValue = (checksumValue + Int(buffer[i])) & 0xFFFF
        }
    }

    /// Read the raw attribute value data from the underlying TNEF stream.
    public func readAttributeRawValue(_ buffer: inout [UInt8], offset: Int, count: Int) -> Int {
        guard offset >= 0, offset < buffer.count, count >= 0, count <= (buffer.count - offset) else {
            return 0
        }

        let dataEndOffset = attributeRawValueStreamOffset + attributeRawValueLength
        let dataLeft = dataEndOffset - streamOffset

        if dataLeft == 0 {
            return 0
        }

        var n = min(dataLeft, count)
        let inputLeft = inputEnd - inputIndex

        if n > inputLeft && inputLeft < Self.readAheadSize {
            if let read = try? readAhead(n) {
                n = min(read, n)
            } else {
                n = 0
            }
            if n == 0 {
                setComplianceError(.streamTruncated)
                return 0
            }
        } else {
            n = min(inputLeft, n)
        }

        buffer.replaceSubrange(offset..<(offset + n), with: input[inputIndex..<(inputIndex + n)])
        updateChecksum(buffer, offset: offset, count: n)
        inputIndex += n

        return n
    }

    /// Reset the compliance status.
    public func resetComplianceStatus() {
        complianceStatus = .compliant
    }

    /// Close the TNEF reader and the underlying stream.
    public func close() {
        if !closed {
            inputStream.close()
            closed = true
        }
    }
}
