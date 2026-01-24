//
// MimeReader.swift
//
// Ported from MimeKit (C#) to Swift.
//

import Foundation

public enum MimeReaderError: Error, Equatable {
    case nilStream
}

internal struct LineInfo {
    let start: Int
    let end: Int
    let breakLength: Int
}

internal struct LineMap {
    let lines: [LineInfo]

    init(_ data: [UInt8]) {
        var items: [LineInfo] = []
        var index = 0
        var lineStart = 0
        while index < data.count {
            let byte = data[index]
            if byte == 0x0D {
                if index + 1 < data.count, data[index + 1] == 0x0A {
                    items.append(LineInfo(start: lineStart, end: index, breakLength: 2))
                    index += 2
                    lineStart = index
                    continue
                } else {
                    items.append(LineInfo(start: lineStart, end: index, breakLength: 1))
                    index += 1
                    lineStart = index
                    continue
                }
            }
            if byte == 0x0A {
                items.append(LineInfo(start: lineStart, end: index, breakLength: 1))
                index += 1
                lineStart = index
                continue
            }
            index += 1
        }
        if lineStart <= data.count {
            items.append(LineInfo(start: lineStart, end: data.count, breakLength: 0))
        }
        self.lines = items
    }

    func lineNumber(for offset: Int) -> Int {
        if lines.isEmpty {
            return 1
        }
        let clamped = max(0, min(offset, lines.last?.end ?? 0))
        var low = 0
        var high = lines.count - 1
        var result = 0
        while low <= high {
            let mid = (low + high) / 2
            if lines[mid].start <= clamped {
                result = mid
                low = mid + 1
            } else {
                high = mid - 1
            }
        }
        return result + 1
    }

    func lineIndex(containing offset: Int) -> Int {
        if lines.isEmpty {
            return 0
        }
        let clamped = max(0, min(offset, (lines.last?.end ?? 0) - 1))
        var low = 0
        var high = lines.count - 1
        var result = 0
        while low <= high {
            let mid = (low + high) / 2
            if lines[mid].start <= clamped {
                result = mid
                low = mid + 1
            } else {
                high = mid - 1
            }
        }
        return result
    }

    func lineCount(from startOffset: Int, to endOffset: Int) -> Int {
        if endOffset <= startOffset {
            return 0
        }
        let startIndex = lineIndex(containing: startOffset)
        let endIndex = lineIndex(containing: endOffset - 1)
        return endIndex - startIndex + 1
    }
}

internal struct MboxMarker {
    let start: Int
    let lineIndex: Int
    let lineEnd: Int
    let lineBreakLength: Int
}

open class MimeReader {
    public var options: ParserOptions

    public private(set) var format: MimeFormat
    public internal(set) var isEndOfStream: Bool = false
    public var position: Int { currentOffset }

    private var data: [UInt8] = []
    private var lineMap = LineMap([])
    private var mboxMarkers: [MboxMarker] = []
    private var currentOffset: Int = 0
    private var currentMarkerIndex: Int = 0

    internal var rawData: [UInt8] {
        data
    }

    internal var internalOffset: Int {
        get { currentOffset }
        set { currentOffset = newValue }
    }

    public init(_ stream: MimeStream, _ format: MimeFormat = .default) throws {
        self.options = ParserOptions.default
        self.format = format
        try setStream(stream, format)
    }

    public init(_ options: ParserOptions, _ stream: MimeStream, _ format: MimeFormat = .default) throws {
        self.options = options
        self.format = format
        try setStream(stream, format)
    }

    public func setStream(_ stream: MimeStream, _ format: MimeFormat = .default) throws {
        self.format = format
        self.data = try readAllBytes(from: stream)
        self.lineMap = LineMap(data)
        self.currentOffset = 0
        self.currentMarkerIndex = 0
        self.isEndOfStream = data.isEmpty
        if format == .mbox {
            self.mboxMarkers = scanMboxMarkers()
        } else {
            self.mboxMarkers = []
        }
    }

    public func readMessage() throws {
        if isEndOfStream {
            return
        }
        switch format {
        case .entity:
            if currentOffset > 0 {
                isEndOfStream = true
                return
            }
            try parseMessageRange(start: 0, end: data.count, marker: nil)
            currentOffset = data.count
            isEndOfStream = true
        case .mbox:
            try parseNextMboxMessage()
        }
    }

    public func readMessageAsync() async throws {
        try readMessage()
    }

    // MARK: - Events (override points)

    open func onMboxMarkerRead(_ marker: [UInt8], startIndex: Int, count: Int, beginOffset: Int, lineNumber: Int) {
    }

    open func onMimeMessageBegin(_ beginOffset: Int, _ beginLineNumber: Int) {
    }

    open func onMimeMessageEnd(_ beginOffset: Int, _ beginLineNumber: Int, _ headersEndOffset: Int, _ endOffset: Int, _ lines: Int) {
    }

    open func onMultipartBegin(_ contentType: ContentType, _ beginOffset: Int, _ beginLineNumber: Int) {
    }

    open func onMultipartEnd(_ contentType: ContentType, _ beginOffset: Int, _ beginLineNumber: Int, _ headersEndOffset: Int, _ endOffset: Int, _ lines: Int) {
    }

    open func onMessagePartBegin(_ contentType: ContentType, _ beginOffset: Int, _ beginLineNumber: Int) {
    }

    open func onMessagePartEnd(_ contentType: ContentType, _ beginOffset: Int, _ beginLineNumber: Int, _ headersEndOffset: Int, _ endOffset: Int, _ lines: Int) {
    }

    open func onMimePartBegin(_ contentType: ContentType, _ beginOffset: Int, _ beginLineNumber: Int) {
    }

    open func onMimePartEnd(_ contentType: ContentType, _ beginOffset: Int, _ beginLineNumber: Int, _ headersEndOffset: Int, _ endOffset: Int, _ lines: Int) {
    }
}

// MARK: - Parsing helpers

private extension MimeReader {
    func readAllBytes(from stream: MimeStream) throws -> [UInt8] {
        var buffer = [UInt8](repeating: 0, count: 4096)
        var data: [UInt8] = []
        _ = try stream.seek(0, origin: .begin)
        while true {
            let read = try stream.read(&buffer, offset: 0, count: buffer.count)
            if read == 0 {
                break
            }
            data.append(contentsOf: buffer[0..<read])
        }
        return data
    }

    func scanMboxMarkers() -> [MboxMarker] {
        let markerBytes = Array("From ".utf8)
        var markers: [MboxMarker] = []
        for (index, line) in lineMap.lines.enumerated() {
            let length = line.end - line.start
            if length < markerBytes.count {
                continue
            }
            let slice = data[line.start..<line.end]
            if slice.starts(with: markerBytes) {
                markers.append(MboxMarker(start: line.start, lineIndex: index, lineEnd: line.end, lineBreakLength: line.breakLength))
            }
        }
        return markers
    }

    func parseNextMboxMessage() throws {
        if currentOffset >= data.count {
            isEndOfStream = true
            return
        }

        var markerIndex = currentMarkerIndex
        while markerIndex < mboxMarkers.count && mboxMarkers[markerIndex].start < currentOffset {
            markerIndex += 1
        }
        if markerIndex >= mboxMarkers.count {
            if currentOffset == 0 {
                try parseMessageRange(start: 0, end: data.count, marker: nil)
                currentOffset = data.count
                isEndOfStream = true
            } else {
                isEndOfStream = true
            }
            return
        }

        let marker = mboxMarkers[markerIndex]
        let markerLineNumber = marker.lineIndex + 1
        let markerBytes = Array(data[marker.start..<marker.lineEnd])
        onMboxMarkerRead(markerBytes, startIndex: 0, count: markerBytes.count, beginOffset: marker.start, lineNumber: markerLineNumber)

        let messageStart = marker.lineEnd + marker.lineBreakLength
        let messageLineNumber = lineMap.lineNumber(for: messageStart)

        var messageEnd = data.count
        var nextMarkerIndex = markerIndex + 1

        if options.respectContentLength, let contentLength = parseContentLength(startOffset: messageStart) {
            let headerEndIndex = headerBodySeparatorOffset(in: data, startOffset: messageStart) ?? messageStart
            let bodyStart = headerEndIndex
            let contentEnd = min(bodyStart + contentLength, data.count)
            while nextMarkerIndex < mboxMarkers.count && mboxMarkers[nextMarkerIndex].start < contentEnd {
                nextMarkerIndex += 1
            }
            if nextMarkerIndex < mboxMarkers.count {
                let nextMarker = mboxMarkers[nextMarkerIndex]
                messageEnd = adjustedEndOffset(beforeLineIndex: nextMarker.lineIndex)
            } else {
                messageEnd = data.count
            }
        } else if nextMarkerIndex < mboxMarkers.count {
            let nextMarker = mboxMarkers[nextMarkerIndex]
            messageEnd = adjustedEndOffset(beforeLineIndex: nextMarker.lineIndex)
        }

        if messageStart <= messageEnd {
            try parseMessageRange(start: messageStart, end: messageEnd, marker: (marker.start, messageLineNumber))
        }

        currentOffset = messageEnd
        currentMarkerIndex = nextMarkerIndex

        if currentOffset >= data.count {
            isEndOfStream = true
        }
    }

    func parseMessageRange(start: Int, end: Int, marker: (offset: Int, lineNumber: Int)?) throws {
        let beginLineNumber = lineMap.lineNumber(for: start)
        onMimeMessageBegin(start, beginLineNumber)

        let messageBytes = Array(data[start..<end])
        let (headers, bodyBytes) = MimeMessage.parseHeaders(messageBytes)
        let headerEndOffset = start + (messageBytes.count - bodyBytes.count)
        let messageEndOffset = end

        if let contentType = resolveContentType(headers: headers, parent: nil) {
            let bodyStartOffset = headerEndOffset
            let bodyLineNumber = lineMap.lineNumber(for: bodyStartOffset)
            try parseEntity(
                contentType: contentType,
                parentContentType: nil,
                headers: headers,
                bodyBytes: bodyBytes,
                baseOffset: start,
                bodyStartOffset: bodyStartOffset,
                bodyEndOffset: messageEndOffset,
                bodyLineNumber: bodyLineNumber,
                depth: 0
            )
        }

        let lines = lineMap.lineCount(from: headerEndOffset, to: messageEndOffset)
        onMimeMessageEnd(start, beginLineNumber, headerEndOffset, messageEndOffset, lines)
    }

    func parseEntity(
        contentType: ContentType,
        parentContentType: ContentType?,
        headers: HeaderList,
        bodyBytes: [UInt8],
        baseOffset: Int,
        bodyStartOffset: Int,
        bodyEndOffset: Int,
        bodyLineNumber: Int,
        depth: Int
    ) throws {
        let beginOffset = baseOffset
        let beginLineNumber = lineMap.lineNumber(for: beginOffset)
        let headerEndOffset = bodyStartOffset
        let lines = lineMap.lineCount(from: headerEndOffset, to: bodyEndOffset)

        let encoding = parseContentEncoding(headers: headers)

        if depth >= options.maxMimeDepth {
            onMimePartBegin(contentType, beginOffset, beginLineNumber)
            onMimePartEnd(contentType, beginOffset, beginLineNumber, headerEndOffset, bodyEndOffset, lines)
            return
        }

        if isMultipart(contentType), let boundary = contentType.boundary {
            onMultipartBegin(contentType, beginOffset, beginLineNumber)
            try parseMultipart(boundary: boundary, parentContentType: contentType, bodyStartOffset: bodyStartOffset, bodyEndOffset: bodyEndOffset, depth: depth + 1)
            onMultipartEnd(contentType, beginOffset, beginLineNumber, headerEndOffset, bodyEndOffset, lines)
            return
        }

        if isMessagePart(contentType, encoding: encoding) {
            onMessagePartBegin(contentType, beginOffset, beginLineNumber)
            try parseNestedMessage(bodyStartOffset: bodyStartOffset, bodyEndOffset: bodyEndOffset, depth: depth + 1)
            onMessagePartEnd(contentType, beginOffset, beginLineNumber, headerEndOffset, bodyEndOffset, lines)
            return
        }

        onMimePartBegin(contentType, beginOffset, beginLineNumber)
        onMimePartEnd(contentType, beginOffset, beginLineNumber, headerEndOffset, bodyEndOffset, lines)
    }

    func parseNestedMessage(bodyStartOffset: Int, bodyEndOffset: Int, depth: Int) throws {
        let beginLineNumber = lineMap.lineNumber(for: bodyStartOffset)
        onMimeMessageBegin(bodyStartOffset, beginLineNumber)
        let bytes = Array(data[bodyStartOffset..<bodyEndOffset])
        let (headers, bodyBytes) = MimeMessage.parseHeaders(bytes)
        let headerEndOffset = bodyStartOffset + (bytes.count - bodyBytes.count)
        if let contentType = resolveContentType(headers: headers, parent: nil) {
            let bodyLineNumber = lineMap.lineNumber(for: headerEndOffset)
            try parseEntity(
                contentType: contentType,
                parentContentType: nil,
                headers: headers,
                bodyBytes: bodyBytes,
                baseOffset: bodyStartOffset,
                bodyStartOffset: headerEndOffset,
                bodyEndOffset: bodyEndOffset,
                bodyLineNumber: bodyLineNumber,
                depth: depth
            )
        }
        let lines = lineMap.lineCount(from: headerEndOffset, to: bodyEndOffset)
        onMimeMessageEnd(bodyStartOffset, beginLineNumber, headerEndOffset, bodyEndOffset, lines)
    }

    func parseMultipart(boundary: String, parentContentType: ContentType, bodyStartOffset: Int, bodyEndOffset: Int, depth: Int) throws {
        let boundaryBytes = Array(("--" + boundary).utf8)
        var currentPartStart: Int? = nil

        let startLineIndex = lineMap.lineIndex(containing: bodyStartOffset)
        var lineIndex = startLineIndex
        while lineIndex < lineMap.lines.count {
            let line = lineMap.lines[lineIndex]
            if line.start >= bodyEndOffset {
                break
            }
            let lineSlice = data[line.start..<min(line.end, bodyEndOffset)]
            if isBoundaryLine(lineSlice, boundary: boundaryBytes) {
                if let start = currentPartStart {
                    let partEnd = adjustedEndOffset(beforeLineIndex: lineIndex)
                    try parseChildPart(startOffset: start, endOffset: partEnd, parentContentType: parentContentType, depth: depth)
                }
                if isEndBoundaryLine(lineSlice, boundary: boundaryBytes) {
                    currentPartStart = nil
                    break
                }
                currentPartStart = line.end + line.breakLength
            }
            lineIndex += 1
        }

        if let start = currentPartStart, start <= bodyEndOffset {
            try parseChildPart(startOffset: start, endOffset: bodyEndOffset, parentContentType: parentContentType, depth: depth)
        }
    }

    func parseChildPart(startOffset: Int, endOffset: Int, parentContentType: ContentType, depth: Int) throws {
        if startOffset > endOffset {
            return
        }
        let bytes = Array(data[startOffset..<endOffset])
        let headers: HeaderList
        let bodyBytes: [UInt8]
        let headerEndOffset: Int
        if bytes.count == 1, bytes[0] == 0x0A || bytes[0] == 0x0D {
            headers = HeaderList()
            bodyBytes = []
            headerEndOffset = startOffset + 1
        } else {
            let parsed = MimeMessage.parseHeaders(bytes)
            headers = parsed.0
            bodyBytes = parsed.1
            headerEndOffset = startOffset + (bytes.count - bodyBytes.count)
        }
        let bodyLineNumber = lineMap.lineNumber(for: headerEndOffset)
        if let contentType = resolveContentType(headers: headers, parent: parentContentType) {
            try parseEntity(
                contentType: contentType,
                parentContentType: parentContentType,
                headers: headers,
                bodyBytes: bodyBytes,
                baseOffset: startOffset,
                bodyStartOffset: headerEndOffset,
                bodyEndOffset: endOffset,
                bodyLineNumber: bodyLineNumber,
                depth: depth
            )
        }
    }

    func resolveContentType(headers: HeaderList, parent: ContentType?) -> ContentType? {
        if let value = headers[.contentType] ?? headers.first(where: { $0.field.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() == "content-type" })?.value {
            if let parsed = try? ContentType(parsing: value) {
                return parsed
            }
            return try? ContentType("application", "octet-stream")
        }
        if let parent, (try? parent.isMimeType("multipart", "digest")) == true {
            return try? ContentType("message", "rfc822")
        }
        return try? ContentType("text", "plain")
    }

    func parseContentEncoding(headers: HeaderList) -> ContentEncoding {
        guard let value = headers[.contentTransferEncoding] else {
            return .default
        }
        switch value.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() {
        case "7bit":
            return .sevenBit
        case "8bit":
            return .eightBit
        case "binary":
            return .binary
        case "base64":
            return .base64
        case "quoted-printable":
            return .quotedPrintable
        case "x-uuencode", "uuencode":
            return .uuEncode
        default:
            return .default
        }
    }

    func isMultipart(_ contentType: ContentType) -> Bool {
        contentType.mediaType.caseInsensitiveCompare("multipart") == .orderedSame
    }

    func isMessagePart(_ contentType: ContentType, encoding: ContentEncoding) -> Bool {
        if encoding == .base64 || encoding == .quotedPrintable || encoding == .uuEncode {
            return false
        }
        if contentType.mediaType.caseInsensitiveCompare("message") == .orderedSame {
            let subtype = contentType.mediaSubtype.lowercased()
            switch subtype {
            case "rfc822", "news", "global", "global-headers", "external-body", "rfc2822":
                return true
            default:
                return false
            }
        }
        return (try? contentType.isMimeType("text", "rfc822-headers")) ?? false
    }

    func isBoundaryLine(_ line: ArraySlice<UInt8>, boundary: [UInt8]) -> Bool {
        if line.count < boundary.count {
            return false
        }
        if !line.starts(with: boundary) {
            return false
        }
        let remainder = line.dropFirst(boundary.count)
        return remainder.allSatisfy { $0 == 0x20 || $0 == 0x09 || $0 == 0x2D }
    }

    func isEndBoundaryLine(_ line: ArraySlice<UInt8>, boundary: [UInt8]) -> Bool {
        if line.count < boundary.count + 2 {
            return false
        }
        if !line.starts(with: boundary) {
            return false
        }
        let remainder = line.dropFirst(boundary.count)
        if remainder.count < 2 {
            return false
        }
        if remainder[remainder.startIndex] != 0x2D || remainder[remainder.index(after: remainder.startIndex)] != 0x2D {
            return false
        }
        return true
    }

    func headerBodySeparatorOffset(in data: [UInt8], startOffset: Int) -> Int? {
        if startOffset >= data.count {
            return nil
        }
        var index = startOffset
        var newlineCount = 0
        while index < data.count {
            let byte = data[index]
            if byte == 0x0D {
                if index + 1 < data.count, data[index + 1] == 0x0A {
                    newlineCount += 1
                    index += 2
                } else {
                    newlineCount += 1
                    index += 1
                }
            } else if byte == 0x0A {
                newlineCount += 1
                index += 1
            } else {
                newlineCount = 0
                index += 1
            }
            if newlineCount >= 2 {
                return index
            }
        }
        return nil
    }

    func parseContentLength(startOffset: Int) -> Int? {
        let bytes = Array(data[startOffset..<data.count])
        let (headers, _) = MimeMessage.parseHeaders(bytes)
        guard let value = headers[.contentLength] else {
            return nil
        }
        return Int(value.trimmingCharacters(in: .whitespacesAndNewlines))
    }

    func adjustedEndOffset(beforeLineIndex lineIndex: Int) -> Int {
        if lineIndex <= 0 {
            return lineMap.lines.first?.start ?? 0
        }
        let previous = lineMap.lines[lineIndex - 1]
        return previous.end
    }
}
