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

    public func clone() -> ContentType {
        let cloned = try! ContentType(type, subtype)
        for param in parameters {
            try? cloned.parameters.add(param.clone())
        }
        return cloned
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

    public static func tryParse(_ options: ParserOptions, _ buffer: [UInt8], startIndex: Int, length: Int, contentType: inout ContentType?) -> Bool {
        guard startIndex >= 0, length >= 0, startIndex + length <= buffer.count else {
            contentType = nil
            return false
        }
        var index = startIndex
        return (try? tryParse(options, buffer, index: &index, endIndex: startIndex + length, throwOnError: false, contentType: &contentType)) ?? false
    }

    public static func tryParse(_ buffer: [UInt8], startIndex: Int, length: Int, contentType: inout ContentType?) -> Bool {
        tryParse(ParserOptions.default, buffer, startIndex: startIndex, length: length, contentType: &contentType)
    }

    public static func tryParse(_ options: ParserOptions, _ buffer: [UInt8], startIndex: Int, contentType: inout ContentType?) -> Bool {
        tryParse(options, buffer, startIndex: startIndex, length: buffer.count - startIndex, contentType: &contentType)
    }

    public static func tryParse(_ buffer: [UInt8], startIndex: Int, contentType: inout ContentType?) -> Bool {
        tryParse(ParserOptions.default, buffer, startIndex: startIndex, contentType: &contentType)
    }

    public static func tryParse(_ options: ParserOptions, _ buffer: [UInt8], contentType: inout ContentType?) -> Bool {
        tryParse(options, buffer, startIndex: 0, length: buffer.count, contentType: &contentType)
    }

    public static func tryParse(_ buffer: [UInt8], contentType: inout ContentType?) -> Bool {
        tryParse(ParserOptions.default, buffer, contentType: &contentType)
    }

    public static func tryParse(_ options: ParserOptions, _ text: String, contentType: inout ContentType?) -> Bool {
        let buffer = Array(text.utf8)
        return tryParse(options, buffer, startIndex: 0, length: buffer.count, contentType: &contentType)
    }

    public static func tryParse(_ text: String, contentType: inout ContentType?) -> Bool {
        tryParse(ParserOptions.default, text, contentType: &contentType)
    }

    public static func parse(_ options: ParserOptions, _ buffer: [UInt8], startIndex: Int, length: Int) throws -> ContentType {
        var index = startIndex
        var type: ContentType? = nil
        let endIndex = startIndex + length
        if try tryParse(options, buffer, index: &index, endIndex: endIndex, throwOnError: true, contentType: &type), let type {
            return type
        }
        throw ParseException("Failed to parse content type.", tokenIndex: startIndex, errorIndex: index)
    }

    public static func parse(_ options: ParserOptions, _ buffer: [UInt8], startIndex: Int) throws -> ContentType {
        try parse(options, buffer, startIndex: startIndex, length: buffer.count - startIndex)
    }

    public static func parse(_ buffer: [UInt8], startIndex: Int, length: Int) throws -> ContentType {
        try parse(ParserOptions.default, buffer, startIndex: startIndex, length: length)
    }

    public static func parse(_ buffer: [UInt8], startIndex: Int) throws -> ContentType {
        try parse(ParserOptions.default, buffer, startIndex: startIndex)
    }

    public static func parse(_ options: ParserOptions, _ buffer: [UInt8]) throws -> ContentType {
        try parse(options, buffer, startIndex: 0, length: buffer.count)
    }

    public static func parse(_ buffer: [UInt8]) throws -> ContentType {
        try parse(ParserOptions.default, buffer, startIndex: 0, length: buffer.count)
    }

    public static func parse(_ options: ParserOptions, _ text: String) throws -> ContentType {
        let buffer = Array(text.utf8)
        return try parse(options, buffer, startIndex: 0, length: buffer.count)
    }

    public static func parse(_ text: String) throws -> ContentType {
        try parse(ParserOptions.default, text)
    }
}
