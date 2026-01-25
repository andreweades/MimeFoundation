//
// Parameter.swift
//
// Ported from MimeKit (C#) to Swift.
//

import Foundation

public enum ParameterError: Error {
    case nilEncoding
    case nilName
    case emptyName
    case invalidName
    case nilValue
    case unsupportedCharset
}

public final class Parameter: Equatable, CustomStringConvertible {
    public let name: String
    private var valueStorage: String
    private var encodingStorage: String.Encoding
    private var encodingMethodStorage: ParameterEncodingMethod
    private var alwaysQuoteStorage: Bool

    public var value: String {
        get { valueStorage }
        set {
            guard valueStorage != newValue else { return }
            valueStorage = newValue
            onChanged()
        }
    }

    public var encoding: String.Encoding {
        get { encodingStorage }
        set {
            guard encodingStorage != newValue else { return }
            encodingStorage = newValue
            onChanged()
        }
    }

    public var encodingMethod: ParameterEncodingMethod {
        get { encodingMethodStorage }
        set {
            guard encodingMethodStorage != newValue else { return }
            encodingMethodStorage = newValue
            onChanged()
        }
    }

    public var alwaysQuote: Bool {
        get { alwaysQuoteStorage }
        set {
            guard alwaysQuoteStorage != newValue else { return }
            alwaysQuoteStorage = newValue
            onChanged()
        }
    }

    internal var changed: ((Parameter) -> Void)?

    public init(_ name: String, _ value: String) throws {
        try Parameter.validateName(name)
        self.name = name
        self.valueStorage = value
        self.encodingStorage = .utf8
        self.encodingMethodStorage = .default
        self.alwaysQuoteStorage = false
    }

    public init(encoding: String.Encoding, name: String, value: String) throws {
        try Parameter.validateName(name)
        self.name = name
        self.valueStorage = value
        self.encodingStorage = encoding
        self.encodingMethodStorage = .default
        self.alwaysQuoteStorage = false
    }

    public init(charset: String, name: String, value: String) throws {
        try Parameter.validateName(name)
        guard let resolved = CharsetUtils.getEncoding(charset) else {
            throw ParameterError.unsupportedCharset
        }
        self.name = name
        self.valueStorage = value
        self.encodingStorage = resolved
        self.encodingMethodStorage = .default
        self.alwaysQuoteStorage = false
    }

    /// Internal initializer for cloning. Assumes name is already validated.
    private init(cloning name: String, _ value: String) {
        self.name = name
        self.valueStorage = value
        self.encodingStorage = .utf8
        self.encodingMethodStorage = .default
        self.alwaysQuoteStorage = false
    }

    public convenience init(_ name: String?, _ value: String?) throws {
        guard let name else {
            throw ParameterError.nilName
        }
        guard let value else {
            throw ParameterError.nilValue
        }
        try self.init(name, value)
    }

    public convenience init(encoding: String.Encoding?, name: String?, value: String?) throws {
        guard let encoding else {
            throw ParameterError.nilEncoding
        }
        guard let name else {
            throw ParameterError.nilName
        }
        guard let value else {
            throw ParameterError.nilValue
        }
        try self.init(encoding: encoding, name: name, value: value)
    }

    public convenience init(charset: String?, name: String?, value: String?) throws {
        guard let charset else {
            throw ParameterError.nilEncoding
        }
        guard let name else {
            throw ParameterError.nilName
        }
        guard let value else {
            throw ParameterError.nilValue
        }
        try self.init(charset: charset, name: name, value: value)
    }

    public func setValue(_ value: String?) throws {
        guard let value else {
            throw ParameterError.nilValue
        }
        self.value = value
    }

    public func setEncoding(_ encoding: String.Encoding?) throws {
        guard let encoding else {
            throw ParameterError.nilEncoding
        }
        self.encoding = encoding
    }

    public func setEncodingMethod(_ rawValue: Int) throws {
        guard rawValue >= 0 && rawValue <= Int(UInt8.max) else {
            throw ParameterError.invalidName
        }
        guard let method = ParameterEncodingMethod(rawValue: UInt8(rawValue)) else {
            throw ParameterError.invalidName
        }
        self.encodingMethod = method
    }

    private enum EncodeMethod {
        case none
        case quote
        case rfc2047
        case rfc2231
    }

    public func encode(_ options: FormatOptions, builder: inout ValueStringBuilder, lineLength: inout Int, charset: String.Encoding) {
        let method = getEncodeMethod(options, name: name, value: value)

        switch method.method {
        case .rfc2231:
            encodeRfc2231(options, builder: &builder, lineLength: &lineLength, headerEncoding: charset)
        case .rfc2047:
            encodeRfc2047(options, builder: &builder, lineLength: &lineLength, headerEncoding: charset)
        case .none:
            encodeQuotedOrPlain(options, builder: &builder, lineLength: &lineLength, value: value)
        case .quote:
            encodeQuotedOrPlain(options, builder: &builder, lineLength: &lineLength, value: method.quoted ?? value)
        }
    }

    public func copy() -> Parameter {
        let param = Parameter(cloning: name, value)
        param.encoding = encoding
        param.encodingMethod = encodingMethod
        param.alwaysQuote = alwaysQuote
        return param
    }

    public func writeTo(_ builder: inout ValueStringBuilder) {
        builder.append(name)
        builder.append("=")
        builder.append(MimeUtils.quote(value))
    }

    public var description: String {
        var builder = ValueStringBuilder(initialCapacity: 64)
        writeTo(&builder)
        return builder.asString()
    }

    public static func == (lhs: Parameter, rhs: Parameter) -> Bool {
        lhs.name.caseInsensitiveCompare(rhs.name) == .orderedSame && lhs.value == rhs.value
    }

    private func onChanged() {
        changed?(self)
    }

    private func getEncodeMethod(_ options: FormatOptions, name: String, value: String) -> (method: EncodeMethod, quoted: String?) {
        var method: EncodeMethod = (alwaysQuote || options.alwaysQuoteParameterValues) ? .quote : .none
        let encode: EncodeMethod

        switch encodingMethod {
        case .default:
            encode = (options.parameterEncodingMethod == .rfc2231) ? .rfc2231 : .rfc2047
        case .rfc2231:
            encode = .rfc2231
        case .rfc2047:
            encode = .rfc2047
        }

        if name.utf16.count + 1 + value.utf16.count >= options.maxLineLength {
            return (encode, nil)
        }

        for scalar in value.unicodeScalars {
            if scalar.value < 128 {
                let byte = UInt8(scalar.value)
                if ByteClassification.isCtrl(byte) {
                    return (encode, nil)
                }
                if !ByteClassification.isAttr(byte) {
                    method = .quote
                }
            } else if options.international {
                method = .quote
            } else {
                return (encode, nil)
            }
        }

        if method == .quote {
            let quoted = MimeUtils.quote(value)
            if name.utf16.count + 1 + quoted.utf16.count >= options.maxLineLength {
                return (encode, nil)
            }
            return (.quote, quoted)
        }

        return (method, nil)
    }

    private static func getEncodeMethod(_ options: FormatOptions, _ value: [UInt16], startIndex: Int, length: Int) -> EncodeMethod {
        var method: EncodeMethod = .none
        let end = startIndex + length

        for idx in startIndex..<end {
            let unit = value[idx]
            if unit < 128 {
                let byte = UInt8(unit)
                if ByteClassification.isCtrl(byte) {
                    return .rfc2231
                }
                if !ByteClassification.isAttr(byte) {
                    method = .quote
                }
            } else if options.international {
                method = .quote
            } else {
                return .rfc2231
            }
        }

        return method
    }

    private static func getEncodeMethod(_ options: FormatOptions, _ value: [UInt8], length: Int) -> EncodeMethod {
        var method: EncodeMethod = .none
        if length == 0 {
            return method
        }
        let end = min(length, value.count)

        for idx in 0..<end {
            let byte = value[idx]
            if byte < 128 {
                if ByteClassification.isCtrl(byte) {
                    return .rfc2231
                }
                if !ByteClassification.isAttr(byte) {
                    method = .quote
                }
            } else if options.international {
                method = .quote
            } else {
                return .rfc2231
            }
        }

        return method
    }

    private static func getBestEncoding(_ value: String, defaultEncoding: String.Encoding) -> String.Encoding {
        var encodingChoice = 0 // ascii
        for scalar in value.unicodeScalars {
            if scalar.value < 127 {
                if ByteClassification.isCtrl(UInt8(scalar.value)) {
                    encodingChoice = max(encodingChoice, 1)
                }
            } else if scalar.value < 256 {
                encodingChoice = max(encodingChoice, 1)
            } else {
                encodingChoice = 2
            }
        }

        switch encodingChoice {
        case 0:
            return .ascii
        case 1:
            return .isoLatin1
        default:
            return defaultEncoding
        }
    }

    private func encodeQuotedOrPlain(_ options: FormatOptions, builder: inout ValueStringBuilder, lineLength: inout Int, value: String) {
        builder.append(";")
        lineLength += 1

        let paramLength = name.utf16.count + 1 + value.utf16.count
        if lineLength + 1 + paramLength >= options.maxLineLength {
            builder.append(options.newLine)
            builder.append("\t")
            lineLength = 1
        } else {
            builder.append(" ")
            lineLength += 1
        }

        builder.append(name)
        builder.append("=")
        builder.append(value)
        lineLength += paramLength
    }

    private static func stringFromUtf16(_ units: [UInt16], startIndex: Int, length: Int) -> String {
        let end = startIndex + length
        let slice = units[startIndex..<end]
        return String(decoding: slice, as: UTF16.self)
    }

    private static func rfc2231GetNextValue(
        _ options: FormatOptions,
        charset: String,
        encoding: String.Encoding,
        units: [UInt16],
        isFirstValue: inout Bool,
        index: inout Int,
        maxLength: Int
    ) -> (encoded: Bool, value: String) {
        var length = units.count - index
        var requiresCharset = false
        var adjustedMax = maxLength

        if isFirstValue {
            let method = getEncodeMethod(options, units, startIndex: 0, length: units.count)
            requiresCharset = method == .rfc2231

            if requiresCharset {
                let charsetLength = charset.utf16.count + 2
                if charsetLength >= adjustedMax {
                    isFirstValue = false
                    return (true, "\(charset)''")
                }
                adjustedMax -= charsetLength
            }
        }

        length = min(adjustedMax, length)
        let hex = HexEncoder()

        while length > 0 {
            let substring = stringFromUtf16(units, startIndex: index, length: length)
            let bytes = CharsetUtils.getBytes(substring, encoding: encoding)
            let count = bytes.count

            if count > adjustedMax && length > 1 {
                let ratio = Int(round(Double(count) / Double(length)))
                if ratio > 1 {
                    length -= max((count - adjustedMax) / ratio, 1)
                } else {
                    length -= 1
                }
                continue
            }

            if !requiresCharset {
                let method = getEncodeMethod(options, bytes, length: count)
                if method == .quote {
                    let value = MimeUtils.quote(String(bytes: bytes, encoding: .utf8) ?? substring)
                    index += length
                    return (false, value)
                }
                if method == .none {
                    let value = String(bytes: bytes, encoding: .utf8) ?? substring
                    index += length
                    return (false, value)
                }
            }

            let outputLength = hex.estimateOutputLength(count)
            var output = Array(repeating: UInt8(0), count: outputLength)
            let written = (try? hex.encode(bytes, startIndex: 0, length: count, output: &output)) ?? 0
            let encoded = String(bytes: output.prefix(written), encoding: .ascii) ?? ""
            let encodedCount = encoded.count

            if length > 1 && encodedCount > 3 && encodedCount > adjustedMax {
                var x = 0
                let bytes = Array(encoded.utf8)
                var idx = bytes.count - 1
                let limit = adjustedMax
                while idx >= 0 && idx >= limit {
                    if bytes[idx] == UInt8(ascii: "%") {
                        x -= 1
                    } else {
                        x += 1
                    }
                    idx -= 1
                }
                let ratio = Int(round(Double(count) / Double(length)))
                if ratio > 1 {
                    length -= max(x / ratio, 1)
                } else {
                    length -= 1
                }
                continue
            }

            if requiresCharset {
                isFirstValue = false
                index += length
                return (true, "\(charset)''\(encoded)")
            }

            index += length
            return (true, encoded)
        }

        return (false, "")
    }

    private func encodeRfc2231(_ options: FormatOptions, builder: inout ValueStringBuilder, lineLength: inout Int, headerEncoding: String.Encoding) {
        let bestEncoding = Parameter.getBestEncoding(value, defaultEncoding: encoding)
        let charset = CharsetUtils.getMimeCharset(bestEncoding)
        let maxLength = max(options.maxLineLength - (name.utf16.count + 6), 3)
        let units = Array(value.utf16)
        var isFirstValue = true
        var index = 0
        var segment = 0

        while index < units.count || (units.isEmpty && segment == 0) {
            builder.append(";")
            lineLength += 1

            let priorIndex = index
            var next = Parameter.rfc2231GetNextValue(options, charset: charset, encoding: bestEncoding, units: units, isFirstValue: &isFirstValue, index: &index, maxLength: maxLength)
            if next.value.isEmpty && index == priorIndex && priorIndex < units.count {
                let substring = Parameter.stringFromUtf16(units, startIndex: priorIndex, length: 1)
                let bytes = CharsetUtils.getBytes(substring, encoding: bestEncoding)
                let hex = HexEncoder()
                let outputLength = hex.estimateOutputLength(bytes.count)
                var output = Array(repeating: UInt8(0), count: outputLength)
                let written = (try? hex.encode(bytes, startIndex: 0, length: bytes.count, output: &output)) ?? 0
                let encoded = String(bytes: output.prefix(written), encoding: .ascii) ?? ""
                if isFirstValue {
                    next = (true, "\(charset)''\(encoded)")
                    isFirstValue = false
                } else {
                    next = (true, encoded)
                }
                index = priorIndex + 1
            }
            let isEncoded = next.encoded
            let valuePart = next.value
            var length = name.utf16.count + (isEncoded ? 1 : 0) + 1 + valuePart.utf16.count

            if segment == 0 && index == units.count {
                if lineLength + 1 + length >= options.maxLineLength {
                    builder.append(options.newLine)
                    builder.append("\t")
                    lineLength = 1
                } else {
                    builder.append(" ")
                    lineLength += 1
                }

                builder.append(name)
                if isEncoded {
                    builder.append("*")
                }
                builder.append("=")
                builder.append(valuePart)
                lineLength += length
                return
            }

            builder.append(options.newLine)
            builder.append("\t")
            lineLength = 1

            let id = String(segment)
            length += id.utf16.count + 1

            builder.append(name)
            builder.append("*")
            builder.append(id)
            if isEncoded {
                builder.append("*")
            }
            builder.append("=")
            builder.append(valuePart)
            lineLength += length
            segment += 1
        }
    }

    private static func estimateEncodedWordLength(charset: String, byteCount: Int, encodeCount: Int) -> Int {
        let base = charset.utf16.count + 7
        if Double(encodeCount) < Double(byteCount) * 0.17 {
            return base + (byteCount - encodeCount) + (encodeCount * 3)
        }
        return base + ((byteCount + 2) / 3) * 4
    }

    private static func exceedsMaxWordLength(charset: String, byteCount: Int, encodeCount: Int, maxLength: Int) -> Bool {
        let length = estimateEncodedWordLength(charset: charset, byteCount: byteCount, encodeCount: encodeCount)
        return length + 1 >= maxLength
    }

    private static func appendEncodedWord(
        builder: inout ValueStringBuilder,
        encoding: String.Encoding,
        charset: String,
        units: [UInt16],
        startIndex: Int,
        length: Int,
        encodeCount: Int,
        byteCount: Int
    ) -> Int {
        let substring = stringFromUtf16(units, startIndex: startIndex, length: length)
        let bytes = CharsetUtils.getBytes(substring, encoding: encoding)
        var nonAscii = 0
        for byte in bytes where byte > 127 {
            nonAscii += 1
        }
        let useQ = Double(nonAscii) < Double(bytes.count) * 0.17
        let encoder: any Rfc2047Encoder = useQ ? Rfc2047QuotedPrintableEncoder(mode: .text) : Rfc2047Base64Encoder()

        let outputLength = encoder.estimateOutputLength(bytes.count)
        var output = Array(repeating: UInt8(0), count: outputLength)
        let written = (try? encoder.encode(bytes, startIndex: 0, length: bytes.count, output: &output)) ?? 0
        let encoded = String(bytes: output.prefix(written), encoding: .ascii) ?? ""

        let before = builder.length
        builder.append("=?")
        builder.append(charset)
        builder.append("?")
        builder.append(String(encoder.encoding))
        builder.append("?")
        builder.append(encoded)
        builder.append("?=")
        return builder.length - before
    }

    private static func rfc2047EncodeNextChunk(
        builder: inout ValueStringBuilder,
        units: [UInt16],
        index: inout Int,
        encoding: String.Encoding,
        charset: String,
        maxLength: Int
    ) -> Int {
        var byteCount = 0
        var charCount = 0
        var encodeCount = 0
        let startIndex = index

        while index < units.count {
            let unit = units[index]
            var nchars = 1
            var nbytes = 1
            var encodeAdded = 0

            if unit < 127 {
                let c = UInt8(unit)
                if ByteClassification.isCtrl(c) || c == 0x22 || c == 0x5C {
                    encodeCount += 1
                    encodeAdded = 1
                }
                byteCount += 1
                charCount += 1
            } else if unit < 256 {
                encodeCount += 1
                encodeAdded = 1
                byteCount += 1
                charCount += 1
            } else {
                if unit >= 0xD800 && unit <= 0xDBFF && index + 1 < units.count {
                    let next = units[index + 1]
                    if next >= 0xDC00 && next <= 0xDFFF {
                        nchars = 2
                    }
                }

                let substring = stringFromUtf16(units, startIndex: index, length: nchars)
                let bytes = CharsetUtils.getBytes(substring, encoding: encoding)
                nbytes = max(1, bytes.count)
                encodeCount += nbytes
                encodeAdded = nbytes
                byteCount += nbytes
                charCount += nchars
            }

            index += nchars

            if exceedsMaxWordLength(charset: charset, byteCount: byteCount, encodeCount: encodeCount, maxLength: maxLength) {
                charCount -= nchars
                index -= nchars
                byteCount -= nbytes
                encodeCount -= encodeAdded
                break
            }
        }

        if charCount <= 0 {
            return 0
        }

        return appendEncodedWord(
            builder: &builder,
            encoding: encoding,
            charset: charset,
            units: units,
            startIndex: startIndex,
            length: charCount,
            encodeCount: encodeCount,
            byteCount: byteCount
        )
    }

    private func encodeRfc2047(_ options: FormatOptions, builder: inout ValueStringBuilder, lineLength: inout Int, headerEncoding: String.Encoding) {
        let bestEncoding = Parameter.getBestEncoding(value, defaultEncoding: encoding)
        let charset = CharsetUtils.getMimeCharset(bestEncoding)
        let units = Array(value.utf16)
        var index = 0

        builder.append(";")
        lineLength += 1

        if lineLength + name.utf16.count + charset.utf16.count + 10 + min(units.count, 10) >= options.maxLineLength {
            builder.append(options.newLine)
            builder.append("\t")
            lineLength = 1
        } else {
            builder.append(" ")
            lineLength += 1
        }

        builder.append(name)
        builder.append("=\"")
        lineLength += name.utf16.count + 2

        while index < units.count {
            let length = Parameter.rfc2047EncodeNextChunk(
                builder: &builder,
                units: units,
                index: &index,
                encoding: bestEncoding,
                charset: charset,
                maxLength: (options.maxLineLength - lineLength) - 1
            )
            lineLength += length

            if index >= units.count {
                break
            }

            builder.append(options.newLine)
            builder.append("\t")
            lineLength = 1
        }

        builder.append("\"")
        lineLength += 1
    }

    private static func validateName(_ name: String?) throws {
        guard let name else {
            throw ParameterError.nilName
        }
        if name.isEmpty {
            throw ParameterError.emptyName
        }
        for byte in name.utf8 {
            if byte > 0x7F || !ByteClassification.isAttr(byte) {
                throw ParameterError.invalidName
            }
        }
    }
}
