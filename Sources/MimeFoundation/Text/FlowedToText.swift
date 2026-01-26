//
// FlowedToText.swift
//
// Ported from MimeKit (C#) to Swift.
//

/// A flowed text to text converter.
///
/// Unwraps the flowed text format described in RFC 3676. This converter
/// takes text that was formatted with soft line breaks (indicated by trailing spaces)
/// and produces plain text with proper line wrapping restored.
public final class FlowedToText: TextConverter {
    /// Gets or sets whether the trailing space on a wrapped line should be deleted.
    ///
    /// The flowed text format defines a Content-Type parameter called "delsp" which can
    /// have a value of "yes" or "no". If the parameter exists and the value is "yes", then
    /// ``deleteSpace`` should be set to `true`, otherwise ``deleteSpace``
    /// should be set to `false`.
    public var deleteSpace: Bool = false

    /// Initializes a new instance of the ``FlowedToText`` class.
    ///
    /// Creates a new flowed text to text converter.
    public override init() {
        super.init()
    }

    /// Gets the input format.
    ///
    /// Always returns ``TextFormat/flowed`` for this converter.
    public override var inputFormat: TextFormat {
        .flowed
    }

    /// Gets the output format.
    ///
    /// Always returns ``TextFormat/plain`` for this converter.
    public override var outputFormat: TextFormat {
        .plain
    }

    private static func unquote(_ line: [Character], quoteDepth: inout Int) -> ArraySlice<Character> {
        var index = 0
        quoteDepth = 0

        if line.isEmpty {
            return line[index...]
        }

        while index < line.count && line[index] == ">" {
            quoteDepth += 1
            index += 1
        }

        if index > 0, index < line.count, line[index] == " " {
            index += 1
        }

        if index >= line.count {
            return line[line.count..<line.count]
        }

        return line[index...]
    }

    /// Converts the contents of the reader from the ``inputFormat`` to the ``outputFormat``
    /// and uses the writer to write the resulting text.
    ///
    /// Converts flowed text to plain text by unwrapping soft line breaks
    /// while preserving quote levels.
    ///
    /// - Parameters:
    ///   - reader: The text reader providing the flowed text input.
    ///   - writer: The text writer to receive the plain text output.
    public override func convert(_ reader: TextReadable, _ writer: TextWritable) {
        var paragraph = ""
        var paragraphQuoteDepth = -1

        if let header, !header.isEmpty {
            writer.write(header)
        }

        while let line = reader.readLine() {
            let chars = Array(line)
            var quoteDepth = 0
            var unquoted = Self.unquote(chars, quoteDepth: &quoteDepth)

            if quoteDepth == 0, let first = unquoted.first, first == " " {
                unquoted = unquoted.dropFirst()
            }

            if paragraphQuoteDepth == -1 {
                paragraphQuoteDepth = quoteDepth
            } else if quoteDepth != paragraphQuoteDepth {
                if paragraphQuoteDepth > 0 {
                    writer.write(String(repeating: ">", count: paragraphQuoteDepth) + " ")
                }
                writer.writeLine(paragraph)
                paragraphQuoteDepth = quoteDepth
                paragraph = ""
            }

            if !unquoted.isEmpty {
                paragraph.append(contentsOf: unquoted)
            }

            if unquoted.isEmpty || unquoted.last != " " {
                if paragraphQuoteDepth > 0 {
                    writer.write(String(repeating: ">", count: paragraphQuoteDepth) + " ")
                }
                writer.writeLine(paragraph)
                paragraphQuoteDepth = -1
                paragraph = ""
            } else if deleteSpace, !paragraph.isEmpty {
                paragraph.removeLast()
            }
        }

        if !paragraph.isEmpty {
            if paragraphQuoteDepth > 0 {
                writer.write(String(repeating: ">", count: paragraphQuoteDepth) + " ")
            }
            writer.write(paragraph)
        }

        if let footer, !footer.isEmpty {
            writer.write(footer)
        }
    }
}
