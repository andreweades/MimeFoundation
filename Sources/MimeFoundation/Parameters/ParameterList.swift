//
// ParameterList.swift
//
// Ported from MimeKit (C#) to Swift.
//

import Foundation

public enum ParameterListError: Error, Sendable {
    case nilParameter
    case nilName
    case nilValue
    case invalidName
    case duplicateName
    case indexOutOfRange
    case nilArray
    case insufficientCapacity
    case nilEncoding
    case unsupportedCharset
}

public final class ParameterList: RandomAccessCollection, MutableCollection, ExpressibleByArrayLiteral, Equatable {
    public typealias Element = Parameter
    public typealias Index = Int

    private var parameters: [Parameter]

    internal var changed: ((ParameterList) -> Void)?

    public init() {
        self.parameters = []
    }

    public init(arrayLiteral elements: Parameter...) {
        self.parameters = []
        for element in elements {
            attach(element)
            self.parameters.append(element)
        }
    }

    public var startIndex: Int { parameters.startIndex }
    public var endIndex: Int { parameters.endIndex }

    public func index(after i: Int) -> Int {
        parameters.index(after: i)
    }

    public var count: Int { parameters.count }
    public var isReadOnly: Bool { false }

    public subscript(position: Int) -> Parameter {
        get {
            precondition(position >= 0 && position < parameters.count, "Index out of range")
            return parameters[position]
        }
        set {
            guard position >= 0 && position < parameters.count else {
                preconditionFailure("Index out of range")
            }
            let nameKey = newValue.name.lowercased()
            if let existing = indexOfName(nameKey), existing != position {
                preconditionFailure("Duplicate parameter name")
            }
            detach(parameters[position])
            attach(newValue)
            parameters[position] = newValue
            onChanged()
        }
    }

    public subscript(name: String) -> String? {
        get {
            guard let index = indexOfName(name) else {
                return nil
            }
            return parameters[index].value
        }
        set {
            if let value = newValue {
                if let index = indexOfName(name) {
                    if parameters[index].value == value {
                        return
                    }
                    parameters[index].value = value
                } else if let param = try? Parameter(name, value) {
                    _ = try? add(param)
                }
            } else {
                if indexOfName(name) != nil {
                    _ = remove(name)
                }
            }
        }
    }

    public func add(_ parameter: Parameter) throws {
        if indexOfName(parameter.name) != nil {
            throw ParameterListError.duplicateName
        }
        attach(parameter)
        parameters.append(parameter)
        onChanged()
    }

    public func add(_ parameter: Parameter?) throws {
        guard let parameter else {
            throw ParameterListError.nilParameter
        }
        try add(parameter)
    }

    public func add(_ name: String, _ value: String) throws {
        let parameter = try Parameter(name, value)
        try add(parameter)
    }

    public func add(_ name: String?, _ value: String?) throws {
        guard let name else {
            throw ParameterListError.nilName
        }
        guard let value else {
            throw ParameterListError.nilValue
        }
        try add(name, value)
    }

    public func add(_ encoding: String.Encoding?, _ name: String?, _ value: String?) throws {
        guard let encoding else {
            throw ParameterListError.nilEncoding
        }
        guard let name else {
            throw ParameterListError.nilName
        }
        guard let value else {
            throw ParameterListError.nilValue
        }
        let parameter = try Parameter(encoding: encoding, name: name, value: value)
        try add(parameter)
    }

    public func add(_ charset: String?, _ name: String?, _ value: String?) throws {
        guard let charset else {
            throw ParameterListError.nilEncoding
        }
        guard let name else {
            throw ParameterListError.nilName
        }
        guard let value else {
            throw ParameterListError.nilValue
        }
        do {
            let parameter = try Parameter(charset: charset, name: name, value: value)
            try add(parameter)
        } catch ParameterError.unsupportedCharset {
            throw ParameterListError.unsupportedCharset
        }
    }

    public func contains(_ parameter: Parameter) -> Bool {
        parameters.contains(where: { $0 === parameter })
    }

    public func contains(_ parameter: Parameter?) throws -> Bool {
        guard let parameter else {
            throw ParameterListError.nilParameter
        }
        return contains(parameter)
    }

    public func contains(_ name: String) -> Bool {
        indexOfName(name) != nil
    }

    public func contains(_ name: String?) throws -> Bool {
        guard let name else {
            throw ParameterListError.nilName
        }
        return contains(name)
    }

    public func copyTo(_ array: inout [Parameter]?, _ arrayIndex: Int) throws {
        guard var target = array else {
            throw ParameterListError.nilArray
        }
        guard arrayIndex >= 0 else {
            throw ParameterListError.indexOutOfRange
        }
        guard arrayIndex + parameters.count <= target.count else {
            throw ParameterListError.insufficientCapacity
        }
        for (offset, param) in parameters.enumerated() {
            target[arrayIndex + offset] = param
        }
        array = target
    }

    public func indexOf(_ parameter: Parameter) -> Int {
        parameters.firstIndex(where: { $0 === parameter }) ?? -1
    }

    public func indexOf(_ parameter: Parameter?) throws -> Int {
        guard let parameter else {
            throw ParameterListError.nilParameter
        }
        return indexOf(parameter)
    }

    public func indexOf(_ name: String) -> Int {
        indexOfName(name) ?? -1
    }

    public func indexOf(_ name: String?) throws -> Int {
        guard let name else {
            throw ParameterListError.nilName
        }
        return indexOfName(name) ?? -1
    }

    public func insert(_ index: Int, _ parameter: Parameter) throws {
        guard index >= 0 && index <= parameters.count else {
            throw ParameterListError.indexOutOfRange
        }
        if indexOfName(parameter.name) != nil {
            throw ParameterListError.duplicateName
        }
        attach(parameter)
        parameters.insert(parameter, at: index)
        onChanged()
    }

    public func insert(_ index: Int, _ parameter: Parameter?) throws {
        guard let parameter else {
            throw ParameterListError.nilParameter
        }
        try insert(index, parameter)
    }

    public func insert(_ index: Int, _ name: String?, _ value: String?) throws {
        guard let name else {
            throw ParameterListError.nilName
        }
        guard let value else {
            throw ParameterListError.nilValue
        }
        let parameter = try Parameter(name, value)
        try insert(index, parameter)
    }

    @discardableResult
    public func remove(_ parameter: Parameter) -> Bool {
        guard let index = parameters.firstIndex(where: { $0 === parameter }) else {
            return false
        }
        detach(parameters[index])
        parameters.remove(at: index)
        onChanged()
        return true
    }

    @discardableResult
    public func remove(_ parameter: Parameter?) throws -> Bool {
        guard let parameter else {
            throw ParameterListError.nilParameter
        }
        return remove(parameter)
    }

    @discardableResult
    public func remove(_ name: String) -> Bool {
        guard let index = indexOfName(name) else {
            return false
        }
        detach(parameters[index])
        parameters.remove(at: index)
        onChanged()
        return true
    }

    @discardableResult
    public func remove(_ name: String?) throws -> Bool {
        guard let name else {
            throw ParameterListError.nilName
        }
        return remove(name)
    }

    public func removeAt(_ index: Int) throws {
        guard index >= 0 && index < parameters.count else {
            throw ParameterListError.indexOutOfRange
        }
        detach(parameters[index])
        parameters.remove(at: index)
        onChanged()
    }

    public func clear() {
        for param in parameters {
            detach(param)
        }
        parameters.removeAll(keepingCapacity: true)
        onChanged()
    }

    public func tryGetValue(_ name: String?, _ parameter: inout Parameter?) throws -> Bool {
        guard let name else {
            throw ParameterListError.nilName
        }
        if let index = indexOfName(name) {
            parameter = parameters[index]
            return true
        }
        parameter = nil
        return false
    }

    public func tryGetValue(_ name: String?, _ value: inout String?) throws -> Bool {
        guard let name else {
            throw ParameterListError.nilName
        }
        if let index = indexOfName(name) {
            value = parameters[index].value
            return true
        }
        value = nil
        return false
    }

    public func toString() -> String {
        var builder = ValueStringBuilder(initialCapacity: 128)
        writeTo(&builder)
        return builder.asString()
    }

    internal func writeTo(_ builder: inout ValueStringBuilder) {
        for param in parameters {
            builder.append("; ")
            param.writeTo(&builder)
        }
    }

    internal func encode(_ options: FormatOptions, builder: inout ValueStringBuilder, lineLength: inout Int, charset: String.Encoding) {
        for param in parameters {
            param.encode(options, builder: &builder, lineLength: &lineLength, charset: charset)
        }
    }

    private struct NameValuePair {
        let valueLength: Int
        let valueStart: Int
        let encoded: Bool
        let value: [UInt8]
        let name: String
        let id: Int?
    }

    private static func skipParamName(_ text: [UInt8], index: inout Int, endIndex: Int) -> Bool {
        let start = index
        while index < endIndex && ByteClassification.isAttr(text[index]) {
            index += 1
        }
        return index > start
    }

    private static func tryParseNameValuePair(
        _ options: ParserOptions,
        _ text: [UInt8],
        index: inout Int,
        endIndex: Int,
        throwOnError: Bool,
        pair: inout NameValuePair?
    ) throws -> Bool {
        var encoded = false
        var id: Int? = nil
        pair = nil

        if !(try ParseUtils.skipCommentsAndWhiteSpace(text, index: &index, endIndex: endIndex, throwOnError: throwOnError)) {
            return false
        }

        let startIndex = index
        if !skipParamName(text, index: &index, endIndex: endIndex) {
            if throwOnError {
                throw ParseException("Invalid parameter name token at offset \(startIndex)", tokenIndex: startIndex, errorIndex: index)
            }
            return false
        }

        let name = String(bytes: text[startIndex..<index], encoding: .ascii) ?? ""

        if !(try ParseUtils.skipCommentsAndWhiteSpace(text, index: &index, endIndex: endIndex, throwOnError: throwOnError)) {
            return false
        }

        if index >= endIndex {
            if throwOnError {
                throw ParseException("Incomplete parameter at offset \(startIndex)", tokenIndex: startIndex, errorIndex: index)
            }
            return false
        }

        if text[index] == 0x2A { // '*'
            index += 1

            if !(try ParseUtils.skipCommentsAndWhiteSpace(text, index: &index, endIndex: endIndex, throwOnError: throwOnError)) {
                return false
            }

            if index >= endIndex {
                if throwOnError {
                    throw ParseException("Incomplete parameter at offset \(startIndex)", tokenIndex: startIndex, errorIndex: index)
                }
                return false
            }

            var identifier = 0
            if ParseUtils.tryParseInt32(text, index: &index, endIndex: endIndex, value: &identifier) {
                if !(try ParseUtils.skipCommentsAndWhiteSpace(text, index: &index, endIndex: endIndex, throwOnError: throwOnError)) {
                    return false
                }
                if index >= endIndex {
                    if throwOnError {
                        throw ParseException("Incomplete parameter at offset \(startIndex)", tokenIndex: startIndex, errorIndex: index)
                    }
                    return false
                }
                if text[index] == 0x2A {
                    encoded = true
                    index += 1
                    if !(try ParseUtils.skipCommentsAndWhiteSpace(text, index: &index, endIndex: endIndex, throwOnError: throwOnError)) {
                        return false
                    }
                    if index >= endIndex {
                        if throwOnError {
                            throw ParseException("Incomplete parameter at offset \(startIndex)", tokenIndex: startIndex, errorIndex: index)
                        }
                        return false
                    }
                }
                id = identifier
            } else {
                encoded = true
            }
        }

        if text[index] != 0x3D { // '='
            if throwOnError {
                throw ParseException("Incomplete parameter at offset \(startIndex)", tokenIndex: startIndex, errorIndex: index)
            }
            return false
        }

        index += 1

        if !(try ParseUtils.skipCommentsAndWhiteSpace(text, index: &index, endIndex: endIndex, throwOnError: throwOnError)) {
            return false
        }

        if index >= endIndex {
            if throwOnError {
                throw ParseException("Incomplete parameter at offset \(startIndex)", tokenIndex: startIndex, errorIndex: index)
            }
            return false
        }

        var valueIndex = index
        var value = text
        var valueLength = 0

        if text[index] == 0x22 {
            _ = try ParseUtils.skipQuoted(text, index: &index, endIndex: endIndex, throwOnError: throwOnError)
            valueLength = index - valueIndex
        } else if options.parameterComplianceMode == .strict {
            _ = ParseUtils.skipToken(text, index: &index, endIndex: endIndex)
            valueLength = index - valueIndex
        } else {
            while index < endIndex && text[index] != 0x3B && text[index] != 0x0D && text[index] != 0x0A {
                index += 1
            }
            valueLength = index - valueIndex

            if index < endIndex && text[index] != 0x3B {
                var buffer = ByteArrayBuilder(initialCapacity: 256)
                buffer.append(text, startIndex: valueIndex, count: valueLength)

                repeat {
                    while index < endIndex && (text[index] == 0x0D || text[index] == 0x0A) {
                        index += 1
                    }
                    valueIndex = index
                    while index < endIndex && text[index] != 0x3B && text[index] != 0x0D && text[index] != 0x0A {
                        index += 1
                    }
                    buffer.append(text, startIndex: valueIndex, count: index - valueIndex)
                } while index < endIndex && text[index] != 0x3B

                value = buffer.toArray()
                valueLength = value.count
                valueIndex = 0
            }

            while valueLength > valueIndex && ByteClassification.isWhitespace(value[valueLength - 1]) {
                valueLength -= 1
            }
        }

        pair = NameValuePair(
            valueLength: valueLength,
            valueStart: valueIndex,
            encoded: encoded,
            value: value,
            name: name,
            id: id
        )
        return true
    }

    private static func tryGetCharset(_ text: [UInt8], index: inout Int, endIndex: Int) -> String? {
        let startIndex = index
        var charsetEnd = 0
        var i = index

        while i < endIndex {
            if text[i] == 0x27 { // '\''
                break
            }
            i += 1
        }
        if i == startIndex || i == endIndex {
            return nil
        }
        charsetEnd = i

        i += 1
        while i < endIndex {
            if text[i] == 0x27 {
                break
            }
            i += 1
        }
        if i == endIndex {
            return nil
        }

        let charset = String(bytes: text[startIndex..<charsetEnd], encoding: .ascii) ?? ""
        index = i + 1
        return charset
    }

    private static func decodeRfc2231Bytes(
        _ text: [UInt8],
        startIndex: Int,
        count: Int,
        isFirstSegment: Bool,
        encoding: inout String.Encoding?
    ) -> [UInt8] {
        var index = startIndex
        let endIndex = startIndex + count
        if isFirstSegment {
            if let charset = tryGetCharset(text, index: &index, endIndex: endIndex) {
                if let resolved = CharsetUtils.getEncoding(charset) {
                    encoding = resolved
                } else {
                    encoding = .isoLatin1
                }
            } else if encoding == nil {
                encoding = .isoLatin1
            }
        }

        let hex = HexDecoder()
        let length = endIndex - index
        let outputLength = hex.estimateOutputLength(length)
        var output = Array(repeating: UInt8(0), count: outputLength)
        let written = (try? hex.decode(text, startIndex: index, length: length, output: &output)) ?? 0
        return Array(output.prefix(written))
    }

    internal static func tryParse(
        _ options: ParserOptions,
        _ text: [UInt8],
        index: inout Int,
        endIndex: Int,
        throwOnError: Bool,
        paramList: inout ParameterList?
    ) throws -> Bool {
        var rfc2231: [String: [NameValuePair]] = [:]
        var params: [NameValuePair] = []
        paramList = nil

        while true {
            if !(try ParseUtils.skipCommentsAndWhiteSpace(text, index: &index, endIndex: endIndex, throwOnError: throwOnError)) {
                return false
            }

            if index >= endIndex {
                break
            }

            if text[index] == 0x3B {
                index += 1
                continue
            }

            var pair: NameValuePair?
            if !(try tryParseNameValuePair(options, text, index: &index, endIndex: endIndex, throwOnError: throwOnError, pair: &pair)) {
                return false
            }

            guard let parsed = pair else {
                return false
            }

            if !(try ParseUtils.skipCommentsAndWhiteSpace(text, index: &index, endIndex: endIndex, throwOnError: throwOnError)) {
                return false
            }

            if parsed.id != nil {
                var list = rfc2231[parsed.name] ?? []
                let isFirst = list.isEmpty
                list.append(parsed)
                rfc2231[parsed.name] = list
                if isFirst {
                    params.append(parsed)
                }
            } else {
                params.append(parsed)
            }

            if index >= endIndex {
                break
            }

            if text[index] != 0x3B {
                if options.parameterComplianceMode == .strict {
                    if throwOnError {
                        throw ParseException("Invalid parameter list token at offset \(index)", tokenIndex: index, errorIndex: index)
                    }
                    return false
                }
            } else {
                index += 1
            }
        }

        let list = ParameterList()

        for param in params {
            var method: ParameterEncodingMethod = .default
            var startIndex = param.valueStart
            var length = param.valueLength
            var buffer = param.value
            var encoding: String.Encoding? = nil
            var value = ""

            if let _ = param.id, let parts = rfc2231[param.name] {
                method = .rfc2231
                let sorted = parts.sorted { (lhs, rhs) -> Bool in
                    (lhs.id ?? -1) < (rhs.id ?? -1)
                }

                var pendingBytes: [UInt8] = []
                for (idx, part) in sorted.enumerated() {
                    startIndex = part.valueStart
                    length = part.valueLength
                    buffer = part.value

                    if part.encoded {
                        if length >= 2 && buffer[startIndex] == 0x22 && buffer[startIndex + length - 1] == 0x22 {
                            startIndex += 1
                            length -= 2
                        }
                        let decoded = decodeRfc2231Bytes(buffer, startIndex: startIndex, count: length, isFirstSegment: idx == 0, encoding: &encoding)
                        pendingBytes.append(contentsOf: decoded)

                        let isLastEncoded = idx + 1 >= sorted.count || !sorted[idx + 1].encoded
                        if isLastEncoded {
                            let decodedString = String(data: Data(pendingBytes), encoding: encoding ?? .isoLatin1)
                                ?? String(decoding: pendingBytes, as: UTF8.self)
                            value.append(decodedString)
                            pendingBytes.removeAll(keepingCapacity: true)
                        }
                    } else if length >= 2 && buffer[startIndex] == 0x22 {
                        if !pendingBytes.isEmpty {
                            let decodedString = String(data: Data(pendingBytes), encoding: encoding ?? .isoLatin1)
                                ?? String(decoding: pendingBytes, as: UTF8.self)
                            value.append(decodedString)
                            pendingBytes.removeAll(keepingCapacity: true)
                        }
                        let quoted = CharsetUtils.convertToUnicode(options, buffer, start: startIndex, length: length)
                        value.append(MimeUtils.unquote(quoted))
                    } else if length > 0 {
                        if !pendingBytes.isEmpty {
                            let decodedString = String(data: Data(pendingBytes), encoding: encoding ?? .isoLatin1)
                                ?? String(decoding: pendingBytes, as: UTF8.self)
                            value.append(decodedString)
                            pendingBytes.removeAll(keepingCapacity: true)
                        }
                        value.append(CharsetUtils.convertToUnicode(options, buffer, start: startIndex, length: length))
                    }
                }

                if !pendingBytes.isEmpty {
                    let decodedString = String(data: Data(pendingBytes), encoding: encoding ?? .isoLatin1)
                        ?? String(decoding: pendingBytes, as: UTF8.self)
                    value.append(decodedString)
                }
            } else if param.encoded {
                if length >= 2 && buffer[startIndex] == 0x22 {
                    if buffer[startIndex + length - 1] == 0x22 {
                        length -= 1
                    }
                    startIndex += 1
                    length -= 1
                }
                let decodedBytes = decodeRfc2231Bytes(buffer, startIndex: startIndex, count: length, isFirstSegment: true, encoding: &encoding)
                value = String(data: Data(decodedBytes), encoding: encoding ?? .isoLatin1)
                    ?? String(decoding: decodedBytes, as: UTF8.self)
                method = .rfc2231
            } else if list.contains(param.name) {
                continue
            } else {
                var codepage = -1
                if length >= 2 && buffer[startIndex] == 0x22 {
                    let unquoted = MimeUtils.unquote(buffer, startIndex: startIndex, length: length)
                    value = Rfc2047.decodeText(options, unquoted, startIndex: 0, count: unquoted.count, codepage: &codepage)
                } else if length > 0 {
                    value = Rfc2047.decodeText(options, buffer, startIndex: startIndex, count: length, codepage: &codepage)
                } else {
                    value = ""
                }

                if codepage != -1 && codepage != 65001 {
                    encoding = CharsetUtils.getEncodingOrDefault(codepage, fallback: .utf8)
                    method = .rfc2047
                }
            }

            let existingIndex = list.indexOf(param.name)
            if existingIndex != -1 {
                let existing = list[existingIndex]
                if let encoding {
                    existing.encoding = encoding
                }
                existing.value = value
                existing.encodingMethod = method
                continue
            }

            if let encoding {
                _ = try? list.add(encoding, param.name, value)
            } else {
                _ = try? list.add(param.name, value)
            }
            let nameIndex = list.indexOf(param.name)
            if nameIndex != -1 {
                list[nameIndex].encodingMethod = method
            }
        }

        paramList = list
        return true
    }

    private func indexOfName(_ name: String) -> Int? {
        let key = name.lowercased()
        return parameters.firstIndex(where: { $0.name.lowercased() == key })
    }

    private func attach(_ parameter: Parameter) {
        parameter.changed = { [weak self] _ in
            self?.onChanged()
        }
    }

    private func detach(_ parameter: Parameter) {
        parameter.changed = nil
    }

    private func onChanged() {
        changed?(self)
    }

    public static func == (lhs: ParameterList, rhs: ParameterList) -> Bool {
        guard lhs.parameters.count == rhs.parameters.count else {
            return false
        }
        for param in lhs.parameters {
            guard let rhsIndex = rhs.indexOfName(param.name) else {
                return false
            }
            if param != rhs.parameters[rhsIndex] {
                return false
            }
        }
        return true
    }
}
