//
// TextIO.swift
//
// Ported from MimeKit (C#) to Swift.
//

import Foundation

public protocol TextReadable {
    func readLine() -> String?
    func readToEnd() -> String
}

public protocol TextWritable {
    func write(_ string: String)
    func writeLine(_ string: String)
}

public final class StringReader: TextReadable {
    private let text: String
    private var index: String.Index

    public init(_ text: String) {
        self.text = text
        self.index = text.startIndex
    }

    public func readLine() -> String? {
        guard index < text.endIndex else {
            return nil
        }

        var lineEnd = index
        while lineEnd < text.endIndex {
            let ch = text[lineEnd]
            if ch == "\n" || ch == "\r" {
                break
            }
            lineEnd = text.index(after: lineEnd)
        }

        let line = String(text[index..<lineEnd])

        if lineEnd < text.endIndex {
            let newlineChar = text[lineEnd]
            lineEnd = text.index(after: lineEnd)
            if newlineChar == "\r", lineEnd < text.endIndex, text[lineEnd] == "\n" {
                lineEnd = text.index(after: lineEnd)
            }
        }

        index = lineEnd
        return line
    }

    public func readToEnd() -> String {
        guard index < text.endIndex else {
            return ""
        }
        let remaining = String(text[index...])
        index = text.endIndex
        return remaining
    }
}

public final class StringWriter: TextWritable {
    private var buffer: String

    public init() {
        buffer = ""
    }

    public func write(_ string: String) {
        buffer.append(string)
    }

    public func writeLine(_ string: String) {
        buffer.append(string)
        buffer.append("\n")
    }

    public var string: String {
        buffer
    }
}
