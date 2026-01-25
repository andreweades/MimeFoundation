//
// ContentDisposition.swift
//
// Ported from MimeKit (C#) to Swift.
//

import Foundation

public enum ContentDispositionError: Error, Sendable {
    case nilDisposition
    case invalidDisposition
    case nilOptions
    case nilEncoding
}

public final class ContentDisposition {
    public static let attachment = "attachment"
    public static let formData = "form-data"
    public static let inline = "inline"

    public private(set) var disposition: String
    public var parameters: ParameterList {
        didSet {
            parameters.changed = { [weak self] _ in
                self?.onChanged()
            }
            onChanged()
        }
    }

    public init(_ disposition: String = ContentDisposition.attachment) throws {
        try ContentDisposition.validateDisposition(disposition)
        self.disposition = disposition
        self.parameters = ParameterList()
        self.parameters.changed = { [weak self] _ in
            self?.onChanged()
        }
    }

    /// Internal initializer for cloning. Assumes disposition is already validated.
    private init(cloning disposition: String) {
        self.disposition = disposition
        self.parameters = ParameterList()
        self.parameters.changed = { [weak self] _ in
            self?.onChanged()
        }
    }

    public var fileName: String? {
        get { parameters["filename"] }
        set {
            let current = parameters["filename"]
            if current == newValue {
                return
            }
            parameters["filename"] = newValue
        }
    }

    public var isAttachment: Bool {
        get { disposition.caseInsensitiveCompare(ContentDisposition.attachment) == .orderedSame }
        set {
            let next = newValue ? ContentDisposition.attachment : ContentDisposition.inline
            if disposition.caseInsensitiveCompare(next) == .orderedSame {
                return
            }
            disposition = next
            onChanged()
        }
    }

    public var creationDate: DateTimeOffset? {
        get {
            guard let value = parameters["creation-date"], !value.isEmpty else {
                return nil
            }
            var parsed: DateTimeOffset?
            if DateUtils.tryParse(value, date: &parsed) {
                return parsed
            }
            return nil
        }
        set {
            let current = parameters["creation-date"]
            if let value = newValue {
                let formatted = DateUtils.formatDate(value)
                if current == formatted {
                    return
                }
                parameters["creation-date"] = formatted
            } else if current != nil {
                parameters["creation-date"] = nil
            }
        }
    }

    public var modificationDate: DateTimeOffset? {
        get {
            guard let value = parameters["modification-date"], !value.isEmpty else {
                return nil
            }
            var parsed: DateTimeOffset?
            if DateUtils.tryParse(value, date: &parsed) {
                return parsed
            }
            return nil
        }
        set {
            let current = parameters["modification-date"]
            if let value = newValue {
                let formatted = DateUtils.formatDate(value)
                if current == formatted {
                    return
                }
                parameters["modification-date"] = formatted
            } else if current != nil {
                parameters["modification-date"] = nil
            }
        }
    }

    public var readDate: DateTimeOffset? {
        get {
            guard let value = parameters["read-date"], !value.isEmpty else {
                return nil
            }
            var parsed: DateTimeOffset?
            if DateUtils.tryParse(value, date: &parsed) {
                return parsed
            }
            return nil
        }
        set {
            let current = parameters["read-date"]
            if let value = newValue {
                let formatted = DateUtils.formatDate(value)
                if current == formatted {
                    return
                }
                parameters["read-date"] = formatted
            } else if current != nil {
                parameters["read-date"] = nil
            }
        }
    }

    public var size: Int64? {
        get {
            guard let value = parameters["size"], !value.isEmpty else {
                return nil
            }
            return Int64(value)
        }
        set {
            let current = parameters["size"]
            if let value = newValue {
                let text = String(value)
                if current == text {
                    return
                }
                parameters["size"] = text
            } else if current != nil {
                parameters["size"] = nil
            }
        }
    }

    public func setDisposition(_ value: String?) throws {
        guard let value else {
            throw ContentDispositionError.nilDisposition
        }
        try ContentDisposition.validateDisposition(value)
        if disposition != value {
            disposition = value
            onChanged()
        }
    }

    public func toString(_ options: FormatOptions?, _ encoding: String.Encoding?, _ encode: Bool) throws -> String {
        guard let options else {
            throw ContentDispositionError.nilOptions
        }
        guard let encoding else {
            throw ContentDispositionError.nilEncoding
        }
        var builder = ValueStringBuilder(initialCapacity: 128)
        builder.append("Content-Disposition: ")
        builder.append(disposition)
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
        var lineLength = "Content-Disposition:".count
        var builder = ValueStringBuilder(initialCapacity: 128)
        builder.append(" ")
        builder.append(disposition)
        lineLength += builder.length
        parameters.encode(options, builder: &builder, lineLength: &lineLength, charset: charset)
        builder.append(options.newLine)
        return builder.asString()
    }

    public func copy() -> ContentDisposition {
        let copied = ContentDisposition(cloning: disposition)
        for param in parameters {
            try? copied.parameters.add(param.copy())
        }
        return copied
    }

    public var changed: (() -> Void)?

    private func onChanged() {
        changed?()
    }

    internal static func tryParse(
        _ options: ParserOptions,
        _ text: [UInt8],
        index: inout Int,
        endIndex: Int,
        throwOnError: Bool,
        disposition: inout ContentDisposition?
    ) throws -> Bool {
        disposition = nil
        if !(try ParseUtils.skipCommentsAndWhiteSpace(text, index: &index, endIndex: endIndex, throwOnError: throwOnError)) {
            return false
        }

        if index >= endIndex {
            if throwOnError {
                throw ParseException("Expected atom token at position \(index)", tokenIndex: index, errorIndex: index)
            }
            return false
        }

        let atomIndex = index
        var type = ""

        if text[index] == 0x22 {
            if throwOnError {
                throw ParseException("Unexpected qstring token at position \(atomIndex)", tokenIndex: atomIndex, errorIndex: index)
            }
            if !(try ParseUtils.skipQuoted(text, index: &index, endIndex: endIndex, throwOnError: throwOnError)) {
                return false
            }

            type = CharsetUtils.convertToUnicode(options, text, start: atomIndex, length: index - atomIndex)
            type = MimeUtils.unquote(type)
            if type.isEmpty {
                type = ContentDisposition.attachment
            }
        } else {
            if !ParseUtils.skipAtom(text, index: &index, endIndex: endIndex) {
                if throwOnError {
                    throw ParseException("Invalid atom token at position \(atomIndex)", tokenIndex: atomIndex, errorIndex: index)
                }
                if index > atomIndex || text[index] != 0x3B {
                    return false
                }
                type = ContentDisposition.attachment
            } else {
                type = String(bytes: text[atomIndex..<index], encoding: .ascii) ?? ContentDisposition.attachment
            }
        }

        let parsed = try? ContentDisposition(type)
        disposition = parsed

        if !(try ParseUtils.skipCommentsAndWhiteSpace(text, index: &index, endIndex: endIndex, throwOnError: throwOnError)) {
            return false
        }

        if index >= endIndex {
            return true
        }

        if text[index] != 0x3B {
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

        if let params, let parsed {
            parsed.parameters = params
        }

        return true
    }

    // MARK: - Swift-Idiomatic Parsing Initializers

    /// Throwing initializer - throws ParseException on failure.
    /// Use `try?` for optional behavior: `let cd = try? ContentDisposition(parsing: text)`
    public convenience init(parsing text: String, options: ParserOptions = .default) throws {
        let buffer = Array(text.utf8)
        try self.init(parsing: buffer, options: options)
    }

    /// Throwing initializer - throws ParseException on failure.
    /// Use `try?` for optional behavior: `let cd = try? ContentDisposition(parsing: buffer)`
    public convenience init(parsing buffer: [UInt8], options: ParserOptions = .default) throws {
        var result: ContentDisposition? = nil
        var index = 0

        // First try with throwOnError: false to allow lenient parsing
        if !(try Self.tryParse(options, buffer, index: &index, endIndex: buffer.count,
                              throwOnError: false, disposition: &result)) {
            // If that fails, try with throwOnError: true to get the proper exception
            index = 0
            _ = try Self.tryParse(options, buffer, index: &index, endIndex: buffer.count,
                                  throwOnError: true, disposition: &result)
        }

        guard let parsed = result else {
            throw ParseException("Failed to parse content disposition.", tokenIndex: 0, errorIndex: index)
        }
        try self.init(parsed.disposition)
        self.parameters = parsed.parameters
    }

    private static func validateDisposition(_ value: String) throws {
        if value.isEmpty {
            throw ContentDispositionError.invalidDisposition
        }
        for byte in value.utf8 {
            if byte > 0x7F || !ByteClassification.isToken(byte) {
                throw ContentDispositionError.invalidDisposition
            }
        }
    }
}
