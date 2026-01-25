//
// MimeTypeRegistry.swift
//
// Ported from MimeKit (C#) to Swift.
//

import Foundation

public enum MimeTypeError: Error, Equatable, Sendable {
    case nilFileName
    case nilMimeType
    case emptyMimeType
    case nilExtension
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

    public func mimeType(for fileName: String?) throws -> String {
        guard let fileName else {
            throw MimeTypeError.nilFileName
        }
        return mimeType(for: fileName)
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

    public mutating func register(_ mimeType: String?, _ fileExtension: String?) throws {
        guard let mimeType else {
            throw MimeTypeError.nilMimeType
        }
        guard let fileExtension else {
            throw MimeTypeError.nilExtension
        }
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

    public func tryGetExtension(_ mimeType: String?) throws -> String? {
        guard let mimeType else {
            throw MimeTypeError.nilMimeType
        }
        let trimmed = mimeType.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            throw MimeTypeError.emptyMimeType
        }
        return extensionByMimeType[trimmed.lowercased()]
    }
}
