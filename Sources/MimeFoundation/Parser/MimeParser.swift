//
// MimeParser.swift
//
// Ported from MimeKit (C#) to Swift.
//

import Foundation

public enum MimeParserError: Error, Equatable, Sendable {
}

open class MimeParser {
    public var options: ParserOptions
    public private(set) var format: MimeFormat
    public private(set) var isEndOfStream: Bool = false
    public var position: Int { currentOffset }

    private var data: [UInt8] = []
    private var lineMap = LineMap([])
    private var mboxMarkers: [MboxMarker] = []
    private var currentOffset: Int = 0
    private var currentMarkerIndex: Int = 0

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

    public func parseHeaders() throws -> HeaderList {
        if isEndOfStream {
            return HeaderList()
        }
        let bytes = Array(data[currentOffset..<data.count])
        if shouldThrowForTruncatedHeaderName(bytes) {
            throw ParseException("Invalid header.", tokenIndex: currentOffset, errorIndex: currentOffset)
        }
        let (headers, bodyBytes) = MimeMessage.parseHeaders(bytes)
        currentOffset += bytes.count - bodyBytes.count
        if currentOffset >= data.count {
            isEndOfStream = true
        }
        return headers
    }

    public func parseHeadersAsync() async throws -> HeaderList {
        try parseHeaders()
    }

    public func parseMessage() throws -> MimeMessage {
        let range = try nextMessageRange()
        var messageBytes = Array(data[range.start..<range.end])
        if messageBytes.isEmpty {
            if format == .mbox {
                let message = MimeMessage(addDefaults: false)
                currentOffset = range.end
                if currentOffset >= data.count {
                    isEndOfStream = true
                }
                return message
            }
            throw ParseException("End of stream.", tokenIndex: currentOffset, errorIndex: currentOffset)
        }
        messageBytes = try stripByteOrderMarkIfNeeded(messageBytes)
        try validateHeaderStart(in: messageBytes, errorMessage: "Failed to parse message headers.")
        let stream = MemoryStream(messageBytes, writable: false)
        let message = try MimeMessage.load(options, stream)
        currentOffset = range.end
        if currentOffset >= data.count {
            isEndOfStream = true
        }
        return message
    }

    public func parseMessageAsync() async throws -> MimeMessage {
        try parseMessage()
    }

    public func parseEntity() throws -> MimeEntity {
        var bytes = Array(data[currentOffset..<data.count])
        if bytes.isEmpty {
            throw ParseException("End of stream.", tokenIndex: currentOffset, errorIndex: currentOffset)
        }
        bytes = try stripByteOrderMarkIfNeeded(bytes)
        try validateHeaderStart(in: bytes, errorMessage: "Failed to parse entity headers.")
        let stream = MemoryStream(bytes, writable: false)
        let entity = try MimeEntity.load(options, stream)
        currentOffset = data.count
        isEndOfStream = true
        return entity
    }

    public func parseEntityAsync() async throws -> MimeEntity {
        try parseEntity()
    }
}

// MARK: - Parsing helpers

private extension MimeParser {
    func shouldThrowForTruncatedHeaderName(_ bytes: [UInt8]) -> Bool {
        guard !bytes.isEmpty else { return false }
        var index = 0
        while index < bytes.count {
            let byte = bytes[index]
            if byte == 0x0D || byte == 0x0A {
                return false
            }
            index += 1
        }
        return !bytes.contains(0x3A)
    }

    func stripByteOrderMarkIfNeeded(_ bytes: [UInt8]) throws -> [UInt8] {
        guard bytes.count >= 2 else {
            return bytes
        }
        if bytes[0] == 0xEF && bytes[1] == 0xBB {
            guard bytes.count >= 3 else {
                throw ParseException("Invalid byte order mark.", tokenIndex: currentOffset, errorIndex: currentOffset)
            }
            guard bytes[2] == 0xBF else {
                throw ParseException("Invalid byte order mark.", tokenIndex: currentOffset, errorIndex: currentOffset)
            }
            if bytes.count == 3 {
                throw ParseException("End of stream.", tokenIndex: currentOffset, errorIndex: currentOffset)
            }
            return Array(bytes[3..<bytes.count])
        }
        return bytes
    }

    func validateHeaderStart(in bytes: [UInt8], errorMessage: String) throws {
        guard !bytes.isEmpty else {
            throw ParseException("End of stream.", tokenIndex: currentOffset, errorIndex: currentOffset)
        }
        var index = 0
        while index < bytes.count {
            let byte = bytes[index]
            if byte == 0x0D || byte == 0x0A {
                break
            }
            index += 1
        }
        if index == 0 {
            return
        }
        if !bytes[0..<index].contains(0x3A) {
            throw ParseException(errorMessage, tokenIndex: currentOffset, errorIndex: currentOffset)
        }
    }

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

    func nextMessageRange() throws -> (start: Int, end: Int) {
        if isEndOfStream || currentOffset >= data.count {
            isEndOfStream = true
            throw ParseException("End of stream.", tokenIndex: currentOffset, errorIndex: currentOffset)
        }

        switch format {
        case .entity:
            return (currentOffset, data.count)
        case .mbox:
            var markerIndex = currentMarkerIndex
            while markerIndex < mboxMarkers.count && mboxMarkers[markerIndex].start < currentOffset {
                markerIndex += 1
            }
            if markerIndex >= mboxMarkers.count {
                throw ParseException("Failed to find mbox From marker.", tokenIndex: currentOffset, errorIndex: currentOffset)
            }
            let marker = mboxMarkers[markerIndex]
            let markerLength = marker.lineEnd - marker.start
            if marker.lineBreakLength == 0 || markerLength > 4096 {
                throw ParseException("Invalid mbox marker.", tokenIndex: marker.start, errorIndex: marker.start)
            }
            let messageStart = marker.lineEnd + marker.lineBreakLength
            var nextMarkerIndex = markerIndex + 1
            var messageEnd = data.count
            if options.respectContentLength, let contentLength = parseContentLength(startOffset: messageStart) {
                let headerEndIndex = headerBodySeparatorOffset(in: data, startOffset: messageStart) ?? messageStart
                let bodyStart = headerEndIndex
                let contentEnd = min(bodyStart + contentLength, data.count)
                while nextMarkerIndex < mboxMarkers.count && mboxMarkers[nextMarkerIndex].start < contentEnd {
                    nextMarkerIndex += 1
                }
                if nextMarkerIndex < mboxMarkers.count {
                    messageEnd = adjustedEndOffset(beforeLineIndex: mboxMarkers[nextMarkerIndex].lineIndex)
                } else {
                    messageEnd = data.count
                }
            } else if nextMarkerIndex < mboxMarkers.count {
                messageEnd = adjustedEndOffset(beforeLineIndex: mboxMarkers[nextMarkerIndex].lineIndex)
            }
            if messageEnd < messageStart {
                messageEnd = messageStart
            }
            currentMarkerIndex = nextMarkerIndex
            return (messageStart, messageEnd)
        }
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
