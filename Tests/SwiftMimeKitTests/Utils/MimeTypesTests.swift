//
// MimeTypesTests.swift
//

import Testing
@testable import SwiftMimeKit

@Test("MimeTypes argument exceptions")
func mimeTypesArgumentExceptions() async {
    do {
        _ = try await MimeTypes.getMimeType(nil)
        Issue.record("Expected nil fileName to throw.")
    } catch let error as MimeTypeError {
        #expect(error == .nilFileName)
    } catch {
        Issue.record("Unexpected error: \(error)")
    }

    do {
        _ = try await MimeTypes.register(nil, ".ext")
        Issue.record("Expected nil mimeType to throw.")
    } catch let error as MimeTypeError {
        #expect(error == .nilMimeType)
    } catch {
        Issue.record("Unexpected error: \(error)")
    }

    do {
        _ = try await MimeTypes.register("", ".ext")
        Issue.record("Expected empty mimeType to throw.")
    } catch let error as MimeTypeError {
        #expect(error == .emptyMimeType)
    } catch {
        Issue.record("Unexpected error: \(error)")
    }

    do {
        _ = try await MimeTypes.register("text/plain", nil)
        Issue.record("Expected nil extension to throw.")
    } catch let error as MimeTypeError {
        #expect(error == .nilExtension)
    } catch {
        Issue.record("Unexpected error: \(error)")
    }

    do {
        _ = try await MimeTypes.register("text/plain", "")
        Issue.record("Expected empty extension to throw.")
    } catch let error as MimeTypeError {
        #expect(error == .emptyExtension)
    } catch {
        Issue.record("Unexpected error: \(error)")
    }

    do {
        _ = try await MimeTypes.tryGetExtension(nil)
        Issue.record("Expected nil mimeType to throw.")
    } catch let error as MimeTypeError {
        #expect(error == .nilMimeType)
    } catch {
        Issue.record("Unexpected error: \(error)")
    }
}

@Test("MimeTypes getMimeType")
func mimeTypesGetMimeType() async {
    #expect(await MimeTypes.getMimeType("filename") == "application/octet-stream")
    #expect(await MimeTypes.getMimeType("filename.") == "application/octet-stream")
    #expect(await MimeTypes.getMimeType("filename.txt") == "text/plain")
    #expect(await MimeTypes.getMimeType("filename.csv") == "text/csv")
}

@Test("MimeTypes tryGetExtension")
func mimeTypesTryGetExtension() async throws {
    #expect(try await MimeTypes.tryGetExtension("text/plain") == ".txt")
    #expect(try await MimeTypes.tryGetExtension("application/x-vnd.fake-mime-type") == nil)
}

@Test("MimeTypes register")
func mimeTypesRegister() async throws {
    #expect(await MimeTypes.getMimeType("filename.bogus") == "application/octet-stream")
    #expect(try await MimeTypes.tryGetExtension("application/vnd.bogus") == nil)

    try await MimeTypes.register("application/vnd.bogus", ".bogus")

    #expect(await MimeTypes.getMimeType("filename.bogus") == "application/vnd.bogus")
    #expect(try await MimeTypes.tryGetExtension("application/vnd.bogus") == ".bogus")
}
