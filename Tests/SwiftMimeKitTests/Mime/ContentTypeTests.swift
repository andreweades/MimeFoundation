//
// ContentTypeTests.swift
//

import Testing
import SwiftMimeKit

private func assertParseResults(_ type: ContentType?, _ expected: ContentType?) {
    if expected == nil {
        #expect(type == nil)
        return
    }
    guard let type, let expected else {
        Issue.record("ContentType mismatch")
        return
    }

    #expect(type.mediaType == expected.mediaType)
    #expect(type.mediaSubtype == expected.mediaSubtype)
    #expect(type.parameters.count == expected.parameters.count)

    for index in 0..<expected.parameters.count {
        let expectedParam = expected.parameters[index]
        let actual = type.parameters[index]
        #expect(actual.name == expectedParam.name)
        #expect(CharsetUtils.getMimeCharset(actual.encoding) == CharsetUtils.getMimeCharset(expectedParam.encoding))
        #expect(actual.value == expectedParam.value)
        #expect(type.parameters.contains(expectedParam.name))
        #expect(type.parameters[expectedParam.name] == expected.parameters[expectedParam.name])
    }
}

private func assertParse(_ text: String, _ expected: ContentType?, result: Bool = true, tokenIndex: Int = -1, errorIndex: Int = -1) {
    let buffer = Array(text.utf8)
    let options = ParserOptions.default
    var type: ContentType? = nil

    #expect(ContentType.tryParse(text, contentType: &type) == result)
    assertParseResults(type, expected)

    type = nil
    #expect(ContentType.tryParse(options, text, contentType: &type) == result)
    assertParseResults(type, expected)

    type = nil
    #expect(ContentType.tryParse(buffer, contentType: &type) == result)
    assertParseResults(type, expected)

    type = nil
    #expect(ContentType.tryParse(options, buffer, contentType: &type) == result)
    assertParseResults(type, expected)

    type = nil
    #expect(ContentType.tryParse(buffer, startIndex: 0, contentType: &type) == result)
    assertParseResults(type, expected)

    type = nil
    #expect(ContentType.tryParse(options, buffer, startIndex: 0, contentType: &type) == result)
    assertParseResults(type, expected)

    type = nil
    #expect(ContentType.tryParse(buffer, startIndex: 0, length: buffer.count, contentType: &type) == result)
    assertParseResults(type, expected)

    type = nil
    #expect(ContentType.tryParse(options, buffer, startIndex: 0, length: buffer.count, contentType: &type) == result)
    assertParseResults(type, expected)

    do {
        let parsed = try ContentType.parse(text)
        if tokenIndex != -1 && errorIndex != -1 {
            Issue.record("Parsing \"\(text)\" should have failed.")
        }
        assertParseResults(parsed, expected)
    } catch let ex as ParseException {
        #expect(ex.tokenIndex == tokenIndex)
        #expect(ex.errorIndex == errorIndex)
    } catch {
        Issue.record("Unexpected exception: \(error)")
    }

    do {
        let parsed = try ContentType.parse(options, text)
        if tokenIndex != -1 && errorIndex != -1 {
            Issue.record("Parsing \"\(text)\" should have failed.")
        }
        assertParseResults(parsed, expected)
    } catch let ex as ParseException {
        #expect(ex.tokenIndex == tokenIndex)
        #expect(ex.errorIndex == errorIndex)
    } catch {
        Issue.record("Unexpected exception: \(error)")
    }

    do {
        let parsed = try ContentType.parse(buffer)
        if tokenIndex != -1 && errorIndex != -1 {
            Issue.record("Parsing \"\(text)\" should have failed.")
        }
        assertParseResults(parsed, expected)
    } catch let ex as ParseException {
        #expect(ex.tokenIndex == tokenIndex)
        #expect(ex.errorIndex == errorIndex)
    } catch {
        Issue.record("Unexpected exception: \(error)")
    }

    do {
        let parsed = try ContentType.parse(options, buffer)
        if tokenIndex != -1 && errorIndex != -1 {
            Issue.record("Parsing \"\(text)\" should have failed.")
        }
        assertParseResults(parsed, expected)
    } catch let ex as ParseException {
        #expect(ex.tokenIndex == tokenIndex)
        #expect(ex.errorIndex == errorIndex)
    } catch {
        Issue.record("Unexpected exception: \(error)")
    }

    do {
        let parsed = try ContentType.parse(buffer, startIndex: 0)
        if tokenIndex != -1 && errorIndex != -1 {
            Issue.record("Parsing \"\(text)\" should have failed.")
        }
        assertParseResults(parsed, expected)
    } catch let ex as ParseException {
        #expect(ex.tokenIndex == tokenIndex)
        #expect(ex.errorIndex == errorIndex)
    } catch {
        Issue.record("Unexpected exception: \(error)")
    }

    do {
        let parsed = try ContentType.parse(options, buffer, startIndex: 0)
        if tokenIndex != -1 && errorIndex != -1 {
            Issue.record("Parsing \"\(text)\" should have failed.")
        }
        assertParseResults(parsed, expected)
    } catch let ex as ParseException {
        #expect(ex.tokenIndex == tokenIndex)
        #expect(ex.errorIndex == errorIndex)
    } catch {
        Issue.record("Unexpected exception: \(error)")
    }

    do {
        let parsed = try ContentType.parse(buffer, startIndex: 0, length: buffer.count)
        if tokenIndex != -1 && errorIndex != -1 {
            Issue.record("Parsing \"\(text)\" should have failed.")
        }
        assertParseResults(parsed, expected)
    } catch let ex as ParseException {
        #expect(ex.tokenIndex == tokenIndex)
        #expect(ex.errorIndex == errorIndex)
    } catch {
        Issue.record("Unexpected exception: \(error)")
    }

    do {
        let parsed = try ContentType.parse(options, buffer, startIndex: 0, length: buffer.count)
        if tokenIndex != -1 && errorIndex != -1 {
            Issue.record("Parsing \"\(text)\" should have failed.")
        }
        assertParseResults(parsed, expected)
    } catch let ex as ParseException {
        #expect(ex.tokenIndex == tokenIndex)
        #expect(ex.errorIndex == errorIndex)
    } catch {
        Issue.record("Unexpected exception: \(error)")
    }
}

@Test("ContentType argument exceptions")
func contentTypeArgumentExceptions() {
    let type = try! ContentType("text", "plain")

    #expect(throws: (any Error).self) { try type.setMediaType(nil) }
    #expect(throws: (any Error).self) { try type.setMediaSubtype(nil) }

    #expect(throws: (any Error).self) { _ = try type.isMimeType(nil, "plain") }
    #expect(throws: (any Error).self) { _ = try type.isMimeType("text", nil) }

    #expect(throws: (any Error).self) { _ = try type.toString(nil, true) }
    #expect(throws: (any Error).self) { _ = try type.toString(nil, .utf8, true) }
    #expect(throws: (any Error).self) { _ = try type.toString(FormatOptions.default, nil, true) }
}

@Test("ContentType clone")
func contentTypeClone() {
    let original = try! ContentType("text", "plain")
    original.charset = "iso-8859-1"
    original.name = "clone-me.txt"
    let clone = original.clone()

    #expect(clone.mediaType == original.mediaType)
    #expect(clone.mediaSubtype == original.mediaSubtype)
    #expect(clone.parameters.count == original.parameters.count)
    #expect(clone.charset == original.charset)
    #expect(clone.name == original.name)
}

@Test("ContentType changed events")
func contentTypeChangedEvents() {
    let contentType = try! ContentType("text", "plain")
    var changed = 0
    contentType.changed = { changed += 1 }

    contentType.name = "filename.txt"
    #expect(changed == 1)
    changed = 0

    contentType.name = "filename.txt"
    #expect(changed == 0)

    contentType.name = "filename.pdf"
    #expect(changed == 1)
    changed = 0

    contentType.name = nil
    #expect(changed == 1)
    changed = 0

    contentType.boundary = "=-boundary-marker--"
    #expect(changed == 1)
    changed = 0

    contentType.boundary = "=-boundary-marker--"
    #expect(changed == 0)

    contentType.boundary = "=-boundary-marker-123--"
    #expect(changed == 1)
    changed = 0

    contentType.boundary = nil
    #expect(changed == 1)
    changed = 0

    contentType.charset = "utf-8"
    #expect(changed == 1)
    changed = 0

    contentType.charset = "utf-8"
    #expect(changed == 0)

    contentType.charset = "iso-8859-1"
    #expect(changed == 1)
    changed = 0

    contentType.charset = nil
    #expect(changed == 1)
    changed = 0

    contentType.charsetEncoding = .utf8
    #expect(changed == 1)
    changed = 0

    contentType.charsetEncoding = .utf8
    #expect(changed == 0)

    contentType.charsetEncoding = .ascii
    #expect(changed == 1)
    changed = 0

    contentType.charsetEncoding = nil
    #expect(changed == 1)
    changed = 0

    contentType.format = "flowed"
    #expect(changed == 1)
    changed = 0

    contentType.format = "flowed"
    #expect(changed == 0)

    contentType.format = "unknown"
    #expect(changed == 1)
    changed = 0

    contentType.format = nil
    #expect(changed == 1)
    changed = 0
}

@Test("ContentType parse")
func contentTypeParse() {
    let text = "text/plain; charset=utf-8"
    let expected = try! ContentType("text", "plain")
    try? expected.parameters.add("charset", "utf-8")
    assertParse(text, expected)
}

@Test("ContentType breaking of long parameter values")
func contentTypeBreakingOfLongParamValues() throws {
    let expected = " text/plain; charset=iso-8859-1;\n\tname*0=\"this is a really really long filename that should force MimeKit to b\";\n\tname*1=\"reak it apart - yay!.html\"\n"
    var format = FormatOptions.default
    format.newLineFormat = .unix

    let type = try ContentType("text", "plain")
    try type.parameters.add("charset", "iso-8859-1")
    try type.parameters.add("name", "this is a really really long filename that should force MimeKit to break it apart - yay!.html")

    let encoded = type.encode(format, .utf8)
    #expect(encoded == expected)
}

@Test("ContentType breaking of long parameter values RFC2047")
func contentTypeBreakingOfLongParamValues2047() throws {
    let expected = " text/plain; charset=iso-8859-1; name=\"=?us-ascii?q?this_is_?=\n\t=?us-ascii?q?a_really_really_long_filename_that_should_force_MimeKit_to_?=\n\t=?us-ascii?q?break_it_apart_-_yay!=2Ehtml?=\"\n"
    var format = FormatOptions.default
    format.parameterEncodingMethod = .rfc2047
    format.newLineFormat = .unix

    let type = try ContentType("text", "plain")
    try type.parameters.add("charset", "iso-8859-1")
    try type.parameters.add("name", "this is a really really long filename that should force MimeKit to break it apart - yay!.html")

    let encoded = type.encode(format, .utf8)
    #expect(encoded == expected)
}

@Test("ContentType encoding of parameter values")
func contentTypeEncodingOfParamValues() throws {
    let expected = " text/plain; charset=iso-8859-1;\n\tname*=iso-8859-1''Kristoffer%20Br%E5nemyr\n"
    var format = FormatOptions.default
    format.newLineFormat = .unix

    let type = try ContentType("text", "plain")
    try type.parameters.add("charset", "iso-8859-1")
    try type.parameters.add("name", "Kristoffer Brånemyr")

    let encoded = type.encode(format, .utf8)
    #expect(encoded == expected)
}

@Test("ContentType encoding of parameter values RFC2047")
func contentTypeEncodingOfParamValues2047() throws {
    let expected = " text/plain; charset=iso-8859-1;\n\tname=\"=?iso-8859-1?q?Kristoffer_Br=E5nemyr?=\"\n"
    var format = FormatOptions.default
    format.parameterEncodingMethod = .rfc2047
    format.newLineFormat = .unix

    let type = try ContentType("text", "plain")
    try type.parameters.add("charset", "iso-8859-1")
    try type.parameters.add("name", "Kristoffer Brånemyr")

    let encoded = type.encode(format, .utf8)
    #expect(encoded == expected)
}

@Test("ContentType encoding of long parameter values")
func contentTypeEncodingOfLongParamValues() throws {
    let expected = " text/plain; charset=utf-8;\n\tname*0*=iso-8859-1''%E5%E5%E5%E5%E5%E5%E5%E5%E5%E5%E5%E5%E5%E5%E5%E5%E5%E5;\n\tname*1*=%E5%E5%E5%E5%E5%E5%E5%E5%E5%E5%E5%E5%E5%E5%E5%E5%E5%E5%E5%E5%E5%E5\n"
    var format = FormatOptions.default
    format.newLineFormat = .unix

    let type = try ContentType("text", "plain")
    try type.parameters.add("charset", "utf-8")
    try type.parameters.add("name", String(repeating: "å", count: 40))

    let encoded = type.encode(format, .utf8)
    #expect(encoded == expected)
}

@Test("ContentType encoding of long parameter values RFC2047")
func contentTypeEncodingOfLongParamValues2047() throws {
    let expected = " text/plain; charset=utf-8; name=\"=?iso-8859-1?b?5eXl5eXl?=\n\t=?iso-8859-1?b?5eXl5eXl5eXl5eXl5eXl5eXl5eXl5eXl5eXl5eXl5eXl5Q==?=\"\n"
    var format = FormatOptions.default
    format.parameterEncodingMethod = .rfc2047
    format.newLineFormat = .unix

    let type = try ContentType("text", "plain")
    try type.parameters.add("charset", "utf-8")
    try type.parameters.add("name", String(repeating: "å", count: 40))

    let encoded = type.encode(format, .utf8)
    #expect(encoded == expected)
}
