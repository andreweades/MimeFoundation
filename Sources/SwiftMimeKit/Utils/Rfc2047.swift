//
// Rfc2047.swift
//
// Ported from MimeKit (C#) to Swift.
//

import Foundation

enum Rfc2047 {

    static func decodePhrase(_ phrase: [UInt8]) -> String {
        decodePhrase(ParserOptions.default, phrase, startIndex: 0, count: phrase.count)
    }

    static func decodePhrase(_ options: ParserOptions, _ phrase: [UInt8]) -> String {
        decodePhrase(options, phrase, startIndex: 0, count: phrase.count)
    }

    static func decodePhrase(_ options: ParserOptions, _ phrase: [UInt8], startIndex: Int, count: Int) -> String {
        var counts: [Int: Int] = [:]
        return decode(options, phrase, startIndex: startIndex, count: count, ignoreWhitespaceBetweenEncodedWords: true, codepageCounts: &counts)
    }

    static func decodePhrase(_ options: ParserOptions, _ phrase: [UInt8], startIndex: Int, count: Int, codepage: inout Int) -> String {
        var counts: [Int: Int] = [:]
        let result = decode(options, phrase, startIndex: startIndex, count: count, ignoreWhitespaceBetweenEncodedWords: true, codepageCounts: &counts)
        if let (best, _) = counts.max(by: { $0.value < $1.value }) {
            codepage = best
        } else {
            codepage = 65001
        }
        return result
    }

    static func decodeText(_ text: [UInt8]) -> String {
        decodeText(ParserOptions.default, text, startIndex: 0, count: text.count)
    }

    static func decodeText(_ options: ParserOptions, _ text: [UInt8]) -> String {
        decodeText(options, text, startIndex: 0, count: text.count)
    }

    static func decodeText(_ options: ParserOptions, _ text: [UInt8], startIndex: Int, count: Int) -> String {
        var counts: [Int: Int] = [:]
        return decode(options, text, startIndex: startIndex, count: count, ignoreWhitespaceBetweenEncodedWords: true, codepageCounts: &counts)
    }

    static func decodeText(_ options: ParserOptions, _ text: [UInt8], startIndex: Int, count: Int, codepage: inout Int) -> String {
        var counts: [Int: Int] = [:]
        let result = decode(options, text, startIndex: startIndex, count: count, ignoreWhitespaceBetweenEncodedWords: true, codepageCounts: &counts)
        if let (best, _) = counts.max(by: { $0.value < $1.value }) {
            codepage = best
        } else {
            codepage = 65001
        }
        return result
    }

    private struct EncodedWordPayload {
        let charset: String
        let encodingChar: Character
        let payload: [UInt8]
    }

    private static func decode(_ options: ParserOptions, _ input: [UInt8], startIndex: Int, count: Int, ignoreWhitespaceBetweenEncodedWords: Bool, codepageCounts: inout [Int: Int]) -> String {
        guard count > 0, startIndex >= 0, startIndex + count <= input.count else {
            return ""
        }

        var output = ValueStringBuilder(initialCapacity: count)
        var index = startIndex
        let endIndex = startIndex + count
        var pendingWhitespace = ""
        var lastWasEncoded = false
        var pendingEncoded: EncodedWordPayload? = nil

        func decodePayload(_ word: EncodedWordPayload) -> String {
            let decodedBytes: [UInt8]
            switch word.encodingChar.lowercased() {
            case "q":
                let decoder = QuotedPrintableDecoder(rfc2047: true)
                let outputLength = decoder.estimateOutputLength(word.payload.count)
                let outputBuffer = Array(repeating: UInt8(0), count: outputLength)
                var outputOptional: [UInt8]? = outputBuffer
                let written = (try? decoder.decode(word.payload, startIndex: 0, length: word.payload.count, output: &outputOptional)) ?? 0
                decodedBytes = Array(outputOptional?.prefix(written) ?? [])
            case "b":
                let decoder = Base64Decoder()
                let outputLength = decoder.estimateOutputLength(word.payload.count)
                let outputBuffer = Array(repeating: UInt8(0), count: outputLength)
                var outputOptional: [UInt8]? = outputBuffer
                let written = (try? decoder.decode(word.payload, startIndex: 0, length: word.payload.count, output: &outputOptional)) ?? 0
                decodedBytes = Array(outputOptional?.prefix(written) ?? [])
            default:
                decodedBytes = word.payload
            }

            let encoding = CharsetUtils.getEncoding(word.charset) ?? options.charsetEncoding
            if let decoded = String(data: Data(decodedBytes), encoding: encoding) {
                let codepage = CharsetUtils.getCodepage(encoding)
                codepageCounts[codepage, default: 0] += decodedBytes.count
                return decoded
            }
            if let decoded = String(data: Data(decodedBytes), encoding: options.charsetEncoding) {
                let codepage = CharsetUtils.getCodepage(options.charsetEncoding)
                codepageCounts[codepage, default: 0] += decodedBytes.count
                return decoded
            }
            if let decoded = String(data: Data(decodedBytes), encoding: .isoLatin1) {
                let codepage = CharsetUtils.getCodepage(.isoLatin1)
                codepageCounts[codepage, default: 0] += decodedBytes.count
                return decoded
            }
            return String(decoding: decodedBytes, as: UTF8.self)
        }

        func flushPendingEncoded() {
            guard let pending = pendingEncoded else { return }
            output.append(decodePayload(pending))
            pendingEncoded = nil
        }

        while index < endIndex {
            let byte = input[index]
            if ByteClassification.isWhitespace(byte) {
                let wsStart = index
                index += 1
                while index < endIndex && ByteClassification.isWhitespace(input[index]) {
                    index += 1
                }
                let wsBytes = Array(input[wsStart..<index])
                if let ws = String(bytes: wsBytes, encoding: .ascii) {
                    pendingWhitespace.append(ws)
                }
                continue
            }

            if let decoded = tryDecodeEncodedWord(options, input, index: index, endIndex: endIndex, consumed: &index) {
                if !pendingWhitespace.isEmpty {
                    if !lastWasEncoded || !ignoreWhitespaceBetweenEncodedWords {
                        output.append(pendingWhitespace)
                    }
                    pendingWhitespace = ""
                }
                if let pending = pendingEncoded {
                    if pending.charset.caseInsensitiveCompare(decoded.charset) == .orderedSame &&
                        pending.encodingChar.lowercased() == decoded.encodingChar.lowercased() {
                        let merged = EncodedWordPayload(charset: pending.charset, encodingChar: pending.encodingChar, payload: pending.payload + decoded.payload)
                        pendingEncoded = merged
                    } else {
                        output.append(decodePayload(pending))
                        pendingEncoded = decoded
                    }
                } else {
                    pendingEncoded = decoded
                }
                lastWasEncoded = true
                continue
            }

            if pendingEncoded != nil {
                flushPendingEncoded()
            }

            if !pendingWhitespace.isEmpty {
                output.append(pendingWhitespace)
                pendingWhitespace = ""
            }

            let start = index
            var ascii = true
            while index < endIndex && !ByteClassification.isWhitespace(input[index]) {
                if input[index] == 0x3D, index + 1 < endIndex, input[index + 1] == 0x3F {
                    break
                }
                ascii = ascii && input[index] < 0x80
                index += 1
            }

            let length = index - start
            if length > 0 {
                if ascii {
                    if let chunk = String(bytes: input[start..<index], encoding: .ascii) {
                        output.append(chunk)
                    }
                } else {
                    let decoded = CharsetUtils.convertToUnicode(options, input, start: start, length: length)
                    output.append(decoded)
                }
            }
            lastWasEncoded = false
        }

        if pendingEncoded != nil {
            flushPendingEncoded()
        }

        if !pendingWhitespace.isEmpty {
            output.append(pendingWhitespace)
        }

        return output.asString()
    }

    private static func tryDecodeEncodedWord(_ options: ParserOptions, _ input: [UInt8], index: Int, endIndex: Int, consumed: inout Int) -> EncodedWordPayload? {
        guard index + 2 < endIndex, input[index] == 0x3D, input[index + 1] == 0x3F else {
            return nil
        }

        var cursor = index + 2
        let charsetStart = cursor
        while cursor < endIndex && input[cursor] != 0x3F { // '?'
            cursor += 1
        }
        guard cursor < endIndex else {
            return nil
        }
        let charsetEnd = cursor
        cursor += 1
        guard cursor + 1 < endIndex else {
            return nil
        }
        let encodingByte = input[cursor]
        cursor += 1
        guard input[cursor] == 0x3F else {
            return nil
        }
        cursor += 1
        let encodedTextStart = cursor
        while cursor + 1 < endIndex {
            if input[cursor] == 0x3F && input[cursor + 1] == 0x3D {
                break
            }
            cursor += 1
        }
        guard cursor + 1 < endIndex else {
            return nil
        }
        let encodedTextEnd = cursor
        cursor += 2

        let charsetBytes = Array(input[charsetStart..<charsetEnd])
        guard var charset = String(bytes: charsetBytes, encoding: .ascii)?.trimmingCharacters(in: .whitespacesAndNewlines), !charset.isEmpty else {
            return nil
        }
        if let asteriskIndex = charset.firstIndex(of: "*") {
            charset = String(charset[..<asteriskIndex])
        }

        let encodingChar = Character(UnicodeScalar(encodingByte))
        let payload = Array(input[encodedTextStart..<encodedTextEnd])
        consumed = cursor
        return EncodedWordPayload(charset: charset, encodingChar: encodingChar, payload: payload)
    }

    static func encodePhrase(_ encoding: String.Encoding, _ phrase: String) -> [UInt8] {
        encodePhrase(FormatOptions.default, encoding, phrase, startIndex: 0, count: phrase.count)
    }

    static func encodePhrase(_ options: FormatOptions, _ encoding: String.Encoding, _ phrase: String) -> [UInt8] {
        encodePhrase(options, encoding, phrase, startIndex: 0, count: phrase.count)
    }

    static func encodePhrase(_ options: FormatOptions, _ encoding: String.Encoding, _ phrase: String, startIndex: Int, count: Int) -> [UInt8] {
        guard startIndex >= 0, count >= 0, startIndex + count <= phrase.count else {
            return []
        }
        let start = phrase.index(phrase.startIndex, offsetBy: startIndex)
        let end = phrase.index(start, offsetBy: count)
        let substring = String(phrase[start..<end])
        if substring.isEmpty {
            return []
        }

        let wordsForLengthCheck = substring.split(whereSeparator: { $0.isWhitespace })
        let exceedsLineLength = wordsForLengthCheck.contains { $0.count > options.maxLineLength }
        let hasInternational = containsNonAsciiOrControl(substring)
        if !hasInternational && !exceedsLineLength {
            if needsQuotedPhrase(substring) {
                return Array(MimeUtils.quote(substring).utf8)
            }
            return Array(substring.utf8)
        }

        let words = wordsForLengthCheck.map { String($0) }
        if words.isEmpty {
            return []
        }

        var runs: [(needsEncoding: Bool, hasSpecials: Bool, words: [String])] = []
        for word in words {
            let needsEncoding = needsEncodingWord(word, options: options)
            let hasSpecials = needsPhraseSpecials(word)

            if let last = runs.last, last.needsEncoding == needsEncoding {
                runs.removeLast()
                runs.append((needsEncoding: last.needsEncoding, hasSpecials: last.hasSpecials || hasSpecials, words: last.words + [word]))
            } else {
                runs.append((needsEncoding: needsEncoding, hasSpecials: hasSpecials, words: [word]))
            }
        }

        var output = ""
        for (index, run) in runs.enumerated() {
            if index > 0 {
                output.append(" ")
            }
            let runText = run.words.joined(separator: " ")
            if run.needsEncoding {
                output.append(encodeRun(options, userEncoding: encoding, text: runText, mode: .phrase))
            } else if run.hasSpecials {
                output.append(MimeUtils.quote(runText))
            } else {
                output.append(runText)
            }
        }

        return Array(output.utf8)
    }

    static func encodeText(_ encoding: String.Encoding, _ text: String) -> [UInt8] {
        encodeText(FormatOptions.default, encoding, text, startIndex: 0, count: text.count)
    }

    static func encodeText(_ options: FormatOptions, _ encoding: String.Encoding, _ text: String) -> [UInt8] {
        encodeText(options, encoding, text, startIndex: 0, count: text.count)
    }

    static func encodeText(_ options: FormatOptions, _ encoding: String.Encoding, _ text: String, startIndex: Int, count: Int) -> [UInt8] {
        guard startIndex >= 0, count >= 0, startIndex + count <= text.count else {
            return []
        }
        let start = text.index(text.startIndex, offsetBy: startIndex)
        let end = text.index(start, offsetBy: count)
        let substring = String(text[start..<end])
        var output = ""
        var current = ""
        var currentNeedsEncoding: Bool? = nil

        for scalar in substring.unicodeScalars {
            let value = scalar.value
            let isControl = value < 32 || value == 127
            let isNonAscii = value > 127
            let needsEncoding = isNonAscii || isControl

            if currentNeedsEncoding == nil {
                currentNeedsEncoding = needsEncoding
            }

            if needsEncoding != currentNeedsEncoding {
                output.append(renderSegment(current, needsEncoding: currentNeedsEncoding ?? false, encoding: encoding, mode: .text))
                current = ""
                currentNeedsEncoding = needsEncoding
            }

            current.unicodeScalars.append(scalar)
        }

        if !current.isEmpty {
            output.append(renderSegment(current, needsEncoding: currentNeedsEncoding ?? false, encoding: encoding, mode: .text))
        }

        return Array(output.utf8)
    }

    static func encodePhraseAsString(_ options: FormatOptions, _ encoding: String.Encoding, _ phrase: String) -> String {
        String(bytes: encodePhrase(options, encoding, phrase, startIndex: 0, count: phrase.count), encoding: .ascii) ?? ""
    }

    static func encodeComment(_ options: FormatOptions, _ encoding: String.Encoding, _ text: String, startIndex: Int, count: Int) -> String {
        guard startIndex >= 0, count >= 0, startIndex + count <= text.count else {
            return ""
        }
        let start = text.index(text.startIndex, offsetBy: startIndex)
        let end = text.index(start, offsetBy: count)
        let substring = String(text[start..<end])
        if substring.isEmpty {
            return "()"
        }
        if !containsNonAsciiOrControl(substring) {
            return "(\(substring))"
        }
        let selectedEncoding = selectEncoding(options, userEncoding: encoding, text: substring)
        let bytes = CharsetUtils.getBytes(substring, encoding: selectedEncoding)
        let encodingChoice = chooseEncodedWordEncoding(bytes, encoding: selectedEncoding, mode: .text)
        let encoded: String
        if encodingChoice == .base64 {
            let segments = splitCommentBase64Segments(options: options, encoding: selectedEncoding, text: substring)
            let encodedWords = segments.map { renderSegment($0, needsEncoding: true, encoding: selectedEncoding, mode: .text) }
            encoded = encodedWords.joined(separator: options.newLine + " ")
        } else {
            encoded = encodeRun(options, userEncoding: selectedEncoding, text: substring, mode: .text)
        }
        return "(\(encoded))"
    }

    private static func renderSegment(_ segment: String, needsEncoding: Bool, encoding: String.Encoding, mode: QEncodeMode) -> String {
        guard !segment.isEmpty else {
            return ""
        }
        if !needsEncoding {
            return segment
        }

        let bytes = CharsetUtils.getBytes(segment, encoding: encoding)
        let qpEncoder = Rfc2047QuotedPrintableEncoder(mode: mode)
        let base64Encoder = Rfc2047Base64Encoder()
        let qpLength = qpEncoder.estimateOutputLength(bytes.count)
        let bLength = base64Encoder.estimateOutputLength(bytes.count)
        let encoder: any Rfc2047Encoder = (bLength < qpLength) ? base64Encoder : qpEncoder

        let outputLength = encoder.estimateOutputLength(bytes.count)
        let output = Array(repeating: UInt8(0), count: outputLength)
        var outputOptional: [UInt8]? = output
        let written: Int
        do {
            written = try encoder.encode(bytes, startIndex: 0, length: bytes.count, output: &outputOptional)
        } catch {
            return segment
        }

        let encodedText = String(bytes: Array(outputOptional?[0..<written] ?? []), encoding: .ascii) ?? segment
        let charset = CharsetUtils.getMimeCharset(encoding)
        let encodingLetter = String(encoder.encoding)
        return "=?\(charset)?\(encodingLetter)?\(encodedText)?="
    }

    private static func containsNonAsciiOrControl(_ text: String) -> Bool {
        for scalar in text.unicodeScalars {
            if scalar.value > 127 || scalar.value < 32 || scalar.value == 127 {
                return true
            }
        }
        return false
    }

    private static func needsEncodingWord(_ word: String, options: FormatOptions) -> Bool {
        if containsNonAsciiOrControl(word) {
            return true
        }
        return word.count > options.maxLineLength
    }

    private static func needsPhraseSpecials(_ word: String) -> Bool {
        for ch in word {
            if isPhraseSpecial(ch) {
                return true
            }
        }
        return false
    }

    private static func canEncode(_ text: String, encoding: String.Encoding) -> Bool {
        text.data(using: encoding) != nil
    }

    private static func selectEncoding(_ options: FormatOptions, userEncoding: String.Encoding, text: String) -> String.Encoding {
        if options.allowMixedHeaderCharsets {
            if canEncode(text, encoding: .ascii) {
                return .ascii
            }
            if canEncode(text, encoding: .isoLatin1) {
                return .isoLatin1
            }
        }
        if canEncode(text, encoding: userEncoding) {
            return userEncoding
        }
        return .utf8
    }

    private enum EncodedWordEncoding {
        case base64
        case quotedPrintable
    }

    private static func chooseEncodedWordEncoding(_ bytes: [UInt8], encoding: String.Encoding, mode: QEncodeMode) -> EncodedWordEncoding {
        if charsetRequiresBase64(encoding) {
            return .base64
        }
        var nonAscii = 0
        for byte in bytes where byte > 127 {
            nonAscii += 1
        }
        if Double(nonAscii) < Double(bytes.count) * 0.17 {
            return .quotedPrintable
        }
        return .base64
    }

    private static func charsetRequiresBase64(_ encoding: String.Encoding) -> Bool {
        false
    }

    private static func encodeRun(_ options: FormatOptions, userEncoding: String.Encoding, text: String, mode: QEncodeMode) -> String {
        let encoding = selectEncoding(options, userEncoding: userEncoding, text: text)
        guard let data = text.data(using: encoding) ?? text.data(using: .utf8) else {
            return text
        }
        let bytes = Array(data)
        let encodingChoice = chooseEncodedWordEncoding(bytes, encoding: encoding, mode: mode)

        let encoder: any Rfc2047Encoder = (encodingChoice == .base64) ? Rfc2047Base64Encoder() : Rfc2047QuotedPrintableEncoder(mode: mode)
        let charset = CharsetUtils.getMimeCharset(encoding)
        let encodingLetter = String(encoder.encoding)
        let maxPayload = max(4, options.maxLineLength - (charset.count + 7))

        let segments: [String]
        switch encodingChoice {
        case .base64:
            segments = encodeBase64Segments(text, encoding: encoding, maxPayload: maxPayload)
        case .quotedPrintable:
            let qpPayload = max(4, maxPayload - 2)
            let outputLength = encoder.estimateOutputLength(bytes.count)
            var output: [UInt8]? = Array(repeating: 0, count: outputLength)
            let written: Int
            do {
                written = try encoder.encode(bytes, startIndex: 0, length: bytes.count, output: &output)
            } catch {
                return text
            }
            let encodedBytes = Array(output?.prefix(written) ?? [])
            segments = splitQuotedPrintableSegments(encodedBytes, maxPayload: qpPayload)
        }

        let encodedWords = segments.map { segment in
            "=?\(charset)?\(encodingLetter)?\(segment)?="
        }

        if encodedWords.count == 1 {
            return encodedWords[0]
        }
        return encodedWords.joined(separator: options.newLine + " ")
    }

    private static func splitCommentBase64Segments(options: FormatOptions, encoding: String.Encoding, text: String) -> [String] {
        let maxEncodedWordLength = max(1, options.maxLineLength - 2)
        let charset = CharsetUtils.getMimeCharset(encoding)
        let maxPayload = max(4, maxEncodedWordLength - (charset.count + 7))
        let maxBytes = max(1, (maxPayload / 4) * 3)
        var segments: [String] = []

        var words: [(leadingWhitespaceStart: String.Index, wordStart: String.Index, wordEnd: String.Index)] = []
        var index = text.startIndex
        while index < text.endIndex {
            let whitespaceStart = index
            while index < text.endIndex, text[index].isWhitespace {
                index = text.index(after: index)
            }
            if index >= text.endIndex {
                break
            }
            let wordStart = index
            while index < text.endIndex, !text[index].isWhitespace {
                index = text.index(after: index)
            }
            let wordEnd = index
            words.append((leadingWhitespaceStart: whitespaceStart, wordStart: wordStart, wordEnd: wordEnd))
        }

        guard let first = words.first else {
            return [text]
        }

        var segmentStart = first.wordStart
        var segmentEnd = first.wordEnd

        func byteCount(_ range: Range<String.Index>) -> Int {
            let substring = String(text[range])
            return substring.lengthOfBytes(using: encoding)
        }

        for word in words.dropFirst() {
            let candidateRange = segmentStart..<word.wordEnd
            let candidateBytes = byteCount(candidateRange)
            if candidateBytes <= maxBytes || segmentStart == word.wordStart {
                segmentEnd = word.wordEnd
            } else {
                segments.append(String(text[segmentStart..<segmentEnd]))
                segmentStart = word.leadingWhitespaceStart
                segmentEnd = word.wordEnd
            }
        }

        segments.append(String(text[segmentStart..<segmentEnd]))
        return segments
    }

    private static func encodeBase64Segments(_ text: String, encoding: String.Encoding, maxPayload: Int) -> [String] {
        let encoder = Rfc2047Base64Encoder()
        let maxBytes = max(1, (maxPayload / 4) * 3)
        var segments: [String] = []
        var current = ""
        var currentBytes = 0

        func flush() {
            guard !current.isEmpty, let data = current.data(using: encoding) else { return }
            let bytes = Array(data)
            let outputLength = encoder.estimateOutputLength(bytes.count)
            var output: [UInt8]? = Array(repeating: 0, count: outputLength)
            let written = (try? encoder.encode(bytes, startIndex: 0, length: bytes.count, output: &output)) ?? 0
            let encoded = String(bytes: output?.prefix(written) ?? [], encoding: .ascii) ?? ""
            segments.append(encoded)
            current = ""
            currentBytes = 0
        }

        let characters = Array(text)
        for (idx, ch) in characters.enumerated() {
            let chStr = String(ch)
            let byteCount = chStr.lengthOfBytes(using: encoding)
            let hasMore = idx < (characters.count - 1)

            if !current.isEmpty {
                if currentBytes + byteCount > maxBytes {
                    flush()
                } else if ch.isWhitespace && hasMore && (currentBytes + byteCount) == maxBytes {
                    // Prefer starting a new encoded word at whitespace boundaries.
                    flush()
                }
            }

            current.append(chStr)
            currentBytes += byteCount
        }

        flush()

        return segments.isEmpty ? [""] : segments
    }

    private static func splitQuotedPrintableSegments(_ bytes: [UInt8], maxPayload: Int) -> [String] {
        guard !bytes.isEmpty else { return [""] }
        var segments: [String] = []
        var index = 0
        let limit = max(4, maxPayload)

        while index < bytes.count {
            var end = min(index + limit, bytes.count)
            if end < bytes.count {
                if bytes[end - 1] == 0x3D { // '='
                    end -= 1
                } else if end - 2 >= index && bytes[end - 2] == 0x3D {
                    end -= 2
                }
                if end <= index {
                    end = min(index + limit, bytes.count)
                }
            }
            let chunk = bytes[index..<end]
            segments.append(String(bytes: chunk, encoding: .ascii) ?? "")
            index = end
        }

        return segments
    }

    private static func needsQuotedPhrase(_ phrase: String) -> Bool {
        for ch in phrase {
            if isPhraseSpecial(ch) {
                return true
            }
        }
        return false
    }

    private static func isPhraseSpecial(_ ch: Character) -> Bool {
        let specials = "()<>@,;:\\\".[]"
        return specials.contains(ch)
    }
}
