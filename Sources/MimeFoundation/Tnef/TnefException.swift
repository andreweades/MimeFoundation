//
// TnefException.swift
//
// Ported from MimeKit (C#) to Swift.
//

import Foundation

/// A TNEF exception.
public final class TnefException: Error, LocalizedError {
    public let errorStatus: TnefComplianceStatus
    public let message: String?
    public let innerError: Error?

    public init(_ errorStatus: TnefComplianceStatus, _ message: String? = nil, innerError: Error? = nil) {
        self.errorStatus = errorStatus
        self.message = message
        self.innerError = innerError
    }

    public var errorDescription: String? {
        message
    }
}
