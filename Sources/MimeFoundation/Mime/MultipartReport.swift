//
// MultipartReport.swift
//
// Ported from MimeKit (C#) to Swift.
//

import Foundation

public final class MultipartReport: Multipart {
    public override init(_ contentType: ContentType) {
        super.init(contentType)
    }

    public convenience init(reportType: String, _ args: Any?...) throws {
        try self.init(reportType: reportType, args: args)
    }

    public init(reportType: String, args: [Any?]) throws {
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
            if let newValue {
                _ = try? setReportType(newValue)
            } else {
                contentType.parameters["report-type"] = nil
            }
        }
    }

    public func setReportType(_ value: String) throws {
        if reportType == value {
            return
        }

        contentType.parameters["report-type"] = value.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    public override func accept(_ visitor: MimeVisitor) {
        visitor.visit(self)
    }
}
