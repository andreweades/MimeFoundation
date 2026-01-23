//
// Cancellation.swift
//
// Simple cancellation primitives for synchronous APIs.
//

import Foundation

public final class CancellationToken {
    private var cancelled = false

    public var isCancelled: Bool { cancelled }

    fileprivate func cancel() {
        cancelled = true
    }
}

public struct OperationCanceledError: Error {
    public init() {}
}

public final class CancellationTokenSource {
    public let token = CancellationToken()

    public init() {}

    public func cancel() {
        token.cancel()
    }
}
