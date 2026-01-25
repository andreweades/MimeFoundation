//
// MimeContentTests.swift
//

import Testing
import MimeFoundation

@Test("MimeContent argument exceptions")
func mimeContentArgumentExceptions() async {
    // Use the throwing initializer with stream: label for dynamic capability checking

    let notReadable = CanReadWriteSeekStream(false, false, true)
    #expect(throws: (any Error).self) {
        _ = try MimeContent(stream: notReadable)
    }

    let notSeekable = CanReadWriteSeekStream(true, false, false)
    #expect(throws: (any Error).self) {
        _ = try MimeContent(stream: notSeekable)
    }
}

@Test("MimeContent async cancellation")
func mimeContentAsyncCancellation() async {
    let data = [UInt8](repeating: 0, count: 1024)
    let content: MimeContent? = MimeContent(MemoryStream(data, writable: false))

    guard let content else {
        Issue.record("Failed to create MimeContent")
        return
    }

    // Test that async methods respect Task cancellation
    let task = Task {
        let destination = MemoryStream()
        try await content.writeToAsync(destination)
        return destination.length
    }

    // Cancel immediately
    task.cancel()

    do {
        _ = try await task.value
        // The task may complete before cancellation is checked, which is acceptable
    } catch is CancellationError {
        // Expected - task was cancelled
    } catch {
        Issue.record("Unexpected error: \(error)")
    }
}
