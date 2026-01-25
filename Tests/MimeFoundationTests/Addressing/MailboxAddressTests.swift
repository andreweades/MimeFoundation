//
// MailboxAddressTests.swift
//

import Testing
import MimeFoundation

@Test("Mailbox argument exceptions")
func mailboxArgumentExceptions() {
    let mailbox = MailboxAddress(name: "Johnny Appleseed", address: "johnny@example.com")
    let route = ["route.com"]

    #expect(throws: (any Error).self) {
        _ = try MailboxAddress(encoding: nil, name: "name", route: route, address: "johnny@example.com")
    }

    #expect(throws: (any Error).self) {
        _ = try MailboxAddress(encoding: .utf8, name: "name", route: nil, address: "johnny@example.com")
    }

    #expect(throws: (any Error).self) {
        _ = try MailboxAddress(encoding: .utf8, name: "name", route: route, address: nil)
    }

    #expect(throws: (any Error).self) {
        _ = try MailboxAddress(name: "name", route: nil, address: "johnny@example.com")
    }

    #expect(throws: (any Error).self) {
        _ = try MailboxAddress(name: "name", route: route, address: nil)
    }

    #expect(throws: (any Error).self) {
        _ = try MailboxAddress(encoding: nil, name: "name", address: "johnny@example.com")
    }

    #expect(throws: (any Error).self) {
        _ = try MailboxAddress(encoding: .utf8, name: "name", address: nil)
    }

    #expect(throws: (any Error).self) {
        _ = try MailboxAddress(name: "name", address: nil)
    }

    #expect(throws: (any Error).self) {
        try mailbox.setAddress(nil)
    }

    #expect(throws: (any Error).self) {
        try mailbox.setEncoding(nil)
    }

    #expect(throws: (any Error).self) {
        _ = try MailboxAddress.encodeAddrspec(nil)
    }

    #expect(throws: (any Error).self) {
        _ = try MailboxAddress.decodeAddrspec(nil)
    }
}

@Test("SecureMailboxAddress argument exceptions")
func secureMailboxArgumentExceptions() {
    let route = ["route.com"]

    #expect(throws: (any Error).self) {
        _ = try SecureMailboxAddress(encoding: nil, name: "name", route: route, address: "johnny@example.com", fingerprint: "ffff")
    }

    #expect(throws: (any Error).self) {
        _ = try SecureMailboxAddress(encoding: .utf8, name: "name", route: nil, address: "johnny@example.com", fingerprint: "ffff")
    }

    #expect(throws: (any Error).self) {
        _ = try SecureMailboxAddress(encoding: .utf8, name: "name", route: route, address: nil, fingerprint: "ffff")
    }

    #expect(throws: (any Error).self) {
        _ = try SecureMailboxAddress(encoding: .utf8, name: "name", route: route, address: "johnny@example.com", fingerprint: nil)
    }

    #expect(throws: (any Error).self) {
        _ = try SecureMailboxAddress(encoding: .utf8, name: "name", route: route, address: "johnny@example.com", fingerprint: "not hex encoded")
    }

    #expect(throws: (any Error).self) {
        _ = try SecureMailboxAddress(name: "name", route: nil, address: "johnny@example.com", fingerprint: "ffff")
    }

    #expect(throws: (any Error).self) {
        _ = try SecureMailboxAddress(name: "name", route: route, address: nil, fingerprint: "ffff")
    }

    #expect(throws: (any Error).self) {
        _ = try SecureMailboxAddress(name: "name", route: route, address: "johnny@example.com", fingerprint: nil)
    }

    #expect(throws: (any Error).self) {
        _ = try SecureMailboxAddress(name: "name", route: route, address: "johnny@example.com", fingerprint: "not hex encoded")
    }

    #expect(throws: (any Error).self) {
        _ = try SecureMailboxAddress(encoding: nil, name: "name", address: "johnny@example.com", fingerprint: "ffff")
    }

    #expect(throws: (any Error).self) {
        _ = try SecureMailboxAddress(encoding: .utf8, name: "name", address: nil, fingerprint: "ffff")
    }

    #expect(throws: (any Error).self) {
        _ = try SecureMailboxAddress(encoding: .utf8, name: "name", address: "johnny@example.com", fingerprint: nil)
    }

    #expect(throws: (any Error).self) {
        _ = try SecureMailboxAddress(encoding: .utf8, name: "name", address: "johnny@example.com", fingerprint: "not hex encoded")
    }

    #expect(throws: (any Error).self) {
        _ = try SecureMailboxAddress(name: "name", address: nil, fingerprint: "ffff")
    }

    #expect(throws: (any Error).self) {
        _ = try SecureMailboxAddress(name: "name", address: "johnny@example.com", fingerprint: nil)
    }

    #expect(throws: (any Error).self) {
        _ = try SecureMailboxAddress(name: "name", address: "johnny@example.com", fingerprint: "not hex encoded")
    }

    do {
        _ = try SecureMailboxAddress(name: "Mailbox Address", address: "user@domain.com", fingerprint: "ffff")
    } catch {
        Issue.record("Unexpected error: \(error)")
    }

    do {
        _ = try SecureMailboxAddress(encoding: .utf8, name: "Mailbox Address", address: "user@domain.com", fingerprint: "ffff")
    } catch {
        Issue.record("Unexpected error: \(error)")
    }

    do {
        _ = try SecureMailboxAddress(name: "Routed Address", route: ["route1", "route2", "route3"], address: "user@domain.com", fingerprint: "ffff")
    } catch {
        Issue.record("Unexpected error: \(error)")
    }

    do {
        _ = try SecureMailboxAddress(encoding: .utf8, name: "Routed Address", route: ["route1", "route2", "route3"], address: "user@domain.com", fingerprint: "ffff")
    } catch {
        Issue.record("Unexpected error: \(error)")
    }
}

private func assertParseFailure(_ text: String, result: Bool, tokenIndex: Int, errorIndex: Int, mode: RfcComplianceMode = .loose) {
    let buffer = text.isEmpty ? [UInt8](repeating: 0, count: 1) : CharsetUtils.getBytes(text, encoding: .utf8)
    var options = ParserOptions.default
    options.addressParserComplianceMode = mode

    #expect(((try? MailboxAddress(parsing: text, options: options)) != nil) == result)
    #expect(((try? MailboxAddress(parsing: buffer, options: options)) != nil) == result)

    do {
        _ = try MailboxAddress(parsing: text, options: options)
        #expect(Bool(false))
    } catch let error as ParseException {
        #expect(error.tokenIndex == tokenIndex)
        #expect(error.errorIndex == errorIndex)
    } catch {
        #expect(Bool(false))
    }

    do {
        _ = try MailboxAddress(parsing: buffer, options: options)
        #expect(Bool(false))
    } catch let error as ParseException {
        #expect(error.tokenIndex == tokenIndex)
        #expect(error.errorIndex == errorIndex)
    } catch {
        #expect(Bool(false))
    }
}

private func assertParse(_ text: String, mode: RfcComplianceMode? = nil) {
    let buffer = CharsetUtils.getBytes(text, encoding: .utf8)
    var options = ParserOptions.default
    if let mode {
        options.addressParserComplianceMode = mode
    }

    #expect((try? MailboxAddress(parsing: text, options: options)) != nil)
    #expect((try? MailboxAddress(parsing: buffer, options: options)) != nil)

    do {
        _ = try MailboxAddress(parsing: text, options: options)
    } catch {
        #expect(Bool(false), "Failed to parse from text: \(error)")
    }

    do {
        _ = try MailboxAddress(parsing: buffer, options: options)
    } catch {
        #expect(Bool(false), "Failed to parse from buffer: \(error)")
    }
}

@Test("Mailbox local-part and domain")
func mailboxLocalPartAndDomain() {
    let mailbox = MailboxAddress(name: "User Name", address: "user@domain.com")
    #expect(mailbox.localPart == "user")
    #expect(mailbox.domain == "domain.com")

    let unixMailbox = MailboxAddress(name: "User Name", address: "user")
    #expect(unixMailbox.localPart == "user")
    #expect(unixMailbox.domain.isEmpty)
}

@Test("Mailbox empty address is not international")
func mailboxEmptyAddress() {
    let mailbox = MailboxAddress(name: "Postmaster", address: "")
    #expect(mailbox.isInternational == false)
}

@Test("Mailbox parse rejects garbage after address")
func mailboxGarbageAfterAddress() {
    do {
        _ = try MailboxAddress(parsing:"fejj@helixcode.com garbage")
        #expect(Bool(false))
    } catch let error as ParseException {
        #expect(error.tokenIndex == 19)
        #expect(error.errorIndex == 19)
    } catch {
        #expect(Bool(false))
    }
}

@Test("Mailbox tryParse and parse succeed")
func mailboxParseSimple() {
    let text = "Johnny Appleseed <johnny@example.com>"
    var mailbox: MailboxAddress? = nil
    mailbox = try? MailboxAddress(parsing: text)
    #expect(mailbox != nil)
    #expect(mailbox?.address == "johnny@example.com")

    let parsed = try? MailboxAddress(parsing: text)
    #expect(parsed?.address == "johnny@example.com")
    #expect(parsed?.name == "Johnny Appleseed")
}

@Test("Mailbox parse empty")
func mailboxParseEmpty() {
    assertParseFailure("", result: false, tokenIndex: 0, errorIndex: 0)
}

@Test("Mailbox parse whitespace")
func mailboxParseWhitespace() {
    let text = " \t\r\n"
    let length = text.utf8.count
    assertParseFailure(text, result: false, tokenIndex: length, errorIndex: length)
}

@Test("Mailbox parse name less-than")
func mailboxParseNameLessThan() {
    let text = "Name <"
    assertParseFailure(text, result: false, tokenIndex: 0, errorIndex: text.count)
}

@Test("Mailbox parse empty domain")
func mailboxParseEmptyDomain() {
    let text = "jeff@"
    assertParseFailure(text, result: false, tokenIndex: 0, errorIndex: text.count)
}

@Test("Mailbox parse incomplete local-part")
func mailboxParseIncompleteLocalPart() {
    let text = "jeff."
    assertParseFailure(text, result: false, tokenIndex: 0, errorIndex: text.count)
}

@Test("Mailbox parse incomplete quoted string")
func mailboxParseIncompleteQuotedString() {
    let text = "\"This quoted string never ends... oh no!"
    assertParseFailure(text, result: false, tokenIndex: 0, errorIndex: text.count)
}

@Test("Mailbox parse incomplete comment after name")
func mailboxParseIncompleteCommentAfterName() {
    let text = "Name (incomplete comment"
    let tokenIndex = text.firstIndex(of: "(")?.utf16Offset(in: text) ?? 0
    assertParseFailure(text, result: false, tokenIndex: tokenIndex, errorIndex: text.count)
}

@Test("Mailbox parse incomplete comment after addrspec")
func mailboxParseIncompleteCommentAfterAddrspec() {
    let text = "jeff@xamarin.com (incomplete comment"
    let tokenIndex = text.firstIndex(of: "(")?.utf16Offset(in: text) ?? 0
    assertParseFailure(text, result: false, tokenIndex: tokenIndex, errorIndex: text.count)
}

@Test("Mailbox parse incomplete comment after domain literal")
func mailboxParseIncompleteCommentAfterDomainLiteral() {
    let text = "jeff@[127.0.0.1] (incomplete comment"
    let tokenIndex = text.firstIndex(of: "(")?.utf16Offset(in: text) ?? 0
    assertParseFailure(text, result: false, tokenIndex: tokenIndex, errorIndex: text.count)
}

@Test("Mailbox parse incomplete comment after address")
func mailboxParseIncompleteCommentAfterAddress() {
    let text = "<jeff@xamarin.com> (incomplete comment"
    let tokenIndex = text.firstIndex(of: "(")?.utf16Offset(in: text) ?? 0
    assertParseFailure(text, result: false, tokenIndex: tokenIndex, errorIndex: text.count)
}

@Test("Mailbox parse incomplete addrspec")
func mailboxParseIncompleteAddrspec() {
    let text = "jeff@ (comment)"
    assertParseFailure(text, result: false, tokenIndex: 0, errorIndex: text.count)
}

@Test("Mailbox parse incomplete routed mailbox at")
func mailboxParseIncompleteRoutedMailboxAt() {
    let text = "Name <@"
    assertParseFailure(text, result: false, tokenIndex: 0, errorIndex: text.count)
}

@Test("Mailbox parse incomplete routed mailbox")
func mailboxParseIncompleteRoutedMailbox() {
    let text = "Name <@route:"
    assertParseFailure(text, result: false, tokenIndex: 0, errorIndex: text.count)
}

@Test("Mailbox parse incomplete routed mailbox with space")
func mailboxParseIncompleteRoutedMailboxSpace() {
    let text = "Name <@route: "
    assertParseFailure(text, result: false, tokenIndex: 0, errorIndex: text.count)
}

@Test("Mailbox parse incomplete comment in route")
func mailboxParseIncompleteCommentInRoute() {
    let text = "Name <@route,(comment"
    assertParseFailure(text, result: false, tokenIndex: 0, errorIndex: text.count)
}

@Test("Mailbox parse invalid route in mailbox")
func mailboxParseInvalidRoute() {
    let text = "Name <@route,invalid:user@example.com>"
    let errorIndex = (text.firstIndex(of: ",")?.utf16Offset(in: text) ?? 0) + 1
    assertParseFailure(text, result: false, tokenIndex: 0, errorIndex: errorIndex)
}

@Test("Mailbox parse mailbox with international route")
func mailboxParseInternationalRoute() {
    let text = "User Name <@route,@伊昭傑@郵件.商務:user@domain.com>"
    assertParse(text)
}

@Test("Mailbox parse IDN address")
func mailboxParseIdnAddress() {
    let encoded = "user@xn--v8jxj3d1dzdz08w.com"
    let expected = "user@名がドメイン.com"
    let mailbox = try? MailboxAddress(parsing: encoded)
    #expect(mailbox != nil)
    #expect(mailbox?.address == expected)
}

@Test("Mailbox parse addrspec without domain")
func mailboxParseAddrspecNoDomain() {
    assertParse("jeff")
}

@Test("Mailbox parse addrspec without domain but greater-than")
func mailboxParseAddrspecNoDomainGreaterThan() {
    let text = "jeff>"
    let errorIndex = text.count - 1
    assertParseFailure(text, result: false, tokenIndex: 0, errorIndex: errorIndex, mode: .strict)
    assertParse(text)
}

@Test("Mailbox parse addrspec without domain with incomplete comment")
func mailboxParseAddrspecNoDomainWithIncompleteComment() {
    let text = "jeff (Jeffrey Stedfast"
    assertParseFailure(text, result: false, tokenIndex: 5, errorIndex: text.count)
}

@Test("Mailbox parse addrspec without domain with comment")
func mailboxParseAddrspecNoDomainWithComment() {
    let text = "jeff (Jeffrey Stedfast)"
    assertParse(text)
    let mailbox = try? MailboxAddress(parsing: text)
    #expect(mailbox?.name == "Jeffrey Stedfast")
    #expect(mailbox?.address == "jeff")
}

@Test("Mailbox parse addrspec")
func mailboxParseAddrspec() {
    assertParse("jeff@xamarin.com")
}

@Test("Mailbox parse mailbox")
func mailboxParseMailbox() {
    assertParse("Jeffrey Stedfast <jestedfa@microsoft.com>")
}

@Test("Mailbox parse with unquoted comma and dot")
func mailboxParseUnquotedCommaDot() {
    assertParse("Warren Worthington, Jr. <warren@worthington.com>")
}

@Test("Mailbox parse with unquoted comma in name")
func mailboxParseUnquotedCommaInName() {
    let text = "Worthington, Warren <warren@worthington.com>"
    assertParse(text)

    let mailbox = try? MailboxAddress(parsing: text)
    #expect(mailbox?.name == "Worthington, Warren")

    var options = ParserOptions.default
    options.allowUnquotedCommasInAddresses = false
    options.allowAddressesWithoutDomain = false

    do {
        _ = try MailboxAddress(parsing: text, options: options)
        #expect(Bool(false))
    } catch let error as ParseException {
        #expect(error.tokenIndex == 0)
        #expect(error.errorIndex == text.firstIndex(of: ",")?.utf16Offset(in: text))
    } catch {
        #expect(Bool(false))
    }
}

@Test("Mailbox parse with open angle space")
func mailboxParseOpenAngleSpace() {
    assertParse("Jeffrey Stedfast < jeff@xamarin.com>")
}

@Test("Mailbox parse with close angle space")
func mailboxParseCloseAngleSpace() {
    assertParse("Jeffrey Stedfast <jeff@xamarin.com >")
}

@Test("Mailbox parse incomplete route")
func mailboxParseIncompleteRoute() {
    let text = "Skye <@"
    assertParseFailure(text, result: false, tokenIndex: 0, errorIndex: text.count)
}

@Test("Mailbox parse missing colon after route")
func mailboxParseMissingColonAfterRoute() {
    let text = "Skye <@hackers.com,@shield.gov"
    assertParseFailure(text, result: false, tokenIndex: 0, errorIndex: text.count)
}

@Test("Mailbox parse multiple mailboxes")
func mailboxParseMultipleMailboxes() {
    let text = "Skye <skye@shield.gov>, Leo Fitz <fitz@shield.gov>, Melinda May <may@shield.gov>"
    let index = text.firstIndex(of: ",")?.utf16Offset(in: text) ?? 0
    assertParseFailure(text, result: false, tokenIndex: index, errorIndex: index)
}

@Test("Mailbox parse group")
func mailboxParseGroup() {
    let text = "Agents of Shield: Skye <skye@shield.gov>, Leo Fitz <fitz@shield.gov>, Melinda May <may@shield.gov>;"
    let errorIndex = text.firstIndex(of: ":")?.utf16Offset(in: text) ?? 0
    assertParseFailure(text, result: false, tokenIndex: 0, errorIndex: errorIndex)
}

@Test("Mailbox parse incomplete group")
func mailboxParseIncompleteGroup() {
    let text = "Agents of Shield: Skye <skye@shield.gov>, Leo Fitz <fitz@shield.gov>, Melinda May <may@shield.gov>"
    let errorIndex = text.firstIndex(of: ":")?.utf16Offset(in: text) ?? 0
    assertParseFailure(text, result: false, tokenIndex: 0, errorIndex: errorIndex)
}

@Test("Mailbox parse group name colon")
func mailboxParseGroupNameColon() {
    let text = "Agents of Shield:"
    let errorIndex = text.firstIndex(of: ":")?.utf16Offset(in: text) ?? 0
    assertParseFailure(text, result: false, tokenIndex: 0, errorIndex: errorIndex)
}

@Test("Mailbox getAddress IDN encoding")
func mailboxGetAddressIdn() {
    let idn = MailboxAddress.idnMapping
    var mailbox = MailboxAddress(name: "Unit Test", address: "點看@domain.com")
    #expect(mailbox.getAddress(false) == "點看@domain.com")
    #expect(mailbox.getAddress(true) == "點看@domain.com")

    mailbox = MailboxAddress(name: "Unit Test", address: "user@名がドメイン.com")
    #expect(mailbox.getAddress(false) == "user@名がドメイン.com")
    #expect(mailbox.getAddress(true) == "user@" + idn.encode("名がドメイン.com"))

    mailbox = MailboxAddress(name: "Unit Test", address: "user@" + idn.encode("名がドメイン.com"))
    #expect(mailbox.getAddress(false) == "user@名がドメイン.com")
    #expect(mailbox.getAddress(true) == "user@" + idn.encode("名がドメイン.com"))

    mailbox = MailboxAddress(name: "Unit Test", address: "點看@名がドメイン.com")
    #expect(mailbox.getAddress(false) == "點看@名がドメイン.com")
    #expect(mailbox.getAddress(true) == "點看@" + idn.encode("名がドメイン.com"))

    mailbox = MailboxAddress(name: "Unit Test", address: "點看@" + idn.encode("名がドメイン.com"))
    #expect(mailbox.getAddress(false) == "點看@名がドメイン.com")
    #expect(mailbox.getAddress(true) == "點看@" + idn.encode("名がドメイン.com"))
}

@Test("Mailbox isInternational")
func mailboxIsInternational() {
    var options = FormatOptions.default
    options.international = true
    let idn = MailboxAddress.idnMapping

    var mailbox = MailboxAddress(name: "Unit Test", address: "點看@domain.com")
    #expect(mailbox.isInternational)
    #expect(mailbox.formatted(with: options, encoded: true) == "Unit Test <點看@domain.com>")

    mailbox = MailboxAddress(name: "Unit Test", address: "user@名がドメイン.com")
    #expect(mailbox.isInternational)
    #expect(mailbox.formatted(with: options, encoded: true) == "Unit Test <user@名がドメイン.com>")

    mailbox = MailboxAddress(name: "Unit Test", address: "user@" + idn.encode("名がドメイン.com"))
    #expect(mailbox.isInternational)
    #expect(mailbox.formatted(with: options, encoded: true) == "Unit Test <user@名がドメイン.com>")

    mailbox = MailboxAddress(name: "Unit Test", address: "user@domain.com")
    #expect(mailbox.isInternational == false)
    mailbox.route.add("route1")
    mailbox.route.add("名がドメイン.com")
    #expect(mailbox.isInternational)
    #expect(mailbox.formatted(with: options, encoded: true) == "Unit Test <@route1,@名がドメイン.com:user@domain.com>")
}

@Test("Mailbox IDN encoding helpers")
func mailboxIdnEncodingHelpers() {
    let domainAscii = "user@xn--v8jxj3d1dzdz08w.com"
    let domainUnicode = "user@名がドメイン.com"

    #expect(MailboxAddress.encodeAddrspec("") == "")
    #expect(MailboxAddress.decodeAddrspec("") == "")

    #expect(MailboxAddress.encodeAddrspec(domainUnicode) == domainAscii)
    #expect(MailboxAddress.decodeAddrspec(domainAscii) == domainUnicode)

    var mailbox = MailboxAddress(name: "", address: domainAscii)
    #expect(mailbox.getAddress(true) == domainAscii)
    #expect(mailbox.getAddress(false) == domainUnicode)

    mailbox = MailboxAddress(name: "", address: domainUnicode)
    #expect(mailbox.getAddress(true) == domainAscii)
    #expect(mailbox.getAddress(false) == domainUnicode)
}

@Test("Mailbox routed address")
func mailboxRoutedAddress() {
    let expected = "Rusty McRouterson\n\t<@comcast.net,@forward.com,@geek.net:rusty@final-destination.com>"
    let expectedNoName = "<@comcast.net,@forward.com,@geek.net:rusty@final-destination.com>"
    let mailbox = MailboxAddress(name: "Rusty McRouterson", address: "rusty@final-destination.com")
    mailbox.route.add("comcast.net")
    mailbox.route.add("forward.com")
    mailbox.route.add("geek.net")

    #expect(mailbox.formatted(with: FormatOptions.default, encoded: true).replacingOccurrences(of: "\r\n", with: "\n") == expected)

    assertParse(expected)

    mailbox.name = nil
    #expect(mailbox.formatted(with: FormatOptions.default, encoded: true) == expectedNoName)
    #expect(mailbox.formatted(with: FormatOptions.default, encoded: false) == expectedNoName)
}

@Test("Mailbox international routed address")
func mailboxInternationalRoutedAddress() {
    let expectedIdn = "User Name <@route,@xn--@-216a8b89fj88ctw7c.xn--lhr59c:user@domain.com>"
    let expected = "User Name <@route,@伊昭傑@郵件.商務:user@domain.com>"
    let route = ["route", "伊昭傑@郵件.商務"]
    let mailbox = MailboxAddress(name: "User Name", route: route, address: "user@domain.com")
    var options = FormatOptions.default

    #expect(mailbox.formatted(with: options, encoded: true) == expectedIdn)

    options.international = true
    #expect(mailbox.formatted(with: options, encoded: true) == expected)
}

@Test("Mailbox excessive angle brackets")
func mailboxExcessiveAngleBrackets() {
    let text = "<<<user2@example.org>>>"
    let example1 = "User 2 <<<user2@example.org>"
    let example2 = "User 2 <user2@example.org>>>"

    assertParse(text)

    assertParseFailure(example1, result: false, tokenIndex: 0, errorIndex: (example1.firstIndex(of: "<")?.utf16Offset(in: example1) ?? 0) + 1, mode: .strict)
    assertParseFailure(example2, result: false, tokenIndex: 0, errorIndex: (example2.firstIndex(of: ">")?.utf16Offset(in: example2) ?? 0) + 1, mode: .strict)
}

@Test("Mailbox missing greater-than")
func mailboxMissingGreaterThan() {
    let text = "<another@example.net"
    assertParse(text)
    assertParseFailure(text, result: false, tokenIndex: 0, errorIndex: text.count, mode: .strict)
}

@Test("Mailbox missing less-than")
func mailboxMissingLessThan() {
    let text = "second@example.org>"
    assertParse(text)
    assertParseFailure(text, result: false, tokenIndex: 0, errorIndex: text.count - 1, mode: .strict)
}

@Test("Mailbox unbalanced quotes")
func mailboxUnbalancedQuotes() {
    let text = "\"Joe <joe@example.com>"
    assertParse(text)
    assertParseFailure(text, result: false, tokenIndex: 0, errorIndex: text.count, mode: .strict)
    assertParseFailure(" \"", result: false, tokenIndex: 1, errorIndex: 2, mode: .loose)
}

@Test("Mailbox addrspec as unquoted name")
func mailboxAddrspecAsUnquotedName() {
    let text = "user@example.com <user@example.com>"
    let errorIndex = text.firstIndex(of: "<")?.utf16Offset(in: text) ?? 0
    assertParse(text)
    assertParseFailure(text, result: false, tokenIndex: 0, errorIndex: errorIndex, mode: .strict)
}

@Test("Mailbox Latin1 addrspec loose")
func mailboxLatin1AddrspecLoose() {
    let text = "Name <æøå@example.com>"
    let buffer = CharsetUtils.getBytes(text, encoding: .isoLatin1)
    #expect((try? MailboxAddress(parsing: buffer)) != nil)
}

@Test("Mailbox Latin1 addrspec strict")
func mailboxLatin1AddrspecStrict() {
    let text = "Name <æøå@example.com>"
    let buffer = CharsetUtils.getBytes(text, encoding: .isoLatin1)
    var options = ParserOptions.default
    options.addressParserComplianceMode = .strict

    #expect((try? MailboxAddress(parsing: buffer, options: options)) == nil)

    do {
        _ = try MailboxAddress(parsing: buffer, options: options)
        #expect(Bool(false))
    } catch let error as ParseException {
        #expect(error.tokenIndex == 6)
        #expect(error.errorIndex == 6)
    } catch {
        #expect(Bool(false))
    }
}

@Test("Mailbox square brackets in display name")
func mailboxSquareBracketsInDisplayName() {
    let text = "[Invalid Sender] <sender@tk2-201-10422.vs.sakura.ne.jp>"
    assertParse(text)
    assertParseFailure(text, result: false, tokenIndex: 0, errorIndex: 0, mode: .strict)
}

@Test("Mailbox square brackets and 8-bit display name")
func mailboxSquareBracketsAnd8BitDisplayName() {
    let text = "Tom Doe [Cörp Öne] <tom.doe@corpone.com>"
    assertParse(text)
    assertParseFailure(text, result: false, tokenIndex: 0, errorIndex: 8, mode: .strict)
}

@Test("Mailbox addrspec unicode local-part")
func mailboxAddrspecUnicodeLocalPart() {
    assertParse("test.täst@test.net")
}

@Test("Mailbox addrspec zero-width space")
func mailboxAddrspecZeroWidthSpace() {
    assertParse("\u{200B}test@test.co.uk")
}

@Test("Mailbox addrspec ending with dot")
func mailboxAddrspecEndingWithDot() {
    let text = "test.@gmail.com"
    assertParse(text, mode: .looser)
    assertParseFailure(text, result: false, tokenIndex: 0, errorIndex: 5, mode: .loose)
    assertParseFailure(text, result: false, tokenIndex: 0, errorIndex: 5, mode: .strict)
}

@Test("Mailbox addrspec ending with dot dot")
func mailboxAddrspecEndingWithDotDot() {
    let text = "test..@gmail.com"
    assertParse(text, mode: .looser)
    assertParseFailure(text, result: false, tokenIndex: 0, errorIndex: 5, mode: .loose)
    assertParseFailure(text, result: false, tokenIndex: 0, errorIndex: 5, mode: .strict)
}

@Test("Mailbox addrspec with dot dot")
func mailboxAddrspecWithDotDot() {
    let text = "test..test@gmail.com"
    assertParse(text, mode: .looser)
    assertParseFailure(text, result: false, tokenIndex: 0, errorIndex: 5, mode: .loose)
    assertParseFailure(text, result: false, tokenIndex: 0, errorIndex: 5, mode: .strict)
}
