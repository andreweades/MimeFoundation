//
// Rfc2047Tests.swift
//

import Foundation
import Testing
@testable import SwiftMimeKit

@Test("Rfc2047 decode empty string")
func rfc2047DecodeEmptyString() {
    let empty: [UInt8] = []
    var codepage = 0

    #expect(Rfc2047.decodePhrase(empty) == "")
    #expect(Rfc2047.decodePhrase(empty, startIndex: 0, count: 0) == "")
    #expect(Rfc2047.decodePhrase(ParserOptions.default, empty) == "")
    #expect(Rfc2047.decodePhrase(ParserOptions.default, empty, startIndex: 0, count: 0) == "")
    _ = Rfc2047.decodePhrase(ParserOptions.default, empty, startIndex: 0, count: 0, codepage: &codepage)
    #expect(codepage != 0)

    #expect(Rfc2047.decodeText(empty) == "")
    #expect(Rfc2047.decodeText(empty, startIndex: 0, count: 0) == "")
    #expect(Rfc2047.decodeText(ParserOptions.default, empty) == "")
    #expect(Rfc2047.decodeText(ParserOptions.default, empty, startIndex: 0, count: 0) == "")
    _ = Rfc2047.decodeText(ParserOptions.default, empty, startIndex: 0, count: 0, codepage: &codepage)
    #expect(codepage != 0)
}

@Test("Rfc2047 decode encoded word empty charset")
func rfc2047DecodeEncodedWordEmptyCharset() {
    let text = "blurdy bloop =??q?no_charset?= beep boop"
    let buffer = CharsetUtils.getBytes(text, encoding: .utf8)

    #expect(Rfc2047.decodePhrase(buffer) == text)
    #expect(Rfc2047.decodeText(buffer) == text)
}

@Test("Rfc2047 decode encoded word empty charset with lang")
func rfc2047DecodeEncodedWordEmptyCharsetWithLang() {
    let text = "blurdy bloop =?*en?q?no_charset?= beep boop"
    let buffer = CharsetUtils.getBytes(text, encoding: .utf8)

    #expect(Rfc2047.decodePhrase(buffer) == text)
    #expect(Rfc2047.decodeText(buffer) == text)
}

@Test("Rfc2047 decode encoded word with lang")
func rfc2047DecodeEncodedWordWithLang() {
    let text = "blurdy bloop =?iso-8859-1*en?q?this_is_english?= beep boop"
    let expected = "blurdy bloop this is english beep boop"
    let buffer = CharsetUtils.getBytes(text, encoding: .utf8)

    #expect(Rfc2047.decodePhrase(buffer) == expected)
    #expect(Rfc2047.decodeText(buffer) == expected)
}

@Test("Rfc2047 decode encoded word invalid encoding")
func rfc2047DecodeEncodedWordInvalidEncoding() {
    let text = "blurdy bloop =?iso-8859-1?x?invalid_encoding?= beep boop"
    let buffer = CharsetUtils.getBytes(text, encoding: .utf8)

    #expect(Rfc2047.decodePhrase(buffer) == text)
    #expect(Rfc2047.decodeText(buffer) == text)
}

@Test("Rfc2047 decode encoded word invalid multi-character encoding")
func rfc2047DecodeEncodedWordInvalidMultiCharacterEncoding() {
    let text = "blurdy bloop =?iso-8859-1?qb?invalid_encoded_word?= beep boop"
    let buffer = CharsetUtils.getBytes(text, encoding: .utf8)

    #expect(Rfc2047.decodePhrase(buffer) == text)
    #expect(Rfc2047.decodeText(buffer) == text)
}

@Test("Rfc2047 decode encoded word incomplete payload")
func rfc2047DecodeEncodedWordIncompletePayload() {
    let text = "blurdy bloop =?iso-8859-1?q?invalid_encoding"
    let buffer = CharsetUtils.getBytes(text, encoding: .utf8)

    #expect(Rfc2047.decodePhrase(buffer) == text)
    #expect(Rfc2047.decodeText(buffer) == text)
}

@Test("Rfc2047 decode encoded word incomplete charset")
func rfc2047DecodeEncodedWordIncompleteCharset() {
    let text = "blurdy bloop =?iso-8859-1"
    let buffer = CharsetUtils.getBytes(text, encoding: .utf8)

    #expect(Rfc2047.decodePhrase(buffer) == text)
    #expect(Rfc2047.decodeText(buffer) == text)
}

@Test("Rfc2047 decode encoded word invalid charset name")
func rfc2047DecodeEncodedWordInvalidCharsetName() {
    let text = "blurdy bloop =?isö-8859-1?q?invalid_charset_name?= beep boop"
    let buffer = CharsetUtils.getBytes(text, encoding: .utf8)

    #expect(Rfc2047.decodePhrase(buffer) == text)
    #expect(Rfc2047.decodeText(buffer) == text)
}

@Test("Rfc2047 decode encoded word invalid language code")
func rfc2047DecodeEncodedWordInvalidLanguageCode() {
    let text = "blurdy bloop =?iso-8859-1*eñ-US?q?invalid_charset_name?= beep boop"
    let buffer = CharsetUtils.getBytes(text, encoding: .utf8)

    #expect(Rfc2047.decodePhrase(buffer) == text)
    #expect(Rfc2047.decodeText(buffer) == text)
}

@Test("Rfc2047 decode encoded word embedded in another word")
func rfc2047DecodeEncodedWordEmbeddedInAnotherWord() {
    let text = "blurdy bloop=?iso-8859-1?q?_encoded_word_?=beep boop"
    let expected = "blurdy bloop encoded word beep boop"
    let buffer = CharsetUtils.getBytes(text, encoding: .utf8)

    #expect(Rfc2047.decodePhrase(buffer) == expected)
    #expect(Rfc2047.decodeText(buffer) == expected)
}

@Test("Rfc2047 decode multiple encoded words with common codepage")
func rfc2047DecodeMultipleEncodedWordsWithCommonCodePage() {
    let text = "=?iso-8859-1?q?latin1_?= =?utf-8?q?unicode_?= =?iso-8859-1?q?and_latin1_again?="
    let expected = "latin1 unicode and latin1 again"
    let buffer = CharsetUtils.getBytes(text, encoding: .utf8)
    var codepage = 0

    let phrase = Rfc2047.decodePhrase(ParserOptions.default, buffer, startIndex: 0, count: buffer.count, codepage: &codepage)
    #expect(phrase == expected)
    #expect(codepage == 28591)

    let decoded = Rfc2047.decodeText(ParserOptions.default, buffer, startIndex: 0, count: buffer.count, codepage: &codepage)
    #expect(decoded == expected)
    #expect(codepage == 28591)
}

@Test("Rfc2047 decode multiple encoded words without common codepage")
func rfc2047DecodeMultipleEncodedWordsWithoutCommonCodePage() {
    let text = "=?iso-8859-1?q?latin1_?= =?iso-8859-2?q?latin2_?= =?iso-8859-3?q?latin3?="
    let expected = "latin1 latin2 latin3"
    let buffer = CharsetUtils.getBytes(text, encoding: .utf8)
    var codepage = 0

    let phrase = Rfc2047.decodePhrase(ParserOptions.default, buffer, startIndex: 0, count: buffer.count, codepage: &codepage)
    #expect(phrase == expected)
    #expect(codepage == 28591)

    let decoded = Rfc2047.decodeText(ParserOptions.default, buffer, startIndex: 0, count: buffer.count, codepage: &codepage)
    #expect(decoded == expected)
    #expect(codepage == 28591)
}

@Test("Rfc2047 decode ensures codepage capacity")
func rfc2047DecodeEnsuresCodepageCapacity() {
    let text = "=?us-ascii?q?0?= =?iso-8859-1?q?1?= =?iso-8859-2?q?2?= =?iso-8859-3?q?3?= =?iso-8859-4?q?4?= =?iso-8859-5?q?5?= =?iso-8859-6?q?6?= =?iso-8859-7?q?7?= =?iso-8859-8?q?8?= =?iso-8859-9?q?9?= =?koi8-r?q?a?= =?koi8-u?q?b?= =?big5?q?c?= =?euc-cn?q?d?= =?euc-kr?q?e?= =?utf-8?q?f?= =?gb2312?q?g?="
    let expected = "0123456789abcdefg"
    let buffer = CharsetUtils.getBytes(text, encoding: .utf8)
    var codepage = 0

    let phrase = Rfc2047.decodePhrase(ParserOptions.default, buffer, startIndex: 0, count: buffer.count, codepage: &codepage)
    #expect(phrase == expected)
    #expect(codepage == 20127)

    let decoded = Rfc2047.decodeText(ParserOptions.default, buffer, startIndex: 0, count: buffer.count, codepage: &codepage)
    #expect(decoded == expected)
    #expect(codepage == 20127)
}

@Test("Rfc2047 encode controls")
func rfc2047EncodeControls() {
    let expected = "I'm so happy! =?utf-8?q?=07?= I love MIME so much =?utf-8?q?=07=07!?= Isn't it great?"
    let text = "I'm so happy! \u{0007} I love MIME so much \u{0007}\u{0007}! Isn't it great?"

    let encodedPhrase = String(bytes: Rfc2047.encodePhrase(.utf8, text), encoding: .ascii)
    #expect(encodedPhrase == expected)

    let encodedPhraseRange = String(bytes: Rfc2047.encodePhrase(.utf8, text, startIndex: 0, count: text.count), encoding: .ascii)
    #expect(encodedPhraseRange == expected)

    let encodedText = String(bytes: Rfc2047.encodeText(.utf8, text), encoding: .ascii)
    #expect(encodedText == expected)

    let encodedTextRange = String(bytes: Rfc2047.encodeText(.utf8, text, startIndex: 0, count: text.count), encoding: .ascii)
    #expect(encodedTextRange == expected)
}

@Test("Rfc2047 encode surrogate pair")
func rfc2047EncodeSurrogatePair() {
    let expected = "I'm so happy! =?utf-8?b?8J+YgA==?= I love MIME so much =?utf-8?b?4p2k77iP4oCN8J+UpSE=?= Isn't it great?"
    let text = "I'm so happy! 😀 I love MIME so much ❤️‍🔥! Isn't it great?"

    let encodedPhrase = String(bytes: Rfc2047.encodePhrase(.utf8, text), encoding: .ascii)
    #expect(encodedPhrase == expected)

    let encodedPhraseRange = String(bytes: Rfc2047.encodePhrase(.utf8, text, startIndex: 0, count: text.count), encoding: .ascii)
    #expect(encodedPhraseRange == expected)

    let encodedText = String(bytes: Rfc2047.encodeText(.utf8, text), encoding: .ascii)
    #expect(encodedText == expected)

    let encodedTextRange = String(bytes: Rfc2047.encodeText(.utf8, text, startIndex: 0, count: text.count), encoding: .ascii)
    #expect(encodedTextRange == expected)
}

@Test("Rfc2047 encode wrong charset")
func rfc2047EncodeWrongCharset() {
    let expected = "I'm so happy! =?utf-8?b?5ZCN44GM44OJ44Oh44Kk44Oz?= I love MIME so much =?utf-8?b?4p2k77iP4oCN8J+UpSE=?= Isn't it great?"
    let text = "I'm so happy! 名がドメイン I love MIME so much ❤️‍🔥! Isn't it great?"

    let encodedPhrase = String(bytes: Rfc2047.encodePhrase(.utf8, text), encoding: .ascii)
    #expect(encodedPhrase == expected)

    let encodedPhraseRange = String(bytes: Rfc2047.encodePhrase(.utf8, text, startIndex: 0, count: text.count), encoding: .ascii)
    #expect(encodedPhraseRange == expected)

    let encodedText = String(bytes: Rfc2047.encodeText(.utf8, text), encoding: .ascii)
    #expect(encodedText == expected)

    let encodedTextRange = String(bytes: Rfc2047.encodeText(.utf8, text, startIndex: 0, count: text.count), encoding: .ascii)
    #expect(encodedTextRange == expected)
}

@Test("Rfc2047 encode phrase long sentence with commas")
func rfc2047EncodePhraseLongSentenceWithCommas() {
    let expected = "\"Once upon a time, back when things that are old now were new, there lived a man with a very particular set of skills.\""
    let text = "Once upon a time, back when things that are old now were new, there lived a man with a very particular set of skills."

    let encoded = String(bytes: Rfc2047.encodePhrase(.utf8, text), encoding: .ascii)
    #expect(encoded == expected)

    guard let encoded = encoded else { return }
    let unquoted = MimeUtils.unquote(encoded)
    #expect(unquoted == text)
}

@Test("Rfc2047 encode phrase with inner quoted string")
func rfc2047EncodePhraseWithInnerQuotedString() {
    let expected = "\"John \\\"Jacob Jingle Heimer\\\" Schmidt\""
    let text = "John \"Jacob Jingle Heimer\" Schmidt"

    let encoded = String(bytes: Rfc2047.encodePhrase(.utf8, text), encoding: .ascii)
    #expect(encoded == expected)

    guard let encoded = encoded else { return }
    let unquoted = MimeUtils.unquote(encoded)
    #expect(unquoted == text)
}

@Test("Rfc2047 encode phrase with inner unicode quoted string 1")
func rfc2047EncodePhraseWithInnerUnicodeQuotedString1() {
    let expected = "John =?utf-8?b?Ium7nueci0DlkI3jgYzjg4njg6HjgqTjg7MgSmFjb2IgSmluZ2xlIEhlaW1lciI=?= Schmidt"
    let text = "John \"點看@名がドメイン Jacob Jingle Heimer\" Schmidt"

    let encoded = String(bytes: Rfc2047.encodePhrase(.utf8, text), encoding: .ascii)
    #expect(encoded == expected)

    guard let encoded = encoded else { return }
    let decoded = Rfc2047.decodePhrase(CharsetUtils.getBytes(encoded, encoding: .ascii))
    #expect(decoded == text)
}

@Test("Rfc2047 encode phrase with inner unicode quoted string 2")
func rfc2047EncodePhraseWithInnerUnicodeQuotedString2() {
    let expected = "John =?utf-8?b?IkphY29iIEppbmdsZSDpu57nnItA5ZCN44GM44OJ44Oh44Kk44OzIEhlaW1lciI=?= Schmidt"
    let text = "John \"Jacob Jingle 點看@名がドメイン Heimer\" Schmidt"

    let encoded = String(bytes: Rfc2047.encodePhrase(.utf8, text), encoding: .ascii)
    #expect(encoded == expected)

    guard let encoded = encoded else { return }
    let decoded = Rfc2047.decodePhrase(CharsetUtils.getBytes(encoded, encoding: .ascii))
    #expect(decoded == text)
}

@Test("Rfc2047 encode phrase with inner unicode quoted string 3")
func rfc2047EncodePhraseWithInnerUnicodeQuotedString3() {
    let expected = "John =?utf-8?b?IkphY29iIEppbmdsZSBIZWltZXIg6bue55yLQOWQjeOBjOODieODoeOCpOODsyI=?= Schmidt"
    let text = "John \"Jacob Jingle Heimer 點看@名がドメイン\" Schmidt"

    let encoded = String(bytes: Rfc2047.encodePhrase(.utf8, text), encoding: .ascii)
    #expect(encoded == expected)

    guard let encoded = encoded else { return }
    let decoded = Rfc2047.decodePhrase(CharsetUtils.getBytes(encoded, encoding: .ascii))
    #expect(decoded == text)
}

@Test("Rfc2047 encode phrase with inner unicode quoted string 4")
func rfc2047EncodePhraseWithInnerUnicodeQuotedString4() {
    let expected = "John =?utf-8?q?=22Jacob_Jingle_Heimer=2C_his_name_is_my_name_too!_Whenever_he_goes_out=2C_the_?=\t=?utf-8?q?people_always_shout=2C_=5C=22There_goes_John_Jacob_Jingle_Heimer_Schmidt!=5C=22_?=\t=?utf-8?b?6bue55yLQOWQjeOBjOODieODoeOCpOODsyI=?= Schmidt"
    let text = "John \"Jacob Jingle Heimer, his name is my name too! Whenever he goes out, the people always shout, \\\"There goes John Jacob Jingle Heimer Schmidt!\\\" 點看@名がドメイン\" Schmidt"

    let encoded = String(bytes: Rfc2047.encodePhrase(.utf8, text), encoding: .ascii)
    #expect(encoded == expected)

    guard let encoded = encoded else { return }
    let decoded = Rfc2047.decodePhrase(CharsetUtils.getBytes(encoded, encoding: .ascii))
    #expect(decoded == text)
}

@Test("Rfc2047 encode phrase with inner unicode quoted string 5")
func rfc2047EncodePhraseWithInnerUnicodeQuotedString5() {
    let expected = "\"John \\\"Whenever he goes out, the people always shout, \\\\\\\"There goes John Jacob Jingle Heimer Schmidt!\\\\\\\"\\\" Schmidt\""
    let text = "John \"Whenever he goes out, the people always shout, \\\"There goes John Jacob Jingle Heimer Schmidt!\\\"\" Schmidt"

    let encoded = String(bytes: Rfc2047.encodePhrase(.utf8, text), encoding: .ascii)
    #expect(encoded == expected)

    guard let encoded = encoded else { return }
    let unquoted = MimeUtils.unquote(encoded)
    #expect(unquoted == text)
}

@Test("Rfc2047 encode phrase with inner unicode comment")
func rfc2047EncodePhraseWithInnerUnicodeComment() {
    let expected = "\"John (Jacob Jingle Heimer) Schmidt\""
    let text = "John (Jacob Jingle Heimer) Schmidt"

    let encoded = String(bytes: Rfc2047.encodePhrase(.utf8, text), encoding: .ascii)
    #expect(encoded == expected)

    guard let encoded = encoded else { return }
    let unquoted = MimeUtils.unquote(encoded)
    #expect(unquoted == text)
}

@Test("Rfc2047 encode phrase with inner unicode comment 1")
func rfc2047EncodePhraseWithInnerUnicodeComment1() {
    let expected = "John =?utf-8?b?KOm7nueci0DlkI3jgYzjg4njg6HjgqTjg7MgSmFjb2IgSmluZ2xlIEhlaW1lcik=?= Schmidt"
    let text = "John (點看@名がドメイン Jacob Jingle Heimer) Schmidt"

    let encoded = String(bytes: Rfc2047.encodePhrase(.utf8, text), encoding: .ascii)
    #expect(encoded == expected)

    guard let encoded = encoded else { return }
    let decoded = Rfc2047.decodePhrase(CharsetUtils.getBytes(encoded, encoding: .ascii))
    #expect(decoded == text)
}

@Test("Rfc2047 encode phrase with inner unicode comment 2")
func rfc2047EncodePhraseWithInnerUnicodeComment2() {
    let expected = "John =?utf-8?b?KEphY29iIEppbmdsZSDpu57nnItA5ZCN44GM44OJ44Oh44Kk44OzIEhlaW1lcik=?= Schmidt"
    let text = "John (Jacob Jingle 點看@名がドメイン Heimer) Schmidt"

    let encoded = String(bytes: Rfc2047.encodePhrase(.utf8, text), encoding: .ascii)
    #expect(encoded == expected)

    guard let encoded = encoded else { return }
    let decoded = Rfc2047.decodePhrase(CharsetUtils.getBytes(encoded, encoding: .ascii))
    #expect(decoded == text)
}

@Test("Rfc2047 encode phrase with inner unicode comment 3")
func rfc2047EncodePhraseWithInnerUnicodeComment3() {
    let expected = "John =?utf-8?b?KEphY29iIEppbmdsZSBIZWltZXIg6bue55yLQOWQjeOBjOODieODoeOCpOODsyk=?= Schmidt"
    let text = "John (Jacob Jingle Heimer 點看@名がドメイン) Schmidt"

    let encoded = String(bytes: Rfc2047.encodePhrase(.utf8, text), encoding: .ascii)
    #expect(encoded == expected)

    guard let encoded = encoded else { return }
    let decoded = Rfc2047.decodePhrase(CharsetUtils.getBytes(encoded, encoding: .ascii))
    #expect(decoded == text)
}

@Test("Rfc2047 encode phrase with inner unicode comment 4")
func rfc2047EncodePhraseWithInnerUnicodeComment4() {
    let expected = "John =?utf-8?q?=28Jacob_Jingle_Heimer=2C_his_name_is_my_name_too!_Whenever_he_goes_out=2C_the_p?=\t=?utf-8?q?eople_always_shout=2C_=22There_goes_John_Jacob_Jingle_Heimer_Schmidt!=22?=\t=?utf-8?b?IOm7nueci0DlkI3jgYzjg4njg6HjgqTjg7Mp?= Schmidt"
    let text = "John (Jacob Jingle Heimer, his name is my name too! Whenever he goes out, the people always shout, \"There goes John Jacob Jingle Heimer Schmidt!\" 點看@名がドメイン) Schmidt"

    let encoded = String(bytes: Rfc2047.encodePhrase(.utf8, text), encoding: .ascii)
    #expect(encoded == expected)

    guard let encoded = encoded else { return }
    let decoded = Rfc2047.decodePhrase(CharsetUtils.getBytes(encoded, encoding: .ascii))
    #expect(decoded == text)
}

@Test("Rfc2047 fold multi-line header value")
func rfc2047FoldMultiLineHeaderValue() {
    let expected = " This is a multi-line\r\n header value.\r\n"
    let text = "This is a multi-line\r\nheader value."
    var options = FormatOptions.default
    options.newLineFormat = .dos

    let result = String(bytes: Rfc2047.foldUnstructuredHeader(options, "Subject", CharsetUtils.getBytes(text, encoding: .ascii)), encoding: .ascii)
    #expect(result == expected)
}

@Test("Rfc2047 fold pre-folded header value")
func rfc2047FoldPreFoldedHeaderValue() {
    let expected = " This is a pre\r\n folded header value.\r\n"
    let text = "This is a pre\r\n folded header value."
    var options = FormatOptions.default
    options.newLineFormat = .dos

    let result = String(bytes: Rfc2047.foldUnstructuredHeader(options, "Subject", CharsetUtils.getBytes(text, encoding: .ascii)), encoding: .ascii)
    #expect(result == expected)
}

@Test("Rfc2047 fold really long word token")
func rfc2047FoldReallyLongWordToken() {
    let expected = " This header value has a\r\n really-really-really-really-long-rfc0822-word-token-that-exceeds-the-max-allo\r\n wable-line-length-and-must-be-folded lets see what MimeKit does...\r\n"
    let text = "This header value has a really-really-really-really-long-rfc0822-word-token-that-exceeds-the-max-allowable-line-length-and-must-be-folded lets see what MimeKit does..."
    var options = FormatOptions.default
    options.newLineFormat = .dos

    let result = String(bytes: Rfc2047.foldUnstructuredHeader(options, "Subject", CharsetUtils.getBytes(text, encoding: .ascii)), encoding: .ascii)
    #expect(result == expected)
}

@Test("Rfc2047 fold header value with encoded words including language codes")
func rfc2047FoldHeaderValueWithEncodedWordsIncludingLanguageCodes() {
    let expected = " I'm so happy! =?utf-8*en-US?b?8J+YgA==?= I love MIME so much\r\n =?utf-8*en-US?b?4p2k77iP4oCN8J+UpSE=?= Isn't it great?\r\n"
    let text = "I'm so happy! =?utf-8*en-US?b?8J+YgA==?= I love MIME so much =?utf-8*en-US?b?4p2k77iP4oCN8J+UpSE=?= Isn't it great?"
    var options = FormatOptions.default
    options.newLineFormat = .dos

    let result = String(bytes: Rfc2047.foldUnstructuredHeader(options, "Subject", CharsetUtils.getBytes(text, encoding: .ascii)), encoding: .ascii)
    #expect(result == expected)
}

@Test("Rfc2047 fold header value at tabs")
func rfc2047FoldHeaderValueAtTabs() {
    let expected = " I'm so happy! =?utf-8*en-US?b?8J+YgA==?= I love MIME so much\r\n\t=?utf-8*en-US?b?4p2k77iP4oCN8J+UpSE=?= Isn't it great? MIME is\r\n\tsupercalafragalisticexpialadotious, don't you think?\r\n"
    let text = "I'm so happy! =?utf-8*en-US?b?8J+YgA==?= I love MIME so much\t=?utf-8*en-US?b?4p2k77iP4oCN8J+UpSE=?= Isn't it great? MIME is\tsupercalafragalisticexpialadotious, don't you think?"
    var options = FormatOptions.default
    options.newLineFormat = .dos

    let result = String(bytes: Rfc2047.foldUnstructuredHeader(options, "Subject", CharsetUtils.getBytes(text, encoding: .ascii)), encoding: .ascii)
    #expect(result == expected)
}

@Test("Rfc2047 fold header value with embedded encoded word tokens")
func rfc2047FoldHeaderValueWithEmbeddedEncodedWordTokens() {
    let expected = " This subject has embedded\r\n =?iso-8859-1*en-US?q?rfc2047_encoded_word_tokens?=... How does the folding\r\n logic handle these embedded=?iso-8859-1*en-US?q?rfc2047_encoded_word_tokens?=\r\n ...?\r\n"
    let text = "This subject has embedded=?iso-8859-1*en-US?q?rfc2047_encoded_word_tokens?=... How does the folding logic handle these embedded=?iso-8859-1*en-US?q?rfc2047_encoded_word_tokens?=...?"
    var options = FormatOptions.default
    options.newLineFormat = .dos

    let result = String(bytes: Rfc2047.foldUnstructuredHeader(options, "Subject", CharsetUtils.getBytes(text, encoding: .ascii)), encoding: .ascii)
    #expect(result == expected)
}

@Test("Rfc2047 fold header value does not ignore whitespace between encoded words")
func rfc2047FoldHeaderValueDoesNotIgnoreWhitespaceBetweenEncodedWords() {
    let expected = " This test should demonstrate that\r\n =?iso-8859-1*en-US?q?whitespace_between_rfc2047_encoded_word_tokens?= \t \t \r\n\t =?iso-8859-1*en-US?q?does_not_get_ignored?=\r\n"
    let text = "This test should demonstrate that =?iso-8859-1*en-US?q?whitespace_between_rfc2047_encoded_word_tokens?= \t \t \t =?iso-8859-1*en-US?q?does_not_get_ignored?="
    var options = FormatOptions.default
    options.newLineFormat = .dos

    let result = String(bytes: Rfc2047.foldUnstructuredHeader(options, "Subject", CharsetUtils.getBytes(text, encoding: .ascii)), encoding: .ascii)
    #expect(result == expected)
}
