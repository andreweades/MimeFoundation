//
// MultipartReport.swift
//
// Ported from MimeKit (C#) to Swift.
//

import Foundation

public enum MultipartReportError: Error, Equatable {
    case nilReportType
    case nilArgs
}

public final class MultipartReport: Multipart {
    public override init(_ contentType: ContentType) {
        super.init(contentType)
    }

    public convenience init(reportType: String, _ args: Any?...) throws {
        try self.init(reportType: reportType, args: args)
    }

    public init(reportType: String, args: [Any?]?) throws {
        guard let args else {
            throw MultipartReportError.nilArgs
        }
        try super.init("report")
        try applyArgs(args)
        try setReportType(reportType)
    }

    public override init(_ reportType: String) throws {
        try super.init("report")
        try setReportType(reportType)
    }

    public var reportType: String? {
        get {
            contentType.parameters["report-type"]
        }
        set {
            _ = try? setReportType(newValue)
        }
    }

    public func setReportType(_ value: String?) throws {
        guard let value else {
            throw MultipartReportError.nilReportType
        }

        if reportType == value {
            return
        }

        contentType.parameters["report-type"] = value.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    public override func accept(_ visitor: MimeVisitor?) throws {
        guard let visitor else {
            throw MimeEntityError.nilVisitor
        }
        visitor.visit(self)
    }
}
