//
// InternetAddressTests.swift
//

import Testing
import MimeFoundation

private func assertAddressParseFailure(_ text: String, result: Bool, tokenIndex: Int, errorIndex: Int) {
    let buffer = text.isEmpty ? [UInt8](repeating: 0, count: 1) : CharsetUtils.getBytes(text, encoding: .utf8)

    #expect(((try? InternetAddress.parsed(from: text)) != nil) == result)
    #expect(((try? InternetAddress.parsed(from: buffer)) != nil) == result)

    // Only check for exceptions when parsing is expected to fail
    if !result {
        do {
            _ = try InternetAddress.parsed(from: text)
            #expect(Bool(false))
        } catch let error as ParseException {
            #expect(error.tokenIndex == tokenIndex)
            #expect(error.errorIndex == errorIndex)
        } catch {
            #expect(Bool(false))
        }

        do {
            _ = try InternetAddress.parsed(from: buffer)
            #expect(Bool(false))
        } catch let error as ParseException {
            #expect(error.tokenIndex == tokenIndex)
            #expect(error.errorIndex == errorIndex)
        } catch {
            #expect(Bool(false))
        }
    }
}

private func assertAddressParse(_ text: String) {
    let buffer = CharsetUtils.getBytes(text, encoding: .utf8)

    #expect((try? InternetAddress.parsed(from: text)) != nil)
    #expect((try? InternetAddress.parsed(from: buffer)) != nil)
}

@Test("InternetAddress parse empty")
func internetAddressParseEmpty() {
    assertAddressParseFailure("", result: false, tokenIndex: 0, errorIndex: 0)
}

@Test("InternetAddress parse whitespace")
func internetAddressParseWhiteSpace() {
    let text = " \t\r\n"
    let length = text.utf8.count
    assertAddressParseFailure(text, result: false, tokenIndex: length, errorIndex: length)
}

@Test("InternetAddress parse name less-than")
func internetAddressParseNameLessThan() {
    let text = "Name <"
    assertAddressParseFailure(text, result: false, tokenIndex: 0, errorIndex: text.count)
}

@Test("InternetAddress parse mailbox with empty domain")
func internetAddressParseMailboxEmptyDomain() {
    let text = "jeff@"
    assertAddressParseFailure(text, result: false, tokenIndex: 0, errorIndex: text.count)
}

@Test("InternetAddress parse mailbox with incomplete local-part")
func internetAddressParseMailboxIncompleteLocalPart() {
    let text = "jeff."
    assertAddressParseFailure(text, result: false, tokenIndex: 0, errorIndex: text.count)
}

@Test("InternetAddress parse incomplete quoted string")
func internetAddressParseIncompleteQuotedString() {
    let text = "\"This quoted string never ends... oh no!"
    assertAddressParseFailure(text, result: false, tokenIndex: 0, errorIndex: text.count)
}

@Test("InternetAddress parse incomplete comment after name")
func internetAddressParseIncompleteCommentAfterName() {
    let text = "Name (incomplete comment"
    let tokenIndex = text.firstIndex(of: "(")?.utf16Offset(in: text) ?? 0
    assertAddressParseFailure(text, result: false, tokenIndex: tokenIndex, errorIndex: text.count)
}

@Test("InternetAddress parse incomplete comment after addrspec")
func internetAddressParseIncompleteCommentAfterAddrspec() {
    let text = "jeff@xamarin.com (incomplete comment"
    let tokenIndex = text.firstIndex(of: "(")?.utf16Offset(in: text) ?? 0
    assertAddressParseFailure(text, result: false, tokenIndex: tokenIndex, errorIndex: text.count)
}

@Test("InternetAddress parse incomplete comment after domain literal")
func internetAddressParseIncompleteCommentAfterDomainLiteral() {
    let text = "jeff@[127.0.0.1] (incomplete comment"
    let tokenIndex = text.firstIndex(of: "(")?.utf16Offset(in: text) ?? 0
    assertAddressParseFailure(text, result: false, tokenIndex: tokenIndex, errorIndex: text.count)
}

@Test("InternetAddress parse incomplete comment after address")
func internetAddressParseIncompleteCommentAfterAddress() {
    let text = "<jeff@xamarin.com> (incomplete comment"
    let tokenIndex = text.firstIndex(of: "(")?.utf16Offset(in: text) ?? 0
    assertAddressParseFailure(text, result: false, tokenIndex: tokenIndex, errorIndex: text.count)
}

@Test("InternetAddress parse incomplete addrspec")
func internetAddressParseIncompleteAddrspec() {
    let text = "jeff@ (comment)"
    assertAddressParseFailure(text, result: false, tokenIndex: 0, errorIndex: text.count)
}

@Test("InternetAddress parse incomplete routed mailbox at")
func internetAddressParseIncompleteRoutedMailboxAt() {
    let text = "Name <@"
    assertAddressParseFailure(text, result: false, tokenIndex: 0, errorIndex: text.count)
}

@Test("InternetAddress parse incomplete routed mailbox")
func internetAddressParseIncompleteRoutedMailbox() {
    let text = "Name <@route:"
    assertAddressParseFailure(text, result: false, tokenIndex: 0, errorIndex: text.count)
}

@Test("InternetAddress parse incomplete routed mailbox space")
func internetAddressParseIncompleteRoutedMailboxSpace() {
    let text = "Name <@route: "
    assertAddressParseFailure(text, result: false, tokenIndex: 0, errorIndex: text.count)
}

@Test("InternetAddress parse incomplete comment in route")
func internetAddressParseIncompleteCommentInRoute() {
    let text = "Name <@route,(comment"
    assertAddressParseFailure(text, result: false, tokenIndex: 0, errorIndex: text.count)
}

@Test("InternetAddress parse invalid route in mailbox")
func internetAddressParseInvalidRouteInMailbox() {
    let text = "Name <@route,invalid:user@example.com>"
    let errorIndex = (text.firstIndex(of: ",")?.utf16Offset(in: text) ?? 0) + 1
    assertAddressParseFailure(text, result: false, tokenIndex: 0, errorIndex: errorIndex)
}

@Test("InternetAddress parse mailbox with international route")
func internetAddressParseMailboxWithInternationalRoute() {
    let text = "User Name <@route,@伊昭傑@郵件.商務:user@domain.com>"
    assertAddressParse(text)
}

@Test("InternetAddress parse addrspec without domain")
func internetAddressParseAddrspecNoDomain() {
    assertAddressParse("jeff")
}

@Test("InternetAddress parse addrspec without domain greater-than")
func internetAddressParseAddrspecNoDomainGreaterThan() {
    assertAddressParse("jeff>")
}

@Test("InternetAddress parse addrspec without domain with incomplete comment")
func internetAddressParseAddrspecNoDomainWithIncompleteComment() {
    let text = "jeff (Jeffrey Stedfast"
    assertAddressParseFailure(text, result: false, tokenIndex: 5, errorIndex: text.count)
}

@Test("InternetAddress parse addrspec without domain with comment")
func internetAddressParseAddrspecNoDomainWithComment() {
    let text = "jeff (Jeffrey Stedfast)"
    assertAddressParse(text)
    let mailbox = try? MailboxAddress(parsing: text)
    #expect(mailbox?.name == "Jeffrey Stedfast")
    #expect(mailbox?.address == "jeff")
}

@Test("InternetAddress parse addrspec")
func internetAddressParseAddrspec() {
    assertAddressParse("jeff@xamarin.com")
}

@Test("InternetAddress parse mailbox")
func internetAddressParseMailbox() {
    assertAddressParse("Jeffrey Stedfast <jestedfa@microsoft.com>")
}

@Test("InternetAddress parse mailbox with unquoted comma and dot")
func internetAddressParseMailboxWithUnquotedCommaAndDot() {
    assertAddressParse("Warren Worthington, Jr. <warren@worthington.com>")
}

@Test("InternetAddress parse mailbox with unquoted comma in name")
func internetAddressParseMailboxWithUnquotedCommaInName() {
    let text = "Worthington, Warren <warren@worthington.com>"
    assertAddressParse(text)

    let addr = try? InternetAddress.parsed(from: text)
    #expect(addr?.name == "Worthington, Warren")

    var options = ParserOptions.default
    options.allowUnquotedCommasInAddresses = false
    options.allowAddressesWithoutDomain = false

    do {
        _ = try InternetAddress.parsed(from: text, options: options)
        #expect(Bool(false))
    } catch let error as ParseException {
        #expect(error.tokenIndex == 0)
        #expect(error.errorIndex == text.firstIndex(of: ",")?.utf16Offset(in: text))
    } catch {
        #expect(Bool(false))
    }
}

@Test("InternetAddress strict disallow unquoted commas in name")
func internetAddressStrictDisallowUnquotedCommas() {
    let input = "Cut the fat, today <5aOJlOFqZs@eachuniverse.host>"
    var options = ParserOptions.default
    options.addressParserComplianceMode = .strict
    options.allowAddressesWithoutDomain = false
    options.allowUnquotedCommasInAddresses = false
    options.rfc2047ComplianceMode = .strict

    #expect((try? InternetAddressList(parsing: input, options: options)) == nil)
}

@Test("InternetAddress parse mailbox with open angle space")
func internetAddressParseMailboxWithOpenAngleSpace() {
    assertAddressParse("Jeffrey Stedfast < jeff@xamarin.com>")
}

@Test("InternetAddress parse mailbox with close angle space")
func internetAddressParseMailboxWithCloseAngleSpace() {
    assertAddressParse("Jeffrey Stedfast <jeff@xamarin.com >")
}

@Test("InternetAddress parse mailbox with incomplete route")
func internetAddressParseMailboxWithIncompleteRoute() {
    let text = "Skye <@"
    assertAddressParseFailure(text, result: false, tokenIndex: 0, errorIndex: text.count)
}

@Test("InternetAddress parse mailbox without colon after route")
func internetAddressParseMailboxWithoutColonAfterRoute() {
    let text = "Skye <@hackers.com,@shield.gov"
    assertAddressParseFailure(text, result: false, tokenIndex: 0, errorIndex: text.count)
}

@Test("InternetAddress parse multiple mailboxes")
func internetAddressParseMultipleMailboxes() {
    let text = "Skye <skye@shield.gov>, Leo Fitz <fitz@shield.gov>, Melinda May <may@shield.gov>"
    let index = text.firstIndex(of: ",")?.utf16Offset(in: text) ?? 0
    assertAddressParseFailure(text, result: false, tokenIndex: index, errorIndex: index)
}

@Test("InternetAddress parse group")
func internetAddressParseGroup() {
    let text = "Agents of Shield: Skye <skye@shield.gov>, Leo Fitz <fitz@shield.gov>, Melinda May <may@shield.gov>;"
    assertAddressParse(text)
}

@Test("InternetAddress parse incomplete group")
func internetAddressParseIncompleteGroup() {
    let text = "Agents of Shield: Skye <skye@shield.gov>, Leo Fitz <fitz@shield.gov>, May <may@shield.gov>"
    assertAddressParse(text)
}

@Test("InternetAddress parse group name colon")
func internetAddressParseGroupNameColon() {
    let text = "Agents of Shield:"
    let length = text.utf8.count
    assertAddressParseFailure(text, result: true, tokenIndex: length, errorIndex: length)
}

@Test("InternetAddress parse group and mailbox")
func internetAddressParseGroupAndMailbox() {
    let text = "Agents of Shield: Skye <skye@shield.gov>, Leo Fitz <fitz@shield.gov>, May <may@shield.gov>;, Fury <fury@shield.gov>"
    let tokenIndex = (text.firstIndex(of: ";")?.utf16Offset(in: text) ?? 0) + 1
    assertAddressParseFailure(text, result: false, tokenIndex: tokenIndex, errorIndex: tokenIndex)
}

@Test("InternetAddress parse excessive angle brackets")
func internetAddressParseExcessiveAngleBrackets() {
    assertAddressParse("<<<user2@example.org>>>")
}

@Test("InternetAddress parse missing greater-than")
func internetAddressParseMissingGreaterThan() {
    assertAddressParse("<another@example.net")
}

@Test("InternetAddress parse missing less-than")
func internetAddressParseMissingLessThan() {
    assertAddressParse("second@example.org>")
}

@Test("InternetAddress parse unbalanced quotes")
func internetAddressParseUnbalancedQuotes() {
    assertAddressParse("\"Joe <joe@example.com>")
}

@Test("InternetAddress parse addrspec as unquoted name")
func internetAddressParseAddrspecAsUnquotedName() {
    assertAddressParse("user@example.com <user@example.com>")
}

@Test("InternetAddress parse mailbox with square brackets in display name")
func internetAddressParseMailboxWithSquareBrackets() {
    assertAddressParse("[Invalid Sender] <sender@tk2-201-10422.vs.sakura.ne.jp>")
}
