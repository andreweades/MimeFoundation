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

@Test("MimeContent cancellation")
func mimeContentCancellation() async {
    let data = [UInt8](repeating: 0, count: 1024)
    let content: MimeContent? = MimeContent(MemoryStream(data, writable: false))
    let source = CancellationTokenSource()
    source.cancel()

    guard let content else {
        Issue.record("Failed to create MimeContent")
        return
    }

    let destination = MemoryStream()
    #expect(throws: OperationCanceledError.self) {
        try content.writeTo(destination, cancellationToken: source.token)
    }
    #expect(destination.length == 0)

    do {
        try await content.writeToAsync(destination, cancellationToken: source.token)
        Issue.record("Expected cancellation error for writeToAsync")
    } catch is OperationCanceledError {
        // expected
    } catch {
        Issue.record("Unexpected error: \(error)")
    }
    #expect(destination.length == 0)
}
