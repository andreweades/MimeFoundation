//
// ConverterError.swift
//
// Ported from MimeKit (C#) to Swift.
//

import Foundation

/// Errors that can occur during content converter operations.
///
/// These errors are used by the content converter system when registering
/// or attempting to use converters for transforming MIME content.
public enum ConverterError: Error, Equatable, Sendable {
    /// A converter for the specified format is already registered.
    ///
    /// This error occurs when attempting to register a converter that conflicts
    /// with an existing converter registration.
    case alreadyRegistered

    /// The requested conversion is not supported.
    ///
    /// This error occurs when attempting to convert content in a format
    /// for which no converter has been registered.
    case notSupported
}
