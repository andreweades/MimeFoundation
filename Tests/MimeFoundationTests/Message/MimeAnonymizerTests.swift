//
// MimeAnonymizerTests.swift
//

import Foundation
import Testing
@testable import MimeFoundation

private func normalizeNewLines(_ text: String) -> String {
    text.replacingOccurrences(of: "\r\n", with: "\n").replacingOccurrences(of: "\r", with: "\n")
}

private func expectedAnonymizedFileName(from fileName: String) -> String {
    let base = (fileName as NSString).deletingPathExtension
    return base + ".anonymized.eml"
}

private func assertAnonymizeMessage(_ fileName: String) throws {
    let data = try TestHelper.loadData(relativePath: "messages/\(fileName)")
    let message: MimeMessage
    do {
        message = try MimeMessage.load(MemoryStream(data, writable: false))
    } catch {
        Issue.record("Failed to load message \(fileName): \(error)")
        throw error
    }
    let anonymizer = MimeAnonymizer()
    let memory = MemoryStream()
    do {
        try anonymizer.anonymize(message, memory)
    } catch {
        Issue.record("Failed to anonymize message \(fileName): \(type(of: error)) \(error)")
        throw error
    }
    let actual = normalizeNewLines(String(decoding: memory.toByteArray(), as: UTF8.self))

    let expectedName = expectedAnonymizedFileName(from: fileName)
    let expectedData = try TestHelper.loadData(relativePath: "messages/\(expectedName)")
    let expected = normalizeNewLines(String(decoding: expectedData, as: UTF8.self))

    #expect(actual == expected)
}

private func assertAnonymizeEntity(_ fileName: String) throws {
    let data = try TestHelper.loadData(relativePath: "messages/\(fileName)")
    let entity: MimeEntity
    do {
        entity = try MimeEntity.load(MemoryStream(data, writable: false))
    } catch {
        Issue.record("Failed to load entity \(fileName): \(error)")
        throw error
    }
    let anonymizer = MimeAnonymizer()
    let memory = MemoryStream()
    do {
        try anonymizer.anonymize(entity, memory)
    } catch {
        Issue.record("Failed to anonymize entity \(fileName): \(type(of: error)) \(error)")
        throw error
    }
    let actual = normalizeNewLines(String(decoding: memory.toByteArray(), as: UTF8.self))

    let expectedName = expectedAnonymizedFileName(from: fileName)
    let expectedData = try TestHelper.loadData(relativePath: "messages/\(expectedName)")
    let expected = normalizeNewLines(String(decoding: expectedData, as: UTF8.self))

    #expect(actual == expected)
}

@Test("MimeAnonymizer argument exceptions")
func mimeAnonymizerArgumentExceptions() throws {
    let anonymizer = MimeAnonymizer()
    let message = MimeMessage()
    let entity = try MimePart("text", "plain")
    let stream = MemoryStream()

    // All nil-argument tests have been removed since parameters are now non-optional
    // Test that valid calls work
    try anonymizer.anonymize(message, stream)
    try anonymizer.anonymize(.default, message, stream)
    try anonymizer.anonymize(entity, stream)
    try anonymizer.anonymize(.default, entity, stream)
}

@Test("MimeAnonymizer received header value")
func mimeAnonymizerReceivedHeaderValue() {
    let cases: [(String, String)] = [
        (" (qmail 21619 invoked from network); 15 Nov 2017 14:16:18 -0000\r\n",
         " (xxxxx xxxxx xxxxxxx xxxx xxxxxxx); 15 Nov 2017 14:16:18 -0000\r\n"),
        (" from unknown (HELO EUR01-HE1-obe.outbound.protection.outlook.com) (80.68.177.35)\r\n  by  with SMTP; 15 Nov 2017 14:16:18 -0000\r\n",
         " from xxxxxxx (xxxx xxxxxxxxxxxxx.xxxxxxxx.xxxxxxxxxx.xxxxxxx.xxx) (xx.xx.xxx.xx)\r\n  by  with xxxx; 15 Nov 2017 14:16:18 -0000\r\n"),
        (" from mail-he1eur01on0133.outbound.protection.outlook.com\r\n\t([104.47.0.133] helo=EUR01-HE1-obe.outbound.protection.outlook.com) by\r\n\tmyassp01.mynet.it with SMTP (2.5.5); 15 Nov 2017 15:16:20 +0100\r\n",
         " from xxxxxxxxxxxxxxxxxxx.xxxxxxxx.xxxxxxxxxx.xxxxxxx.xxx\r\n\t([xxx.xx.x.xxx] xxxxxxxxxxxxxxxxxx.xxxxxxxx.xxxxxxxxxx.xxxxxxx.xxx) by\r\n\txxxxxxxx.xxxxx.xx with xxxx (x.x.x); 15 Nov 2017 15:16:20 +0100\r\n"),
        (" from AM4PR01MB1444.eurprd01.prod.exchangelabs.com (10.164.76.26) by\r\n AM4PR01MB1442.eurprd01.prod.exchangelabs.com (10.164.76.24) with Microsoft\r\n SMTP Server (version=TLS1_2,\r\n cipher=TLS_ECDHE_RSA_WITH_AES_256_CBC_SHA384_P256) id 15.20.218.12; Wed, 15\r\n Nov 2017 14:16:14 +0000\r\n",
         " from xxxxxxxxxxxxx.xxxxxxxx.xxxx.xxxxxxxxxxxx.xxx (xx.xxx.xx.xx) by\r\n xxxxxxxxxxxxx.xxxxxxxx.xxxx.xxxxxxxxxxxx.xxx (xx.xxx.xx.xx) with xxxxxxxxx\r\n xxxx xxxxxx (xxxxxxxxxxxxxx,\r\n xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx) id xx.xx.xxx.xx; Wed, 15\r\n Nov 2017 14:16:14 +0000\r\n"),
        (" from AM4PR01MB1444.eurprd01.prod.exchangelabs.com\r\n ([fe80::7830:c66f:eaa8:e3dd]) by AM4PR01MB1444.eurprd01.prod.exchangelabs.com\r\n ([fe80::7830:c66f:eaa8:e3dd%14]) with mapi id 15.20.0218.015; Wed, 15 Nov\r\n 2017 14:16:14 +0000\r\n",
         " from xxxxxxxxxxxxx.xxxxxxxx.xxxx.xxxxxxxxxxxx.xxx\r\n ([xxxx::xxxx:xxxx:xxxx:xxxx]) by xxxxxxxxxxxxx.xxxxxxxx.xxxx.xxxxxxxxxxxx.xxx\r\n ([xxxx::xxxx:xxxx:xxxx:xxxxxxx]) with xxxx id xx.xx.xxxx.xxx; Wed, 15 Nov\r\n 2017 14:16:14 +0000\r\n"),
        (" from unknown (this is a (nested comment) with an \\\"escaped quoted\")\r\n by AM4PR01MB1442.eurprd01.prod.exchangelabs.com (10.164.76.24) \r\n",
         " from xxxxxxx (xxxx xx x (xxxxxx xxxxxxx) xxxx xx \\xxxxxxxx xxxxxxx)\r\n by xxxxxxxxxxxxx.xxxxxxxx.xxxx.xxxxxxxxxxxx.xxx (xx.xxx.xx.xx) \r\n"),
    ]

    for (value, expected) in cases {
        let rawValue = Array(value.utf8)
        let anonymizedValue = MimeAnonymizer.anonymizeReceivedHeaderValue(rawValue)
        let anonymized = String(decoding: anonymizedValue, as: UTF8.self)
        #expect(anonymized == expected)
    }
}

@Test("MimeAnonymizer address header value")
func mimeAnonymizerAddressHeaderValue() {
    let cases: [(String, String)] = [
        (" \":sysmail\"@  Some-Group. Some-Org,\r\n Muhammed.(I am  the greatest) Ali @(the)Vegas.WBA\r\n",
         " \"xxxxxxxx\"@  xxxxxxxxxx. xxxxxxxx,\r\n xxxxxxxx.(x xx  xxx xxxxxxxx) xxx @(xxx)xxxxx.xxx\r\n"),
        (" Pete(A nice \\) chap) <pete(his account)@silly.test(his host)>\r\n",
         " xxxx(x xxxx \\) xxxx) <xxxx(xxx xxxxxxx)@xxxxx.xxxx(xxx xxxx)>\r\n"),
        (" GNOME Hackers: Miguel de Icaza <miguel@gnome.org>, Havoc Pennington\r\n\t<hp@redhat.com>;, fejj@helixcode.com\r\n",
         " xxxxx xxxxxxx: xxxxxx xx xxxxx <xxxxxx@xxxxx.xxx>, xxxxx xxxxxxxxxx\r\n\t<xx@xxxxxx.xxx>;, xxxx@xxxxxxxxx.xxx\r\n"),
        (" A Group(Some people):Chris Jones <c@(Chris's host.)public.example>, joe@example.org,\r\n John <jdoe@one.test> (my dear friend); (the end of the group)\r\n",
         " x xxxxx(xxxx xxxxxx):xxxxx xxxxx <x@(xxxxxxx xxxx.)xxxxxx.xxxxxxx>, xxx@xxxxxxx.xxx,\r\n xxxx <xxxx@xxx.xxxx> (xx xxxx xxxxxx); (xxx xxx xx xxx xxxxx)\r\n"),
        (" \"Nathaniel S. Borenstein\" <nsb@thumper.bellcore.com>\r\n",
         " \"xxxxxxxxxxxxxxxxxxxxxxx\" <xxx@xxxxxxx.xxxxxxxx.xxx>\r\n"),
        (" \"Nathaniel\r\nS. Borenstein\" <nsb@thumper.bellcore.com>\r\n",
         " \"xxxxxxxxx\r\nxxxxxxxxxxxxx\" <xxx@xxxxxxx.xxxxxxxx.xxx>\r\n"),
        (" =?utf-8?b?2YfZhCDYqtiq2YPZhNmFINin2YTZhNi62Kkg2KfZhNil2YbYrNmE2YrYstmK2Kk=?=\r\n =?utf-8?b?IC/Yp9mE2LnYsdio2YrYqdif?= <do.you.speak@arabic.com>\r\n",
         " =?utf-8?b?xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx?=\r\n =?utf-8?b?xxxxxxxxxxxxxxxxxxxxxxxx?= <xx.xxx.xxxxx@xxxxxx.xxx>\r\n"),
        (" =?utf-8?b?54uC44Gj44Gf44GT44Gu5LiW44Gn54u\r\nC44GG44Gq44KJ5rCX44Gv56K644GL44Gg?=\r\n =?utf-8?b?44CC?= <famous@quotes.ja>\r\n",
         " =?utf-8?b?xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx\r\nxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx?=\r\n =?utf-8?b?xxxx?= <xxxxxx@xxxxxx.xx>\r\n"),
        (" 伊昭傑@郵件.商務, राम@मोहन.ईन्फो,\r\n юзер@екзампл.ком, θσερ@εχαμπλε.ψομ\r\n",
         " xxxxxxxxx@xxxxxx.xxxxxx, xxxxxxxxx@xxxxxxxxxxxx.xxxxxxxxxxxxxxx,\r\n xxxxxxxx@xxxxxxxxxxxxxx.xxxxxx, xxxxxxxx@xxxxxxxxxxxxxx.xxxxxx\r\n"),
        (" <<<user2@example.org>>>, <another@example.net, second@example.org>\r\n",
         " <<<xxxxx@xxxxxxx.xxx>>>, <xxxxxxx@xxxxxxx.xxx, xxxxxx@xxxxxxx.xxx>\r\n"),
        (" <user@[domain.com\r\n <img src=x onerror=alert()>]>\r\n",
         " <xxxx@[xxxxxx.xxx\r\n <xxx xxx=x xxxxxxx=xxxxx()>]>\r\n"),
        (" <user@[domain.com]\0\r\n]>\r\n",
         " <xxxx@[xxxxxx.xxx]x\r\n]>\r\n"),
        (" \"User Name\" <user@example.com>, \"Unterminated qstring token\r\n",
         " \"xxxxxxxxx\" <xxxx@xxxxxxx.xxx>, \"xxxxxxxxxxxxxxxxxxxxxxxxxx\r\n"),
        (" \"User Name\" <user@example.com>, (Unterminated comment\r\n",
         " \"xxxxxxxxx\" <xxxx@xxxxxxx.xxx>, (xxxxxxxxxxxx xxxxxxx\r\n"),
        (" Display Name <escaped\\\"quoted@example.com>\r\n",
         " xxxxxxx xxxx <xxxxxxx\\\"xxxxxx@xxxxxxx.xxx>\r\n"),
    ]

    for (value, expected) in cases {
        let rawValue = Array(value.utf8)
        let anonymizedValue = MimeAnonymizer.anonymizeAddressHeaderValue(rawValue)
        let anonymized = String(decoding: anonymizedValue, as: UTF8.self)
        #expect(anonymized == expected)
    }
}

@Test("MimeAnonymizer content disposition value")
func mimeAnonymizerContentDispositionValue() {
    let cases: [(String, String)] = [
        (" attachment\r\n", " attachment\r\n"),
        (" attachment; \r\n", " attachment; \r\n"),
        (" attachment; filename=winmail.dat\r\n", " attachment; filename=xxxxxxxxxxx\r\n"),
        (" attachment; filename=\"escaped \\\"quotes\\\".doc\";;\r\n", " attachment; filename=\"xxxxxxxx\\\"xxxxxx\\\"xxxx\";;\r\n"),
        (" attachment;\r\n filename*0*=UTF-8''UnicodeFile;\n filename*1*=name.doc\r\n", " attachment;\r\n filename*0*=xxxxxxxxxxxxxxxxxx;\n filename*1*=xxxxxxxx\r\n"),
        (" attachment;\r\n filename*0*=UTF-8''UnicodeFile;\n filename*1=\"name.doc\";\r\n", " attachment;\r\n filename*0*=xxxxxxxxxxxxxxxxxx;\n filename*1=\"xxxxxxxx\";\r\n"),
        (" inline; filename; size=32767;\r\n", " inline; filename; size=xxxxx;\r\n"),
        (" inline; filename*; filename*0; filename*1*; filename*2*=;\r\n", " inline; filename*; filename*0; filename*1*; filename*2*=;\r\n"),
    ]

    for (value, expected) in cases {
        let rawValue = Array(value.utf8)
        let anonymizedValue = MimeAnonymizer.anonymizeContentDispositionValue(rawValue)
        let anonymized = String(decoding: anonymizedValue, as: UTF8.self)
        #expect(anonymized == expected)
    }
}

@Test("MimeAnonymizer content type value")
func mimeAnonymizerContentTypeValue() {
    let cases: [(String, String)] = [
        (" application/octet-stream\r\n", " application/octet-stream\r\n"),
        (" application/octet-stream; \r\n", " application/octet-stream; \r\n"),
        (" text/plain; charset=us-ascii\r\n", " text/plain; charset=us-ascii\r\n"),
        (" text/plain; charset=\"us-ascii\"\r\n", " text/plain; charset=\"us-ascii\"\r\n"),
        (" text/plain; charset=us-ascii; format=flowed\r\n deslsp=yes; name=anonymize.txt\r\n",
         " text/plain; charset=us-ascii; format=flowed\r\n deslsp=yes; name=xxxxxxxxxxxxx\r\n"),
        (" multipart/mixed;\r\n\tboundary=\"----=_NextPart_000_0031_01D36222.8A648550\"\r\n",
         " multipart/mixed;\r\n\tboundary=\"----=_NextPart_000_0031_01D36222.8A648550\"\r\n"),
        (" multipart/mixed;\r\n\tboundary*=\"----=_NextPart_000_0031_01D36222.8A648550\"\r\n",
         " multipart/mixed;\r\n\tboundary*=\"----=_NextPart_000_0031_01D36222.8A648550\"\r\n"),
        (" multipart/mixed;\r\n\tboundary*0*=US-ASCII''----=3D_NextPart_000_;\r\n\tboundary*1*=0031_01D36222.8A648550;\r\n",
         " multipart/mixed;\r\n\tboundary*0*=US-ASCII''----=3D_NextPart_000_;\r\n\tboundary*1*=0031_01D36222.8A648550;\r\n"),
        (" application/octet-stream;\r\n name*0*=UTF-8''anonymize;\n name*1*=this.doc\r\n",
         " application/octet-stream;\r\n name*0*=xxxxxxxxxxxxxxxx;\n name*1*=xxxxxxxx\r\n"),
        (" application/octet-stream;\r\n name*0*=UTF-8''UnicodeFile;\n name*1=\"name.doc\";\r\n",
         " application/octet-stream;\r\n name*0*=xxxxxxxxxxxxxxxxxx;\n name*1=\"xxxxxxxx\";\r\n"),
        (" application/octet-stream;\r\n name=\"unterminated qstring value;\r\n",
         " application/octet-stream;\r\n name=\"xxxxxxxxxxxxxxxxxxxxxxxxxxx\r\n"),
    ]

    for (value, expected) in cases {
        let rawValue = Array(value.utf8)
        let anonymizedValue = MimeAnonymizer.anonymizeContentTypeValue(rawValue)
        let anonymized = String(decoding: anonymizedValue, as: UTF8.self)
        #expect(anonymized == expected)
    }
}

@Test("MimeAnonymizer unstructured header value")
func mimeAnonymizerUnstructuredHeaderValue() {
    let cases: [(String, String)] = [
        (" This is a simple subject...", " xxxx xx x xxxxxx xxxxxxxxxx"),
        (" blurdy bloop =??q?no_charset?= beep boop\r\n", " xxxxxx xxxxx =??x?xxxxxxxxxx?= xxxx xxxx\r\n"),
        (" blurdy bloop =?iso-8859-1?q?this_is_english?= beep boop\r\n", " xxxxxx xxxxx =?iso-8859-1?q?xxxxxxxxxxxxxxx?= xxxx xxxx\r\n"),
        (" I'm so happy! =?utf-8?b?8J+YgA==?= I love MIME so much =?utf-8?b?4p2k77iP4oCN8J+UpSE=?= Isn't it great?\r\n",
         " xxx xx xxxxxx =?utf-8?b?xxxxxxxx?= x xxxx xxxx xx xxxx =?utf-8?b?xxxxxxxxxxxxxxxxxxxx?= xxxxx xx xxxxx?\r\n"),
        (" blurdy bloop =?=?q?this_is_english?= beep boop\r\n", " xxxxxx xxxxx =?=?x?xxxxxxxxxxxxxxx?= xxxx xxxx\r\n"),
        (" blurdy bloop =?iso-8859-1??this_is_english?= beep boop\r\n", " xxxxxx xxxxx =?iso-8859-1??xxxxxxxxxxxxxxx?= xxxx xxxx\r\n"),
        (" blurdy bloop =?iso-8859-1?=?this_is_english?= beep boop\r\n", " xxxxxx xxxxx =?iso-8859-1?=?xxxxxxxxxxxxxxx?= xxxx xxxx\r\n"),
    ]

    for (value, expected) in cases {
        let rawValue = Array(value.utf8)
        let anonymizedValue = MimeAnonymizer.anonymizeUnstructuredHeaderValue(rawValue)
        let anonymized = String(decoding: anonymizedValue, as: UTF8.self)
        #expect(anonymized == expected)
    }
}

@Test("MimeAnonymizer simple embedded message")
func mimeAnonymizerSimpleEmbeddedMessage() throws {
    try assertAnonymizeMessage("simple-embedded-message.eml")
}

@Test("MimeAnonymizer simple multipart message")
func mimeAnonymizerSimpleMultipartMessage() throws {
    try assertAnonymizeMessage("simple-multipart.eml")
}

@Test("MimeAnonymizer simple multipart entity")
func mimeAnonymizerSimpleMultipartEntity() throws {
    try assertAnonymizeEntity("simple-multipart.eml")
}

@Test("MimeAnonymizer message delivery status")
func mimeAnonymizerMessageDeliveryStatus() throws {
    try assertAnonymizeMessage("delivery-status.txt")
}

@Test("MimeAnonymizer message disposition notification")
func mimeAnonymizerMessageDispositionNotification() throws {
    try assertAnonymizeMessage("disposition-notification.txt")
}

@Test("MimeAnonymizer generated message")
func mimeAnonymizerGeneratedMessage() throws {
    let expected = """
Received: from xxxxxxxxxx.xxxxxxx.xxx by xxxxxxxxx via xxxx;
	Sun, 6 Nov 2025 13:22:23 -0400
From: \"xxxxxxxxxxxxxxxxxxx\" <xxxxxxxxxx@xxxxxxx.xxx>
Date: Sun, 06 Apr 2025 13:22:18 -0400
Subject: xxxx xx x xxxx xxxxxxx
Message-Id: <xx.x@xxxxxxx.xxx>
To: \"xxxxxxxxxxxxxxxxxxx\" <xxxxxxxxxx@xxxxxxx.xxx>
References: <xx.x@xxxxxxx.xxx>
In-Reply-To: <xx.x@xxxxxxx.xxx>
MIME-Version: 1.0
Content-Type: multipart/mixed;
	boundary=\"----=_NextPart_000_003F_01CE98CE.6E826F90\"

------=_NextPart_000_003F_01CE98CE.6E826F90
Content-Type: text/plain; charset=utf-8

xxxx xx x xxxx xxxxxxx

------=_NextPart_000_003F_01CE98CE.6E826F90
Content-Type: text/plain; name=xxxxxxxxxxxxxxx; charset=utf-8
Content-Disposition: attachment; filename=xxxxxxxxxxxxxxx
Content-Transfer-Encoding: base64

xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
xxxx

------=_NextPart_000_003F_01CE98CE.6E826F90--

"""

    let message = MimeMessage()
    message.headers.insert(Header(field: "Received", value: "from unit-tests.mimekit.net by localhost via SMTP; Sun, 6 Nov 2025 13:22:23 -0400"), at: 0)
    message.from.add(MailboxAddress(name: "LastName, FirstName", address: "unit-tests@mimekit.net"))
    message.date = DateTimeOffset(year: 2025, month: 4, day: 6, hour: 13, minute: 22, second: 18, offsetMinutes: -240)
    message.subject = "This is a test subject"
    message.headers[.messageId] = "<id.2@mimekit.net>"
    message.to.add(MailboxAddress(name: "LastName, FirstName", address: "unit-tests@mimekit.net"))
    message.headers[.references] = "<id.1@mimekit.net>"
    message.headers[.inReplyTo] = "<id.1@mimekit.net>"

    let multipart = try Multipart("mixed")
    multipart.setBoundary("----=_NextPart_000_003F_01CE98CE.6E826F90")

    let text = TextPart("plain")
    text.text = "This is a test message\r\n"
    try multipart.add(text)

    let attachmentText = TextPart("plain")
    attachmentText.fileName = "lorem-ipsum.txt"
    attachmentText.contentTransferEncoding = .base64
    let loremData = try TestHelper.loadData(relativePath: "text/lorem-ipsum.txt")
    let loremText = String(decoding: loremData, as: UTF8.self).replacingOccurrences(of: "\r\n", with: "\n").replacingOccurrences(of: "\n", with: "\r\n")
    attachmentText.text = loremText
    try multipart.add(attachmentText)

    message.body = multipart

    let anonymizer = MimeAnonymizer()
    let memory = MemoryStream()
    try anonymizer.anonymize(message, memory)
    let actual = normalizeNewLines(String(decoding: memory.toByteArray(), as: UTF8.self))
    let expectedNormalized = normalizeNewLines(expected)
    #expect(actual == expectedNormalized)
}

@Test("MimeAnonymizer generated message without body")
func mimeAnonymizerGeneratedMessageWithoutBody() throws {
    let expected = """
Received: from xxxxxxxxxx.xxxxxxx.xxx by xxxxxxxxx via xxxx;
\tSun, 6 Nov 2025 13:22:23 -0400
From: \"xxxxxxxxxxxxxxxxxxx\" <xxxxxxxxxx@xxxxxxx.xxx>
Date: Sun, 06 Apr 2025 13:22:18 -0400
Subject: xxxx xx x xxxx xxxxxxx
Message-Id: <xx.x@xxxxxxx.xxx>
To: \"xxxxxxxxxxxxxxxxxxx\" <xxxxxxxxxx@xxxxxxx.xxx>
References: <xx.x@xxxxxxx.xxx>
In-Reply-To: <xx.x@xxxxxxx.xxx>
xxxx xx xx xxxxxxx xxxxxxxxx

"""

    let message = MimeMessage()
    message.headers.insert(Header(field: "Received", value: "from unit-tests.mimekit.net by localhost via SMTP; Sun, 6 Nov 2025 13:22:23 -0400"), at: 0)
    message.from.add(MailboxAddress(name: "LastName, FirstName", address: "unit-tests@mimekit.net"))
    message.date = DateTimeOffset(year: 2025, month: 4, day: 6, hour: 13, minute: 22, second: 18, offsetMinutes: -240)
    message.subject = "This is a test subject"
    message.headers[.messageId] = "<id.2@mimekit.net>"
    message.to.add(MailboxAddress(name: "LastName, FirstName", address: "unit-tests@mimekit.net"))
    message.headers[.references] = "<id.1@mimekit.net>"
    message.headers[.inReplyTo] = "<id.1@mimekit.net>"

    let invalid = Array("This is an invalid header...\r\n".utf8)
    let invalidHeader = Header(.default, fieldBytes: invalid, fieldNameLength: invalid.count, rawValue: [])
    message.headers.add(invalidHeader)

    let anonymizer = MimeAnonymizer()
    let memory = MemoryStream()
    try anonymizer.anonymize(message, memory)
    let actual = normalizeNewLines(String(decoding: memory.toByteArray(), as: UTF8.self))
    let expectedNormalized = normalizeNewLines(expected)
    #expect(actual == expectedNormalized)
}

@Test("MimeAnonymizer preserve headers")
func mimeAnonymizerPreserveHeaders() throws {
    let expected = """
Received: from unit-tests.mimekit.net by localhost via SMTP;
\tSun, 6 Nov 2025 13:22:23 -0400
From: \"xxxxxxxxxxxxxxxxxxx\" <xxxxxxxxxx@xxxxxxx.xxx>
Date: Sun, 06 Apr 2025 13:22:18 -0400
Subject: xxxx xx x xxxx xxxxxxx
Message-Id: <id.2@mimekit.net>
To: \"xxxxxxxxxxxxxxxxxxx\" <xxxxxxxxxx@xxxxxxx.xxx>
References: <xx.x@xxxxxxx.xxx>
In-Reply-To: <xx.x@xxxxxxx.xxx>

"""

    let message = MimeMessage()
    message.headers.insert(Header(field: "Received", value: "from unit-tests.mimekit.net by localhost via SMTP; Sun, 6 Nov 2025 13:22:23 -0400"), at: 0)
    message.from.add(MailboxAddress(name: "LastName, FirstName", address: "unit-tests@mimekit.net"))
    message.date = DateTimeOffset(year: 2025, month: 4, day: 6, hour: 13, minute: 22, second: 18, offsetMinutes: -240)
    message.subject = "This is a test subject"
    message.headers[.messageId] = "<id.2@mimekit.net>"
    message.to.add(MailboxAddress(name: "LastName, FirstName", address: "unit-tests@mimekit.net"))
    message.headers[.references] = "<id.1@mimekit.net>"
    message.headers[.inReplyTo] = "<id.1@mimekit.net>"

    let anonymizer = MimeAnonymizer()
    anonymizer.preserveHeaders.insert("received")
    anonymizer.preserveHeaders.insert("message-id")

    let memory = MemoryStream()
    try anonymizer.anonymize(message, memory)
    let actual = normalizeNewLines(String(decoding: memory.toByteArray(), as: UTF8.self))
    let expectedNormalized = normalizeNewLines(expected)
    #expect(actual == expectedNormalized)
}
