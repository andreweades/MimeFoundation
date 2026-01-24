//
// AssortedTests.swift
//

import Foundation
import Testing
@testable import MimeFoundation

@Test("Assorted: parsing obsolete In-Reply-To syntax")
func assortedParsingObsoleteInReplyToSyntax() {
    let obsolete = "Joe Sixpack's message sent on Mon, 17 Jan 1994 11:14:55 -0500 <some.message.id.1@some.domain>"
    let msgId = MimeUtils.enumerateReferences(obsolete).first
    #expect(msgId == "some.message.id.1@some.domain")

    let obsolete2 = "<some.message.id.2@some.domain> as sent on Mon, 17 Jan 1994 11:14:55 -0500"
    let msgId2 = MimeUtils.enumerateReferences(obsolete2).first
    #expect(msgId2 == "some.message.id.2@some.domain")
}

@Test("Assorted: simple RFC2047 Q encoded phrase")
func assortedSimpleRfc2047QEncodedPhrase() {
    let input = "=?iso-8859-1?q?hola?="
    var options = ParserOptions.default
    options.rfc2047ComplianceMode = .strict
    let strict = Rfc2047.decodePhrase(options, CharsetUtils.getBytes(input, encoding: .ascii))
    #expect(strict == "hola")

    options.rfc2047ComplianceMode = .loose
    let loose = Rfc2047.decodePhrase(options, CharsetUtils.getBytes(input, encoding: .ascii))
    #expect(loose == "hola")
}

@Test("Assorted: simple RFC2047 B encoded phrase")
func assortedSimpleRfc2047BEncodedPhrase() {
    let input = "=?iso-8859-1?B?aG9sYQ==?="
    var options = ParserOptions.default
    options.rfc2047ComplianceMode = .strict
    let strict = Rfc2047.decodePhrase(options, CharsetUtils.getBytes(input, encoding: .ascii))
    #expect(strict == "hola")

    options.rfc2047ComplianceMode = .loose
    let loose = Rfc2047.decodePhrase(options, CharsetUtils.getBytes(input, encoding: .ascii))
    #expect(loose == "hola")
}

@Test("Assorted: simple RFC2047 Q encoded text")
func assortedSimpleRfc2047QEncodedText() {
    let input = "=?iso-8859-1?q?hola?="
    var options = ParserOptions.default
    options.rfc2047ComplianceMode = .strict
    let strict = Rfc2047.decodeText(options, CharsetUtils.getBytes(input, encoding: .ascii))
    #expect(strict == "hola")

    options.rfc2047ComplianceMode = .loose
    let loose = Rfc2047.decodeText(options, CharsetUtils.getBytes(input, encoding: .ascii))
    #expect(loose == "hola")
}

@Test("Assorted: simple RFC2047 B encoded text")
func assortedSimpleRfc2047BEncodedText() {
    let input = "=?iso-8859-1?B?aG9sYQ==?="
    var options = ParserOptions.default
    options.rfc2047ComplianceMode = .strict
    let strict = Rfc2047.decodeText(options, CharsetUtils.getBytes(input, encoding: .ascii))
    #expect(strict == "hola")

    options.rfc2047ComplianceMode = .loose
    let loose = Rfc2047.decodeText(options, CharsetUtils.getBytes(input, encoding: .ascii))
    #expect(loose == "hola")
}

@Test("Assorted: RFC2047 decode invalid multibyte break")
func assortedRfc2047DecodeInvalidMultibyteBreak() {
    let japanese = "狂ったこの世で狂うなら気は確かだ。"
    let utf8 = Array(japanese.utf8)

    for wordBreak in (utf8.count / 2 - 5)..<(utf8.count / 2 + 5) {
        let left = Data(utf8[0..<wordBreak]).base64EncodedString()
        let right = Data(utf8[wordBreak..<utf8.count]).base64EncodedString()
        let combined = "=?utf-8?b?\(left)?= =?utf-8?b?\(right)?="
        let decoded = Rfc2047.decodeText(CharsetUtils.getBytes(combined, encoding: .ascii))
        #expect(decoded == japanese)
    }
}

@Test("Assorted: RFC2047 decode invalid payload break")
func assortedRfc2047DecodeInvalidPayloadBreak() {
    let japanese = "狂ったこの世で狂うなら気は確かだ。"
    let utf8 = Array(japanese.utf8)
    let base64 = Data(utf8).base64EncodedString()

    let left = String(base64.prefix(base64.count - 6))
    let right = String(base64.suffix(6))
    let combined = "=?utf-8?b?\(left)?= =?utf-8?b?\(right)?="

    let decoded = Rfc2047.decodeText(CharsetUtils.getBytes(combined, encoding: .ascii))
    #expect(decoded == japanese)
}

@Test("Assorted: decode invalid charset")
func assortedDecodeInvalidCharset() {
    let xunknown = "=?x-unknown?B?aG9sYQ==?="
    let cp1260 = "=?cp1260?B?aG9sYQ==?="

    let decodedUnknown = Rfc2047.decodeText(CharsetUtils.getBytes(xunknown, encoding: .ascii))
    #expect(decodedUnknown == "hola")

    let decodedCp = Rfc2047.decodeText(CharsetUtils.getBytes(cp1260, encoding: .ascii))
    #expect(decodedCp == "hola")
}

@Test("Assorted: invalid message-id variants")
func assortedInvalidMessageIds() {
    let doubleDomain = MimeUtils.enumerateReferences("<local-part@domain1@domain2>").first
    #expect(doubleDomain == "local-part@domain1@domain2")

    let atNoDomain = MimeUtils.enumerateReferences("<local-part@>").first
    #expect(atNoDomain == "local-part@")

    let noDomain = MimeUtils.enumerateReferences("<local-part>").first
    #expect(noDomain == "local-part")
}

@Test("Assorted: CharsetUtils getCodePage")
func assortedCharsetUtilsGetCodePage() {
    for i in 1...15 {
        let expected: Int
        switch i {
        case 11:
            expected = 874
        case 10, 12, 14:
            expected = -1
        default:
            expected = 28590 + i
        }

        let name = "iso-8859-\(i)"
        let codepage = CharsetUtils.getCodePage(name)
        #expect(codepage == expected)
    }

    for i in 0..<10 {
        let expected = (i < 9) ? (1250 + i) : -1

        let name = "windows-125\(i)"
        #expect(CharsetUtils.getCodePage(name) == expected)

        let nameCp = "windows-cp125\(i)"
        #expect(CharsetUtils.getCodePage(nameCp) == expected)

        let nameShort = "cp125\(i)"
        #expect(CharsetUtils.getCodePage(nameShort) == expected)
    }

    let ibmPages = [850, 852, 855, 857, 860, 861, 862, 863]
    for ibm in ibmPages {
        let name = "ibm-\(ibm)"
        #expect(CharsetUtils.getCodePage(name) == ibm)
    }
}
