//
// MimeTypeRegistryTests.swift
//

import Testing
@testable import MimeFoundation

@Test("MimeTypeRegistry argument exceptions")
func mimeTypeRegistryArgumentExceptions() {
    var registry = MimeTypeRegistry.default

    #expect(throws: MimeTypeError.nilFileName) {
        _ = try registry.mimeType(for: nil)
    }
    #expect(throws: MimeTypeError.nilMimeType) {
        try registry.register(nil, ".ext")
    }
    #expect(throws: MimeTypeError.emptyMimeType) {
        try registry.register("", ".ext")
    }
    #expect(throws: MimeTypeError.nilExtension) {
        try registry.register("text/plain", nil)
    }
    #expect(throws: MimeTypeError.emptyExtension) {
        try registry.register("text/plain", "")
    }
    #expect(throws: MimeTypeError.nilMimeType) {
        _ = try registry.tryGetExtension(nil)
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

@Test("MimeTypeRegistry tryGetExtension")
func mimeTypeRegistryTryGetExtension() throws {
    let registry = MimeTypeRegistry.default
    #expect(try registry.tryGetExtension("text/plain") == ".txt")
    #expect(try registry.tryGetExtension("application/x-vnd.fake-mime-type") == nil)
}

@Test("MimeTypeRegistry register")
func mimeTypeRegistryRegister() throws {
    var registry = MimeTypeRegistry.default
    #expect(registry.mimeType(for: "filename.bogus") == "application/octet-stream")
    #expect(try registry.tryGetExtension("application/vnd.bogus") == nil)

    try registry.register("application/vnd.bogus", ".bogus")

    #expect(registry.mimeType(for: "filename.bogus") == "application/vnd.bogus")
    #expect(try registry.tryGetExtension("application/vnd.bogus") == ".bogus")
}
