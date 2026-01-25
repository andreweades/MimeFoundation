//
// TextIO.swift
//
// Ported from MimeKit (C#) to Swift.
//

import Foundation

public protocol TextReadable {
    func readLine() -> String?
    func readToEnd() -> String
    func read() -> Character?
    func readBlock(_ buffer: inout [Character], index: Int, count: Int) -> Int
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

    public func read() -> Character? {
        guard index < text.endIndex else {
            return nil
        }
        let char = text[index]
        index = text.index(after: index)
        return char
    }

    public func readBlock(_ buffer: inout [Character], index startIndex: Int, count: Int) -> Int {
        var nread = 0
        while nread < count, index < text.endIndex {
            buffer[startIndex + nread] = text[index]
            index = text.index(after: index)
            nread += 1
        }
        return nread
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
