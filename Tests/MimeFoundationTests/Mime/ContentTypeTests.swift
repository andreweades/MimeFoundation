//
// ContentTypeTests.swift
//

import Testing
import MimeFoundation

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

    // Test failable parsing
    let parsedFromText = try? ContentType(parsing: text)
    #expect((parsedFromText != nil) == result)
    // Only compare results when parsing succeeds
    if result {
        assertParseResults(parsedFromText, expected)
    }

    let parsedFromBuffer = try? ContentType(parsing: buffer)
    #expect((parsedFromBuffer != nil) == result)
    // Only compare results when parsing succeeds
    if result {
        assertParseResults(parsedFromBuffer, expected)
    }

    // Test throwing parsing - only check for exceptions when parsing should fail
    if !result {
        do {
            _ = try ContentType(parsing: text)
            Issue.record("Parsing \"\(text)\" should have failed.")
        } catch let ex as ParseException {
            #expect(ex.tokenIndex == tokenIndex)
            #expect(ex.errorIndex == errorIndex)
        } catch {
            Issue.record("Unexpected exception: \(error)")
        }

        do {
            _ = try ContentType(parsing: buffer)
            Issue.record("Parsing \"\(text)\" should have failed.")
        } catch let ex as ParseException {
            #expect(ex.tokenIndex == tokenIndex)
            #expect(ex.errorIndex == errorIndex)
        } catch {
            Issue.record("Unexpected exception: \(error)")
        }
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

@Test("ContentType simple content type")
func contentTypeSimple() {
    let expected = try! ContentType("text", "plain")
    let text = "text/plain"
    assertParse(text, expected)
}

@Test("ContentType simple content type with vendor extension")
func contentTypeSimpleVendorExtension() {
    let expected = try! ContentType("application", "x-vnd.msdoc")
    let text = "application/x-vnd.msdoc"
    assertParse(text, expected)
}

@Test("ContentType simple content type with parameter")
func contentTypeSimpleWithParameter() {
    let expected = try! ContentType("multipart", "mixed")
    expected.boundary = "boundary-text"
    let text = "multipart/mixed; boundary=\"boundary-text\""
    assertParse(text, expected)
}

@Test("ContentType multipart parameter example from RFC2231")
func contentTypeMultipartParameterExampleFromRfc2231() throws {
    let text = "message/external-body; access-type=URL;\n      URL*0=\"ftp://\";\n      URL*1=\"cs.utk.edu/pub/moore/bulk-mailer/bulk-mailer.tar\""
    let expected = try ContentType("message", "external-body")
    try expected.parameters.add("access-type", "URL")
    try expected.parameters.add("URL", "ftp://cs.utk.edu/pub/moore/bulk-mailer/bulk-mailer.tar")
    assertParse(text, expected)
}

@Test("ContentType with empty parameter")
func contentTypeWithEmptyParameter() throws {
    let text = "multipart/mixed;;\n                Boundary=\"===========================_ _= 1212158(26598)\""
    let expected = try ContentType("multipart", "mixed")
    try expected.parameters.add("Boundary", "===========================_ _= 1212158(26598)")
    assertParse(text, expected)
}

@Test("ContentType without semicolon between parameters")
func contentTypeWithoutSemicolonBetweenParameters() throws {
    let text = "application/x-pkcs7-mime;\n name=\"smime.p7m\"\n smime-type=enveloped-data"
    let expected = try ContentType("application", "x-pkcs7-mime")
    expected.name = "smime.p7m"
    try expected.parameters.add("smime-type", "enveloped-data")
    assertParse(text, expected, result: true)
}

@Test("ContentType and content-transfer-encoding on one line")
func contentTypeAndContentTransferEncodingOnOneLine() throws {
    let text = "text/plain; charset = \"iso-8859-1\" Content-Transfer-Encoding: 8bit"
    let expected = try ContentType("text", "plain")
    assertParse(text, expected, result: false, tokenIndex: 35, errorIndex: 60)
}

@Test("ContentType encoded parameter example from RFC2231")
func contentTypeEncodedParameterExampleFromRfc2231() throws {
    let text = "application/x-stuff;\n      title*=us-ascii'en-us'This%20is%20%2A%2A%2Afun%2A%2A%2A"
    let expected = try ContentType("application", "x-stuff")
    try expected.parameters.add(.ascii, "title", "This is ***fun***")
    assertParse(text, expected)
}

@Test("ContentType multipart encoded parameter example from RFC2231")
func contentTypeMultipartEncodedParameterExampleFromRfc2231() throws {
    let text = "application/x-stuff;\n    title*1*=us-ascii'en'This%20is%20even%20more%20;\n    title*2*=%2A%2A%2Afun%2A%2A%2A%20;\n    title*3=\"isn't it!\""
    let expected = try ContentType("application", "x-stuff")
    try expected.parameters.add(.ascii, "title", "This is even more ***fun*** isn't it!")
    assertParse(text, expected)
}

@Test("ContentType RFC2047 encoded parameter")
func contentTypeRfc2047EncodedParameter() throws {
    let text = "application/x-stuff;\n    title=\"some chinese characters =?utf-8?q?=E4=B8=AD=E6=96=87?= and stuff\"\n"
    let expected = try ContentType("application", "x-stuff")
    try expected.parameters.add("title", "some chinese characters 中文 and stuff")
    assertParse(text, expected)
}

@Test("ContentType RFC2047 encoded parameter Big5")
func contentTypeRfc2047EncodedParameterBig5() throws {
    let text = "application/x-stuff;\n    title=\"some chinese characters =?big5?b?pKSk5Q==?= and stuff\"\n"
    let expected = try ContentType("application", "x-stuff")
    let big5 = CharsetUtils.getEncoding("big5") ?? .utf8
    try expected.parameters.add(big5, "title", "some chinese characters 中文 and stuff")
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

@Test("ContentType unquoted parameter")
func contentTypeUnquotedParameter() throws {
    let text = "application/octet-stream; name=Test;"
    let expected = try ContentType("application", "octet-stream")
    try expected.parameters.add("name", "Test")
    assertParse(text, expected)
}

@Test("ContentType unquoted parameter with spaces")
func contentTypeUnquotedParameterWithSpaces() throws {
    let text = "application/octet-stream; name=Test Name.pdf;"
    var options = ParserOptions.default
    let buffer = Array(text.utf8)
    var type: ContentType? = nil

    options.parameterComplianceMode = .strict
    type = try? ContentType(parsing: buffer, options: options)
    #expect(type == nil)

    options.parameterComplianceMode = .loose
    type = nil
    type = try? ContentType(parsing: buffer, options: options)
    #expect(type != nil)
    #expect(type?.mediaType == "application")
    #expect(type?.mediaSubtype == "octet-stream")
    #expect(type?.parameters.contains("name") == true)
    #expect(type?.parameters["name"] == "Test Name.pdf")
}

@Test("ContentType unquoted boundary with trailing newline and space")
func contentTypeUnquotedBoundaryWithTrailingNewLineAndSpace() throws {
    let text = "multipart/mixed;\n boundary=--boundary_0_8ab0e518-760f-4a94-acc0-66f7cdea5c9f\n "
    var options = ParserOptions.default
    let buffer = Array(text.utf8)
    var type: ContentType? = nil

    options.parameterComplianceMode = .strict
    type = try? ContentType(parsing: buffer, options: options)
    #expect(type != nil)
    #expect(type?.mediaType == "multipart")
    #expect(type?.mediaSubtype == "mixed")
    #expect(type?.boundary == "--boundary_0_8ab0e518-760f-4a94-acc0-66f7cdea5c9f")

    options.parameterComplianceMode = .loose
    type = nil
    type = try? ContentType(parsing: buffer, options: options)
    #expect(type != nil)
    #expect(type?.mediaType == "multipart")
    #expect(type?.mediaSubtype == "mixed")
    #expect(type?.boundary == "--boundary_0_8ab0e518-760f-4a94-acc0-66f7cdea5c9f")
}

@Test("ContentType international parameter value")
func contentTypeInternationalParameterValue() throws {
    let text = " text/plain; format=flowed; x-eai-please-do-not=\"abstürzen\""
    var type: ContentType? = nil
    type = try? ContentType(parsing: text)
    #expect(type != nil)
    #expect(type?.parameters["x-eai-please-do-not"] == "abstürzen")
}

@Test("ContentType mime type without subtype")
func contentTypeMimeTypeWithoutSubtype() {
    let text = "application-x-gzip; name=document.xml.gz"
    assertParse(text, nil, result: false, tokenIndex: 18, errorIndex: 18)
}

@Test("ContentType invalid type")
func contentTypeInvalidType() {
    let text = "åpplication/octet-stream"
    assertParse(text, nil, result: false, tokenIndex: 0, errorIndex: 0)
}

@Test("ContentType invalid subtype")
func contentTypeInvalidSubtype() {
    let text = "application/åtom"
    assertParse(text, nil, result: false, tokenIndex: 12, errorIndex: 12)
}

@Test("ContentType invalid data after mime type")
func contentTypeInvalidDataAfterMimeType() throws {
    let expected = try ContentType("application", "octet-stream")
    let text = "application/octet-stream x"
    assertParse(text, expected, result: false, tokenIndex: 25, errorIndex: 25)
}

@Test("ContentType empty parameter name")
func contentTypeEmptyParameterName() throws {
    let expected = try ContentType("text", "plain")
    let text = "text/plain; ="
    assertParse(text, expected, result: false, tokenIndex: 12, errorIndex: 12)
}

@Test("ContentType incomplete parameter name")
func contentTypeIncompleteParameterName() throws {
    let expected = try ContentType("text", "plain")
    let text = "text/plain; name"
    assertParse(text, expected, result: false, tokenIndex: 12, errorIndex: 16)
}

@Test("ContentType incomplete parameter name with star")
func contentTypeIncompleteParameterNameWithStar() throws {
    let expected = try ContentType("text", "plain")
    let text = "text/plain; name*"
    assertParse(text, expected, result: false, tokenIndex: 12, errorIndex: 17)
}

@Test("ContentType incomplete parameter name with part id")
func contentTypeIncompleteParameterNameWithPartId() throws {
    let expected = try ContentType("text", "plain")
    let text = "text/plain; name*0"
    assertParse(text, expected, result: false, tokenIndex: 12, errorIndex: 18)
}

@Test("ContentType incomplete parameter name with part id star")
func contentTypeIncompleteParameterNameWithPartIdStar() throws {
    let expected = try ContentType("text", "plain")
    let text = "text/plain; name*0*"
    assertParse(text, expected, result: false, tokenIndex: 12, errorIndex: 19)
}

@Test("ContentType invalid parameter name with part id")
func contentTypeInvalidParameterNameWithPartId() throws {
    let expected = try ContentType("text", "plain")
    let text = "text/plain; name*0*x"
    assertParse(text, expected, result: false, tokenIndex: 12, errorIndex: 19)
}

@Test("ContentType incomplete parameter name with part id star equal")
func contentTypeIncompleteParameterNameWithPartIdStarEqual() throws {
    let expected = try ContentType("text", "plain")
    let text = "text/plain; name*0*="
    assertParse(text, expected, result: false, tokenIndex: 12, errorIndex: 20)
}

@Test("ContentType properties")
func contentTypeProperties() throws {
    let type = try ContentType("application", "octet-stream")
    type.mediaType = "text"
    #expect(type.mediaType == "text")

    type.mediaSubtype = "plain"
    #expect(type.mediaSubtype == "plain")

    type.boundary = "--=Boundary=--"
    #expect(type.boundary == "--=Boundary=--")
    type.boundary = nil
    #expect(type.boundary == nil)

    type.format = "flowed"
    #expect(type.format == "flowed")
    type.format = nil
    #expect(type.format == nil)

    type.charset = "iso-8859-1"
    #expect(type.charset == "iso-8859-1")
    type.charset = nil
    #expect(type.charset == nil)

    type.name = "filename.txt"
    #expect(type.name == "filename.txt")
    type.name = nil
    #expect(type.name == nil)
}

@Test("ContentType toString")
func contentTypeToString() throws {
    let expected = "Content-Type: text/plain; format=\"flowed\"; charset=\"iso-8859-1\"; name=\"filename.txt\""
    let type = try ContentType("text", "plain")
    type.format = "flowed"
    type.charset = "iso-8859-1"
    type.name = "filename.txt"
    let value = type.toString().replacingOccurrences(of: "\r\n", with: "\n")
    #expect(value == expected)
}

@Test("ContentType toString encode")
func contentTypeToStringEncode() throws {
    let rfc2231 = "Content-Type: text/plain; format=flowed; charset=utf-8;\n\tname*0*=utf-8''%D0%AD%D1%82%D0%BE%20%D1%80%D1%83%D1%81%D1%81%D0%BA%D0%BE;\n\tname*1*=%D0%B5%20%D0%B8%D0%BC%D1%8F%20%D1%84%D0%B0%D0%B9%D0%BB%D0%B0.txt"
    let rfc2047 = "Content-Type: text/plain; format=flowed; charset=utf-8;\n\tname=\"=?utf-8?b?0K3RgtC+INGA0YPRgdGB0LrQvtC1INC40LzRjyDRhNCw0LnQu9CwLnR4?=\n\t=?utf-8?q?t?=\""

    let type = try ContentType("text", "plain")
    type.format = "flowed"
    type.charset = "utf-8"
    type.name = "Это русское имя файла.txt"

    var value = try type.toString(.utf8, true).replacingOccurrences(of: "\r\n", with: "\n")
    #expect(value == rfc2231)

    for param in type.parameters {
        param.encodingMethod = .rfc2231
    }
    value = try type.toString(.utf8, true).replacingOccurrences(of: "\r\n", with: "\n")
    #expect(value == rfc2231)

    for param in type.parameters {
        param.encodingMethod = .rfc2047
    }
    value = try type.toString(.utf8, true).replacingOccurrences(of: "\r\n", with: "\n")
    #expect(value == rfc2047)
}

@Test("ContentType parse multipart multipart mixed")
func contentTypeParseMultipartMultipartMixed() throws {
    let input = "multipart/multipart/mixed; boundary=\"boundary-marker\"\r\n"
    var contentType: ContentType? = nil
    contentType = try? ContentType(parsing: input)
    #expect(contentType != nil)
    #expect(contentType?.mediaType == "multipart")
    #expect(contentType?.mediaSubtype == "multipart/mixed")
    #expect(contentType?.boundary == "boundary-marker")
}
