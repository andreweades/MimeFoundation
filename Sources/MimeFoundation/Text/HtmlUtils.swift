//
// HtmlUtils.swift
//
// Ported from MimeKit (C#) to Swift.
//

import Foundation

public enum HtmlUtils {
    public static func htmlEncode(_ data: String) -> String {
        let writer = StringWriter()
        htmlEncode(writer, data)
        return writer.string
    }

    public static func htmlEncode(_ output: TextWritable, _ data: String) {
        guard !data.isEmpty else {
            return
        }

        var result = ""
        result.reserveCapacity(data.count)

        for scalar in data.unicodeScalars {
            let value = scalar.value
            switch value {
            case 9, 10, 12, 13:
                result.unicodeScalars.append(scalar)
            case 39:
                result.append("&#39;")
            case 34:
                result.append("&quot;")
            case 38:
                result.append("&amp;")
            case 60:
                result.append("&lt;")
            case 62:
                result.append("&gt;")
            default:
                if value < 32 || (value >= 127 && value < 160) {
                    break
                }
                if value >= 160 {
                    result.append("&#\(value);")
                } else {
                    result.unicodeScalars.append(scalar)
                }
            }
        }

        output.write(result)
    }

    public static func htmlAttributeEncode(_ value: String, quote: Character = "\"") -> String {
        let writer = StringWriter()
        htmlAttributeEncode(writer, value, quote: quote)
        return writer.string
    }

    public static func htmlAttributeEncode(_ output: TextWritable, _ value: String, quote: Character = "\"") {
        var result = ""
        result.append(quote)

        for scalar in value.unicodeScalars {
            let v = scalar.value
            switch v {
            case 9, 10, 12, 13:
                result.unicodeScalars.append(scalar)
            case 39:
                if quote == "'" {
                    result.append("&#39;")
                } else {
                    result.append("'")
                }
            case 34:
                if quote == "\"" {
                    result.append("&quot;")
                } else {
                    result.append("\"")
                }
            case 38:
                result.append("&amp;")
            case 60:
                result.append("&lt;")
            case 62:
                result.append("&gt;")
            default:
                if v < 32 || (v >= 127 && v < 160) {
                    break
                }
                if v >= 160 {
                    result.append("&#\(v);")
                } else {
                    result.unicodeScalars.append(scalar)
                }
            }
        }

        result.append(quote)
        output.write(result)
    }
}
