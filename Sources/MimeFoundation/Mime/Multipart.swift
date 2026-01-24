//
// Multipart.swift
//
// Ported from MimeKit (C#) to Swift.
//

import Foundation

public enum MultipartError: Error, Equatable {
    case nilSubtype
    case nilArgs
    case invalidArgument
    case nilBoundary
    case indexOutOfRange
    case nilEntity
    case invalidMaxLineLength
}

open class Multipart: MimeEntity, RandomAccessCollection, MutableCollection {
    public typealias Element = MimeEntity
    public typealias Index = Int

    private var children: [MimeEntity] = []
    private var preambleStorage: String?
    private var epilogueStorage: String?
    private var writeEndBoundaryStorage: Bool = true
    internal var rawBody: [UInt8]? = nil

    public var rawEndBoundary: [UInt8]? {
        didSet {
            if let rawEndBoundary, rawEndBoundary.isEmpty {
                writeEndBoundaryStorage = false
            }
        }
    }

    public var writeEndBoundary: Bool {
        writeEndBoundaryStorage
    }

    public var isReadOnly: Bool { false }

    public var startIndex: Int { children.startIndex }
    public var endIndex: Int { children.endIndex }

    public func index(after i: Int) -> Int { children.index(after: i) }

    public subscript(position: Int) -> MimeEntity {
        get { children[position] }
        set {
            precondition(position >= 0 && position < children.count, "index out of range")
            children[position] = newValue
        }
    }

    public var count: Int { children.count }

    public var boundary: String {
        contentType.boundary ?? ""
    }

    public var preamble: String? {
        get { preambleStorage }
        set {
            rawBody = nil
            if let value = newValue {
                preambleStorage = Multipart.foldPreambleOrEpilogue(.default, value, isEpilogue: false)
            } else {
                preambleStorage = nil
            }
        }
    }

    public var epilogue: String? {
        get { epilogueStorage }
        set {
            rawBody = nil
            if let value = newValue {
                epilogueStorage = Multipart.foldPreambleOrEpilogue(.default, value, isEpilogue: true)
                writeEndBoundaryStorage = true
            } else {
                epilogueStorage = nil
            }
        }
    }

    public override init(_ contentType: ContentType) {
        super.init(contentType)
    }

    public init(_ subtype: String) throws {
        if subtype.isEmpty {
            throw MultipartError.nilSubtype
        }
        let contentType = try ContentType("multipart", subtype)
        super.init(contentType)
        contentType.boundary = Multipart.generateBoundary()
    }

    public convenience init(_ subtype: String, _ args: Any?...) throws {
        try self.init(subtype, args: args)
    }

    public convenience init(_ subtype: String, args: [Any?]?) throws {
        guard let args else {
            throw MultipartError.nilArgs
        }
        try self.init(subtype)
        try applyArgs(args)
    }

    public convenience init() {
        do {
            try self.init("mixed")
        } catch {
            preconditionFailure("Failed to create multipart/mixed - this is a programming error")
        }
    }

    public func setBoundary(_ value: String?) throws {
        guard let value else {
            throw MultipartError.nilBoundary
        }
        rawBody = nil
        contentType.boundary = value
    }

    public func add(_ entity: MimeEntity?) throws {
        guard let entity else {
            throw MultipartError.nilEntity
        }
        rawBody = nil
        children.append(entity)
    }

    public func insert(_ entity: MimeEntity?, at index: Int) throws {
        guard let entity else {
            throw MultipartError.nilEntity
        }
        guard index >= 0 && index <= children.count else {
            throw MultipartError.indexOutOfRange
        }
        rawBody = nil
        children.insert(entity, at: index)
    }

    @discardableResult
    public func remove(_ entity: MimeEntity?) throws -> Bool {
        guard let entity else {
            throw MultipartError.nilEntity
        }
        guard let index = children.firstIndex(where: { $0 === entity }) else {
            return false
        }
        children.remove(at: index)
        return true
    }

    public func remove(at index: Int) throws {
        guard index >= 0 && index < children.count else {
            throw MultipartError.indexOutOfRange
        }
        rawBody = nil
        children.remove(at: index)
    }

    public func contains(_ entity: MimeEntity?) throws -> Bool {
        guard let entity else {
            throw MultipartError.nilEntity
        }
        return children.contains(where: { $0 === entity })
    }

    public func indexOf(_ entity: MimeEntity?) throws -> Int {
        guard let entity else {
            throw MultipartError.nilEntity
        }
        return children.firstIndex(where: { $0 === entity }) ?? -1
    }

    public func setItem(at index: Int, _ entity: MimeEntity?) throws {
        guard let entity else {
            throw MultipartError.nilEntity
        }
        guard index >= 0 && index < children.count else {
            throw MultipartError.indexOutOfRange
        }
        children[index] = entity
    }

    public func clear() {
        rawBody = nil
        children.removeAll(keepingCapacity: true)
    }

    public func copyTo(_ array: inout [MimeEntity], at index: Int) throws {
        guard index >= 0 && index <= array.count else {
            throw MultipartError.indexOutOfRange
        }
        array.insert(contentsOf: children, at: index)
    }

    public func prepare(_ constraint: EncodingConstraint, maxLineLength: Int = FormatOptions.defaultMaxLineLength) throws {
        if maxLineLength < FormatOptions.minimumLineLength || maxLineLength > FormatOptions.maximumLineLength {
            throw MultipartError.invalidMaxLineLength
        }
        for child in children {
            if let part = child as? MimePart {
                try part.prepare(constraint)
            } else if let messagePart = child as? MessagePart {
                try messagePart.prepare(constraint, maxLineLength: maxLineLength)
            } else if let multipart = child as? Multipart {
                try multipart.prepare(constraint, maxLineLength: maxLineLength)
            }
        }
    }

    open override func accept(_ visitor: MimeVisitor?) throws {
        guard let visitor else {
            throw MimeEntityError.nilVisitor
        }
        visitor.visit(self)
    }

    open func tryGetValue(_ format: TextFormat, body: inout TextPart?) -> Bool {
        for index in 0..<count {
            if let multipart = children[index] as? Multipart {
                if multipart.tryGetValue(format, body: &body) {
                    return true
                }
                break
            }

            if let text = children[index] as? TextPart, !text.isAttachment {
                if text.isFormat(format) {
                    body = text
                    return true
                }
                break
            }
        }

        body = nil
        return false
    }

    public override func writeTo(_ options: FormatOptions?, _ stream: MimeStream?) throws {
        try super.writeTo(options, stream)
    }

    internal override func writeBody(_ options: FormatOptions, stream: MimeStream) throws {
        guard let boundary = contentType.boundary else {
            if let preamble = preambleStorage {
                let bytes = Array(preamble.utf8)
                try stream.write(bytes, offset: 0, count: bytes.count)
            }
            if let epilogue = epilogueStorage {
                let bytes = Array(epilogue.utf8)
                try stream.write(bytes, offset: 0, count: bytes.count)
            }
            return
        }

        if let preamble = preambleStorage {
            let bytes = Array(preamble.utf8)
            try stream.write(bytes, offset: 0, count: bytes.count)
        }

        let newLine = options.newLine
        for part in children {
            let boundaryLine = "--\(boundary)\(newLine)"
            let boundaryBytes = Array(boundaryLine.utf8)
            try stream.write(boundaryBytes, offset: 0, count: boundaryBytes.count)
            try part.writeTo(options, stream)
            if shouldWriteNewLine(after: part) {
                let newLineBytes = Array(newLine.utf8)
                try stream.write(newLineBytes, offset: 0, count: newLineBytes.count)
            }
        }

        if writeEndBoundaryStorage {
            let endLine = "--\(boundary)--\(newLine)"
            let endBytes = Array(endLine.utf8)
            try stream.write(endBytes, offset: 0, count: endBytes.count)
        }

        if let epilogue = epilogueStorage {
            let bytes = Array(epilogue.utf8)
            try stream.write(bytes, offset: 0, count: bytes.count)
        }
    }

    public static func foldPreambleOrEpilogue(_ options: FormatOptions, _ text: String, isEpilogue: Bool) -> String {
        let normalized = text
            .replacingOccurrences(of: "\r\n", with: "\n")
            .replacingOccurrences(of: "\r", with: "\n")
        let lines = normalized.split(separator: "\n", omittingEmptySubsequences: false)
        var outputLines: [String] = []
        let maxLineLength = options.maxLineLength

        for line in lines {
            if line.isEmpty {
                outputLines.append("")
                continue
            }
            outputLines.append(contentsOf: wrapLine(String(line), maxLineLength: maxLineLength))
        }

        var result = outputLines.joined(separator: options.newLine)
        if !result.isEmpty && !result.hasSuffix(options.newLine) {
            result.append(options.newLine)
        }
        if isEpilogue && !result.hasPrefix(options.newLine) {
            result = options.newLine + result
        }
        return result
    }

    private static func wrapLine(_ line: String, maxLineLength: Int) -> [String] {
        var result: [String] = []
        var remaining = line
        while remaining.count > maxLineLength {
            let splitIndex = remaining.index(remaining.startIndex, offsetBy: maxLineLength)
            var breakIndex = remaining[..<splitIndex].lastIndex(of: " ")
            if breakIndex == nil {
                breakIndex = splitIndex
            }
            let head = remaining[..<breakIndex!]
            result.append(String(head))
            var tailStart = breakIndex!
            if tailStart < remaining.endIndex, remaining[tailStart] == " " {
                tailStart = remaining.index(after: tailStart)
            }
            remaining = String(remaining[tailStart...])
            if remaining.isEmpty {
                break
            }
        }
        if !remaining.isEmpty {
            result.append(remaining)
        }
        return result
    }

    private static func generateBoundary() -> String {
        let uuid = UUID().uuidString.replacingOccurrences(of: "-", with: "")
        return "=-\(uuid)"
    }

    private func shouldWriteNewLine(after part: MimeEntity) -> Bool {
        if let mimePart = part as? MimePart {
            return mimePart.content != nil
        }
        if let messagePart = part as? MessagePart {
            return messagePart.message?.body != nil
        }
        if let multipart = part as? Multipart {
            return multipart.writeEndBoundary
        }
        return true
    }

    private func tryInit(_ obj: Any) -> Bool {
        if let header = obj as? Header {
            headers.add(header)
            return true
        }
        if let headers = obj as? [Header] {
            for header in headers {
                self.headers.add(header)
            }
            return true
        }
        return false
    }

    internal func applyArgs(_ args: [Any?]) throws {
        for obj in args {
            guard let obj else { continue }
            if tryInit(obj) {
                continue
            }
            if let entity = obj as? MimeEntity {
                try add(entity)
                continue
            }
            throw MultipartError.invalidArgument
        }
    }
}
