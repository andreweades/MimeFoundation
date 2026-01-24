//
// GroupAddressTests.swift
//

import Testing
import MimeFoundation

private func assertParseFailure(_ text: String, result: Bool, tokenIndex: Int, errorIndex: Int) {
    let buffer = text.isEmpty ? [UInt8](repeating: 0, count: 1) : CharsetUtils.getBytes(text, encoding: .utf8)
    var group: GroupAddress? = nil

    #expect(GroupAddress.tryParse(text, group: &group) == result)
    #expect(GroupAddress.tryParse(buffer, group: &group) == result)
    #expect(GroupAddress.tryParse(buffer, startIndex: 0, group: &group) == result)
    #expect(GroupAddress.tryParse(buffer, startIndex: 0, length: buffer.count, group: &group) == result)

    do {
        _ = try GroupAddress.parse(text)
        #expect(Bool(false))
    } catch let error as ParseException {
        #expect(error.tokenIndex == tokenIndex)
        #expect(error.errorIndex == errorIndex)
    } catch {
        #expect(Bool(false))
    }

    do {
        _ = try GroupAddress.parse(buffer)
        #expect(Bool(false))
    } catch let error as ParseException {
        #expect(error.tokenIndex == tokenIndex)
        #expect(error.errorIndex == errorIndex)
    } catch {
        #expect(Bool(false))
    }

    do {
        _ = try GroupAddress.parse(buffer, startIndex: 0)
        #expect(Bool(false))
    } catch let error as ParseException {
        #expect(error.tokenIndex == tokenIndex)
        #expect(error.errorIndex == errorIndex)
    } catch {
        #expect(Bool(false))
    }

    do {
        _ = try GroupAddress.parse(buffer, startIndex: 0, length: buffer.count)
        #expect(Bool(false))
    } catch let error as ParseException {
        #expect(error.tokenIndex == tokenIndex)
        #expect(error.errorIndex == errorIndex)
    } catch {
        #expect(Bool(false))
    }
}

private func assertParse(_ text: String) {
    let buffer = CharsetUtils.getBytes(text, encoding: .utf8)
    var group: GroupAddress? = nil

    #expect(GroupAddress.tryParse(text, group: &group))
    #expect(GroupAddress.tryParse(buffer, group: &group))
    #expect(GroupAddress.tryParse(buffer, startIndex: 0, group: &group))
    #expect(GroupAddress.tryParse(buffer, startIndex: 0, length: buffer.count, group: &group))

    #expect((try? GroupAddress.parse(text)) != nil)
    #expect((try? GroupAddress.parse(buffer)) != nil)
    #expect((try? GroupAddress.parse(buffer, startIndex: 0)) != nil)
    #expect((try? GroupAddress.parse(buffer, startIndex: 0, length: buffer.count)) != nil)
}

@Test("Group clone")
func groupClone() {
    let encoded = "Group Name: First Name <first@address.com>, Second Name <second@address.com>,\n Inner Group Name: First Inner Name <first-inner@address.com>,\n Second Inner Name <second-inner@address.com>;, Third Name <third@address.com>;"
    var options = FormatOptions.default
    options.newLineFormat = .unix
    options.international = true

    let inner = GroupAddress(name: "Inner Group Name")
    inner.members.add(MailboxAddress(name: "First Inner Name", address: "first-inner@address.com"))
    inner.members.add(MailboxAddress(name: "Second Inner Name", address: "second-inner@address.com"))

    let group = GroupAddress(name: "Group Name")
    group.members.add(MailboxAddress(name: "First Name", address: "first@address.com"))
    group.members.add(MailboxAddress(name: "Second Name", address: "second@address.com"))
    group.members.add(inner)
    group.members.add(MailboxAddress(name: "Third Name", address: "third@address.com"))

    let clone = group.clone()
    #expect(group.compareTo(clone) == 0)

    let actual = clone.toString(options, encode: true)
    #expect(actual == encoded)
}

@Test("Group parse empty")
func groupParseEmpty() {
    assertParseFailure("", result: false, tokenIndex: 0, errorIndex: 0)
}

@Test("Group parse whitespace")
func groupParseWhiteSpace() {
    let text = " \t\r\n"
    let length = text.utf8.count
    assertParseFailure(text, result: false, tokenIndex: length, errorIndex: length)
}

@Test("Group parse name less-than")
func groupParseNameLessThan() {
    let text = "Name <"
    let errorIndex = text.firstIndex(of: "<")?.utf16Offset(in: text) ?? 0
    assertParseFailure(text, result: false, tokenIndex: 0, errorIndex: errorIndex)
}

@Test("Group parse mailbox with empty domain")
func groupParseMailboxEmptyDomain() {
    let text = "jeff@"
    let errorIndex = text.firstIndex(of: "@")?.utf16Offset(in: text) ?? 0
    assertParseFailure(text, result: false, tokenIndex: 0, errorIndex: errorIndex)
}

@Test("Group parse mailbox with incomplete local-part")
func groupParseMailboxIncompleteLocalPart() {
    let text = "jeff."
    assertParseFailure(text, result: false, tokenIndex: 0, errorIndex: text.count)
}

@Test("Group parse incomplete quoted string")
func groupParseIncompleteQuotedString() {
    let text = "\"This quoted string never ends... oh no!"
    assertParseFailure(text, result: false, tokenIndex: 0, errorIndex: text.count)
}

@Test("Group parse mailbox with incomplete comment after name")
func groupParseIncompleteCommentAfterName() {
    let text = "Name (incomplete comment"
    let tokenIndex = text.firstIndex(of: "(")?.utf16Offset(in: text) ?? 0
    assertParseFailure(text, result: false, tokenIndex: tokenIndex, errorIndex: text.count)
}

@Test("Group parse mailbox with incomplete comment after addrspec")
func groupParseIncompleteCommentAfterAddrspec() {
    let text = "jeff@xamarin.com (incomplete comment"
    let errorIndex = text.firstIndex(of: "@")?.utf16Offset(in: text) ?? 0
    assertParseFailure(text, result: false, tokenIndex: 0, errorIndex: errorIndex)
}

@Test("Group parse mailbox with incomplete comment after address")
func groupParseIncompleteCommentAfterAddress() {
    let text = "<jeff@xamarin.com> (incomplete comment"
    assertParseFailure(text, result: false, tokenIndex: 0, errorIndex: 0)
}

@Test("Group parse incomplete addrspec")
func groupParseIncompleteAddrspec() {
    let text = "jeff@ (comment)"
    let errorIndex = text.firstIndex(of: "@")?.utf16Offset(in: text) ?? 0
    assertParseFailure(text, result: false, tokenIndex: 0, errorIndex: errorIndex)
}

@Test("Group parse addrspec without domain")
func groupParseAddrspecNoDomain() {
    let text = "jeff"
    assertParseFailure(text, result: false, tokenIndex: 0, errorIndex: text.count)
}

@Test("Group parse addrspec")
func groupParseAddrspec() {
    let text = "jeff@xamarin.com"
    let errorIndex = text.firstIndex(of: "@")?.utf16Offset(in: text) ?? 0
    assertParseFailure(text, result: false, tokenIndex: 0, errorIndex: errorIndex)
}

@Test("Group parse mailbox")
func groupParseMailbox() {
    let text = "Jeffrey Stedfast <jestedfa@microsoft.com>"
    let errorIndex = text.firstIndex(of: "<")?.utf16Offset(in: text) ?? 0
    assertParseFailure(text, result: false, tokenIndex: 0, errorIndex: errorIndex)
}

@Test("Group parse mailbox with unquoted comma and dot in name")
func groupParseMailboxWithUnquotedCommaAndDotInName() {
    let text = "Warren Worthington, Jr. <warren@worthington.com>"
    let errorIndex = text.firstIndex(of: "<")?.utf16Offset(in: text) ?? 0
    assertParseFailure(text, result: false, tokenIndex: 0, errorIndex: errorIndex)
}

@Test("Group parse mailbox with open angle space")
func groupParseMailboxWithOpenAngleSpace() {
    let text = "Jeffrey Stedfast < jeff@xamarin.com>"
    let errorIndex = text.firstIndex(of: "<")?.utf16Offset(in: text) ?? 0
    assertParseFailure(text, result: false, tokenIndex: 0, errorIndex: errorIndex)
}

@Test("Group parse mailbox with close angle space")
func groupParseMailboxWithCloseAngleSpace() {
    let text = "Jeffrey Stedfast <jeff@xamarin.com >"
    let errorIndex = text.firstIndex(of: "<")?.utf16Offset(in: text) ?? 0
    assertParseFailure(text, result: false, tokenIndex: 0, errorIndex: errorIndex)
}

@Test("Group parse mailbox with incomplete route")
func groupParseMailboxWithIncompleteRoute() {
    let text = "Skye <@"
    let errorIndex = text.firstIndex(of: "<")?.utf16Offset(in: text) ?? 0
    assertParseFailure(text, result: false, tokenIndex: 0, errorIndex: errorIndex)
}

@Test("Group parse mailbox without colon after route")
func groupParseMailboxWithoutColonAfterRoute() {
    let text = "Skye <@hackers.com,@shield.gov"
    let errorIndex = text.firstIndex(of: "<")?.utf16Offset(in: text) ?? 0
    assertParseFailure(text, result: false, tokenIndex: 0, errorIndex: errorIndex)
}

@Test("Group parse group")
func groupParseGroup() {
    let text = "Agents of Shield: Skye <skye@shield.gov>, Leo Fitz <fitz@shield.gov>, Melinda May <may@shield.gov>;"
    assertParse(text)
}

@Test("Group parse incomplete group")
func groupParseIncompleteGroup() {
    let text = "Agents of Shield: Skye <skye@shield.gov>, Leo Fitz <fitz@shield.gov>, Melinda May <may@shield.gov>"
    assertParse(text)
}

@Test("Group parse group name colon")
func groupParseGroupNameColon() {
    let text = "Agents of Shield:"
    let length = text.utf8.count
    assertParseFailure(text, result: true, tokenIndex: length, errorIndex: length)
}

@Test("Group parse group and mailbox")
func groupParseGroupAndMailbox() {
    let text = "Agents of Shield: Skye <skye@shield.gov>, Leo Fitz <fitz@shield.gov>, May <may@shield.gov>;, Fury <fury@shield.gov>"
    let tokenIndex = (text.firstIndex(of: ";")?.utf16Offset(in: text) ?? 0) + 1
    assertParseFailure(text, result: false, tokenIndex: tokenIndex, errorIndex: tokenIndex)
}

@Test("Group default max group depth overflow")
func groupDefaultMaxGroupDepthOverflow() {
    let overflow = "group0: group1: group2: group3: milbox@host.com;;;;"
    let safe = "group0: group1: group2: milbox@host.com;;;"

    assertParse(safe)
    assertParseFailure(overflow, result: false, tokenIndex: 24, errorIndex: 30)
}
