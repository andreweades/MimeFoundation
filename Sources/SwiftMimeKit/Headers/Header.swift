//
// Header.swift
//
// Ported from MimeKit (C#) to Swift.
//

import Foundation

public enum HeaderError: Error, Equatable {
    case unknownHeaderId
    case emptyFieldName
    case invalidFieldName
    case invalidRawValue
    case unsupportedCharset
}

public final class Header: CustomStringConvertible, Equatable {
    public let id: HeaderId
    public let field: String
    public let rawField: [UInt8]
    public var encoding: String.Encoding {
        didSet {
            onChanged()
        }
    }

    internal let options: ParserOptions
    private var rawValueStorage: [UInt8]
    private var textValue: String?
    private var explicitRawValue: Bool

    public var value: String {
        get {
            if let textValue {
                return textValue
            }
            let decoded = Header.unfold(Rfc2047.decodeText(options, rawValueStorage, startIndex: 0, count: rawValueStorage.count))
            textValue = decoded
            return decoded
        }
        set {
            setValue(.default, encoding: encoding, value: newValue)
        }
    }

    public var rawValue: [UInt8] {
        rawValueStorage
    }

    internal var changed: ((Header) -> Void)?

    public init(_ id: HeaderId, value: String, encoding: String.Encoding = .utf8) {
        precondition(id != .unknown, "HeaderId.unknown is not valid for Header initialization.")
        self.options = .default
        self.id = id
        self.field = id.headerName
        self.encoding = encoding
        self.rawField = Array(field.utf8)
        self.rawValueStorage = []
        self.textValue = nil
        self.explicitRawValue = false
        setValue(.default, encoding: encoding, value: value)
    }

    public init(field: String, value: String, encoding: String.Encoding = .utf8) {
        let trimmed = field.trimmingCharacters(in: .whitespacesAndNewlines)
        precondition(!trimmed.isEmpty, "Header field names must not be empty.")
        precondition(Header.isValidFieldName(trimmed), "Header field names must contain only ASCII field-text characters.")
        self.options = .default
        self.field = trimmed
        self.id = HeaderId.from(field: trimmed)
        self.encoding = encoding
        self.rawField = Array(trimmed.utf8)
        self.rawValueStorage = []
        self.textValue = nil
        self.explicitRawValue = false
        setValue(.default, encoding: encoding, value: value)
    }

    public init(validating id: HeaderId, value: String, encoding: String.Encoding = .utf8) throws {
        guard id != .unknown else {
            throw HeaderError.unknownHeaderId
        }
        self.options = .default
        self.id = id
        self.field = id.headerName
        self.encoding = encoding
        self.rawField = Array(field.utf8)
        self.rawValueStorage = []
        self.textValue = nil
        self.explicitRawValue = false
        setValue(.default, encoding: encoding, value: value)
    }

    public init(validating field: String, value: String, encoding: String.Encoding = .utf8) throws {
        let trimmed = field.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            throw HeaderError.emptyFieldName
        }
        guard Header.isValidFieldName(trimmed) else {
            throw HeaderError.invalidFieldName
        }
        self.options = .default
        self.field = trimmed
        self.id = HeaderId.from(field: trimmed)
        self.encoding = encoding
        self.rawField = Array(trimmed.utf8)
        self.rawValueStorage = []
        self.textValue = nil
        self.explicitRawValue = false
        setValue(.default, encoding: encoding, value: value)
    }

    internal init(_ options: ParserOptions, _ id: HeaderId, _ field: String, _ rawValue: [UInt8]) {
        self.options = options
        self.id = id
        self.field = field
        self.rawField = Array(field.utf8)
        self.encoding = .utf8
        self.rawValueStorage = rawValue
        self.textValue = nil
        self.explicitRawValue = false
    }

    internal init(_ options: ParserOptions, fieldBytes: [UInt8], fieldNameLength: Int, rawValue: [UInt8]) {
        let nameBytes = Array(fieldBytes.prefix(fieldNameLength))
        self.options = options
        self.field = String(bytes: nameBytes, encoding: .ascii) ?? ""
        self.id = HeaderId.from(field: self.field)
        self.rawField = nameBytes
        self.encoding = .utf8
        self.rawValueStorage = rawValue
        self.textValue = nil
        self.explicitRawValue = false
    }

    public func toString(_ options: FormatOptions = .default, encode: Bool = false) -> String {
        if encode {
            var raw = getRawValue(options)
            if raw.last == 0x0A {
                raw.removeLast()
                if raw.last == 0x0D {
                    raw.removeLast()
                }
            }
            let valueText = String(decoding: raw, as: UTF8.self)
            return "\(field):" + valueText
        }
        return "\(field): \(value)"
    }

    public func getRawValue(_ options: FormatOptions) -> [UInt8] {
        if options.international && !explicitRawValue {
            switch id {
            case .dispositionNotificationTo, .resentReplyTo, .resentSender, .resentFrom, .resentBcc, .resentCc, .resentTo,
                    .replyTo, .sender, .from, .bcc, .cc, .to:
                return Header.reformatAddressHeader(options: self.options, format: options, field: field, rawValue: rawValueStorage)
            case .received:
                return rawValueStorage
            case .originalMessageId, .resentMessageId, .inReplyTo, .messageId, .contentId:
                return rawValueStorage
            case .references:
                return rawValueStorage
            case .contentDisposition:
                return Header.reformatContentDisposition(options: self.options, format: options, encoding: .utf8, field: field, rawValue: rawValueStorage)
            case .contentType:
                return Header.reformatContentType(options: self.options, format: options, encoding: .utf8, field: field, rawValue: rawValueStorage)
            case .arcAuthenticationResults, .authenticationResults:
                return rawValueStorage
            case .dkimSignature, .arcMessageSignature, .arcSeal:
                return rawValueStorage
            default:
                return Header.encodeUnstructuredHeader(options: self.options, format: options, encoding: .utf8, field: field, value: value)
            }
        }
        return rawValueStorage
    }

    public func getValue(_ encoding: String.Encoding) -> String {
        var options = self.options
        options.charsetEncoding = encoding
        return Header.unfold(Rfc2047.decodeText(options, rawValueStorage, startIndex: 0, count: rawValueStorage.count))
    }

    public func getValue(_ charset: String) throws -> String {
        guard let encoding = CharsetUtils.getEncoding(charset) else {
            throw HeaderError.unsupportedCharset
        }
        return getValue(encoding)
    }

    public func setValue(_ format: FormatOptions, encoding: String.Encoding, value: String) {
        textValue = Header.unfold(value.trimmingCharacters(in: .whitespacesAndNewlines))
        rawValueStorage = Header.formatRawValue(options: options, format: format, encoding: encoding, field: field, id: id, value: textValue ?? "")
        explicitRawValue = false
        onChanged()
    }

    public func setValue(_ encoding: String.Encoding, _ value: String) {
        setValue(.default, encoding: encoding, value: value)
    }

    public func setValue(_ format: FormatOptions, charset: String, value: String) throws {
        guard let encoding = CharsetUtils.getEncoding(charset) else {
            throw HeaderError.unsupportedCharset
        }
        setValue(format, encoding: encoding, value: value)
    }

    public func setValue(_ charset: String, _ value: String) throws {
        try setValue(.default, charset: charset, value: value)
    }

    public func setRawValue(_ value: [UInt8]) throws {
        guard !value.isEmpty, value.last == 0x0A else {
            throw HeaderError.invalidRawValue
        }
        explicitRawValue = true
        rawValueStorage = value
        textValue = nil
        onChanged()
    }

    public func clone() -> Header {
        let clone = Header(options, id, field, rawValueStorage)
        clone.explicitRawValue = explicitRawValue
        clone.textValue = textValue
        clone.encoding = encoding
        return clone
    }

    public static func unfold(_ text: String?) -> String {
        guard let text, !text.isEmpty else {
            return ""
        }
        let scalars = Array(text.unicodeScalars)
        var start = 0
        while start < scalars.count, CharacterSet.whitespacesAndNewlines.contains(scalars[start]) {
            start += 1
        }
        if start >= scalars.count {
            return ""
        }

        var end = scalars.count - 1
        while end >= start, CharacterSet.whitespacesAndNewlines.contains(scalars[end]) {
            end -= 1
        }
        if end < start {
            return ""
        }

        var result = String.UnicodeScalarView()
        result.reserveCapacity(end - start + 1)
        for index in start...end {
            let scalar = scalars[index]
            if scalar.value != 0x0D && scalar.value != 0x0A {
                result.append(scalar)
            }
        }
        return String(result)
    }

    public var description: String {
        toString(.default, encode: false)
    }

    private func onChanged() {
        changed?(self)
    }

    public static func == (lhs: Header, rhs: Header) -> Bool {
        lhs.id == rhs.id && lhs.field == rhs.field && lhs.value == rhs.value
    }

    private static func isValidFieldName(_ field: String) -> Bool {
        for scalar in field.unicodeScalars {
            if scalar.value >= 127 {
                return false
            }
            let byte = UInt8(scalar.value)
            if !Header.isFieldText(byte) {
                return false
            }
        }
        return true
    }

    private static func isFieldText(_ byte: UInt8) -> Bool {
        if byte == 0x3A {
            return false
        }
        if byte < 0x21 || byte > 0x7E {
            return false
        }
        return true
    }
}

// MARK: - Formatting and parsing helpers
extension Header {
    public static func fold(_ format: FormatOptions, field: String, value: String) -> String {
        foldInternal(format, field: field, value: value)
    }

    private static func encodeAddressHeader(options: ParserOptions, format: FormatOptions, encoding: String.Encoding, field: String, value: String) -> [UInt8] {
        var list: InternetAddressList? = nil
        if !InternetAddressList.tryParse(options, value, addresses: &list) || list == nil {
            return encodeUnstructuredHeader(options: options, format: format, encoding: encoding, field: field, value: value)
        }

        var builder = ""
        builder.append(" ")
        var lineLength = field.count + 2
        list?.encode(format, builder: &builder, firstToken: true, lineLength: &lineLength)
        builder.append(format.newLine)
        return Array(builder.utf8)
    }

    private static func encodeMessageIdHeader(format: FormatOptions, encoding: String.Encoding, value: String) -> [UInt8] {
        let text = " " + value + format.newLine
        return Array(text.data(using: encoding) ?? Data())
    }

    private static func encodeReferencesHeader(format: FormatOptions, encoding: String.Encoding, field: String, value: String) -> [UInt8] {
        var encoded = ValueStringBuilder(initialCapacity: value.count + 8)
        var lineLength = field.count + 1
        var count = 0

        for reference in MimeUtils.enumerateReferences(value) {
            if count > 0 && lineLength + reference.count + 3 > format.maxLineLength {
                encoded.append(format.newLine)
                encoded.append("\t")
                lineLength = 1
                count = 0
            } else {
                encoded.append(" ")
                lineLength += 1
            }

            encoded.append("<")
            encoded.append(reference)
            encoded.append(">")
            lineLength += reference.count + 2
            count += 1
        }

        encoded.append(format.newLine)
        return Array(encoded.toString().data(using: encoding) ?? Data())
    }

    private static func encodeUnstructuredHeader(options: ParserOptions, format: FormatOptions, encoding: String.Encoding, field: String, value: String) -> [UInt8] {
        if format.international {
            if value.count <= format.maxLineLength {
                let text = " " + value + format.newLine
                return Array(text.utf8)
            }
            let folded = foldInternal(format, field: field, value: value)
            return Array(folded.utf8)
        }

        if shouldEncodeAsSingleWord(value) {
            let encodedWord = encodeSingleWord(encoding: encoding, text: value)
            let folded = foldUnstructuredHeader(format, field: field, text: Array(encodedWord.utf8))
            return folded
        }

        let encoded = Rfc2047.encodeText(format, encoding, value)
        let folded = foldUnstructuredHeader(format, field: field, text: encoded)
        return folded
    }

    private static func reformatAddressHeader(options: ParserOptions, format: FormatOptions, field: String, rawValue: [UInt8]) -> [UInt8] {
        var list: InternetAddressList? = nil
        if !InternetAddressList.tryParse(options, rawValue, startIndex: 0, length: rawValue.count, addresses: &list) {
            return rawValue
        }

        var builder = ""
        builder.append(" ")
        var lineLength = field.count + 2
        list?.encode(format, builder: &builder, firstToken: true, lineLength: &lineLength)
        builder.append(format.newLine)
        return Array(builder.utf8)
    }

    private static func reformatContentDisposition(options: ParserOptions, format: FormatOptions, encoding: String.Encoding, field: String, rawValue: [UInt8]) -> [UInt8] {
        if let disposition = try? ContentDisposition.parse(options, rawValue) {
            let encoded = disposition.encode(format, encoding)
            return Array(encoded.utf8)
        }
        return rawValue
    }

    private static func reformatContentType(options: ParserOptions, format: FormatOptions, encoding: String.Encoding, field: String, rawValue: [UInt8]) -> [UInt8] {
        if let contentType = try? ContentType.parse(options, rawValue) {
            let encoded = contentType.encode(format, encoding)
            return Array(encoded.utf8)
        }
        return rawValue
    }

    private static func encodeContentDisposition(options: ParserOptions, format: FormatOptions, encoding: String.Encoding, field: String, value: String) -> [UInt8] {
        if let disposition = try? ContentDisposition.parse(options, value) {
            let encoded = disposition.encode(format, encoding)
            return Array(encoded.utf8)
        }
        return encodeUnstructuredHeader(options: options, format: format, encoding: encoding, field: field, value: value)
    }

    private static func encodeContentType(options: ParserOptions, format: FormatOptions, encoding: String.Encoding, field: String, value: String) -> [UInt8] {
        if let contentType = try? ContentType.parse(options, value) {
            let encoded = contentType.encode(format, encoding)
            return Array(encoded.utf8)
        }
        return encodeUnstructuredHeader(options: options, format: format, encoding: encoding, field: field, value: value)
    }

    private static func encodeReceivedHeader(options: ParserOptions, format: FormatOptions, encoding: String.Encoding, field: String, value: String) -> [UInt8] {
        let rawValue = Array(value.data(using: encoding) ?? Data())
        var tokens: [(start: Int, length: Int)] = []
        var index = 0
        var date = false

        func skipAtom(_ text: [UInt8], _ index: inout Int) {
            _ = (try? ParseUtils.skipCommentsAndWhiteSpace(text, index: &index, endIndex: text.count, throwOnError: false)) ?? false
            _ = ParseUtils.skipAtom(text, index: &index, endIndex: text.count)
        }

        func skipDomain(_ text: [UInt8], _ index: inout Int) {
            _ = (try? ParseUtils.skipCommentsAndWhiteSpace(text, index: &index, endIndex: text.count, throwOnError: false)) ?? false
            if index < text.count, text[index] == UInt8(ascii: "[") {
                while index < text.count && text[index] != UInt8(ascii: "]") {
                    index += 1
                }
                if index < text.count {
                    index += 1
                }
                return
            }
            while ParseUtils.skipAtom(text, index: &index, endIndex: text.count) && index < text.count && text[index] == UInt8(ascii: ".") {
                index += 1
            }
        }

        func skipAddress(_ text: [UInt8], _ index: inout Int) {
            _ = (try? ParseUtils.skipCommentsAndWhiteSpace(text, index: &index, endIndex: text.count, throwOnError: false)) ?? false
            if index < text.count, text[index] == UInt8(ascii: "<") {
                index += 1
            }
            if index >= text.count {
                return
            }
            var address: String? = nil
            var atIndex = 0
            _ = try? InternetAddress.tryParseAddrspec(text, index: &index, endIndex: text.count, sentinels: [UInt8(ascii: ">"), UInt8(ascii: ";")], compliance: .strict, throwOnError: false, addrspec: &address, at: &atIndex)
            if index < text.count, text[index] == UInt8(ascii: ">") {
                index += 1
            }
        }

        func skipMessageId(_ text: [UInt8], _ index: inout Int) {
            _ = (try? ParseUtils.skipCommentsAndWhiteSpace(text, index: &index, endIndex: text.count, throwOnError: false)) ?? false
            if index < text.count, text[index] == UInt8(ascii: "<") {
                index += 1
                if index >= text.count {
                    return
                }
                var address: String? = nil
                var atIndex = 0
                _ = try? InternetAddress.tryParseAddrspec(text, index: &index, endIndex: text.count, sentinels: [UInt8(ascii: ">")], compliance: .strict, throwOnError: false, addrspec: &address, at: &atIndex)
                if index < text.count, text[index] == UInt8(ascii: ">") {
                    index += 1
                }
            } else {
                _ = ParseUtils.skipAtom(text, index: &index, endIndex: text.count)
            }
        }

        while index < rawValue.count {
            let startIndex = index
            if !((try? ParseUtils.skipCommentsAndWhiteSpace(rawValue, index: &index, endIndex: rawValue.count, throwOnError: false)) ?? false) || index >= rawValue.count {
                tokens.append((start: startIndex, length: index - startIndex))
                break
            }

            while index < rawValue.count && !ByteClassification.isWhitespace(rawValue[index]) {
                index += 1
            }

            let atom = String(bytes: rawValue[startIndex..<index], encoding: encoding)?.lowercased() ?? ""
            var matched = true
            switch atom {
            case "from", "by", "via":
                skipDomain(rawValue, &index)
            case "with":
                skipAtom(rawValue, &index)
            case "id":
                skipMessageId(rawValue, &index)
            case "for":
                skipAddress(rawValue, &index)
            default:
                matched = false
            }

            if matched {
                if (try? ParseUtils.skipCommentsAndWhiteSpace(rawValue, index: &index, endIndex: rawValue.count, throwOnError: false)) == true {
                    if index < rawValue.count && rawValue[index] == UInt8(ascii: ";") {
                        date = true
                        index += 1
                    }
                }
                tokens.append((start: startIndex, length: index - startIndex))
            }

            if !matched {
                if (try? ParseUtils.skipCommentsAndWhiteSpace(rawValue, index: &index, endIndex: rawValue.count, throwOnError: false)) == true {
                    while index < rawValue.count && !ByteClassification.isWhitespace(rawValue[index]) {
                        index += 1
                    }
                }
                tokens.append((start: startIndex, length: index - startIndex))
            }

            _ = ParseUtils.skipWhiteSpace(rawValue, index: &index, endIndex: rawValue.count)

            if date && index < rawValue.count {
                tokens.append((start: index, length: rawValue.count - index))
                break
            }
        }

        var encoded = ValueStringBuilder(initialCapacity: rawValue.count + 8)
        var lineLength = field.count + 1
        var count = 0

        for token in tokens {
            let text = String(bytes: rawValue[token.start..<token.start + token.length], encoding: encoding)?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            if count > 0 && lineLength + text.count + 1 > format.maxLineLength {
                encoded.append(format.newLine)
                encoded.append("\t")
                lineLength = 1
                count = 0
            } else {
                encoded.append(" ")
                lineLength += 1
            }
            encoded.append(text)
            lineLength += text.count
            count += 1
        }

        encoded.append(format.newLine)
        return Array(encoded.toString().data(using: encoding) ?? Data())
    }

    private static func encodeDkimLongValue(_ format: FormatOptions, encoded: inout ValueStringBuilder, lineLength: inout Int, value: String) {
        var startIndex = value.startIndex
        while startIndex < value.endIndex {
            let lineLeft = format.maxLineLength - lineLength
            let endIndex = value.index(startIndex, offsetBy: min(lineLeft, value.distance(from: startIndex, to: value.endIndex)))
            encoded.append(String(value[startIndex..<endIndex]))
            lineLength += value.distance(from: startIndex, to: endIndex)
            if endIndex == value.endIndex {
                break
            }
            encoded.append(format.newLine)
            encoded.append("\t")
            lineLength = 1
            startIndex = endIndex
        }
    }

    private static func encodeDkimHeaderList(_ format: FormatOptions, encoded: inout ValueStringBuilder, lineLength: inout Int, value: String, delimiter: Character) {
        let tokens = value.split(separator: delimiter, omittingEmptySubsequences: false)
        for (idx, token) in tokens.enumerated() {
            if idx > 0 {
                encoded.append(String(delimiter))
                lineLength += 1
            }
            if lineLength + token.count + 1 > format.maxLineLength {
                encoded.append(format.newLine)
                encoded.append("\t")
                lineLength = 1
            }
            encoded.append(String(token))
            lineLength += token.count
        }
    }

    private static func encodeDkimOrArcSignatureHeader(format: FormatOptions, encoding: String.Encoding, field: String, value: String) -> [UInt8] {
        var encoded = ValueStringBuilder(initialCapacity: value.count + 8)
        var lineLength = field.count + 1
        var index = value.startIndex

        while index < value.endIndex {
            var token = ValueStringBuilder(initialCapacity: 128)

            while index < value.endIndex && Header.isWhiteSpace(value[index]) {
                index = value.index(after: index)
            }

            let startIndex = index
            while index < value.endIndex && value[index] != "=" {
                if !Header.isWhiteSpace(value[index]) {
                    token.append(value[index])
                }
                index = value.index(after: index)
            }

            let name = String(value[startIndex..<index])

            while index < value.endIndex && value[index] != ";" {
                if !Header.isWhiteSpace(value[index]) {
                    token.append(value[index])
                }
                index = value.index(after: index)
            }

            if index < value.endIndex && value[index] == ";" {
                token.append(";")
                index = value.index(after: index)
            }

            if lineLength + token.length + 1 > format.maxLineLength || name == "bh" || name == "b" {
                encoded.append(format.newLine)
                encoded.append("\t")
                lineLength = 1
            } else {
                encoded.append(" ")
                lineLength += 1
            }

            let tokenString = token.asString()
            if token.length > format.maxLineLength {
                if name == "z" {
                    encodeDkimHeaderList(format, encoded: &encoded, lineLength: &lineLength, value: tokenString, delimiter: "|")
                } else if name == "h" {
                    encodeDkimHeaderList(format, encoded: &encoded, lineLength: &lineLength, value: tokenString, delimiter: ":")
                } else {
                    encodeDkimLongValue(format, encoded: &encoded, lineLength: &lineLength, value: tokenString)
                }
            } else {
                encoded.append(tokenString)
                lineLength += token.length
            }
        }

        encoded.append(format.newLine)
        return Array(encoded.toString().data(using: encoding) ?? Data())
    }

    private static func encodeAuthenticationResultsHeader(format: FormatOptions, encoding: String.Encoding, field: String, value: String) -> [UInt8] {
        var tokens: [String] = []
        var current = ""
        for ch in value {
            if ch == ";" {
                let trimmed = current.trimmingCharacters(in: .whitespacesAndNewlines)
                if !trimmed.isEmpty {
                    tokens.append(trimmed + ";")
                }
                current = ""
            } else {
                current.append(ch)
            }
        }
        let trimmed = current.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmed.isEmpty {
            tokens.append(trimmed)
        }

        var expanded: [String] = []
        for token in tokens {
            var valueToken = token
            var hasSemicolon = false
            if valueToken.hasSuffix(";") {
                valueToken.removeLast()
                hasSemicolon = true
            }

            if let open = valueToken.firstIndex(of: "("), let close = valueToken.lastIndex(of: ")"), open < close {
                let trimmedEnd = valueToken.trimmingCharacters(in: .whitespacesAndNewlines)
                let endsWithComment = trimmedEnd.lastIndex(of: ")") == trimmedEnd.index(before: trimmedEnd.endIndex)
                if !endsWithComment {
                    var combined = valueToken.trimmingCharacters(in: .whitespacesAndNewlines)
                    if hasSemicolon {
                        combined.append(";")
                    }
                    if !combined.isEmpty {
                        expanded.append(combined)
                    }
                    continue
                }
                let prefix = valueToken[..<open].trimmingCharacters(in: .whitespacesAndNewlines)
                let comment = valueToken[open...close].trimmingCharacters(in: .whitespacesAndNewlines)
                if !prefix.isEmpty {
                    expanded.append(prefix)
                }
                if !comment.isEmpty {
                    var commentToken = String(comment)
                    if hasSemicolon {
                        commentToken.append(";")
                        hasSemicolon = false
                    }
                    expanded.append(commentToken)
                }
                if hasSemicolon {
                    expanded.append(";")
                }
            } else {
                var combined = valueToken.trimmingCharacters(in: .whitespacesAndNewlines)
                if hasSemicolon {
                    combined.append(";")
                }
                if !combined.isEmpty {
                    expanded.append(combined)
                }
            }
        }

        var encoded = ValueStringBuilder(initialCapacity: value.count + 8)
        var lineLength = field.count + 1

        for (index, token) in expanded.enumerated() {
            let lower = token.lowercased()
            let forceNewLine = index > 0 && lower.hasPrefix("arc=")
            if forceNewLine || (index > 0 && lineLength + token.count + 1 > format.maxLineLength) {
                encoded.append(format.newLine)
                encoded.append("\t")
                lineLength = 1
            } else {
                encoded.append(" ")
                lineLength += 1
            }

            encoded.append(token)
            lineLength += token.count
        }

        encoded.append(format.newLine)
        return Array(encoded.toString().data(using: encoding) ?? Data())
    }

    private static func shouldEncodeAsSingleWord(_ value: String) -> Bool {
        var hasNonAscii = false
        for scalar in value.unicodeScalars {
            if scalar.value <= 0x7F {
                if !CharacterSet.whitespacesAndNewlines.contains(scalar) {
                    return false
                }
            } else {
                hasNonAscii = true
            }
        }
        return hasNonAscii
    }

    private static func encodeSingleWord(encoding: String.Encoding, text: String) -> String {
        let bytes = CharsetUtils.getBytes(text, encoding: encoding)
        let qpEncoder = Rfc2047QuotedPrintableEncoder(mode: .text)
        let base64Encoder = Rfc2047Base64Encoder()
        let qpLength = qpEncoder.estimateOutputLength(bytes.count)
        let bLength = base64Encoder.estimateOutputLength(bytes.count)
        let encoder: any Rfc2047Encoder = (bLength < qpLength) ? base64Encoder : qpEncoder

        let outputLength = encoder.estimateOutputLength(bytes.count)
        let output = Array(repeating: UInt8(0), count: outputLength)
        var outputOptional: [UInt8]? = output
        let written = (try? encoder.encode(bytes, startIndex: 0, length: bytes.count, output: &outputOptional)) ?? 0
        let encodedText = String(bytes: Array(outputOptional?[0..<written] ?? []), encoding: .ascii) ?? text
        let charset = CharsetUtils.getMimeCharset(encoding)
        let encodingLetter = String(encoder.encoding)
        return "=?\(charset)?\(encodingLetter)?\(encodedText)?="
    }

    private static func isWhiteSpace(_ ch: Character) -> Bool {
        ch == " " || ch == "\t" || ch == "\r" || ch == "\n"
    }

    private static func formatRawValue(options: ParserOptions, format: FormatOptions, encoding: String.Encoding, field: String, id: HeaderId, value: String) -> [UInt8] {
        switch id {
        case .dispositionNotificationTo, .resentReplyTo, .resentSender, .resentFrom, .resentBcc, .resentCc, .resentTo,
                .replyTo, .sender, .from, .bcc, .cc, .to:
            return encodeAddressHeader(options: options, format: format, encoding: encoding, field: field, value: value)
        case .received:
            return encodeReceivedHeader(options: options, format: format, encoding: encoding, field: field, value: value)
        case .originalMessageId, .resentMessageId, .inReplyTo, .messageId, .contentId:
            return encodeMessageIdHeader(format: format, encoding: encoding, value: value)
        case .references:
            return encodeReferencesHeader(format: format, encoding: encoding, field: field, value: value)
        case .contentDisposition:
            return encodeContentDisposition(options: options, format: format, encoding: encoding, field: field, value: value)
        case .contentType:
            return encodeContentType(options: options, format: format, encoding: encoding, field: field, value: value)
        case .arcAuthenticationResults, .authenticationResults:
            return encodeAuthenticationResultsHeader(format: format, encoding: encoding, field: field, value: value)
        case .dkimSignature, .arcMessageSignature, .arcSeal:
            return encodeDkimOrArcSignatureHeader(format: format, encoding: encoding, field: field, value: value)
        default:
            return encodeUnstructuredHeader(options: options, format: format, encoding: encoding, field: field, value: value)
        }
    }

    private static func foldInternal(_ format: FormatOptions, field: String, value: String) -> String {
        var folded = ValueStringBuilder(initialCapacity: value.count + 8)
        var lineLength = field.count + 2
        var lastLwsp: Int? = nil

        folded.append(" ")

        for word in tokenizeText(value) {
            if Header.isWhiteSpace(word.first ?? " ") {
                if lineLength + word.count > format.maxLineLength {
                    for ch in word {
                        if lineLength > format.maxLineLength {
                            folded.append(format.newLine)
                            lineLength = 0
                        }
                        folded.append(ch)
                        lineLength += 1
                    }
                } else {
                    lineLength += word.count
                    folded.append(word)
                }
                lastLwsp = folded.length - 1
                continue
            }

            if let last = lastLwsp, lineLength + word.count > format.maxLineLength {
                folded.insert(format.newLine, at: last)
                lineLength = 1
                lastLwsp = nil
            }

            if word.count > format.maxLineLength {
                var index = word.startIndex
                while index < word.endIndex {
                    let remaining = word.distance(from: index, to: word.endIndex)
                    let allowed = max(format.maxLineLength - lineLength, 1)
                    let take = min(remaining, allowed)
                    let end = word.index(index, offsetBy: take)
                    if lineLength + take > format.maxLineLength {
                        folded.append(format.newLine)
                        folded.append(" ")
                        lineLength = 1
                    }
                    folded.append(String(word[index..<end]))
                    lineLength += take
                    index = end
                }
            } else {
                folded.append(word)
                lineLength += word.count
            }
        }

        folded.append(format.newLine)
        return folded.asString()
    }

    private static func tokenizeText(_ text: String) -> [String] {
        var tokens: [String] = []
        var index = text.startIndex
        while index < text.endIndex {
            let ch = text[index]
            let start = index
            if isWhiteSpace(ch) {
                while index < text.endIndex && isWhiteSpace(text[index]) {
                    index = text.index(after: index)
                }
            } else {
                while index < text.endIndex && !isWhiteSpace(text[index]) {
                    index = text.index(after: index)
                }
            }
            tokens.append(String(text[start..<index]))
        }
        return tokens
    }

    private static func foldUnstructuredHeader(_ format: FormatOptions, field: String, text: [UInt8]) -> [UInt8] {
        let value = String(bytes: text, encoding: .ascii) ?? String(decoding: text, as: UTF8.self)
        let folded = foldInternal(format, field: field, value: value)
        return Array(folded.utf8)
    }
}

// MARK: - Parsing
extension Header {
    public static func tryParse(_ options: ParserOptions, _ buffer: [UInt8], startIndex: Int, length: Int, header: inout Header?) -> Bool {
        let endIndex = startIndex + length
        guard startIndex >= 0, length >= 0, endIndex <= buffer.count else {
            header = nil
            return false
        }

        var index = startIndex
        while index < endIndex && Header.isFieldText(buffer[index]) {
            index += 1
        }

        let fieldNameLength = index - startIndex
        while index < endIndex && ByteClassification.isBlank(buffer[index]) {
            index += 1
        }

        guard index < endIndex, buffer[index] == UInt8(ascii: ":") else {
            header = nil
            return false
        }

        let rawField = Array(buffer[startIndex..<index])
        if fieldNameLength == 0 {
            header = nil
            return false
        }

        index += 1
        var rawValue = Array(buffer[index..<endIndex])
        if rawValue.last != 0x0A {
            rawValue.append(contentsOf: FormatOptions.default.newLineBytes)
        }

        header = Header(options, fieldBytes: rawField, fieldNameLength: fieldNameLength, rawValue: rawValue)
        return true
    }

    public static func tryParse(_ buffer: [UInt8], startIndex: Int, length: Int, header: inout Header?) -> Bool {
        tryParse(.default, buffer, startIndex: startIndex, length: length, header: &header)
    }

    public static func tryParse(_ options: ParserOptions, _ buffer: [UInt8], startIndex: Int, header: inout Header?) -> Bool {
        tryParse(options, buffer, startIndex: startIndex, length: buffer.count - startIndex, header: &header)
    }

    public static func tryParse(_ buffer: [UInt8], startIndex: Int, header: inout Header?) -> Bool {
        tryParse(.default, buffer, startIndex: startIndex, length: buffer.count - startIndex, header: &header)
    }

    public static func tryParse(_ options: ParserOptions, _ buffer: [UInt8], header: inout Header?) -> Bool {
        tryParse(options, buffer, startIndex: 0, length: buffer.count, header: &header)
    }

    public static func tryParse(_ buffer: [UInt8], header: inout Header?) -> Bool {
        tryParse(.default, buffer, startIndex: 0, length: buffer.count, header: &header)
    }

    public static func tryParse(_ options: ParserOptions, _ text: String, header: inout Header?) -> Bool {
        let buffer = CharsetUtils.getBytes(text, encoding: .utf8)
        return tryParse(options, buffer, startIndex: 0, length: buffer.count, header: &header)
    }

    public static func tryParse(_ text: String, header: inout Header?) -> Bool {
        tryParse(.default, text, header: &header)
    }

    public static func parse(_ options: ParserOptions, _ buffer: [UInt8], startIndex: Int, length: Int) throws -> Header {
        var header: Header? = nil
        if tryParse(options, buffer, startIndex: startIndex, length: length, header: &header), let header {
            return header
        }
        throw ParseException("Invalid header.", tokenIndex: startIndex, errorIndex: startIndex)
    }

    public static func parse(_ buffer: [UInt8], startIndex: Int, length: Int) throws -> Header {
        try parse(.default, buffer, startIndex: startIndex, length: length)
    }

    public static func parse(_ options: ParserOptions, _ buffer: [UInt8], startIndex: Int) throws -> Header {
        try parse(options, buffer, startIndex: startIndex, length: buffer.count - startIndex)
    }

    public static func parse(_ buffer: [UInt8], startIndex: Int) throws -> Header {
        try parse(.default, buffer, startIndex: startIndex, length: buffer.count - startIndex)
    }

    public static func parse(_ options: ParserOptions, _ buffer: [UInt8]) throws -> Header {
        try parse(options, buffer, startIndex: 0, length: buffer.count)
    }

    public static func parse(_ buffer: [UInt8]) throws -> Header {
        try parse(.default, buffer, startIndex: 0, length: buffer.count)
    }

    public static func parse(_ options: ParserOptions, _ text: String) throws -> Header {
        let buffer = CharsetUtils.getBytes(text, encoding: .utf8)
        return try parse(options, buffer, startIndex: 0, length: buffer.count)
    }

    public static func parse(_ text: String) throws -> Header {
        try parse(.default, text)
    }
}
