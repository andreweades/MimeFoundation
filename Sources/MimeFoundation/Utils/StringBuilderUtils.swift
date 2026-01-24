//
// StringBuilderUtils.swift
//
// Ported from MimeKit (C#) to Swift.
//

import Foundation

enum StringBuilderUtils {
    static func lineWrap(_ text: inout String, options: FormatOptions) {
        guard !text.isEmpty else {
            return
        }

        if let last = text.last, last.isWhitespace {
            let insertIndex = text.index(before: text.endIndex)
            text.insert(contentsOf: options.newLine, at: insertIndex)
        } else {
            text.append(options.newLine)
            text.append("\t")
        }
    }

    static func appendTokens(_ text: inout String, options: FormatOptions, lineLength: inout Int, tokens: [String]) {
        var spaces = ""
        for token in tokens {
            if token.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                spaces = token
                continue
            }

            if lineLength + spaces.count + token.count > options.maxLineLength {
                text.append(options.newLine)
                spaces = ""
                text.append("\t")
                lineLength = 1
            } else {
                lineLength += spaces.count
                text.append(spaces)
                spaces = ""
            }

            lineLength += token.count
            text.append(token)
        }
    }

    static func appendFolded(_ text: inout String, options: FormatOptions, firstToken: inout Bool, value: String, lineLength: inout Int) {
        var wordIndex = value.startIndex

        while wordIndex < value.endIndex {
            var lwspIndex = wordIndex

            if value[lwspIndex] == "\"" {
                lwspIndex = value.index(after: lwspIndex)
                while lwspIndex < value.endIndex && value[lwspIndex] != "\"" {
                    if value[lwspIndex] == "\\" {
                        lwspIndex = value.index(after: lwspIndex)
                        if lwspIndex < value.endIndex {
                            lwspIndex = value.index(after: lwspIndex)
                        }
                    } else {
                        lwspIndex = value.index(after: lwspIndex)
                    }
                }
                if lwspIndex < value.endIndex {
                    lwspIndex = value.index(after: lwspIndex)
                }
            } else {
                while lwspIndex < value.endIndex && !value[lwspIndex].isWhitespace {
                    lwspIndex = value.index(after: lwspIndex)
                }
            }

            let word = value[wordIndex..<lwspIndex]
            let length = word.count
            if !firstToken && lineLength > 1 && (lineLength + length) > options.maxLineLength {
                lineWrap(&text, options: options)
                lineLength = 1
            }

            text.append(contentsOf: word)
            lineLength += length
            firstToken = false

            wordIndex = lwspIndex
            while wordIndex < value.endIndex && value[wordIndex].isWhitespace {
                wordIndex = value.index(after: wordIndex)
            }

            if wordIndex < value.endIndex && wordIndex > lwspIndex {
                text.append(" ")
                lineLength += 1
            }
        }
    }
}
