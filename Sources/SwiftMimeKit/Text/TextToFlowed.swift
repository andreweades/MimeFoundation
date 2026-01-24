//
// TextToFlowed.swift
//
// Ported from MimeKit (C#) to Swift.
//

public final class TextToFlowed: TextConverter {
    private static let maxLineLength = 78

    public override init() {
        super.init()
    }

    public override var inputFormat: TextFormat {
        .plain
    }

    public override var outputFormat: TextFormat {
        .flowed
    }

    private static func unquote(_ line: [Character], quoteDepth: inout Int) -> Int {
        var index = 0
        quoteDepth = 0

        if line.isEmpty || line[0] != ">" {
            return 0
        }

        repeat {
            quoteDepth += 1
            index += 1

            if index < line.count, line[index] == " " {
                index += 1
            }
        } while index < line.count && line[index] == ">"

        return index
    }

    private static func startsWithFrom(_ line: [Character], _ index: Int) -> Bool {
        guard index + 5 <= line.count else {
            return false
        }
        return line[index] == "F"
            && line[index + 1] == "r"
            && line[index + 2] == "o"
            && line[index + 3] == "m"
            && line[index + 4] == " "
    }

    private static func getFlowedLine(_ flowed: inout [Character], _ line: [Character], index: inout Int, quoteDepth: Int) -> String {
        flowed.removeAll(keepingCapacity: true)

        if quoteDepth > 0 {
            flowed.append(contentsOf: Array(repeating: Character(">"), count: quoteDepth))
        }

        if quoteDepth > 0 || (index < line.count && line[index] == " ") || startsWithFrom(line, index) {
            flowed.append(" ")
        }

        if flowed.count + (line.count - index) <= maxLineLength {
            flowed.append(contentsOf: line[index..<line.count])
            index = line.count
            return String(flowed)
        }

        while index < line.count && flowed.count + 1 < maxLineLength {
            let nextSpace = line[index..<line.count].firstIndex(of: " ")
            let wordEnd = nextSpace ?? line.count
            let softBreak = nextSpace == nil ? 0 : 2
            var wordLength = wordEnd - index

            if flowed.count + wordLength + softBreak <= maxLineLength {
                flowed.append(contentsOf: line[index..<wordEnd])
                index = wordEnd
            } else if wordLength > maxLineLength - (quoteDepth + 1) {
                wordLength = maxLineLength - (flowed.count + 1)
                if wordLength > 0 {
                    flowed.append(contentsOf: line[index..<(index + wordLength)])
                    index += wordLength
                }
                break
            } else {
                break
            }

            while flowed.count + 1 < maxLineLength, index < line.count, line[index] == " " {
                flowed.append(" ")
                index += 1
            }
        }

        if index < line.count {
            flowed.append(" ")
        }

        return String(flowed)
    }

    private static func trimTrailingSpaces(_ line: String) -> String {
        var endIndex = line.endIndex
        while endIndex > line.startIndex {
            let prevIndex = line.index(before: endIndex)
            if line[prevIndex] == " " {
                endIndex = prevIndex
            } else {
                break
            }
        }
        if endIndex == line.endIndex {
            return line
        }
        return String(line[..<endIndex])
    }

    public override func convert(_ reader: TextReadable, _ writer: TextWritable) {
        if let header, !header.isEmpty {
            writer.write(header)
        }

        var flowed: [Character] = []
        while let line = reader.readLine() {
            let trimmed = Self.trimTrailingSpaces(line)
            let chars = Array(trimmed)
            var quoteDepth = 0
            let startIndex = Self.unquote(chars, quoteDepth: &quoteDepth)
            var index = startIndex

            repeat {
                let flowedLine = Self.getFlowedLine(&flowed, chars, index: &index, quoteDepth: quoteDepth)
                writer.writeLine(flowedLine)
            } while index < chars.count
        }

        if let footer, !footer.isEmpty {
            writer.write(footer)
        }
    }
}
