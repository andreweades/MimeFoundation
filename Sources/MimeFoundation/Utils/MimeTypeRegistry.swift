//
// MimeTypeRegistry.swift
//
// Ported from MimeKit (C#) to Swift.
//

import Foundation

public enum MimeTypeError: Error, Equatable, Sendable {
    case emptyMimeType
    case emptyExtension
}

public struct MimeTypeRegistry: Sendable {
    public static var `default`: MimeTypeRegistry { MimeTypeRegistry() }

    private static let defaultMimeType = "application/octet-stream"

    private var mimeTypeByExtension: [String: String]
    private var extensionByMimeType: [String: String]

    public init() {
        self.mimeTypeByExtension = [
            ".txt": "text/plain",
            ".csv": "text/csv",
            ".html": "text/html",
            ".htm": "text/html",
            ".jpg": "image/jpeg",
            ".jpeg": "image/jpeg",
            ".gif": "image/gif",
            ".png": "image/png",
            ".eml": "message/rfc822",
            ".pdf": "application/pdf"
        ]
        var mapping: [String: String] = [:]
        for (ext, mime) in mimeTypeByExtension {
            if mapping[mime.lowercased()] == nil {
                mapping[mime.lowercased()] = ext
            }
        }
        self.extensionByMimeType = mapping
    }

    public func mimeType(for fileName: String) -> String {
        let trimmed = fileName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            return Self.defaultMimeType
        }
        let url = URL(fileURLWithPath: trimmed)
        let ext = url.pathExtension.lowercased()
        guard !ext.isEmpty else {
            return Self.defaultMimeType
        }
        let key = "." + ext
        return mimeTypeByExtension[key] ?? Self.defaultMimeType
    }

    public mutating func register(mimeType: String, fileExtension: String) throws {
        let trimmedMime = mimeType.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedMime.isEmpty else {
            throw MimeTypeError.emptyMimeType
        }
        let trimmedExt = fileExtension.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedExt.isEmpty else {
            throw MimeTypeError.emptyExtension
        }
        let normalizedExt = trimmedExt.hasPrefix(".") ? trimmedExt.lowercased() : "." + trimmedExt.lowercased()
        mimeTypeByExtension[normalizedExt] = trimmedMime
        extensionByMimeType[trimmedMime.lowercased()] = normalizedExt
    }

    public func extensionFor(mimeType: String) -> String? {
        let trimmed = mimeType.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            return nil
        }
        return extensionByMimeType[trimmed.lowercased()]
    }
}
