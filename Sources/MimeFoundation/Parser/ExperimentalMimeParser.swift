//
// ExperimentalMimeParser.swift
//
// Ported from MimeKit (C#) to Swift.
//

import Foundation

open class ExperimentalMimeParser: MimeReader {
    public private(set) var mboxMarkerOffset: Int = -1
    public private(set) var mboxMarker: String?

    private var captureTopLevel = false
    private var messageDepth = 0
    private var capturedRange: (start: Int, end: Int)?

    public init(_ stream: MimeStream, _ format: MimeFormat = .default, persistent: Bool = false) throws {
        try super.init(stream, format)
    }

    public init(_ options: ParserOptions, _ stream: MimeStream, _ format: MimeFormat = .default, persistent: Bool = false) throws {
        try super.init(options, stream, format)
    }

    public func parseHeaders() throws -> HeaderList {
        if isEndOfStream {
            return HeaderList()
        }
        let start = internalOffset
        if start >= rawData.count {
            isEndOfStream = true
            return HeaderList()
        }
        let bytes = Array(rawData[start..<rawData.count])
        let (headers, bodyBytes) = MimeMessage.parseHeaders(bytes)
        internalOffset = start + (bytes.count - bodyBytes.count)
        if internalOffset >= rawData.count {
            isEndOfStream = true
        }
        return headers
    }

    public func parseHeadersAsync() async throws -> HeaderList {
        try parseHeaders()
    }

    public func parseMessage() throws -> MimeMessage {
        capturedRange = nil
        captureTopLevel = true
        messageDepth = 0
        try readMessage()
        captureTopLevel = false
        guard let range = capturedRange else {
            throw ParseException("Failed to parse message.", tokenIndex: internalOffset, errorIndex: internalOffset)
        }
        let bytes = Array(rawData[range.start..<range.end])
        let stream = MemoryStream(bytes, writable: false)
        return try MimeMessage.load(options, stream)
    }

    public func parseMessageAsync() async throws -> MimeMessage {
        try parseMessage()
    }

    public func parseEntity() throws -> MimeEntity {
        if isEndOfStream {
            throw ParseException("Failed to parse entity.", tokenIndex: internalOffset, errorIndex: internalOffset)
        }
        let bytes = Array(rawData[internalOffset..<rawData.count])
        let stream = MemoryStream(bytes, writable: false)
        let entity = try MimeEntity.load(options, stream)
        internalOffset = rawData.count
        isEndOfStream = true
        return entity
    }

    public func parseEntityAsync() async throws -> MimeEntity {
        try parseEntity()
    }

    open override func onMboxMarkerRead(_ marker: [UInt8], startIndex: Int, count: Int, beginOffset: Int, lineNumber: Int) {
        mboxMarkerOffset = beginOffset
        mboxMarker = String(bytes: marker[startIndex..<startIndex + count], encoding: .utf8)
        super.onMboxMarkerRead(marker, startIndex: startIndex, count: count, beginOffset: beginOffset, lineNumber: lineNumber)
    }

    open override func onMimeMessageBegin(_ beginOffset: Int, _ beginLineNumber: Int) {
        if captureTopLevel && messageDepth == 0 {
            capturedRange = (start: beginOffset, end: beginOffset)
        }
        messageDepth += 1
        super.onMimeMessageBegin(beginOffset, beginLineNumber)
    }

    open override func onMimeMessageEnd(_ beginOffset: Int, _ beginLineNumber: Int, _ headersEndOffset: Int, _ endOffset: Int, _ lines: Int) {
        messageDepth = max(0, messageDepth - 1)
        if captureTopLevel && messageDepth == 0 {
            capturedRange = (start: beginOffset, end: endOffset)
        }
        super.onMimeMessageEnd(beginOffset, beginLineNumber, headersEndOffset, endOffset, lines)
    }
}
