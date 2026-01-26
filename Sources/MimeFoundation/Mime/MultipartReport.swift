//
// MultipartReport.swift
//
// Ported from MimeKit (C#) to Swift.
//

import Foundation

/// A multipart/report MIME entity.
///
/// A ``MultipartReport`` is a specialized multipart entity used for returning
/// delivery status notifications, disposition notifications, or other types of reports.
/// The first part typically contains a human-readable description of the report,
/// and subsequent parts contain machine-readable report data.
///
/// ## Topics
///
/// ### Creating Multipart Report Entities
/// - ``init(reportType:_:)``
/// - ``init(reportType:args:)``
/// - ``init(_:)``
///
/// ### Report Type
/// - ``reportType``
/// - ``setReportType(_:)``
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

    /// The type of report.
    ///
    /// The report type is specified in the "report-type" parameter of the Content-Type
    /// header. Common values include "delivery-status", "disposition-notification",
    /// and "feedback-report".
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

    /// Sets the type of report.
    ///
    /// - Parameter value: The report type (e.g., "delivery-status", "disposition-notification").
    /// - Throws: An error if the operation fails.
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
