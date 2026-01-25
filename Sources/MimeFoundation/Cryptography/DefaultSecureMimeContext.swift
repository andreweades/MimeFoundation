//
// DefaultSecureMimeContext.swift
//
// Default implementation of SecureMimeContext using swift-certificates.
//

import Foundation
@_spi(CMS) import X509

/// Default implementation of `SecureMimeContext`.
///
/// This class provides a concrete implementation of S/MIME signing and
/// verification using the swift-certificates library's CMS APIs.
@available(macOS 11.0, iOS 14, tvOS 14, watchOS 7, macCatalyst 14, *)
public final class DefaultSecureMimeContext: SecureMimeContext, @unchecked Sendable {

    /// Shared instance of the default S/MIME context.
    public static let shared = DefaultSecureMimeContext()

    /// Creates a new default S/MIME context.
    public override init() {
        super.init()
    }
}
