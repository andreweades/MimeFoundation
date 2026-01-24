//
// DkimSignatureStream.swift
//
// Ported from MimeKit (C#) to Swift.
//

import Foundation

final class DkimSignatureStream: MimeStream {
    private let signer: DkimSignatureContext
    private var currentLength: Int = 0
    private var closed = false

    init(_ signer: DkimSignatureContext?) throws {
        guard let signer else {
            throw StreamError.invalidArgument
        }
        self.signer = signer
    }

    func generateSignature() throws -> [UInt8] {
        try signer.generateSignature()
    }

    func verifySignature(_ signature: String?) throws -> Bool {
        guard let signature else {
            throw StreamError.invalidArgument
        }
        guard let data = Data(base64Encoded: signature, options: [.ignoreUnknownCharacters]) else {
            throw StreamError.invalidArgument
        }
        return try signer.verify(signature: Array(data))
    }

    var canRead: Bool { false }
    var canWrite: Bool { true }
    var canSeek: Bool { false }
    var canTimeout: Bool { false }

    var readTimeout: Int {
        get { 0 }
        set { }
    }

    var writeTimeout: Int {
        get { 0 }
        set { }
    }

    var position: Int {
        get { currentLength }
        set { _ = try? seek(newValue, origin: .begin) }
    }

    var length: Int { currentLength }

    func read(_ buffer: inout [UInt8], offset: Int, count: Int) throws -> Int {
        try ensureOpen()
        throw StreamError.notSupported
    }

    func write(_ buffer: [UInt8], offset: Int, count: Int) throws {
        try ensureOpen()
        guard offset >= 0, count >= 0, offset + count <= buffer.count else {
            throw StreamError.invalidArgument
        }
        guard count > 0 else {
            return
        }

        signer.update(buffer, offset: offset, count: count)
        currentLength += count
    }

    func seek(_ offset: Int, origin: SeekOrigin) throws -> Int {
        try ensureOpen()
        throw StreamError.notSupported
    }

    func flush() throws {
        try ensureOpen()
    }

    func close() {
        closed = true
    }

    private func ensureOpen() throws {
        if closed {
            throw StreamError.closed
        }
    }
}
