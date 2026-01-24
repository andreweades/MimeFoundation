//
// DkimVerifierBase.swift
//
// Ported from MimeKit (C#) to Swift.
//

import Foundation

open class DkimVerifierBase {
    private static let colon: [UInt8] = [0x3A]

    internal static func writeHeaderRelaxed(options: FormatOptions, stream: MimeStream, header: Header, isDkimSignature: Bool) throws {
        let name = Array(header.field.lowercased().utf8)
        let rawValue = header.getRawValue(options)
        var index = 0

        try stream.write(name, offset: 0, count: name.count)
        try stream.write(colon, offset: 0, count: colon.count)

        while index < rawValue.count && ByteClassification.isWhitespace(rawValue[index]) {
            index += 1
        }

        while index < rawValue.count {
            let startIndex = index
            while index < rawValue.count && ByteClassification.isWhitespace(rawValue[index]) {
                index += 1
            }

            if index >= rawValue.count {
                break
            }

            if index > startIndex {
                let space: [UInt8] = [0x20]
                try stream.write(space, offset: 0, count: space.count)
            }

            let wordStart = index
            while index < rawValue.count && !ByteClassification.isWhitespace(rawValue[index]) {
                index += 1
            }

            if index > wordStart {
                try stream.write(rawValue, offset: wordStart, count: index - wordStart)
            }
        }

        if !isDkimSignature {
            let newLine = options.newLineBytes
            try stream.write(newLine, offset: 0, count: newLine.count)
        }
    }

    internal static func writeHeaderSimple(options: FormatOptions, stream: MimeStream, header: Header, isDkimSignature: Bool) throws {
        let rawValue = header.getRawValue(options)
        var rawLength = rawValue.count

        if isDkimSignature && rawLength > 0 {
            if rawValue[rawLength - 1] == 0x0A {
                rawLength -= 1
                if rawLength > 0 && rawValue[rawLength - 1] == 0x0D {
                    rawLength -= 1
                }
            }
        }

        try stream.write(header.rawField, offset: 0, count: header.rawField.count)
        try stream.write(colon, offset: 0, count: colon.count)
        if rawLength > 0 {
            try stream.write(rawValue, offset: 0, count: rawLength)
        }
    }

    internal static func writeHeaders(options: FormatOptions, message: MimeMessage, fields: [String], canonicalization: DkimCanonicalizationAlgorithm, stream: MimeStream) throws {
        var counts: [String: Int] = [:]

        for field in fields {
            let headers: HeaderList
            if field.lowercased().hasPrefix("content-") {
                guard let body = message.body else {
                    continue
                }
                headers = body.headers
            } else {
                headers = message.headers
            }

            let name = field.lowercased()
            let count = counts[name] ?? 0

            var index = headers.count - 1
            var seen = 0
            var matchedIndex: Int? = nil

            while index >= 0 {
                if headers[index].field.caseInsensitiveCompare(name) == .orderedSame {
                    if seen == count {
                        matchedIndex = index
                        break
                    }
                    seen += 1
                }
                index -= 1
            }

            guard let headerIndex = matchedIndex else {
                continue
            }

            let header = headers[headerIndex]
            switch canonicalization {
            case .relaxed:
                try writeHeaderRelaxed(options: options, stream: stream, header: header, isDkimSignature: false)
            case .simple:
                try writeHeaderSimple(options: options, stream: stream, header: header, isDkimSignature: false)
            }

            counts[name] = count + 1
        }
    }
}
