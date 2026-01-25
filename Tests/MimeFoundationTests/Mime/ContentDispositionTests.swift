//
// ContentDispositionTests.swift
//

import Testing
import MimeFoundation

private func assertParseResults(_ disposition: ContentDisposition?, _ expected: ContentDisposition?) {
    if expected == nil {
        #expect(disposition == nil)
        return
    }
    guard let disposition, let expected else {
        Issue.record("Disposition mismatch")
        return
    }

    #expect(disposition.disposition == expected.disposition)
    #expect(disposition.parameters.count == expected.parameters.count)

    for index in 0..<expected.parameters.count {
        let expectedParam = expected.parameters[index]
        let actual = disposition.parameters[index]
        #expect(actual.name == expectedParam.name)
        #expect(CharsetUtils.getMimeCharset(actual.encoding) == CharsetUtils.getMimeCharset(expectedParam.encoding))
        #expect(actual.value == expectedParam.value)
        #expect(disposition.parameters.contains(expectedParam.name))
        #expect(disposition.parameters[expectedParam.name] == expected.parameters[expectedParam.name])
    }
}

private func assertParse(_ text: String, _ expected: ContentDisposition?, result: Bool = true, tokenIndex: Int = -1, errorIndex: Int = -1) {
    let buffer = Array(text.utf8)

    // Test failable parsing
    let parsedFromText = try? ContentDisposition(parsing: text)
    #expect((parsedFromText != nil) == result)
    // Only compare results when parsing succeeds
    if result {
        assertParseResults(parsedFromText, expected)
    }

    let parsedFromBuffer = try? ContentDisposition(parsing: buffer)
    #expect((parsedFromBuffer != nil) == result)
    // Only compare results when parsing succeeds
    if result {
        assertParseResults(parsedFromBuffer, expected)
    }

    // Test throwing parsing - only check for exceptions when parsing should fail
    if !result {
        do {
            _ = try ContentDisposition(parsing: text)
            Issue.record("Parsing \"\(text)\" should have failed.")
        } catch let ex as ParseException {
            #expect(ex.tokenIndex == tokenIndex)
            #expect(ex.errorIndex == errorIndex)
        } catch {
            Issue.record("Unexpected exception: \(error)")
        }

        do {
            _ = try ContentDisposition(parsing: buffer)
            Issue.record("Parsing \"\(text)\" should have failed.")
        } catch let ex as ParseException {
            #expect(ex.tokenIndex == tokenIndex)
            #expect(ex.errorIndex == errorIndex)
        } catch {
            Issue.record("Unexpected exception: \(error)")
        }
    }
}

@Test("ContentDisposition argument exceptions")
func contentDispositionArgumentExceptions() {
    let disposition = try! ContentDisposition()

    #expect(throws: (any Error).self) { try disposition.setDisposition(nil) }
    #expect(throws: (any Error).self) { try disposition.setDisposition("") }
    #expect(throws: (any Error).self) { try disposition.setDisposition("žádost") }
    #expect(throws: (any Error).self) { try disposition.setDisposition("two atoms") }
    #expect(throws: (any Error).self) { _ = try disposition.toString(nil, .utf8, true) }
    #expect(throws: (any Error).self) { _ = try disposition.toString(FormatOptions.default, nil, true) }
}

@Test("ContentDisposition clone")
func contentDispositionClone() {
    let original = try! ContentDisposition()
    original.creationDate = DateTimeOffset(year: 2024, month: 2, day: 1, hour: 10, minute: 0, second: 0, offsetMinutes: 0)
    original.modificationDate = DateTimeOffset(year: 2024, month: 2, day: 2, hour: 10, minute: 0, second: 0, offsetMinutes: 0)
    original.readDate = DateTimeOffset(year: 2024, month: 2, day: 3, hour: 10, minute: 0, second: 0, offsetMinutes: 0)
    original.fileName = "clone-me.txt"
    original.size = 10
    let clone = original.copy()

    #expect(clone.disposition == original.disposition)
    #expect(clone.parameters.count == original.parameters.count)
    #expect(clone.creationDate == original.creationDate)
    #expect(clone.modificationDate == original.modificationDate)
    #expect(clone.readDate == original.readDate)
    #expect(clone.fileName == original.fileName)
    #expect(clone.size == original.size)
}

@Test("ContentDisposition changed events")
func contentDispositionChangedEvents() {
    let timestamp = DateTimeOffset(year: 2022, month: 9, day: 9, hour: 7, minute: 41, second: 23, offsetMinutes: -240)!
    let disposition = try! ContentDisposition(ContentDisposition.attachment)
    var changed = 0

    disposition.changed = { changed += 1 }

    try? disposition.setDisposition(ContentDisposition.attachment)
    #expect(changed == 0)

    try? disposition.setDisposition(ContentDisposition.inline)
    #expect(changed == 1)
    changed = 0

    disposition.fileName = "filename.txt"
    #expect(changed == 1)
    changed = 0

    disposition.fileName = "filename.txt"
    #expect(changed == 0)

    disposition.fileName = "filename.pdf"
    #expect(changed == 1)
    changed = 0

    disposition.fileName = nil
    #expect(changed == 1)
    changed = 0

    disposition.creationDate = timestamp
    #expect(changed == 1)
    changed = 0

    disposition.creationDate = timestamp
    #expect(changed == 0)

    disposition.creationDate = DateTimeOffset.now()
    #expect(changed == 1)
    changed = 0

    disposition.creationDate = nil
    #expect(changed == 1)
    changed = 0

    disposition.modificationDate = timestamp
    #expect(changed == 1)
    changed = 0

    disposition.modificationDate = timestamp
    #expect(changed == 0)

    disposition.modificationDate = DateTimeOffset.now()
    #expect(changed == 1)
    changed = 0

    disposition.modificationDate = nil
    #expect(changed == 1)
    changed = 0

    disposition.readDate = timestamp
    #expect(changed == 1)
    changed = 0

    disposition.readDate = timestamp
    #expect(changed == 0)

    disposition.readDate = DateTimeOffset.now()
    #expect(changed == 1)
    changed = 0

    disposition.readDate = nil
    #expect(changed == 1)
    changed = 0

    disposition.size = 1024
    #expect(changed == 1)
    changed = 0

    disposition.size = 1024
    #expect(changed == 0)

    disposition.size = 2048
    #expect(changed == 1)
    changed = 0

    disposition.size = nil
    #expect(changed == 1)
    changed = 0
}

@Test("ContentDisposition empty value")
func contentDispositionEmptyValue() {
    assertParse(" ", nil, result: false, tokenIndex: 1, errorIndex: 1)
}

@Test("ContentDisposition multiple parameters with identical names")
func contentDispositionMultipleParametersWithIdenticalNames() {
    let text1 = "inline;\n filename=\"Filename.doc\";\n filename*0*=UTF-8''UnicodeFile;\n filename*1*=name.doc"
    let text2 = "inline;\n filename*0*=UTF-8''UnicodeFile;\n filename*1*=name.doc;\n filename=\"Filename.doc\""
    let text3 = "inline;\n filename*0*=UTF-8''UnicodeFile;\n filename=\"Filename.doc\";\n filename*1*=name.doc"
    let expected = try! ContentDisposition("inline")
    try? expected.parameters.add("filename", "UnicodeFilename.doc")

    assertParse(text1, expected)
    assertParse(text2, expected)
    assertParse(text3, expected)
}

@Test("ContentDisposition non-existent disposition with parameters")
func contentDispositionNonExistentDispositionValueWithParameters() {
    let text = " ; filename=\"test.txt\""
    let expected = try! ContentDisposition("attachment")
    try? expected.parameters.add("filename", "test.txt")

    assertParse(text, expected, result: true, tokenIndex: 1, errorIndex: 1)
}

@Test("ContentDisposition mistakenly quoted disposition value")
func contentDispositionMistakenlyQuotedDispositionValue() {
    let text = "\"inline\"; filename=\"test.txt\""
    let expected = try! ContentDisposition("inline")
    try? expected.parameters.add("filename", "test.txt")

    assertParse(text, expected, result: true, tokenIndex: 0, errorIndex: 0)
}

@Test("ContentDisposition mistakenly quoted encoded parameter values")
func contentDispositionMistakenlyQuotedEncodedParameterValues() {
    let text = "attachment;\n filename*0*=\"ISO-8859-2''%C8%50%50%20%2D%20%BE%E1%64%6F%73%74%20%6F%20%61%6B%63%65\";\n " +
        "filename*1*=\"%70%74%61%63%69%20%73%6D%6C%6F%75%76%79%20%31%32%2E%31%32%2E\";\n " +
        "filename*2*=\"%64%6F%63\""
    let filename = "ČPP - žádost o akceptaci smlouvy 12.12.doc"
    let expected = try! ContentDisposition("attachment")
    let encoding = CharsetUtils.getEncoding("ISO-8859-2")!
    try? expected.parameters.add(encoding: encoding, name: "filename", value: filename)

    assertParse(text, expected)
}

@Test("ContentDisposition folded quoted filename")
func contentDispositionFoldedQuotedFilename() {
    let text = "attachment; \r\n\tfilename=\"CR_A-EXCG-2020-0008 - Addition of UAT Email Domain in CMMP-GCN Connector\r\n\t.docx\"\r\n"
    let filename = "CR_A-EXCG-2020-0008 - Addition of UAT Email Domain in CMMP-GCN Connector\t.docx"
    let expected = try! ContentDisposition("attachment")
    try? expected.parameters.add("filename", filename)

    assertParse(text, expected)
}

@Test("ContentDisposition folded unquoted filename")
func contentDispositionFoldedUnquotedFilename() {
    let text = " attachment; filename=Partnership Marketing Agreement\n\tForm - Mega Brands - Easter Toys - Week 11.pdf"
    let filename = "Partnership Marketing Agreement\tForm - Mega Brands - Easter Toys - Week 11.pdf"
    let expected = try! ContentDisposition("attachment")
    try? expected.parameters.add("filename", filename)

    assertParse(text, expected)
}

@Test("ContentDisposition invalid disposition")
func contentDispositionInvalidDisposition() {
    assertParse("\\attachment", nil, result: false, tokenIndex: 0, errorIndex: 0)
}

@Test("ContentDisposition invalid data after disposition")
func contentDispositionInvalidDataAfterDisposition() {
    let expected = try! ContentDisposition("attachment")
    let text = "attachment x"
    assertParse(text, expected, result: false, tokenIndex: 11, errorIndex: 11)
}

@Test("ContentDisposition Chinese filename")
func contentDispositionChineseFilename() {
    let expected = " attachment;\n\tfilename*=gb18030''%B2%E2%CA%D4%CE%C4%B1%BE.txt\n"
    let disposition = try! ContentDisposition(ContentDisposition.attachment)
    try? disposition.parameters.add(charset: "GB18030", name: "filename", value: "测试文本.txt")

    var format = FormatOptions.default
    format.newLineFormat = .unix

    let encoded = disposition.encode(format, .utf8)
    #expect(encoded == expected)

    let parsed = try? ContentDisposition(parsing: encoded)
    #expect(parsed != nil)
    #expect(parsed?.fileName == "测试文本.txt")

    let param = parsed?.parameters.parameter(named: "filename")
    #expect(param != nil)
    #expect(CharsetUtils.getMimeCharset(param!.encoding) == "gb18030")
}

@Test("ContentDisposition Chinese filename RFC2047")
func contentDispositionChineseFilename2047() {
    let expected = " attachment; filename=\"=?gb18030?b?suLK1M7Esb4udHh0?=\"\n"
    let disposition = try! ContentDisposition(ContentDisposition.attachment)
    try? disposition.parameters.add(charset: "GB18030", name: "filename", value: "测试文本.txt")

    var format = FormatOptions.default
    format.parameterEncodingMethod = .rfc2047
    format.newLineFormat = .unix

    let encoded = disposition.encode(format, .utf8)
    #expect(encoded == expected)

    let parsed = try? ContentDisposition(parsing: encoded)
    #expect(parsed != nil)
    #expect(parsed?.fileName == "测试文本.txt")

    let param = parsed?.parameters.parameter(named: "filename")
    #expect(param != nil)
    #expect(CharsetUtils.getMimeCharset(param!.encoding) == "gb18030")
}

@Test("ContentDisposition issue 239")
func contentDispositionIssue239() {
    let text = " attachment; size=1049971;\n\tfilename*=\"utf-8''SBD%20%C5%A0kodov%C3%A1k%2Ejpg\""
    let filename = "SBD Škodovák.jpg"
    let expected = try! ContentDisposition("attachment")
    try? expected.parameters.add("size", "1049971")
    try? expected.parameters.add("filename", filename)
    assertParse(text, expected)
}

@Test("ContentDisposition form data")
func contentDispositionFormData() {
    let text = "form-data; filename=\"form.txt\""
    let buffer = Array(text.utf8)

    let dispositionFromText = try? ContentDisposition(parsing: text)
    #expect(dispositionFromText != nil)
    #expect(dispositionFromText?.disposition == "form-data")
    #expect(dispositionFromText?.fileName == "form.txt")

    let dispositionFromBuffer = try? ContentDisposition(parsing: buffer)
    #expect(dispositionFromBuffer != nil)
    #expect(dispositionFromBuffer?.disposition == "form-data")
    #expect(dispositionFromBuffer?.fileName == "form.txt")
}

@Test("ContentDisposition parameters")
func contentDispositionParameters() {
    let expected = "Content-Disposition: attachment; filename=document.doc;\n" +
        "\tcreation-date=\"Sat, 04 Jan 1997 15:22:17 -0400\";\n" +
        "\tmodification-date=\"Thu, 04 Jan 2007 15:22:17 -0400\";\n" +
        "\tread-date=\"Wed, 04 Jan 2012 15:22:17 -0400\"; size=37001"

    let ctime = DateTimeOffset(year: 1997, month: 1, day: 4, hour: 15, minute: 22, second: 17, offsetMinutes: -240)!
    let mtime = DateTimeOffset(year: 2007, month: 1, day: 4, hour: 15, minute: 22, second: 17, offsetMinutes: -240)!
    let atime = DateTimeOffset(year: 2012, month: 1, day: 4, hour: 15, minute: 22, second: 17, offsetMinutes: -240)!
    let disposition = try! ContentDisposition()
    var format = FormatOptions.default
    format.newLineFormat = .unix

    #expect(disposition.disposition == ContentDisposition.attachment)
    #expect(disposition.isAttachment == true)
    #expect(disposition.fileName == nil)
    #expect(disposition.creationDate == nil)
    #expect(disposition.modificationDate == nil)
    #expect(disposition.readDate == nil)
    #expect(disposition.size == nil)

    disposition.fileName = "document.doc"
    disposition.creationDate = ctime
    disposition.modificationDate = mtime
    disposition.readDate = atime
    disposition.size = 37001

    let encoded = try! disposition.toString(format, .utf8, true)
    #expect(encoded == expected)

    let parsed = try! ContentDisposition(parsing:String(encoded.dropFirst("Content-Disposition:".count)))
    #expect(parsed.fileName == "document.doc")
    #expect(parsed.creationDate == ctime)
    #expect(parsed.modificationDate == mtime)
    #expect(parsed.readDate == atime)
    #expect(parsed.size == 37001)

    parsed.creationDate = nil
    #expect(parsed.parameters.parameter(named: "creation-date") == nil)

    parsed.modificationDate = nil
    #expect(parsed.parameters.parameter(named: "modification-date") == nil)

    parsed.readDate = nil
    #expect(parsed.parameters.parameter(named: "read-date") == nil)

    parsed.fileName = nil
    #expect(parsed.parameters.parameter(named: "filename") == nil)

    parsed.size = nil
    #expect(parsed.parameters.parameter(named: "size") == nil)

    parsed.isAttachment = false
    #expect(parsed.disposition == ContentDisposition.inline)
    #expect(parsed.isAttachment == false)
}

@Test("ContentDisposition toString")
func contentDispositionToString() {
    let expected = "Content-Disposition: attachment; filename=\"filename.txt\"; creation-date=\"Fri, 09 Sep 2022 07:41:23 -0400\"; modification-date=\"Fri, 09 Sep 2022 07:41:23 -0400\"; size=\"2048\""
    let timestamp = DateTimeOffset(year: 2022, month: 9, day: 9, hour: 7, minute: 41, second: 23, offsetMinutes: -240)!
    let disposition = try! ContentDisposition()
    try? disposition.setDisposition(ContentDisposition.attachment)
    disposition.fileName = "filename.txt"
    disposition.creationDate = timestamp
    disposition.modificationDate = timestamp
    disposition.size = 2048

    let value = disposition.toString()
    #expect(value == expected)

    let value2 = try! disposition.toString(.utf8, false)
    #expect(value2 == expected)
}
