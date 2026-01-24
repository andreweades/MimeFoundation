//
// MultipartRelated.swift
//
// Ported from MimeKit (C#) to Swift.
//

import Foundation

public enum MultipartRelatedError: Error, Equatable {
    case nilUri
    case nilRoot
    case notFound
}

public final class MultipartRelated: Multipart {
    public override init(_ contentType: ContentType) {
        super.init(contentType)
    }

    public convenience init(_ args: Any?...) throws {
        try self.init(args: args)
    }

    public init(args: [Any?]?) throws {
        guard let args else {
            throw MultipartError.nilArgs
        }
        try super.init("related")
        try applyArgs(args)
    }

    public convenience init() {
        do {
            try self.init(args: [])
        } catch {
            preconditionFailure("Failed to create multipart/related - this is a programming error")
        }
    }

    public var root: MimeEntity? {
        get {
            let index = rootIndex()
            if index < 0 && count == 0 {
                return nil
            }
            return self[Swift.max(index, 0)]
        }
        set {
            _ = try? setRoot(newValue)
        }
    }

    public func setRoot(_ value: MimeEntity?) throws {
        guard let value else {
            throw MultipartRelatedError.nilRoot
        }

        var index = -1

        if count > 0 {
            let rootIndex = self.rootIndex()
            if rootIndex != -1 {
                self[rootIndex] = value
                index = rootIndex
            } else {
                try insert(value, at: 0)
                index = 0
            }
        } else {
            try add(value)
            index = 0
        }

        contentType.parameters["type"] = "\(value.contentType.mediaType)/\(value.contentType.mediaSubtype)"

        if index > 0 {
            if let contentId = value.contentId, !contentId.isEmpty {
                contentType.parameters["start"] = "<\(contentId)>"
            } else {
                let generated = MimeUtils.generateMessageId()
                try? value.setContentId(generated)
                if let contentId = value.contentId, !contentId.isEmpty {
                    contentType.parameters["start"] = "<\(contentId)>"
                }
            }
        } else {
            contentType.parameters["start"] = nil
        }
    }

    public override func accept(_ visitor: MimeVisitor?) throws {
        guard let visitor else {
            throw MimeEntityError.nilVisitor
        }
        visitor.visit(self)
    }

    public override func tryGetValue(_ format: TextFormat, body: inout TextPart?) -> Bool {
        if let root = root {
            if let text = root as? TextPart {
                body = text.isFormat(format) ? text : nil
                return body != nil
            }
            if let multipart = root as? Multipart {
                return multipart.tryGetValue(format, body: &body)
            }
        }

        body = nil
        return false
    }

    public func contains(_ uri: URL?) throws -> Bool {
        return try indexOf(uri) != -1
    }

    public func indexOf(_ uri: URL?) throws -> Int {
        guard let uri else {
            throw MultipartRelatedError.nilUri
        }
        return indexOfUri(uri)
    }

    public func open(_ uri: URL?, mimeType: inout String, charset: inout String?) throws -> MimeStream {
        guard let uri else {
            throw MultipartRelatedError.nilUri
        }

        let index = indexOfUri(uri)
        guard index != -1 else {
            throw MultipartRelatedError.notFound
        }

        guard let part = self[index] as? MimePart, let content = part.content else {
            throw MultipartRelatedError.notFound
        }

        mimeType = part.contentType.mimeType
        charset = part.contentType.charset

        return try content.open()
    }

    public func open(_ uri: URL?) throws -> MimeStream {
        guard let uri else {
            throw MultipartRelatedError.nilUri
        }

        let index = indexOfUri(uri)
        guard index != -1 else {
            throw MultipartRelatedError.notFound
        }

        guard let part = self[index] as? MimePart, let content = part.content else {
            throw MultipartRelatedError.notFound
        }

        return try content.open()
    }

    private func rootIndex() -> Int {
        if let start = contentType.parameters["start"] {
            let references = MimeUtils.enumerateReferences(start)
            let contentId = references.first ?? start
            if let cid = URL(string: "cid:\(contentId)") {
                return indexOfUri(cid)
            }
        }

        if let type = contentType.parameters["type"] {
            for index in 0..<count {
                let mimeType = self[index].contentType.mimeType
                if mimeType.caseInsensitiveCompare(type) == .orderedSame {
                    return index
                }
            }
        }

        return -1
    }

    private func indexOfUri(_ uri: URL) -> Int {
        let isAbsolute = uri.scheme != nil
        let isCid = isAbsolute && uri.scheme?.caseInsensitiveCompare("cid") == .orderedSame

        for index in 0..<count {
            let entity = self[index]

            if isAbsolute {
                if isCid {
                    if let contentId = entity.contentId, contentId == uri.path {
                        return index
                    }
                } else if let location = entity.contentLocation {
                    let absolute: URL?
                    if location.scheme == nil {
                        if let base = entity.contentBase ?? contentBase {
                            absolute = URL(string: location.relativeString, relativeTo: base)?.absoluteURL
                        } else {
                            absolute = nil
                        }
                    } else {
                        absolute = location
                    }

                    if let absolute, absolute == uri {
                        return index
                    }
                }
            } else if let location = entity.contentLocation, location == uri {
                return index
            }
        }

        return -1
    }
}
