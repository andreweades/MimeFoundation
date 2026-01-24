//
// ConverterError.swift
//
// Ported from MimeKit (C#) to Swift.
//

import Foundation

public enum ConverterError: Error, Equatable {
    case alreadyRegistered
    case notSupported
}
