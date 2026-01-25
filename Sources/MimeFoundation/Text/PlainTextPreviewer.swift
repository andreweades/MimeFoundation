//
// PlainTextPreviewer.swift
//
// Ported from MimeKit (C#) to Swift.
//

import Foundation

/// A text previewer for plain text.
public class PlainTextPreviewer: TextPreviewer {
    /// Initialize a new instance of the `PlainTextPreviewer` class.
    public override init() {
        super.init()
    }

    /// Get the input format.
    public override var inputFormat: TextFormat {
        .plain
    }

    private static func isWhiteSpace(_ c: Character) -> Bool {
        if c.isWhitespace {
            return true
        }
        for scalar in c.unicodeScalars {
            let v = scalar.value
            if v >= 0x200B && v <= 0x200D {
                return true
            }
        }
        return false
    }

    /// Get a text preview of a string of text.
    public override func getPreviewText(_ text: String) -> String {
        if text.isEmpty {
            return ""
        }

        var preview = ""
        preview.reserveCapacity(min(maximumPreviewLength, text.count))
        var lwsp = true
        var count = 0
        let chars = Array(text)
        var i = 0

        while i < chars.count && count < maximumPreviewLength {
            let c = chars[i]
            if Self.isWhiteSpace(c) {
                if !lwsp {
                    preview.append(" ")
                    count += 1
                    lwsp = true
                }
            } else {
                preview.append(c)
                count += 1
                lwsp = false
            }
            i += 1
        }

        if i < chars.count {
            if !preview.isEmpty {
                preview.removeLast()
                preview.append("\u{2026}")
            }
        } else if lwsp && !preview.isEmpty {
            preview.removeLast()
        }

        return preview
    }

    /// Get a text preview of a stream of text.
    public override func getPreviewText(_ reader: TextReadable) -> String {
        var preview = ""
        preview.reserveCapacity(maximumPreviewLength)
        var lwsp = true
        var count = 0
        var truncated = false

        while let c = reader.read() {
            if Self.isWhiteSpace(c) {
                if !lwsp {
                    if count < maximumPreviewLength {
                        preview.append(" ")
                        count += 1
                        lwsp = true
                    } else {
                        truncated = true
                        break
                    }
                }
            } else {
                if count < maximumPreviewLength {
                    preview.append(c)
                    count += 1
                    lwsp = false
                } else {
                    truncated = true
                    break
                }
            }
        }

        if truncated {
            if !preview.isEmpty {
                preview.removeLast()
                preview.append("\u{2026}")
            }
        } else if lwsp && !preview.isEmpty {
            preview.removeLast()
        }

        return preview
    }
}
