//
// CharsetUtilsTests.swift
//

import Testing
@testable import MimeFoundation

@Test("CharsetUtils unsupported encodings")
func charsetUtilsUnsupportedEncodings() {
    #expect(CharsetUtils.getEncoding("x-undefined") == nil)
}

@Test("CharsetUtils parse code page")
func charsetUtilsParseCodePage() {
    #expect(CharsetUtils.parseCodePage("iso10646") == 1201)
    #expect(CharsetUtils.parseCodePage("iso-10646") == 1201)
    #expect(CharsetUtils.parseCodePage("iso10646-1") == 1201)
    #expect(CharsetUtils.parseCodePage("iso-10646-1") == 1201)

    #expect(CharsetUtils.parseCodePage("iso8859-1") == 28591)
    #expect(CharsetUtils.parseCodePage("iso8859_1") == 28591)
    #expect(CharsetUtils.parseCodePage("iso-8859-1") == 28591)
    #expect(CharsetUtils.parseCodePage("iso_8859_1") == 28591)
    #expect(CharsetUtils.parseCodePage("latin1") == 28591)

    #expect(CharsetUtils.parseCodePage("iso2022-jp") == 50220)
    #expect(CharsetUtils.parseCodePage("iso-2022-jp") == 50220)
    #expect(CharsetUtils.parseCodePage("iso_2022_jp") == 50220)
    #expect(CharsetUtils.parseCodePage("iso2022-kr") == 50225)
    #expect(CharsetUtils.parseCodePage("iso-2022-kr") == 50225)
    #expect(CharsetUtils.parseCodePage("iso_2022_kr") == 50225)

    #expect(CharsetUtils.parseCodePage("windows-cp1252") == 1252)
    #expect(CharsetUtils.parseCodePage("windows-1252") == 1252)
    #expect(CharsetUtils.parseCodePage("cp-1252") == 1252)
    #expect(CharsetUtils.parseCodePage("cp1252") == 1252)

    #expect(CharsetUtils.parseCodePage("cp") == -1)
    #expect(CharsetUtils.parseCodePage("iso") == -1)
    #expect(CharsetUtils.parseCodePage("ibm") == -1)
    #expect(CharsetUtils.parseCodePage("windows") == -1)
    #expect(CharsetUtils.parseCodePage("windows-") == -1)

    #expect(CharsetUtils.parseCodePage("iso-8859") == -1)
    #expect(CharsetUtils.parseCodePage("iso-BB59") == -1)
    #expect(CharsetUtils.parseCodePage("iso-8859-") == -1)
    #expect(CharsetUtils.parseCodePage("iso-8859-A") == -1)
    #expect(CharsetUtils.parseCodePage("iso-2022-US") == -1)
    #expect(CharsetUtils.parseCodePage("iso-4999-1") == -1)
    #expect(CharsetUtils.parseCodePage("iso-abcd-1") == -1)
}

@Test("CharsetUtils convert to unicode")
func charsetUtilsConvertToUnicode() throws {
    let expected = "要連両存使破薫聞載線弁明小設幸名代開告覧。胸問中写視映的収掲笛事来更知。会教握話整団負画断問囲士英高枠営言。近着開交識営害新緑提犯趣大第快者一代田。海補間山間府序打面真教義優決位。需著会容同警士趣場社主交干今兆。電増罪合三時株再姿県人生。広暮分昭熊勢戦帯票昨切議読権月期春著。生上呼警上際岡作朝米趙情。"
    var options = ParserOptions.default
    let encoding = CharsetUtils.getEncodingOrDefault(936, fallback: .utf8)
    options.charsetEncoding = encoding
    let input = CharsetUtils.getBytes(expected, encoding: encoding)

    let parsed = CharsetUtils.convertToUnicode(options, input, start: 0, length: input.count)
    #expect(parsed == expected)

    let parsedEncoding = try CharsetUtils.getString(input, start: 0, length: input.count, encoding: encoding)
    #expect(parsedEncoding == expected)
}

@Test("CharsetUtils get mime charset")
func charsetUtilsGetMimeCharset() {
    #expect(CharsetUtils.getMimeCharset("latin1") == "iso-8859-1")
    #expect(CharsetUtils.getMimeCharset(CharsetUtils.latin1) == "iso-8859-1")
    #expect(CharsetUtils.getMimeCharset("gibberish") == "gibberish")

    if let encoding = CharsetUtils.getEncoding(codepage: 932) {
        #expect(CharsetUtils.getMimeCharset(encoding) == "shift_jis")
    }
    if let encoding = CharsetUtils.getEncoding(codepage: 50220) {
        #expect(CharsetUtils.getMimeCharset(encoding) == "iso-2022-jp")
    }
    if let encoding = CharsetUtils.getEncoding(codepage: 50221) {
        #expect(CharsetUtils.getMimeCharset(encoding) == "iso-2022-jp")
    }
    if let encoding = CharsetUtils.getEncoding(codepage: 50222) {
        #expect(CharsetUtils.getMimeCharset(encoding) == "iso-2022-jp")
    }
    if let encoding = CharsetUtils.getEncoding(codepage: 50225) {
        #expect(CharsetUtils.getMimeCharset(encoding) == "euc-kr")
    }
    if let encoding = CharsetUtils.getEncoding(codepage: 949) {
        #expect(CharsetUtils.getMimeCharset(encoding) == "euc-kr")
    }
}
