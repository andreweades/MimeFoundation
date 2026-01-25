//
// ContentType.swift
//
// Ported from MimeKit (C#) to Swift.
//

import Foundation

public enum ContentTypeError: Error {
    case nilMediaType
    case nilMediaSubtype
    case invalidMediaType
    case invalidMediaSubtype
    case nilOptions
    case nilEncoding
}

public final class ContentType {
    private var type: String
    private var subtype: String

    public var parameters: ParameterList {
        didSet {
            parameters.changed = { [weak self] _ in
                self?.onChanged()
            }
            onChanged()
        }
    }

    public init(_ mediaType: String, _ mediaSubtype: String) throws {
        if mediaType.isEmpty {
            throw ContentTypeError.invalidMediaType
        }
        if mediaSubtype.isEmpty {
            throw ContentTypeError.invalidMediaSubtype
        }
        self.type = mediaType
        self.subtype = mediaSubtype
        self.parameters = ParameterList()
        self.parameters.changed = { [weak self] _ in
            self?.onChanged()
        }
    }

    /// Internal initializer for cloning. Assumes values are already validated.
    private init(cloning mediaType: String, _ mediaSubtype: String) {
        self.type = mediaType
        self.subtype = mediaSubtype
        self.parameters = ParameterList()
        self.parameters.changed = { [weak self] _ in
            self?.onChanged()
        }
    }

    public var mediaType: String {
        get { type }
        set {
            if newValue.isEmpty {
                return
            }
            if type == newValue {
                return
            }
            type = newValue
            onChanged()
        }
    }

    public var mediaSubtype: String {
        get { subtype }
        set {
            if newValue.isEmpty {
                return
            }
            if subtype == newValue {
                return
            }
            subtype = newValue
            onChanged()
        }
    }

    public var boundary: String? {
        get { parameters["boundary"] }
        set {
            if parameters["boundary"] == newValue {
                return
            }
            parameters["boundary"] = newValue
        }
    }

    public var charset: String? {
        get { parameters["charset"] }
        set {
            if parameters["charset"] == newValue {
                return
            }
            parameters["charset"] = newValue
        }
    }

    public var charsetEncoding: String.Encoding? {
        get {
            guard let charset else { return nil }
            return CharsetUtils.getEncoding(charset)
        }
        set {
            charset = newValue != nil ? CharsetUtils.getMimeCharset(newValue!) : nil
        }
    }

    public var format: String? {
        get { parameters["format"] }
        set {
            if parameters["format"] == newValue {
                return
            }
            parameters["format"] = newValue
        }
    }

    public var name: String? {
        get { parameters["name"] }
        set {
            if parameters["name"] == newValue {
                return
            }
            parameters["name"] = newValue
        }
    }

    public var mimeType: String {
        "\(type)/\(subtype)"
    }

    public func isMimeType(_ mediaType: String?, _ mediaSubtype: String?) throws -> Bool {
        guard let mediaType else {
            throw ContentTypeError.nilMediaType
        }
        guard let mediaSubtype else {
            throw ContentTypeError.nilMediaSubtype
        }

        if mediaType == "*" || mediaType.caseInsensitiveCompare(type) == .orderedSame {
            return mediaSubtype == "*" || mediaSubtype.caseInsensitiveCompare(subtype) == .orderedSame
        }
        return false
    }

    public func setMediaType(_ value: String?) throws {
        guard let value else {
            throw ContentTypeError.nilMediaType
        }
        if value.isEmpty {
            throw ContentTypeError.invalidMediaType
        }
        if type != value {
            type = value
            onChanged()
        }
    }

    public func setMediaSubtype(_ value: String?) throws {
        guard let value else {
            throw ContentTypeError.nilMediaSubtype
        }
        if value.isEmpty {
            throw ContentTypeError.invalidMediaSubtype
        }
        if subtype != value {
            subtype = value
            onChanged()
        }
    }

    public var changed: (() -> Void)?

    private func onChanged() {
        changed?()
    }

    public func copy() -> ContentType {
        let copied = ContentType(cloning: type, subtype)
        for param in parameters {
            try? copied.parameters.add(param.copy())
        }
        return copied
    }

    public func toString(_ options: FormatOptions?, _ encoding: String.Encoding?, _ encode: Bool) throws -> String {
        guard let options else {
            throw ContentTypeError.nilOptions
        }
        guard let encoding else {
            throw ContentTypeError.nilEncoding
        }
        var builder = ValueStringBuilder(initialCapacity: 128)
        builder.append("Content-Type: ")
        builder.append(type)
        builder.append("/")
        builder.append(subtype)
        if encode {
            var lineLength = builder.length
            parameters.encode(options, builder: &builder, lineLength: &lineLength, charset: encoding)
        } else {
            parameters.writeTo(&builder)
        }
        return builder.toString()
    }

    public func toString(_ encoding: String.Encoding?, _ encode: Bool) throws -> String {
        try toString(FormatOptions.default, encoding, encode)
    }

    public func toString(_ encode: Bool) -> String {
        (try? toString(FormatOptions.default, .utf8, encode)) ?? ""
    }

    public func toString() -> String {
        toString(false)
    }

    public func encode(_ options: FormatOptions, _ charset: String.Encoding) -> String {
        let lineLength = "Content-Type:".count
        var builder = ValueStringBuilder(initialCapacity: 128)
        builder.append(" ")
        builder.append(type)
        builder.append("/")
        builder.append(subtype)
        var currentLength = lineLength + builder.length
        parameters.encode(options, builder: &builder, lineLength: &currentLength, charset: charset)
        builder.append(options.newLine)
        return builder.asString()
    }

    private static func skipType(_ text: [UInt8], index: inout Int, endIndex: Int) -> Bool {
        let start = index
        while index < endIndex && ByteClassification.isAsciiAtom(text[index]) && text[index] != UInt8(ascii: "/") {
            index += 1
        }
        return index > start
    }

    private static func skipSubtype(_ text: [UInt8], index: inout Int, endIndex: Int) -> Bool {
        let start = index
        while index < endIndex && (ByteClassification.isToken(text[index]) || text[index] == UInt8(ascii: "/")) {
            index += 1
        }
        return index > start
    }

    internal static func tryParse(
        _ options: ParserOptions,
        _ text: [UInt8],
        index: inout Int,
        endIndex: Int,
        throwOnError: Bool,
        contentType: inout ContentType?
    ) throws -> Bool {
        contentType = nil

        if !(try ParseUtils.skipCommentsAndWhiteSpace(text, index: &index, endIndex: endIndex, throwOnError: throwOnError)) {
            return false
        }

        let start = index
        if !skipType(text, index: &index, endIndex: endIndex) {
            if throwOnError {
                throw ParseException("Invalid type token at position \(start)", tokenIndex: start, errorIndex: index)
            }
            return false
        }

        let type = String(bytes: text[start..<index], encoding: .ascii) ?? ""

        if !(try ParseUtils.skipCommentsAndWhiteSpace(text, index: &index, endIndex: endIndex, throwOnError: throwOnError)) {
            return false
        }

        if index >= endIndex || text[index] != UInt8(ascii: "/") {
            if throwOnError {
                throw ParseException("Expected '/' at position \(index)", tokenIndex: index, errorIndex: index)
            }
            return false
        }

        index += 1

        if !(try ParseUtils.skipCommentsAndWhiteSpace(text, index: &index, endIndex: endIndex, throwOnError: throwOnError)) {
            return false
        }

        let subtypeStart = index
        if !skipSubtype(text, index: &index, endIndex: endIndex) {
            if throwOnError {
                throw ParseException("Invalid atom token at position \(subtypeStart)", tokenIndex: subtypeStart, errorIndex: index)
            }
            return false
        }

        let subtype = String(bytes: text[subtypeStart..<index], encoding: .ascii) ?? ""

        if !(try ParseUtils.skipCommentsAndWhiteSpace(text, index: &index, endIndex: endIndex, throwOnError: throwOnError)) {
            return false
        }

        contentType = try ContentType(type, subtype)

        if index >= endIndex {
            return true
        }

        if text[index] != UInt8(ascii: ";") {
            if throwOnError {
                throw ParseException("Expected ';' at position \(index)", tokenIndex: index, errorIndex: index)
            }
            return false
        }

        index += 1

        if !(try ParseUtils.skipCommentsAndWhiteSpace(text, index: &index, endIndex: endIndex, throwOnError: throwOnError)) {
            return false
        }

        if index >= endIndex {
            return true
        }

        var params: ParameterList? = nil
        if !(try ParameterList.tryParse(options, text, index: &index, endIndex: endIndex, throwOnError: throwOnError, paramList: &params)) {
            return false
        }

        if let params {
            contentType?.parameters = params
        }

        return true
    }

    // MARK: - Swift-Idiomatic Parsing Initializers

    /// Throwing initializer - throws ParseException on failure.
    /// Use `try?` for optional behavior: `let ct = try? ContentType(parsing: text)`
    public convenience init(parsing text: String, options: ParserOptions = .default) throws {
        let buffer = Array(text.utf8)
        try self.init(parsing: buffer, options: options)
    }

    /// Throwing initializer - throws ParseException on failure.
    /// Use `try?` for optional behavior: `let ct = try? ContentType(parsing: buffer)`
    public convenience init(parsing buffer: [UInt8], options: ParserOptions = .default) throws {
        var result: ContentType? = nil
        var index = 0

        // First try with throwOnError: false to allow lenient parsing
        if !(try Self.tryParse(options, buffer, index: &index, endIndex: buffer.count,
                              throwOnError: false, contentType: &result)) {
            // If that fails, try with throwOnError: true to get the proper exception
            index = 0
            _ = try Self.tryParse(options, buffer, index: &index, endIndex: buffer.count,
                                  throwOnError: true, contentType: &result)
        }

        guard let parsed = result else {
            throw ParseException("Failed to parse content type.", tokenIndex: 0, errorIndex: index)
        }
        try self.init(parsed.mediaType, parsed.mediaSubtype)
        self.parameters = parsed.parameters
    }
}
