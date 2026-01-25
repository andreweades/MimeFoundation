//
// HeaderTests.swift
//

import Foundation
import Testing
@testable import MimeFoundation

private func byteArrayToString(_ bytes: [UInt8]) -> String {
    String(decoding: bytes, as: UTF8.self)
}

private func maxLineLength(_ text: String) -> Int {
    var current = 0
    var maxLen = 0
    var index = text.startIndex
    while index < text.endIndex {
        let ch = text[index]
        if ch == "\r" {
            let next = text.index(after: index)
            if next < text.endIndex, text[next] == "\n" {
                index = next
            }
        }
        if ch == "\n" {
            maxLen = max(maxLen, current)
            current = 0
        } else {
            current += 1
        }
        index = text.index(after: index)
    }
    return maxLen
}

private func normalizeNewLines(_ text: String) -> String {
    text.replacingOccurrences(of: "\r\n", with: "\n").replacingOccurrences(of: "\n", with: FormatOptions.default.newLine)
}

@Test("Header validates field name and id")
func headerValidation() {
    #expect(throws: HeaderError.unknownHeaderId) {
        _ = try Header(validating: .unknown, value: "value")
    }

    #expect(throws: HeaderError.emptyFieldName) {
        _ = try Header(validating: "", value: "value")
    }

    #expect(throws: HeaderError.invalidFieldName) {
        _ = try Header(validating: "Illegal:char", value: "value")
    }

    #expect(throws: HeaderError.invalidFieldName) {
        _ = try Header(validating: "测试文本", value: "value")
    }
}

@Test("Header toString preserves field case")
func headerToString() {
    let header = Header(field: "SuBjEcT", value: "This is a subject...")
    #expect(header.toString(.default, encode: false) == "SuBjEcT: This is a subject...")
}

@Test("Header cloning")
func headerClone() {
    let header = Header(.comments, value: "These are some comments.")
    let clone = header.copy()
    #expect(clone.id == header.id)
    #expect(clone.field == header.field)
    #expect(clone.value == header.value)
    #expect(clone.rawField == header.rawField)
    #expect(clone.rawValue == header.rawValue)
}

@Test("Header unfold handles nil")
func headerUnfoldNil() {
    #expect(Header.unfold(nil).isEmpty)
}

@Test("Header raw value ends with newline")
func headerRawValueEndsWithNewline() {
    let header = Header(.subject, value: "Hello")
    let raw = String(decoding: header.rawValue, as: UTF8.self)
    #expect(raw.hasSuffix(FormatOptions.default.newLine))
}

@Test("Header address folding")
func headerAddressFolding() {
    let expected = " Jeffrey Stedfast <jeff@xamarin.com>, \"Jeffrey A. Stedfast\"" + FormatOptions.default.newLine +
        "\t<jeff@xamarin.com>, \"Dr. Gregory House, M.D.\"" + FormatOptions.default.newLine +
        "\t<house@princeton-plainsboro-hospital.com>" + FormatOptions.default.newLine
    let header = Header(field: "To", value: "Jeffrey Stedfast <jeff@xamarin.com>, \"Jeffrey A. Stedfast\" <jeff@xamarin.com>, \"Dr. Gregory House, M.D.\" <house@princeton-plainsboro-hospital.com>")
    let raw = byteArrayToString(header.rawValue)

    #expect(raw.last == "\n")
    #expect(maxLineLength(raw) < FormatOptions.default.maxLineLength)
    #expect(raw == expected)
}

@Test("Header ARC-Authentication-Results folding")
func headerArcAuthenticationResultsFolding() {
    let values = [
        " i=1; lists.example.org;" + FormatOptions.default.newLine + "\tspf=pass smtp.mfrom=jqd@d1.example;" + FormatOptions.default.newLine + "\tdkim=pass (1024 - bit key) header.i=@d1.example; dmarc=pass",
        " i=2; gmail.example;" + FormatOptions.default.newLine + "\tspf=fail smtp.from=jqd@d1.example;" + FormatOptions.default.newLine + "\tdkim=fail (512-bit key) header.i=@example.org; dmarc=fail;" + FormatOptions.default.newLine + "\tarc=pass (as.1.lists.example.org=pass, ams.1.lists.example.org=pass)",
        " i=3; gmail.example;" + FormatOptions.default.newLine + "\tspf=fail smtp.from=jqd@d1.example;" + FormatOptions.default.newLine + "\tdkim=fail (512-bit key) header.i=@example.org; dmarc=fail" + FormatOptions.default.newLine + "\t(this-is-a-really-really-really-long-unbroken-comment-that-will-be-on-a-line-by-itself);" + FormatOptions.default.newLine + "\tarc=pass (as.1.lists.example.org=pass, ams.1.lists.example.org=pass)"
    ]

    let header = Header(field: "ARC-Authentication-Results", value: "")
    for value in values {
        header.setValue(.default, encoding: .ascii, value: value.replacingOccurrences(of: FormatOptions.default.newLine + "\t", with: " ").trimmingCharacters(in: .whitespacesAndNewlines))
        let raw = byteArrayToString(header.rawValue)
        #expect(raw.last == "\n")
        #expect(raw == value + FormatOptions.default.newLine)
    }
}

@Test("Header Message-Id folding")
func headerMessageIdFolding() {
    let id = UUID().uuidString
    let header = Header(field: "Message-Id", value: "<\(id)@princeton-plainsboro-hospital.com>")
    let expected = " " + header.value + FormatOptions.default.newLine
    let raw = byteArrayToString(header.rawValue)
    #expect(raw.last == "\n")
    #expect(raw == expected)
}

@Test("Header subject folding")
func headerSubjectFolding() {
    let expected = " =?utf-8?b?0KLQtdGB0YLQvtCy0YvQuSDQt9Cw0LPQvtC70L7QstC+0Log0L/QuNGB0YzQvNCw?=\n"
    let header = Header(field: "Subject", value: "Тестовый заголовок письма")
    let actual = byteArrayToString(header.rawValue).replacingOccurrences(of: "\r", with: "")
    #expect(actual == expected)
}

@Test("Header received folding")
func headerReceivedFolding() {
    let values = [
        " from thumper.bellcore.com by greenbush.bellcore.com (4.1/4.7)" + FormatOptions.default.newLine + "\tid <AA01648> for nsb; Fri, 29 Nov 91 07:13:33 EST" + FormatOptions.default.newLine,
        " from joyce.cs.su.oz.au by thumper.bellcore.com (4.1/4.7)" + FormatOptions.default.newLine + "\tid <AA11898> for nsb@greenbush; Fri, 29 Nov 91 07:11:57 EST" + FormatOptions.default.newLine,
        " from Messages.8.5.N.CUILIB.3.45.SNAP.NOT.LINKED.greenbush.galaxy.sun4.41" + FormatOptions.default.newLine + "\tvia MS.5.6.greenbush.galaxy.sun4_41; Fri, 12 Jun 1992 13:29:05 -0400 (EDT)" + FormatOptions.default.newLine,
        " from sqhilton.pc.cs.cmu.edu by po3.andrew.cmu.edu (5.54/3.15)" + FormatOptions.default.newLine + "\tid <AA21478> for beatty@cosmos.vlsi.cs.cmu.edu; Wed, 26 Aug 92 22:14:07 EDT" + FormatOptions.default.newLine,
        " from [127.0.0.1] by [127.0.0.1] id <AA21478> with sendmail (v1.8)" + FormatOptions.default.newLine + "\tfor <beatty@cosmos.vlsi.cs.cmu.edu>; Wed, 26 Aug 92 22:14:07 EDT" + FormatOptions.default.newLine,
        " (incomplete comment" + FormatOptions.default.newLine,
        " from (incomplete comment" + FormatOptions.default.newLine,
        " by (incomplete comment" + FormatOptions.default.newLine,
        " via (incomplete comment" + FormatOptions.default.newLine,
        " with (incomplete comment" + FormatOptions.default.newLine,
        " id (incomplete comment" + FormatOptions.default.newLine,
        " for (incomplete comment" + FormatOptions.default.newLine,
        " from thumper.bellcore.com" + FormatOptions.default.newLine + "\tby greenbush.bellcore.com (this is an incomplete comment that is really really long in order to enforce folding..." + FormatOptions.default.newLine
    ]

    let header = Header(field: "Received", value: "")
    for received in values {
        header.setValue(.default, encoding: .ascii, value: received.replacingOccurrences(of: FormatOptions.default.newLine + "\t", with: " ").trimmingCharacters(in: .whitespacesAndNewlines))
        let raw = byteArrayToString(header.rawValue)
        #expect(raw.last == "\n")
        #expect(raw == received)
    }
}

@Test("Header references folding")
func headerReferencesFolding() {
    var expected = " <\(UUID().uuidString)@princeton-plainsboro-hospital.com>"
    for _ in 0..<5 {
        expected += "\(FormatOptions.default.newLine)\t<\(UUID().uuidString)@princeton-plainsboro-hospital.com>"
    }
    expected += FormatOptions.default.newLine
    let header = Header(field: "References", value: expected)
    let raw = byteArrayToString(header.rawValue)
    #expect(raw.last == "\n")
    #expect(raw == expected)
}

@Test("Header DKIM signature folding")
func headerDkimSignatureFolding() {
    let header = Header(field: "DKIM-Signature", value: "v=1; a=rsa-sha256; c=simple/simple; d=maillist.codeproject.com; s=mail; t=1435835767; bh=tiafHSAvEg4GPJlbkR6e7qr1oydTj+ZXs392TcHwwvs=; h=MIME-Version:From:To:Date:Subject:Content-Type:Content-Transfer-Encoding:Message-Id; b=Qtgo0bWwT0H18CxD2+ey8/382791TBNYtZ8VOLlXxxsbw5fab8uEo53o5tPun6kNx4khmJx/yWowvrCOAcMoqgNO7Hb7JB8NR7eNyOvtLKCG34AfDZyHNcTZHR/QnBpRKHssu5w2CQDUAjKnuGKRW95LCMMX3r924dErZOJnGhs=")
    let expected = " v=1; a=rsa-sha256; c=simple/simple;\n\td=maillist.codeproject.com; s=mail; t=1435835767;\n\tbh=tiafHSAvEg4GPJlbkR6e7qr1oydTj+ZXs392TcHwwvs=;\n\th=MIME-Version:From:To:Date:Subject:Content-Type:Content-Transfer-Encoding:\n\tMessage-Id;\n\tb=Qtgo0bWwT0H18CxD2+ey8/382791TBNYtZ8VOLlXxxsbw5fab8uEo53o5tPun6kNx4khmJx/yWo\n\twvrCOAcMoqgNO7Hb7JB8NR7eNyOvtLKCG34AfDZyHNcTZHR/QnBpRKHssu5w2CQDUAjKnuGKRW95L\n\tCMMX3r924dErZOJnGhs=\n".replacingOccurrences(of: "\n", with: FormatOptions.default.newLine)
    let raw = byteArrayToString(header.rawValue)
    #expect(raw == expected)
}

@Test("Header DKIM signature folding with z")
func headerDkimSignatureFoldingWithZ() {
    let header = Header(field: "DKIM-Signature", value: "v=1; a=rsa-sha256; c=simple/simple; d=maillist.codeproject.com; s=mail; t=1435835767; bh=tiafHSAvEg4GPJlbkR6e7qr1oydTj+ZXs392TcHwwvs=; z=MIME-Version|From|To|Date|Subject|Content-Type|Content-Transfer-Encoding|Message-Id; b=Qtgo0bWwT0H18CxD2+ey8/382791TBNYtZ8VOLlXxxsbw5fab8uEo53o5tPun6kNx4khmJx/yWowvrCOAcMoqgNO7Hb7JB8NR7eNyOvtLKCG34AfDZyHNcTZHR/QnBpRKHssu5w2CQDUAjKnuGKRW95LCMMX3r924dErZOJnGhs=")
    let expected = " v=1; a=rsa-sha256; c=simple/simple;\n\td=maillist.codeproject.com; s=mail; t=1435835767;\n\tbh=tiafHSAvEg4GPJlbkR6e7qr1oydTj+ZXs392TcHwwvs=;\n\tz=MIME-Version|From|To|Date|Subject|Content-Type|Content-Transfer-Encoding|\n\tMessage-Id;\n\tb=Qtgo0bWwT0H18CxD2+ey8/382791TBNYtZ8VOLlXxxsbw5fab8uEo53o5tPun6kNx4khmJx/yWo\n\twvrCOAcMoqgNO7Hb7JB8NR7eNyOvtLKCG34AfDZyHNcTZHR/QnBpRKHssu5w2CQDUAjKnuGKRW95L\n\tCMMX3r924dErZOJnGhs=\n".replacingOccurrences(of: "\n", with: FormatOptions.default.newLine)
    let raw = byteArrayToString(header.rawValue)
    #expect(raw == expected)
}

@Test("Header reformat DKIM signature")
func headerReformatDkimSignature() {
    let expected = " v=1; a=rsa-sha256; c=simple/simple;\n\td=maillist.codeproject.com; s=mail; t=1435835767;\n\tbh=tiafHSAvEg4GPJlbkR6e7qr1oydTj+ZXs392TcHwwvs=;\n\th=MIME-Version:From:To:Date:Subject:Content-Type:Content-Transfer-Encoding:\n\tMessage-Id;\n\tb=Qtgo0bWwT0H18CxD2+ey8/382791TBNYtZ8VOLlXxxsbw5fab8uEo53o5tPun6kNx4khmJx/yWo\n\twvrCOAcMoqgNO7Hb7JB8NR7eNyOvtLKCG34AfDZyHNcTZHR/QnBpRKHssu5w2CQDUAjKnuGKRW95L\n\tCMMX3r924dErZOJnGhs=\n"
    var options = FormatOptions.default
    options.newLineFormat = .dos
    options.international = true

    let rawValue = Array(expected.utf8)
    let header = Header(ParserOptions.default, .dkimSignature, "DKIM-Signature", rawValue)
    let result = byteArrayToString(header.getRawValue(options))
    #expect(result == expected)
}

@Test("Header list command encoding")
func headerListCommandEncoding() {
    let cases: [(HeaderId, String, String, String?)] = [
        (.listHelp, "<mailto:list@host.com?subject=help> (List Instructions)", " <mailto:list@host.com?subject=help> (List Instructions)\r\n", nil),
        (.listHelp, "<mailto:list-manager@host.com?body=info>", " <mailto:list-manager@host.com?body=info>\r\n", nil),
        (.listHelp, "<mailto:list-info@host.com> (Info about the list)", " <mailto:list-info@host.com> (Info about the list)\r\n", nil),
        (.listHelp, "<http://www.host.com/list/>, <mailto:list-info@host.com>", " <http://www.host.com/list/>, <mailto:list-info@host.com>\r\n", nil),
        (.listHelp, "<ftp://ftp.host.com/list.txt> (FTP), <mailto:list@host.com?subject=help>", " <ftp://ftp.host.com/list.txt> (FTP),\r\n <mailto:list@host.com?subject=help>\r\n", nil),
        (.listUnsubscribe, "<mailto:list@host.com?subject=unsubscribe>", " <mailto:list@host.com?subject=unsubscribe>\r\n", nil),
        (.listUnsubscribe, "(Use this command to get off the list) <mailto:list-manager@host.com?body=unsubscribe%20list>", " (Use this command to get off the list)\r\n <mailto:list-manager@host.com?body=unsubscribe%20list>\r\n", nil),
        (.listUnsubscribe, "<mailto:list-off@host.com>", " <mailto:list-off@host.com>\r\n", nil),
        (.listUnsubscribe, "<http://www.host.com/list.cgi?cmd=unsub&lst=list>, <mailto:list-request@host.com?subject=unsubscribe>", " <http://www.host.com/list.cgi?cmd=unsub&lst=list>,\r\n <mailto:list-request@host.com?subject=unsubscribe>\r\n", nil),
        (.listSubscribe, "<mailto:list@host.com?subject=subscribe>", " <mailto:list@host.com?subject=subscribe>\r\n", nil),
        (.listSubscribe, "<mailto:list-request@host.com?subject=subscribe>", " <mailto:list-request@host.com?subject=subscribe>\r\n", nil),
        (.listSubscribe, "(Use this command to join the list) <mailto:list-manager@host.com?body=subscribe%20list>", " (Use this command to join the list)\r\n <mailto:list-manager@host.com?body=subscribe%20list>\r\n", nil),
        (.listSubscribe, "<mailto:list-on@host.com>", " <mailto:list-on@host.com>\r\n", nil),
        (.listSubscribe, "<http://www.host.com/list.cgi?cmd=sub&lst=list>, <mailto:list-manager@host.com?body=subscribe%20list>", " <http://www.host.com/list.cgi?cmd=sub&lst=list>,\r\n <mailto:list-manager@host.com?body=subscribe%20list>\r\n", nil),
        (.listPost, "<mailto:list@host.com>", " <mailto:list@host.com>\r\n", nil),
        (.listPost, "<mailto:moderator@host.com> (Postings are Moderated)", " <mailto:moderator@host.com> (Postings are Moderated)\r\n", nil),
        (.listPost, "<mailto:moderator@host.com?subject=list%20posting>", " <mailto:moderator@host.com?subject=list%20posting>\r\n", nil),
        (.listPost, "NO (posting not allowed on this list)", " NO (posting not allowed on this list)\r\n", nil),
        (.listOwner, "<mailto:listmom@host.com> (Contact Person for Help)", " <mailto:listmom@host.com> (Contact Person for Help)\r\n", nil),
        (.listOwner, "<mailto:grant@foo.bar> (Grant Neufeld)", " <mailto:grant@foo.bar> (Grant Neufeld)\r\n", nil),
        (.listOwner, "<mailto:josh@foo.bar?Subject=list>", " <mailto:josh@foo.bar?Subject=list>\r\n", nil),
        (.listArchive, "<mailto:archive@host.com?subject=index%20list>", " <mailto:archive@host.com?subject=index%20list>\r\n", nil),
        (.listArchive, "<ftp://ftp.host.com/pub/list/archive/>", " <ftp://ftp.host.com/pub/list/archive/>\r\n", nil),
        (.listArchive, "<http://www.host.com/list/archive/> (Web Archive)", " <http://www.host.com/list/archive/> (Web Archive)\r\n", nil),
        (.listHelp, "<mailto:list@host.com?subject=help> (목록 지침)", " <mailto:list@host.com?subject=help>\r\n (=?utf-8?b?66qp66GdIOyngOy5qA==?=)\r\n", " <mailto:list@host.com?subject=help> (목록 지침)\r\n"),
        (.listUnsubscribe, "(이 명령을 사용하여 목록에서 구독을 취소합니다.) <mailto:list-manager@host.com?body=unsubscribe%20list>", "\r\n (=?utf-8?b?7J20IOuqheugueydhCDsgqzsmqntlZjsl6wg66qp66Gd7JeQ7ISc?=\r\n =?utf-8?b?IOq1rOuPheydhCDst6jshoztlanri4jri6Qu?=)\r\n <mailto:list-manager@host.com?body=unsubscribe%20list>\r\n", " (이 명령을 사용하여 목록에서 구독을 취소합니다.)\r\n <mailto:list-manager@host.com?body=unsubscribe%20list>\r\n"),
        (.listSubscribe, "(이 명령을 사용하여 목록에 조인합니다.) <mailto:list-manager@host.com?body=subscribe%20list>", " (=?utf-8?b?7J20IOuqheugueydhCDsgqzsmqntlZjsl6wg66qp66Gd7JeQ?=\r\n =?utf-8?b?IOyhsOyduO2VqeuLiOuLpC4=?=)\r\n <mailto:list-manager@host.com?body=subscribe%20list>\r\n", " (이 명령을 사용하여 목록에 조인합니다.)\r\n <mailto:list-manager@host.com?body=subscribe%20list>\r\n"),
        (.listPost, "NO (이 목록에 게시가 허용되지 않음)", " NO\r\n (=?utf-8?b?7J20IOuqqeuhneyXkCDqsozsi5zqsIAg7ZeI7Jqp65CY7KeAIOyViuydjA==?=)\r\n", " NO (이 목록에 게시가 허용되지 않음)\r\n"),
        (.listPost, "(This long comment should force the 'NO' token onto the next line) NO <mailto:list-manager@host.com>", " (This long comment should force the 'NO' token onto the next line)\r\n NO <mailto:list-manager@host.com>\r\n", " (This long comment should force the 'NO' token onto the next line)\r\n NO <mailto:list-manager@host.com>\r\n"),
        (.listHelp, "This is a super-califragilistic-expialidociously-looooooooooooooooooooooooong-word-token that will need to be broken up <mailto:list-manager@host.com?subject=help>", " This is a super-califragilistic-expialidociously-looooooooooooooooo\r\n oooooooong-word-token that will need to be broken up\r\n <mailto:list-manager@host.com?subject=help>\r\n", nil)
    ]

    for (id, value, expected, international) in cases {
        let header = Header(id, value: value)
        let raw = normalizeNewLines(byteArrayToString(header.rawValue))
        #expect(raw == normalizeNewLines(expected))

        var options = FormatOptions.default
        options.newLineFormat = .dos
        options.international = false
        let reformatted = normalizeNewLines(byteArrayToString(header.getRawValue(options)))
        #expect(reformatted == normalizeNewLines(expected))

        options.international = true
        let expectedInternational = international ?? expected
        let reformattedIntl = normalizeNewLines(byteArrayToString(header.getRawValue(options)))
        #expect(reformattedIntl == normalizeNewLines(expectedInternational))
    }
}

@Test("Header list command long URL")
func headerListCommandLongUrl() {
    let value = "<https://www.some-link.com/query-params?abcd=efgh&this=is-very-long-string-which-should-not-be-Rfc2047-encoded-and-should-be-kept-the-way-it-is-by-default>"
    let expected = "\r\n <https://www.some-link.com/query-params?abcd=efgh&this=is-very-long-string-which-should-not-be-Rfc2047-encoded-and-should-be-kept-the-way-it-is-by-default>\r\n"
    let header = Header(.listUnsubscribe, value: value)

    var options = FormatOptions.default
    options.newLineFormat = .dos
    options.international = false

    let result = byteArrayToString(header.getRawValue(options))
    #expect(result == normalizeNewLines(expected))
}

@Test("Header disposition notification options encoding")
func headerDispositionNotificationOptions() {
    let value = "    signed-receipt-protocol=optional,pkcs7-signature;signed-receipt-micalg=optional,sha1,sha128,sha256"
    let expected = " signed-receipt-protocol=optional,pkcs7-signature;\r\n\tsigned-receipt-micalg=optional,sha1,sha128,sha256\r\n"
    let header = Header(.dispositionNotificationOptions, value: value)

    var options = FormatOptions.default
    options.newLineFormat = .dos
    options.international = false

    let result = byteArrayToString(header.getRawValue(options))
    #expect(result == normalizeNewLines(expected))
}

@Test("Header unstructured folding")
func headerUnstructuredFolding() {
    let header = Header(field: "Subject", value: "This is a subject value that should be long enough to force line wrapping to keep the line length under the 78 character limit.")
    let raw = byteArrayToString(header.rawValue)

    #expect(raw.last == "\n")
    #expect(maxLineLength(raw) <= FormatOptions.default.maxLineLength)
    let unfolded = Header.unfold(raw)
    #expect(unfolded == header.value)
}

@Test("Header unstructured folding with long whitespace")
func headerUnstructuredFoldingWithLongWhitespace() {
    let spaces = String(repeating: " ", count: 78)
    let original = "This is a header value with a really long sequence of \(spaces) and such"
    let folded = Header.fold(.default, field: "Subject", value: original)
    let unfolded = Header.unfold(folded)

    #expect(folded.last == "\n")
    #expect(maxLineLength(folded) <= FormatOptions.default.maxLineLength)
    #expect(unfolded == original)
}

@Test("Header international unstructured folding")
func headerInternationalUnstructuredFolding() {
    var options = FormatOptions.default
    options.international = true
    let original = "This is a subject value that should be long enough to force line wrapping to keep the line length under the 78 character limit."
    let folded = Header.fold(options, field: "Subject", value: original)
    let unfolded = Header.unfold(folded)

    #expect(folded.last == "\n")
    #expect(maxLineLength(folded) < FormatOptions.default.maxLineLength)
    #expect(unfolded == original)
}

@Test("Header Japanese UTF-8 decoding")
func headerJapaneseUtf8Decoding() {
    let input = "Subject: =?UTF-8?B?RndkOiDjgI7jg53jgrHjg6Ljg7Mgzqnjg6vjg5Pjg7zjg7vOseOCteODleOCoeOCpOOCog==?= =?UTF-8?B?44CP44KS44OX44Os44Kk44GV44KM44Gf55qG44GV44G+44G4IDcyMOeorumhnuOBruODneOCseODog==?= =?UTF-8?B?44Oz44GM5Yui44Ge44KN44GE77yBM0RT5pyA5paw44K944OV44OI44Gu44GK44GX44KJ44Gb44Gn44GZ?="
    let expected = "Fwd: 『ポケモン Ωルビー・αサファイア』をプレイされた皆さまへ 720種類のポケモンが勢ぞろい！3DS最新ソフトのおしらせです"
    var header: Header? = nil

    #expect(Header.tryParse(input, header: &header))
    #expect(header?.id == .subject)
    #expect(header?.value == expected)
}

@Test("Header Japanese ISO-2022-JP decoding")
func headerJapaneseIso2022JpDecoding() {
    let input = "Subject: =?ISO-2022-JP?B?GyRCRnxLXDhsJWEhPCVrJUYlOSVIGyhCICh0ZXN0aW5nIEph?=\n =?ISO-2022-JP?B?cGFuZXNlIGVtYWlscyk=?="
    let expected = "日本語メールテスト (testing Japanese emails)"
    var header: Header? = nil

    #expect(Header.tryParse(input, header: &header))
    #expect(header?.id == .subject)
    #expect(header?.value == expected)
}

@Test("Header raw UTF-8 decoding")
func headerRawUtf8Decoding() {
    let input = "Subject: Fwd: 『ポケモン Ωルビー・αサファイア』をプレイされた皆さまへ 720種類のポケモンが勢ぞろい！3DS最新ソフトのおしらせです"
    let expected = "Fwd: 『ポケモン Ωルビー・αサファイア』をプレイされた皆さまへ 720種類のポケモンが勢ぞろい！3DS最新ソフトのおしらせです"
    let buffer = Array(input.utf8)
    var header: Header? = nil

    #expect(Header.tryParse(buffer, header: &header))
    #expect(header?.id == .subject)
    #expect(header?.value == expected)

    #expect(Header.tryParse(buffer, startIndex: 0, length: buffer.count, header: &header))
    #expect(header?.id == .subject)
    if let parsed = header {
        #expect((try? parsed.getValue("utf-8")) == expected)
    } else {
        #expect(Bool(false))
    }
}

@Test("Header parser canonicalization")
func headerParserCanonicalization() {
    var header: Header? = nil
    #expect(Header.tryParse("Content-Type: text/plain", header: &header))
    #expect(header?.field == "Content-Type")
    #expect(header?.value == "text/plain")
    #expect(header?.rawValue.last == 0x0A)
}

@Test("Header parse invalid")
func headerParseInvalid() {
    let input = "This is invalid"
    let raw = Array(input.utf8)
    var header: Header? = nil
    #expect(!Header.tryParse(input, header: &header))
    #expect(!Header.tryParse(raw, startIndex: 0, length: raw.count, header: &header))
}

@Test("HeaderId mapping")
func headerIdMapping() {
    for id in HeaderId.allCases where id != .unknown {
        let name = id.headerName.uppercased()
        let parsed = HeaderId.from(field: name)
        #expect(parsed == id)
    }
    #expect(HeaderId.from(field: "X-MadeUp-Header") == .unknown)
}

@Test("Header set raw value")
func headerSetRawValue() throws {
    let header = Header(.subject, value: "This is the subject")
    let rawValue = Array("This is the\n raw subject\n".utf8)
    var format = FormatOptions.default
    format.international = true

    try header.setRawValue(rawValue)
    let value = header.getRawValue(format)
    #expect(value.count == rawValue.count)
    for (i, byte) in rawValue.enumerated() {
        #expect(value[i] == byte)
    }
}

@Test("Header reformat subject")
func headerReformatSubject() {
    let subject = " I'm so happy! =?utf-8?b?5ZCN44GM44OJ44Oh44Kk44Oz?= I love MIME so\r\n much =?utf-8?b?4p2k77iP4oCN8J+UpSE=?= Isn't it great?\r\n"
    let expected = " I'm so happy! 名がドメイン I love MIME so much ❤️‍🔥! Isn't it great?\r\n"
    var options = FormatOptions.default
    options.newLineFormat = .dos
    options.international = true

    let rawValue = Array(subject.utf8)
    let header = Header(ParserOptions.default, .subject, "Subject", rawValue)
    let result = byteArrayToString(header.getRawValue(options))
    #expect(result == expected)
}

@Test("Header reformat content disposition")
func headerReformatContentDisposition() {
    let contentDisposition = " attachment; filename*=gb18030''%B2%E2%CA%D4%CE%C4%B1%BE.txt\r\n"
    let expected = " attachment; filename=\"测试文本.txt\"\r\n"
    var options = FormatOptions.default
    options.newLineFormat = .dos
    options.international = true

    let rawValue = Array(contentDisposition.utf8)
    let header = Header(ParserOptions.default, .contentDisposition, "Content-Disposition", rawValue)
    let result = byteArrayToString(header.getRawValue(options))
    #expect(result == expected)
}

@Test("Header reformat invalid content disposition")
func headerReformatInvalidContentDisposition() {
    let contentDisposition = " @!^($@*$&( @*$&@*#@OE UF Jfdfadsf adfsd\r\n"
    var options = FormatOptions.default
    options.newLineFormat = .dos
    options.international = true

    let rawValue = Array(contentDisposition.utf8)
    let header = Header(ParserOptions.default, .contentDisposition, "Content-Disposition", rawValue)
    let result = byteArrayToString(header.getRawValue(options))
    #expect(result == contentDisposition)
}

@Test("Header reformat content type")
func headerReformatContentType() {
    let contentType = " text/plain; name*=gb18030''%B2%E2%CA%D4%CE%C4%B1%BE.txt\r\n"
    let expected = " text/plain; name=\"测试文本.txt\"\r\n"
    var options = FormatOptions.default
    options.newLineFormat = .dos
    options.international = true

    let rawValue = Array(contentType.utf8)
    let header = Header(ParserOptions.default, .contentType, "Content-Type", rawValue)
    let result = byteArrayToString(header.getRawValue(options))
    #expect(result == expected)
}

@Test("Header reformat invalid content type")
func headerReformatInvalidContentType() {
    let contentType = " @!^($@*$&( @*$&@*#@OE UF Jfdfadsf adfsd\r\n"
    var options = FormatOptions.default
    options.newLineFormat = .dos
    options.international = true

    let rawValue = Array(contentType.utf8)
    let header = Header(ParserOptions.default, .contentType, "Content-Type", rawValue)
    let result = byteArrayToString(header.getRawValue(options))
    #expect(result == contentType)
}
