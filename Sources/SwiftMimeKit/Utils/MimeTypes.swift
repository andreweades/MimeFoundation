//
// MimeTypes.swift
//
// Ported from MimeKit (C#) to Swift.
//

import Foundation

public enum MimeTypeError: Error, Equatable {
    case nilFileName
    case nilMimeType
    case emptyMimeType
    case nilExtension
    case emptyExtension
}

public enum MimeTypes {
    private static let defaultMimeType = "application/octet-stream"

    private struct StoreState {
        var mimeTypeByExtension: [String: String]
        var extensionByMimeType: [String: String]
    }

    private actor Store {
        private var state: StoreState

        init() {
            self.state = StoreState(
                mimeTypeByExtension: [
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
                ],
                extensionByMimeType: [
                    "text/plain": ".txt",
                    "text/csv": ".csv",
                    "text/html": ".html",
                    "image/jpeg": ".jpg",
                    "image/gif": ".gif",
                    "image/png": ".png",
                    "message/rfc822": ".eml",
                    "application/pdf": ".pdf"
                ]
            )
        }

        func mimeType(for fileName: String) -> String {
            let trimmed = fileName.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !trimmed.isEmpty else {
                return MimeTypes.defaultMimeType
            }
            let url = URL(fileURLWithPath: trimmed)
            let ext = url.pathExtension.lowercased()
            guard !ext.isEmpty else {
                return MimeTypes.defaultMimeType
            }
            let key = "." + ext
            return state.mimeTypeByExtension[key] ?? MimeTypes.defaultMimeType
        }

        func register(mimeType: String, fileExtension: String) {
            let normalizedExt = fileExtension.hasPrefix(".") ? fileExtension.lowercased() : "." + fileExtension.lowercased()
            state.mimeTypeByExtension[normalizedExt] = mimeType
            state.extensionByMimeType[mimeType.lowercased()] = normalizedExt
        }

        func fileExtension(for mimeType: String) -> String? {
            state.extensionByMimeType[mimeType.lowercased()]
        }
    }

    private static let store = Store()

    public static func getMimeType(_ fileName: String?) async throws -> String {
        guard let fileName else {
            throw MimeTypeError.nilFileName
        }
        return await store.mimeType(for: fileName)
    }

    public static func getMimeType(_ fileName: String) async -> String {
        await store.mimeType(for: fileName)
    }

    public static func register(_ mimeType: String?, _ fileExtension: String?) async throws {
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
        await store.register(mimeType: trimmedMime, fileExtension: trimmedExt)
    }

    public static func tryGetExtension(_ mimeType: String?) async throws -> String? {
        guard let mimeType else {
            throw MimeTypeError.nilMimeType
        }
        let trimmed = mimeType.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            throw MimeTypeError.emptyMimeType
        }
        return await store.fileExtension(for: trimmed)
    }
}
