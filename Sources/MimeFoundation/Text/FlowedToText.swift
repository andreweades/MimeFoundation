//
// FlowedToText.swift
//
// Ported from MimeKit (C#) to Swift.
//

public final class FlowedToText: TextConverter {
    public var deleteSpace: Bool = false

    public override init() {
        super.init()
    }

    public override var inputFormat: TextFormat {
        .flowed
    }

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
