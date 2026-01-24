//
// InternetAddressListTests.swift
//

import Foundation
import Testing
@testable import MimeFoundation

private func unixFormatOptions() -> FormatOptions {
    var options = FormatOptions.default
    options.newLineFormat = .unix
    return options
}

private func assertInternetAddressListsEqual(_ text: String, _ expected: InternetAddressList, _ result: InternetAddressList) {
    #expect(result.count == expected.count)

    for index in 0..<expected.count {
        #expect(type(of: result[index]) == type(of: expected[index]))
        #expect(result[index].toString(encode: false) == expected[index].toString(encode: false))
    }

    let encoded = result.toString(unixFormatOptions(), encode: true)
    #expect(encoded == text)
}

private func assertTryParse(_ text: String, _ encoded: String, _ expected: InternetAddressList, options: ParserOptions? = nil) {
    let buffer = CharsetUtils.getBytes(text, encoding: .utf8)
    let opts = options ?? ParserOptions.default

    if let result = try? InternetAddressList(parsing: text, options: opts) {
        assertInternetAddressListsEqual(encoded, expected, result)
    } else {
        #expect(Bool(false), "Failed to parse from text")
    }

    if let result = try? InternetAddressList(parsing: buffer, options: opts) {
        assertInternetAddressListsEqual(encoded, expected, result)
    } else {
        #expect(Bool(false), "Failed to parse from buffer")
    }
}

private func assertParse(_ text: String, _ encoded: String, _ expected: InternetAddressList, options: ParserOptions? = nil) {
    let buffer = CharsetUtils.getBytes(text, encoding: .utf8)
    let opts = options ?? ParserOptions.default

    do {
        let result = try InternetAddressList(parsing: text, options: opts)
        assertInternetAddressListsEqual(encoded, expected, result)
    } catch {
        #expect(Bool(false), "Failed to parse from text: \(error)")
    }

    do {
        let result = try InternetAddressList(parsing: buffer, options: opts)
        assertInternetAddressListsEqual(encoded, expected, result)
    } catch {
        #expect(Bool(false), "Failed to parse from buffer: \(error)")
    }
}

private func assertParseAndTryParse(_ text: String, _ encoded: String, _ expected: InternetAddressList, options: ParserOptions? = nil) {
    assertTryParse(text, encoded, expected, options: options)
    assertParse(text, encoded, expected, options: options)
}

private func assertTryParseFails(_ text: String, options: ParserOptions? = nil) {
    let buffer = CharsetUtils.getBytes(text, encoding: .utf8)
    let opts = options ?? ParserOptions.default

    #expect((try? InternetAddressList(parsing: text, options: opts)) == nil)
    #expect((try? InternetAddressList(parsing: buffer, options: opts)) == nil)
}

private func assertParseFails(_ text: String, options: ParserOptions? = nil) {
    let buffer = CharsetUtils.getBytes(text, encoding: .utf8)
    let opts = options ?? ParserOptions.default

    do {
        _ = try InternetAddressList(parsing: text, options: opts)
        #expect(Bool(false))
    } catch is ParseException {
    } catch {
        #expect(Bool(false))
    }

    do {
        _ = try InternetAddressList(parsing: buffer, options: opts)
        #expect(Bool(false))
    } catch is ParseException {
    } catch {
        #expect(Bool(false))
    }
}

private func assertParseAndTryParseFail(_ text: String, options: ParserOptions? = nil) {
    assertTryParseFails(text, options: options)
    assertParseFails(text, options: options)
}

@Test("InternetAddressList parse whitespace")
func internetAddressListParseWhitespace() {
    assertParseAndTryParseFail("   ")
}

@Test("InternetAddressList parse name less than")
func internetAddressListParseNameLessThan() {
    assertTryParseFails("\"Name\" <")
    assertParseFails("\"Name\" <")
}

@Test("InternetAddressList simple addr-spec")
func internetAddressListSimpleAddrSpec() {
    var expected = InternetAddressList([
        MailboxAddress(name: "", address: "fejj@helixcode.com")
    ])
    assertParseAndTryParse("fejj@helixcode.com", "fejj@helixcode.com", expected)

    expected = InternetAddressList([
        MailboxAddress(name: "", address: "fejj")
    ])
    assertParseAndTryParse("fejj", "fejj", expected)
}

@Test("InternetAddressList simple addr-spec with trailing dot")
func internetAddressListSimpleAddrSpecWithTrailingDot() {
    let expected = InternetAddressList([
        MailboxAddress(name: "", address: "fejj@helixcode.com")
    ])
    assertParseAndTryParse("fejj@helixcode.com.", "fejj@helixcode.com", expected)
}

@Test("InternetAddressList RFC822 comments")
func internetAddressListRfc822Comments() {
    let text = "\":sysmail\"@  Some-Group. Some-Org,\n Muhammed.(I am  the greatest) Ali @(the)Vegas.WBA"
    let encoded = "\":sysmail\"@Some-Group.Some-Org, Muhammed.Ali@Vegas.WBA"
    let expected = InternetAddressList([
        MailboxAddress(name: "", address: "\":sysmail\"@Some-Group.Some-Org"),
        MailboxAddress(name: "", address: "Muhammed.Ali@Vegas.WBA")
    ])

    assertParseAndTryParse(text, encoded, expected)
}

@Test("InternetAddressList RFC5322 comments")
func internetAddressListRfc5322Comments() {
    let text = "Pete(A nice \\) chap) <pete(his account)@silly.test(his host)>"
    let encoded = "Pete <pete@silly.test>"
    let expected = InternetAddressList([
        MailboxAddress(name: "Pete", address: "pete@silly.test")
    ])

    assertParseAndTryParse(text, encoded, expected)
}

@Test("InternetAddressList simple mailboxes")
func internetAddressListSimpleMailboxes() {
    var expected = InternetAddressList([
        MailboxAddress(name: "Jeffrey Stedfast", address: "fejj@helixcode.com")
    ])
    assertParseAndTryParse("Jeffrey Stedfast <fejj@helixcode.com>", "Jeffrey Stedfast <fejj@helixcode.com>", expected)

    expected = InternetAddressList([
        MailboxAddress(name: "this is a folded name", address: "folded@name.com")
    ])
    assertParseAndTryParse("this is\n\ta folded name <folded@name.com>", "this is a folded name <folded@name.com>", expected)

    expected = InternetAddressList([
        MailboxAddress(name: "Jeffrey \"fejj\" Stedfast", address: "fejj@helixcode.com")
    ])
    assertParseAndTryParse("\"Jeffrey \\\"fejj\\\" Stedfast\" <fejj@helixcode.com>", "\"Jeffrey \\\"fejj\\\" Stedfast\" <fejj@helixcode.com>", expected)

    expected = InternetAddressList([
        MailboxAddress(name: "Stedfast, Jeffrey", address: "fejj@helixcode.com")
    ])
    assertParseAndTryParse("\"Stedfast, Jeffrey\" <fejj@helixcode.com>", "\"Stedfast, Jeffrey\" <fejj@helixcode.com>", expected)

    expected = InternetAddressList([
        MailboxAddress(name: "Jeffrey Stedfast", address: "fejj@helixcode.com")
    ])
    assertParseAndTryParse("fejj@helixcode.com (Jeffrey Stedfast)", "Jeffrey Stedfast <fejj@helixcode.com>", expected)

    expected = InternetAddressList([
        MailboxAddress(name: "Jeffrey Stedfast", address: "fejj@helixcode.com")
    ])
    assertParseAndTryParse("Jeffrey Stedfast <fejj(recursive (comment) block)@helixcode.(and a comment here)com>", "Jeffrey Stedfast <fejj@helixcode.com>", expected)

    expected = InternetAddressList([
        MailboxAddress(name: "Jeffrey Stedfast", address: "fejj@helixcode.com")
    ])
    assertParseAndTryParse("Jeffrey Stedfast <fejj@helixcode.com.>", "Jeffrey Stedfast <fejj@helixcode.com>", expected)
}

@Test("InternetAddressList RFC2047 encoded names")
func internetAddressListRfc2047EncodedNames() {
    var expected = InternetAddressList([
        MailboxAddress(name: "Kristoffer Brånemyr", address: "ztion@swipenet.se")
    ])
    let text1 = "=?iso-8859-1?q?Kristoffer_Br=E5nemyr?= <ztion@swipenet.se>"
    let encoded1 = "Kristoffer =?iso-8859-1?q?Br=E5nemyr?= <ztion@swipenet.se>"
    assertParseAndTryParse(text1, encoded1, expected)

    expected = InternetAddressList([
        MailboxAddress(name: "François Pons", address: "fpons@mandrakesoft.com")
    ])
    let text2 = "=?iso-8859-1?q?Fran=E7ois?= Pons <fpons@mandrakesoft.com>"
    assertParseAndTryParse(text2, text2, expected)
}

@Test("InternetAddressList group and addrspec")
func internetAddressListGroupAndAddrspec() {
    let text = "GNOME Hackers: Miguel de Icaza <miguel@gnome.org>, Havoc Pennington <hp@redhat.com>;, fejj@helixcode.com"
    let encoded = "GNOME Hackers: Miguel de Icaza <miguel@gnome.org>, Havoc Pennington\n\t<hp@redhat.com>;, fejj@helixcode.com"
    let expected = InternetAddressList([
        GroupAddress(name: "GNOME Hackers", members: [
            MailboxAddress(name: "Miguel de Icaza", address: "miguel@gnome.org"),
            MailboxAddress(name: "Havoc Pennington", address: "hp@redhat.com")
        ]),
        MailboxAddress(name: "", address: "fejj@helixcode.com")
    ])

    assertParseAndTryParse(text, encoded, expected)
}

@Test("InternetAddressList local group without semicolon")
func internetAddressListLocalGroupWithoutSemicolon() {
    let text = "Local recipients: phil, joe, alex, bob"
    let encoded = "Local recipients: phil, joe, alex, bob;"
    let expected = InternetAddressList([
        GroupAddress(name: "Local recipients", members: [
            MailboxAddress(name: "", address: "phil"),
            MailboxAddress(name: "", address: "joe"),
            MailboxAddress(name: "", address: "alex"),
            MailboxAddress(name: "", address: "bob")
        ])
    ])

    assertTryParse(text, encoded, expected)
}

@Test("InternetAddressList RFC5322 group comments")
func internetAddressListRfc5322GroupComments() {
    let text = "A Group(Some people):Chris Jones <c@(Chris's host.)public.example>, joe@example.org, John <jdoe@one.test> (my dear friend); (the end of the group)"
    let encoded = "A Group: Chris Jones <c@public.example>, joe@example.org, John <jdoe@one.test>;"
    let expected = InternetAddressList([
        GroupAddress(name: "A Group", members: [
            MailboxAddress(name: "Chris Jones", address: "c@public.example"),
            MailboxAddress(name: "", address: "joe@example.org"),
            MailboxAddress(name: "John", address: "jdoe@one.test")
        ])
    ])

    assertParseAndTryParse(text, encoded, expected)
}

@Test("InternetAddressList mailbox with dots in name")
func internetAddressListMailboxWithDotsInName() {
    let encoded = "\"Nathaniel S. Borenstein\" <nsb@thumper.bellcore.com>"
    let text = "Nathaniel S. Borenstein <nsb@thumper.bellcore.com>"
    let expected = InternetAddressList([
        MailboxAddress(name: "Nathaniel S. Borenstein", address: "nsb@thumper.bellcore.com")
    ])

    assertParseAndTryParse(text, encoded, expected)
}

@Test("InternetAddressList mailbox with 8bit name")
func internetAddressListMailboxWith8bitName() {
    let encoded = "Patrik =?utf-8?b?RsKlZGx0c3RywqV2bQ==?= <paf@nada.kth.se>"
    let text = "Patrik F¥dltstr¥vm <paf@nada.kth.se>"
    let expected = InternetAddressList([
        MailboxAddress(name: "Patrik F¥dltstr¥vm", address: "paf@nada.kth.se")
    ])

    assertParseAndTryParse(text, encoded, expected)
}

@Test("InternetAddressList obsolete routing syntax")
func internetAddressListObsoleteRoutingSyntax() {
    let text = "Routed Address <@route:user@domain.com>"
    let expected = InternetAddressList([
        MailboxAddress(name: "Routed Address", route: ["route"], address: "user@domain.com")
    ])

    assertParseAndTryParse(text, text, expected)
}

@Test("InternetAddressList obsolete routing syntax with empty domains")
func internetAddressListObsoleteRoutingSyntaxWithEmptyDomains() {
    let text = "Routed Address <@route1,,@route2,,,@route3:user@domain.com>"
    let encoded = "Routed Address <@route1,@route2,@route3:user@domain.com>"
    let expected = InternetAddressList([
        MailboxAddress(name: "Routed Address", route: ["route1", "route2", "route3"], address: "user@domain.com")
    ])

    assertParseAndTryParse(text, encoded, expected)
}

@Test("InternetAddressList encoding simple mailbox with quoted name")
func internetAddressListEncodingSimpleMailboxWithQuotedName() {
    let expected = "\"Stedfast, Jeffrey\" <fejj@gnome.org>"
    let list = InternetAddressList([
        MailboxAddress(name: "Stedfast, Jeffrey", address: "fejj@gnome.org")
    ])

    let actual = list.toString(unixFormatOptions(), encode: true)
    #expect(actual == expected)
}

@Test("InternetAddressList encoding simple mailbox with latin1 name")
func internetAddressListEncodingSimpleMailboxWithLatin1Name() {
    let latin1 = String.Encoding.isoLatin1
    var list = InternetAddressList([
        MailboxAddress(encoding: latin1, name: "Kristoffer Brånemyr", address: "ztion@swipenet.se")
    ])

    var expected = "Kristoffer =?iso-8859-1?q?Br=E5nemyr?= <ztion@swipenet.se>"
    var actual = list.toString(unixFormatOptions(), encode: true)
    #expect(actual == expected)

    let name = "T\u{0081}õivo Leedj\u{0081}ärv"
    list = InternetAddressList([
        MailboxAddress(encoding: latin1, name: name, address: "leedjarv@interest.ee")
    ])

    expected = "=?iso-8859-1?b?VIH1aXZvIExlZWRqgeRydg==?= <leedjarv@interest.ee>"
    actual = list.toString(unixFormatOptions(), encode: true)
    #expect(actual == expected)
}

@Test("InternetAddressList encoding mailbox with really long word")
func internetAddressListEncodingMailboxWithReallyLongWord() {
    let expected = "=?us-ascii?q?reeeeeeeeeeeeeeaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaallllllllllll?=\n =?us-ascii?q?llllllllllllllllllllllllllllllllllllllllllly?= long word\n\t<really.long.word@example.com>"
    let name = "reeeeeeeeeeeeeeaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaallllllllllllllllllllllllllllllllllllllllllllllllllllllly long word"
    let list = InternetAddressList([
        MailboxAddress(name: name, address: "really.long.word@example.com")
    ])
    var options = FormatOptions.default
    options.newLineFormat = .unix
    options.allowMixedHeaderCharsets = true

    let actual = list.toString(options, encode: true)
    #expect(actual == expected)
    var parsed: InternetAddressList? = nil
    parsed = try? InternetAddressList(parsing: actual)
    #expect(parsed != nil)
    #expect(parsed?.first?.name == name)
}

@Test("InternetAddressList encoding mailbox with arabic name")
func internetAddressListEncodingMailboxWithArabicName() {
    let expected = "=?utf-8?b?2YfZhCDYqtiq2YPZhNmFINin2YTZhNi62Kkg2KfZhNil2YbYrNmE2YrYstmK2Kk=?=\n =?utf-8?b?IC/Yp9mE2LnYsdio2YrYqdif?= <do.you.speak@arabic.com>"
    let mailbox = MailboxAddress(name: "هل تتكلم اللغة الإنجليزية /العربية؟", address: "do.you.speak@arabic.com")
    let list = InternetAddressList([mailbox])

    let actual = list.toString(unixFormatOptions(), encode: true)
    #expect(actual == expected)
    var parsed: InternetAddressList? = nil
    parsed = try? InternetAddressList(parsing: actual)
    #expect(parsed != nil)
    #expect(parsed?.first?.name == mailbox.name)
}

@Test("InternetAddressList encoding mailbox with japanese name")
func internetAddressListEncodingMailboxWithJapaneseName() {
    let expected = "=?utf-8?b?54uC44Gj44Gf44GT44Gu5LiW44Gn54uC44GG44Gq44KJ5rCX44Gv56K644GL44Gg?=\n =?utf-8?b?44CC?= <famous@quotes.ja>"
    let mailbox = MailboxAddress(name: "狂ったこの世で狂うなら気は確かだ。", address: "famous@quotes.ja")
    let list = InternetAddressList([mailbox])

    let actual = list.toString(unixFormatOptions(), encode: true)
    #expect(actual == expected)
    var parsed: InternetAddressList? = nil
    parsed = try? InternetAddressList(parsing: actual)
    #expect(parsed != nil)
    #expect(parsed?.first?.name == mailbox.name)
}

@Test("InternetAddressList encoding simple address list")
func internetAddressListEncodingSimpleAddressList() {
    let expectedEncoded = "Kristoffer =?iso-8859-1?q?Br=E5nemyr?= <ztion@swipenet.se>, Jeffrey Stedfast\n\t<fejj@gnome.org>"
    let expectedDisplay = "\"Kristoffer Brånemyr\" <ztion@swipenet.se>, \"Jeffrey Stedfast\" <fejj@gnome.org>"
    let latin1 = String.Encoding.isoLatin1
    var options = FormatOptions.default
    options.newLineFormat = .unix
    let list = InternetAddressList([
        MailboxAddress(encoding: latin1, name: "Kristoffer Brånemyr", address: "ztion@swipenet.se"),
        MailboxAddress(name: "Jeffrey Stedfast", address: "fejj@gnome.org")
    ])

    let display = list.toString(options, encode: false)
    #expect(display == expectedDisplay)

    let encoded = list.toString(options, encode: true)
    #expect(encoded == expectedEncoded)
}

@Test("InternetAddressList encoding long name mixed quoting and encoding")
func internetAddressListEncodingLongNameMixedQuotingAndEncoding() {
    let name = "Dr. xxxxxxxxxx xxxxx | xxxxxx.xxxxxxx für xxxxxxxxxxxxx xxxx"
    let encodedNameLatin1 = "\"Dr. xxxxxxxxxx xxxxx | xxxxxx.xxxxxxx\" =?iso-8859-1?b?Zvxy?= xxxxxxxxxxxxx xxxx"
    let encodedNameUnicode = "\"Dr. xxxxxxxxxx xxxxx | xxxxxx.xxxxxxx\" =?utf-8?b?ZsO8cg==?= xxxxxxxxxxxxx xxxx"
    let encodedMailbox = "\"Dr. xxxxxxxxxx xxxxx | xxxxxx.xxxxxxx\" =?iso-8859-1?b?Zvxy?= xxxxxxxxxxxxx\n xxxx <x.xxxxx@xxxxxxx-xxxxxx.xx>"
    let address = "x.xxxxx@xxxxxxx-xxxxxx.xx"
    var options = FormatOptions.default
    options.newLineFormat = .unix
    options.allowMixedHeaderCharsets = true

    let buffer = Rfc2047.encodePhrase(options, .utf8, name)
    let result = String(bytes: buffer, encoding: .ascii) ?? ""
    #expect(result == encodedNameLatin1)

    let list = InternetAddressList([
        MailboxAddress(name: name, address: address)
    ])
    let encoded = list.toString(options, encode: true)
    #expect(encoded == encodedMailbox)

    options.allowMixedHeaderCharsets = false

    let bufferUnicode = Rfc2047.encodePhrase(options, .utf8, name)
    let resultUnicode = String(bytes: bufferUnicode, encoding: .ascii) ?? ""
    #expect(resultUnicode == encodedNameUnicode)
}

@Test("InternetAddressList decoded mailbox has correct charset")
func internetAddressListDecodedMailboxHasCorrectCharsetEncoding() {
    let latin1 = String.Encoding.isoLatin1
    let mailbox = MailboxAddress(encoding: latin1, name: "Kristoffer Brånemyr", address: "ztion@swipenet.se")
    let list = InternetAddressList([mailbox])
    let encoded = list.toString(unixFormatOptions(), encode: true)

    var parsed: InternetAddressList? = nil
    parsed = try? InternetAddressList(parsing: encoded)
    #expect(parsed != nil)
    #expect(parsed?.first?.encoding == latin1)
}

@Test("InternetAddressList unsupported charset does not throw")
func internetAddressListUnsupportedCharsetDoesNotThrow() {
    let mailbox = MailboxAddress(encoding: .utf8, name: "狂ったこの世で狂うなら気は確かだ。", address: "famous@quotes.ja")
    let list = InternetAddressList([mailbox])
    var encoded = list.toString(.default, encode: true)
    encoded = encoded.replacingOccurrences(of: "utf-8", with: "x-unknown")

    var parsed: InternetAddressList? = nil
    parsed = try? InternetAddressList(parsing: encoded)
    #expect(parsed != nil)
}

@Test("InternetAddressList international email addresses")
func internetAddressListInternationalEmailAddresses() {
    let text = "伊昭傑@郵件.商務, राम@मोहन.ईन्फो, юзер@екзампл.ком, θσερ@εχαμπλε.ψομ"
    var list: InternetAddressList? = nil

    list = try? InternetAddressList(parsing: text)
    #expect(list != nil)
    #expect(list?.count == 4)

    let addresses = text.split(separator: ",").map { String($0).trimmingCharacters(in: .whitespacesAndNewlines) }
    for index in 0..<addresses.count {
        let mailbox = list?[index] as? MailboxAddress
        #expect(mailbox?.address == addresses[index])
    }
}

@Test("InternetAddressList basic functionality")
func internetAddressListBasicFunctionality() {
    let user0 = MailboxAddress(name: "Name Zero", address: "user0@address.com")
    let user1 = MailboxAddress(name: "Name One", address: "user1@address.com")
    let user2 = MailboxAddress(name: "Name Two", address: "user2@address.com")
    let list = InternetAddressList()

    #expect(list.isReadOnly == false)

    list.add(user1)
    list.add(user2)

    #expect(list.count == 2)
    #expect(list.contains(user1))
    #expect(list.contains(user2))
    #expect(list.contains(MailboxAddress(name: "Unknown", address: "unknown@address.com")) == false)
    #expect(list.indexOf(user1) == 0)
    #expect(list.indexOf(user2) == 1)

    list.insert(user0, at: 0)
    #expect(list.count == 3)
    #expect(list.contains(user0))
    #expect(list.indexOf(user0) == 0)
    #expect(list[0].name == user0.name)

    list.remove(at: 0)
    #expect(list.count == 2)
    #expect(list.contains(user0) == false)
    #expect(list.indexOf(user0) == -1)

    #expect(list.remove(user0) == false)

    #expect(list.remove(user2))
    #expect(list.count == 1)
    #expect(list.contains(user2) == false)
    #expect(list.indexOf(user0) == -1)

    list[0] = user0
    #expect(list.count == 1)
    #expect(list.contains(user0))
    #expect(list.contains(user1) == false)
    #expect(list.indexOf(user0) == 0)
    #expect(list.indexOf(user1) == -1)
}

@Test("InternetAddressList enumerating mailboxes")
func internetAddressListEnumeratingMailboxes() {
    let innerGroup = GroupAddress(name: "Inner")
    innerGroup.members.add(MailboxAddress(name: "Inner1", address: "inner1@address.com"))
    innerGroup.members.add(MailboxAddress(name: "Inner2", address: "inner2@address.com"))

    let outerGroup = GroupAddress(name: "Outer")
    outerGroup.members.add(MailboxAddress(name: "Outer1", address: "outer1@address.com"))
    outerGroup.members.add(innerGroup)
    outerGroup.members.add(MailboxAddress(name: "Outer2", address: "outer2@address.com"))

    let list = InternetAddressList([
        MailboxAddress(name: "Before", address: "before@address.com"),
        outerGroup,
        MailboxAddress(name: "After", address: "after@address.com")
    ])

    let expected: [InternetAddress] = [
        list[0],
        outerGroup.members[0],
        innerGroup.members[0],
        innerGroup.members[1],
        outerGroup.members[2],
        list[2]
    ]

    for (index, mailbox) in list.mailboxes.enumerated() {
        #expect(mailbox == expected[index])
    }
}

@Test("InternetAddressList equality")
func internetAddressListEquality() {
    let list1 = InternetAddressList([
        GroupAddress(name: "Local recipients", members: [
            MailboxAddress(name: "", address: "phil"),
            MailboxAddress(name: "", address: "joe"),
            MailboxAddress(name: "", address: "alex"),
            MailboxAddress(name: "", address: "bob")
        ]),
        MailboxAddress(name: "Joey", address: "joey@friends.com"),
        MailboxAddress(name: "Chandler", address: "chandler@friends.com")
    ])

    let list2 = InternetAddressList([
        GroupAddress(name: "Local recipients", members: [
            MailboxAddress(name: "", address: "phil"),
            MailboxAddress(name: "", address: "joe"),
            MailboxAddress(name: "", address: "alex"),
            MailboxAddress(name: "", address: "bob")
        ]),
        MailboxAddress(name: "Joey", address: "joey@friends.com"),
        MailboxAddress(name: "Chandler", address: "chandler@friends.com")
    ])

    #expect(list1 == list2)
    #expect(list1 != InternetAddressList())
}

@Test("InternetAddressList compareTo")
func internetAddressListCompareTo() {
    let list1 = InternetAddressList([
        GroupAddress(name: "Local recipients", members: [
            MailboxAddress(name: "", address: "phil"),
            MailboxAddress(name: "", address: "joe"),
            MailboxAddress(name: "", address: "alex"),
            MailboxAddress(name: "", address: "bob")
        ]),
        MailboxAddress(name: "Joey", address: "joey@friends.com"),
        MailboxAddress(name: "Chandler", address: "chandler@friends.com")
    ])

    let list2 = InternetAddressList([
        MailboxAddress(name: "Chandler", address: "chandler@friends.com"),
        GroupAddress(name: "Local recipients", members: [
            MailboxAddress(name: "", address: "phil"),
            MailboxAddress(name: "", address: "joe"),
            MailboxAddress(name: "", address: "alex"),
            MailboxAddress(name: "", address: "bob")
        ]),
        MailboxAddress(name: "Joey", address: "joey@friends.com")
    ])

    #expect(list1.compareTo(list2) > 0)
    #expect(list2.compareTo(list1) < 0)

    let mailbox = MailboxAddress(name: "Joe", address: "joe@inter.net")
    let group = GroupAddress(name: "Joe", members: [
        MailboxAddress(name: "Joe", address: "joe@inter.net")
    ])

    #expect(mailbox.compareTo(group) < 0)
    #expect(group.compareTo(mailbox) > 0)
    #expect(mailbox.compareTo(group.members[0]) == 0)

    let alice = MailboxAddress(name: "", address: "alice@example.com")
    let bob = MailboxAddress(name: "", address: "bob@example.com")
    #expect(alice.compareTo(bob) < 0)
    #expect(bob.compareTo(alice) > 0)

    let alexa = MailboxAddress(name: "", address: "alexa@example.com")
    let alex = MailboxAddress(name: "", address: "alex@example.com")
    #expect(alex.compareTo(alexa) < 0)
    #expect(alexa.compareTo(alex) > 0)
}

@Test("InternetAddressList parse mailbox with escaped at symbol")
func internetAddressListParseMailboxWithEscapedAtSymbol() {
    let text = "First Last <webmaster\\@custom-domain.com@mail-host.com>"
    let modes: [RfcComplianceMode] = [.strict, .loose, .looser]

    for mode in modes {
        var options = ParserOptions.default
        options.addressParserComplianceMode = mode
        if mode == .looser {
            var list: InternetAddressList? = nil
            list = try? InternetAddressList(parsing: text, options: options)
            #expect(list != nil)
            #expect(list?.count == 1)
            let mailbox = list?.first as? MailboxAddress
            #expect(mailbox?.address == "webmaster%40custom-domain.com@mail-host.com")
            #expect(mailbox?.localPart == "webmaster%40custom-domain.com")
            #expect(mailbox?.domain == "mail-host.com")
        } else {
            var list: InternetAddressList? = nil
            list = try? InternetAddressList(parsing: text, options: options)
            #expect(list == nil)
        }
    }
}

@Test("InternetAddressList rfc7103 excessive angle brackets")
func internetAddressListParseMailboxWithExcessiveAngleBrackets() {
    let text = "<<<user2@example.org>>>"
    let encoded = "user2@example.org"
    let expected = InternetAddressList([
        MailboxAddress(name: "", address: encoded)
    ])

    assertParseAndTryParse(text, encoded, expected)
}

@Test("InternetAddressList rfc7103 missing greater than")
func internetAddressListParseMailboxWithMissingGreaterThan() {
    let text = "<another@example.net"
    let encoded = "another@example.net"
    let expected = InternetAddressList([
        MailboxAddress(name: "", address: encoded)
    ])

    assertParseAndTryParse(text, encoded, expected)
}

@Test("InternetAddressList rfc7103 missing less than")
func internetAddressListParseMailboxWithMissingLessThan() {
    let text = "second@example.org>"
    let encoded = "second@example.org"
    let expected = InternetAddressList([
        MailboxAddress(name: "", address: encoded)
    ])

    assertParseAndTryParse(text, encoded, expected)
}

@Test("InternetAddressList rfc7103 errant comma")
func internetAddressListParseErrantComma() {
    let text = "<third@example.net, fourth@example.net>"
    let encoded = "third@example.net, fourth@example.net"
    let expected = InternetAddressList([
        MailboxAddress(name: "", address: "third@example.net"),
        MailboxAddress(name: "", address: "fourth@example.net")
    ])

    assertParseAndTryParse(text, encoded, expected)
}

@Test("InternetAddressList rfc7103 unbalanced close paren")
func internetAddressListParseMailboxWithUnbalancedClosedParenthesis() {
    let text = "Testing) <sam@example.com>"
    let encoded = "\"Testing)\" <sam@example.com>"
    let expected = InternetAddressList([
        MailboxAddress(name: "Testing)", address: "sam@example.com")
    ])

    assertParseAndTryParse(text, encoded, expected)
}

@Test("InternetAddressList rfc7103 unbalanced quotes")
func internetAddressListParseMailboxWithUnbalancedQuotes() {
    let text = "\"Joe <joe@example.com>"
    let encoded = "Joe <joe@example.com>"
    let expected = InternetAddressList([
        MailboxAddress(name: "Joe", address: "joe@example.com")
    ])

    assertParseAndTryParse(text, encoded, expected)
}

@Test("InternetAddressList rfc7103 unbalanced quotes with list")
func internetAddressListParseMailboxWithUnbalancedQuotes2() {
    let text = "\"Joe <joe@example.com>, Bob <bob@example.com>"
    let encoded = "Joe <joe@example.com>, Bob <bob@example.com>"
    let expected = InternetAddressList([
        MailboxAddress(name: "Joe", address: "joe@example.com"),
        MailboxAddress(name: "Bob", address: "bob@example.com")
    ])

    assertParseAndTryParse(text, encoded, expected)
}

@Test("InternetAddressList rfc7103 addrspec as unquoted name")
func internetAddressListParseMailboxWithAddrspecAsUnquotedName() {
    let text = "user@example.com <user@example.com>"
    let encoded = "\"user@example.com\" <user@example.com>"
    let expected = InternetAddressList([
        MailboxAddress(name: "user@example.com", address: "user@example.com")
    ])

    assertParseAndTryParse(text, encoded, expected)
}

@Test("InternetAddressList suspicious mailbox 1")
func internetAddressListParseSuspiciousMailbox1() {
    let suspicious = "<user@[domain.com\r\n <img src=x onerror=alert()>]>"
    let encoded = "user@[domain.com<imgsrc=xonerror=alert()>]"
    let expected = InternetAddressList([
        MailboxAddress(name: "", address: "user@[domain.com<imgsrc=xonerror=alert()>]")
    ])

    assertParseAndTryParse(suspicious, encoded, expected)
}

@Test("InternetAddressList suspicious mailbox 2")
func internetAddressListParseSuspiciousMailbox2() {
    let suspicious = "<user@[domain.com]\u{0000}\r\n]>"
    let modes: [RfcComplianceMode] = [.strict, .loose, .looser]
    for mode in modes {
        var options = ParserOptions.default
        options.addressParserComplianceMode = mode
        assertTryParseFails(suspicious, options: options)
    }
}

@Test("InternetAddressList suspicious mailbox 3")
func internetAddressListParseSuspiciousMailbox3() {
    let suspicious = "<user@[::1>\"\\[:<h1>user@gmail.com,русский?]>"
    let modes: [RfcComplianceMode] = [.strict, .loose, .looser]
    for mode in modes {
        var options = ParserOptions.default
        options.addressParserComplianceMode = mode
        assertTryParseFails(suspicious, options: options)
    }
}

@Test("InternetAddressList suspicious mailbox 4")
func internetAddressListParseSuspiciousMailbox4() {
    let suspicious = "user@spoofed-domain.com <user@legit-domain.com>"
    let encoded = "\"user@spoofed-domain.com\" <user@legit-domain.com>"
    let modes: [RfcComplianceMode] = [.strict, .loose, .looser]

    for mode in modes {
        var options = ParserOptions.default
        options.addressParserComplianceMode = mode
        let expected = InternetAddressList([
            MailboxAddress(name: "user@spoofed-domain.com", address: "user@legit-domain.com")
        ])

        if mode == .strict {
            assertTryParseFails(suspicious, options: options)
        } else {
            assertTryParse(suspicious, encoded, expected, options: options)
        }
    }
}

@Test("InternetAddressList suspicious mailbox 5")
func internetAddressListParseSuspiciousMailbox5() {
    let suspicious = "<user@spoofed-domain.com> <user@legit-domain.com>"
    let encoded = "user@spoofed-domain.com, user@legit-domain.com"
    let modes: [RfcComplianceMode] = [.strict, .loose, .looser]

    for mode in modes {
        var options = ParserOptions.default
        options.addressParserComplianceMode = mode
        let expected = InternetAddressList([
            MailboxAddress(name: "", address: "user@spoofed-domain.com"),
            MailboxAddress(name: "", address: "user@legit-domain.com")
        ])

        if mode == .strict {
            assertTryParseFails(suspicious, options: options)
        } else {
            assertTryParse(suspicious, encoded, expected, options: options)
        }
    }
}

@Test("InternetAddressList suspicious mailbox 6")
func internetAddressListParseSuspiciousMailbox6() {
    let suspicious = "<user@spoofed-domain.com> \"spoofed\" <user@legit-domain.com>"
    let encoded = "user@spoofed-domain.com, spoofed <user@legit-domain.com>"
    let modes: [RfcComplianceMode] = [.strict, .loose, .looser]

    for mode in modes {
        var options = ParserOptions.default
        options.addressParserComplianceMode = mode
        let expected = InternetAddressList([
            MailboxAddress(name: "", address: "user@spoofed-domain.com"),
            MailboxAddress(name: "spoofed", address: "user@legit-domain.com")
        ])

        if mode == .strict {
            assertTryParseFails(suspicious, options: options)
        } else {
            assertTryParse(suspicious, encoded, expected, options: options)
        }
    }
}

@Test("InternetAddressList suspicious group 1")
func internetAddressListParseSuspiciousGroup1() {
    let suspicious = "user@spoofed-domain.com: user@legit-domain.com;"
    let encoded = "user@spoofed-domain.com, : user@legit-domain.com;"
    let modes: [RfcComplianceMode] = [.strict, .loose, .looser]

    for mode in modes {
        var options = ParserOptions.default
        options.addressParserComplianceMode = mode
        let expected = InternetAddressList([
            MailboxAddress(name: "", address: "user@spoofed-domain.com"),
            GroupAddress(name: "", members: [
                MailboxAddress(name: "", address: "user@legit-domain.com")
            ])
        ])

        if mode == .strict {
            assertTryParseFails(suspicious, options: options)
        } else {
            assertTryParse(suspicious, encoded, expected, options: options)
        }
    }
}

@Test("InternetAddressList suspicious group 2")
func internetAddressListParseSuspiciousGroup2() {
    let suspicious = "<user@spoofed-domain.com>: <user@legit-domain.com>;"
    let encoded = "user@spoofed-domain.com, : user@legit-domain.com;"
    let modes: [RfcComplianceMode] = [.strict, .loose, .looser]

    for mode in modes {
        var options = ParserOptions.default
        options.addressParserComplianceMode = mode
        let expected = InternetAddressList([
            MailboxAddress(name: "", address: "user@spoofed-domain.com"),
            GroupAddress(name: "", members: [
                MailboxAddress(name: "", address: "user@legit-domain.com")
            ])
        ])

        if mode == .strict {
            assertTryParseFails(suspicious, options: options)
        } else {
            assertTryParse(suspicious, encoded, expected, options: options)
        }
    }
}

@Test("InternetAddressList suspicious group 3")
func internetAddressListParseSuspiciousGroup3() {
    let suspicious = "\"user@spoofed-domain.com\": user@legit-domain.com;"
    let encoded = "\"user@spoofed-domain.com\": user@legit-domain.com;"
    let modes: [RfcComplianceMode] = [.strict, .loose, .looser]

    for mode in modes {
        var options = ParserOptions.default
        options.addressParserComplianceMode = mode
        let expected = InternetAddressList([
            GroupAddress(name: "user@spoofed-domain.com", members: [
                MailboxAddress(name: "", address: "user@legit-domain.com")
            ])
        ])

        assertTryParse(suspicious, encoded, expected, options: options)
    }
}

@Test("InternetAddressList invalid addrspec")
func internetAddressListTryParseFailsWithInvalidAddrSpec() {
    let text = "name.@abc.com"
    assertTryParseFails(text)
}

@Test("InternetAddressList parses mailbox list")
func internetAddressListParsesMailboxes() {
    let text = "Alice <alice@example.com>, Bob <bob@example.com>"
    var list: InternetAddressList? = nil
    list = try? InternetAddressList(parsing: text)
    #expect(list != nil)
    #expect(list?.count == 2)
    #expect(list?[0].toString(.default, encode: false) == "\"Alice\" <alice@example.com>")
    #expect(list?[1].toString(.default, encode: false) == "\"Bob\" <bob@example.com>")

    let parsed = try? InternetAddressList(parsing: text)
    #expect(parsed?.count == 2)
}

@Test("InternetAddressList collects mailboxes from groups")
func internetAddressListMailboxesFlatten() {
    let group = GroupAddress(name: "Team")
    group.members.add(MailboxAddress(name: "Alice", address: "alice@example.com"))
    group.members.add(MailboxAddress(name: "Bob", address: "bob@example.com"))

    let list = InternetAddressList([group, MailboxAddress(name: "Cara", address: "cara@example.com")])
    let mailboxes = list.mailboxes
    #expect(mailboxes.count == 3)
    #expect(mailboxes[0].address == "alice@example.com")
    #expect(mailboxes[1].address == "bob@example.com")
    #expect(mailboxes[2].address == "cara@example.com")
}
