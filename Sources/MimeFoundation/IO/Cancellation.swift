//
// Cancellation.swift
//
// Cancellation primitives. For async operations, prefer using Swift's native
// Task cancellation via `Task.checkCancellation()` and `Task.isCancelled`.
//

import Foundation

/// An error indicating that an operation was canceled.
///
/// For async operations, prefer using Swift's native `CancellationError` instead.
public struct OperationCanceledError: Error, Sendable {
    public init() {}
}
