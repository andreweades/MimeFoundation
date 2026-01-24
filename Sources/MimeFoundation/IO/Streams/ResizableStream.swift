//
// ResizableStream.swift
//
// Ported from MimeKit (C#) to Swift.
//

public protocol ResizableStream: MimeStream {
    func setLength(_ length: Int) throws
}
