//
// MimeTypeRegistryTests.swift
//

import Testing
@testable import MimeFoundation

@Test("MimeTypeRegistry argument exceptions")
func mimeTypeRegistryArgumentExceptions() throws {
    var registry = MimeTypeRegistry.default

    #expect(throws: MimeTypeError.emptyMimeType) {
        try registry.register(mimeType: "", fileExtension: ".ext")
    }
    #expect(throws: MimeTypeError.emptyExtension) {
        try registry.register(mimeType: "text/plain", fileExtension: "")
    }
}

@Test("MimeTypeRegistry getMimeType")
func mimeTypeRegistryGetMimeType() {
    let registry = MimeTypeRegistry.default
    #expect(registry.mimeType(for: "filename") == "application/octet-stream")
    #expect(registry.mimeType(for: "filename.") == "application/octet-stream")
    #expect(registry.mimeType(for: "filename.txt") == "text/plain")
    #expect(registry.mimeType(for: "filename.csv") == "text/csv")
}

@Test("MimeTypeRegistry extensionFor")
func mimeTypeRegistryExtensionFor() {
    let registry = MimeTypeRegistry.default
    #expect(registry.extensionFor(mimeType: "text/plain") == ".txt")
    #expect(registry.extensionFor(mimeType: "application/x-vnd.fake-mime-type") == nil)
}

@Test("MimeTypeRegistry register")
func mimeTypeRegistryRegister() throws {
    var registry = MimeTypeRegistry.default
    #expect(registry.mimeType(for: "filename.bogus") == "application/octet-stream")
    #expect(registry.extensionFor(mimeType: "application/vnd.bogus") == nil)

    try registry.register(mimeType: "application/vnd.bogus", fileExtension: ".bogus")

    #expect(registry.mimeType(for: "filename.bogus") == "application/vnd.bogus")
    #expect(registry.extensionFor(mimeType: "application/vnd.bogus") == ".bogus")
}
