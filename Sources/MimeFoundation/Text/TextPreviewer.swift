//
// TextPreviewer.swift
//
// Ported from MimeKit (C#) to Swift.
//

import Foundation

/// An abstract class for generating a text preview of a message.
open class TextPreviewer {
    private var _maximumPreviewLength: Int = 230

    /// Initialize a new instance of the `TextPreviewer` class.
    public init() {
    }

    /// Get the input format.
    open var inputFormat: TextFormat {
        fatalError("Override in subclasses")
    }

    /// Get or set the maximum text preview length.
    ///
    /// The default value is `230` which is what the GMail web API seems to use.
    public var maximumPreviewLength: Int {
        get { _maximumPreviewLength }
        set {
            guard newValue >= 1 && newValue <= 1024 else {
                return
            }
            _maximumPreviewLength = newValue
        }
    }

    static func create(for format: TextFormat) -> TextPreviewer {
        switch format {
        case .html:
            return HtmlTextPreviewer()
        default:
            return PlainTextPreviewer()
        }
    }

    /// Get a text preview of the text part.
    ///
    /// - Parameter body: The text part.
    /// - Returns: A string representing a shortened preview of the original text.
    public static func getPreviewText(for body: TextPart) -> String {
        guard let content = body.content else {
            return ""
        }

        let charset = body.contentType.charset
        var encoding: String.Encoding? = nil
        if let charset = charset {
            encoding = CharsetUtils.getEncoding(charset)
        }

        // MimeKit reads up to 16KB to detect BOM and decode.
        // For simplicity, we'll use a similar approach if possible.
        let memory = MemoryStream()
        _ = try? content.decodeTo(memory)
        let data = memory.toByteArray()
        
        if data.isEmpty {
            return ""
        }

        let actualEncoding = encoding ?? .utf8 // Should probably use BOM detection here if encoding is nil

        let text = String(data: Data(data), encoding: actualEncoding) ?? ""
        let previewer = create(for: body.format)
        return previewer.getPreviewText(text)
    }

    /// Get a text preview of a string of text.
    ///
    /// - Parameter text: The original text.
    /// - Returns: A string representing a shortened preview of the original text.
    open func getPreviewText(_ text: String) -> String {
        let reader = StringReader(text)
        return getPreviewText(reader)
    }

    /// Get a text preview of a stream of text.
    ///
    /// - Parameter reader: The original text stream.
    /// - Returns: A string representing a shortened preview of the original text.
    open func getPreviewText(_ reader: TextReadable) -> String {
        fatalError("Override in subclasses")
    }
}
