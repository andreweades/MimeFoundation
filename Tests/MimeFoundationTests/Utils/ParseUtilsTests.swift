//
// ParseUtilsTests.swift
//

import Foundation
import Testing
@testable import MimeFoundation

@Test("ParseUtils try parse int32")
func parseUtilsTryParseInt32() {
    var index = 0
    var value = 0
    var buffer = Array(String(Int32.max).utf8)

    #expect(ParseUtils.tryParseInt32(buffer, index: &index, endIndex: buffer.count, value: &value) == true)
    #expect(value == Int(Int32.max))

    buffer = Array(String(Int64(Int32.max) + 1).utf8)
    index = 0
    #expect(ParseUtils.tryParseInt32(buffer, index: &index, endIndex: buffer.count, value: &value) == false)

    buffer = Array(String(Int64(Int32.max) * 10).utf8)
    index = 0
    #expect(ParseUtils.tryParseInt32(buffer, index: &index, endIndex: buffer.count, value: &value) == false)
}

@Test("ParseUtils skip badly quoted")
func parseUtilsSkipBadlyQuoted() {
    let buffer = Array("\"This is missing the end quote.".utf8)
    var index = 0

    #expect((try? ParseUtils.skipQuoted(buffer, index: &index, endIndex: buffer.count, throwOnError: false)) == false)
    #expect(index == buffer.count)

    index = 0
    do {
        _ = try ParseUtils.skipQuoted(buffer, index: &index, endIndex: buffer.count, throwOnError: true)
        #expect(Bool(false))
    } catch let error as ParseException {
        #expect(error.tokenIndex == 0)
        #expect(error.errorIndex == buffer.count)
    } catch {
        #expect(Bool(false))
    }
}

private let goodDomains: [String] = [
    "[127.0.0.1]", "[127.0.0.1]",
    "amazon (comment) . (comment) com (comment)", "amazon.com",
    "测试文本.cn", "测试文本.cn",
]

@Test("ParseUtils try parse good domains")
func parseUtilsTryParseGoodDomains() {
    let sentinels: [UInt8] = [0x2C]
    var index = 0

    var i = 0
    while i < goodDomains.count {
        let input = goodDomains[i]
        let expected = goodDomains[i + 1]
        let buffer = Array(input.utf8)
        index = 0
        var domain: String? = nil

        #expect((try? ParseUtils.tryParseDomain(buffer, index: &index, endIndex: buffer.count, sentinels: sentinels, throwOnError: false, domain: &domain)) == true)
        #expect(domain == expected)

        i += 2
    }
}

private let badDomains: [String] = [
    "[127.0.0.1",
    "[127\\.0.0.1]",
    "amazon (comment) . (comment com",
    "测试文本.cn",
]

private let badDomainTokenIndexes: [Int] = [0, 0, 19, 0]
private let badDomainErrorIndexes: [Int] = [10, 4, 31, 0]

@Test("ParseUtils try parse bad domains")
func parseUtilsTryParseBadDomains() {
    let sentinels: [UInt8] = [0x2C]

    for i in 0..<badDomains.count {
        var buffer = Array(badDomains[i].utf8)
        var domain: String? = nil
        var index = 0

        if let first = badDomains[i].unicodeScalars.first, first.value > 127 {
            if let encoding = CharsetUtils.getEncoding(codepage: 54936),
               let data = badDomains[i].data(using: encoding) {
                buffer = Array(data)
            } else {
                buffer = [0xFF, 0xFE, 0xFF]
            }
        }

        #expect((try? ParseUtils.tryParseDomain(buffer, index: &index, endIndex: buffer.count, sentinels: sentinels, throwOnError: false, domain: &domain)) == false)

        index = 0
        do {
            _ = try ParseUtils.tryParseDomain(buffer, index: &index, endIndex: buffer.count, sentinels: sentinels, throwOnError: true, domain: &domain)
            #expect(Bool(false))
        } catch let error as ParseException {
            #expect(error.tokenIndex == badDomainTokenIndexes[i])
            #expect(error.errorIndex == badDomainErrorIndexes[i])
        } catch {
            #expect(Bool(false))
        }
    }
}

private let msgIdInputs: [String] = [
    " <Messe_Bauma_rz(1)_ae284449-6bdc-488f-8ec3-5be5e5b09efb.jpg>",
    " Messe_Bauma_rz(1)_ae284449-6bdc-488f-8ec3-5be5e5b09efb.jpg",
    " <15627601.388658.1676916781911.JavaMail.\"xxxxxx@united.com\"@xxxxxxx.ual.com>"
]

private let msgIdOutputs: [String] = [
    "Messe_Bauma_rz(1)_ae284449-6bdc-488f-8ec3-5be5e5b09efb.jpg",
    "Messe_Bauma_rz(1)_ae284449-6bdc-488f-8ec3-5be5e5b09efb.jpg",
    "15627601.388658.1676916781911.JavaMail.\"xxxxxx@united.com\"@xxxxxxx.ual.com"
]

@Test("ParseUtils try parse msg-id tokens")
func parseUtilsTryParseMsgIdTokens() {
    for i in 0..<msgIdInputs.count {
        let buffer = Array(msgIdInputs[i].utf8)
        var index = 0
        var msgid: String? = nil

        #expect((try? ParseUtils.tryParseMsgId(buffer, index: &index, endIndex: buffer.count, requireAngleAddr: false, throwOnError: false, msgid: &msgid)) == true)
        #expect(msgid == msgIdOutputs[i])
    }
}

@Test("ParseUtils try parse msg-id empty string")
func parseUtilsTryParseMsgIdEmptyString() {
    let buffer = Array(" ".utf8)
    var index = 0
    var msgid: String? = nil

    #expect((try? ParseUtils.tryParseMsgId(buffer, index: &index, endIndex: buffer.count, requireAngleAddr: false, throwOnError: false, msgid: &msgid)) == false)

    index = 0
    do {
        _ = try ParseUtils.tryParseMsgId(buffer, index: &index, endIndex: buffer.count, requireAngleAddr: false, throwOnError: true, msgid: &msgid)
        #expect(Bool(false))
    } catch let error as ParseException {
        #expect(error.tokenIndex == 1)
        #expect(error.errorIndex == 1)
    } catch {
        #expect(Bool(false))
    }
}

@Test("ParseUtils try parse msg-id less than")
func parseUtilsTryParseMsgIdLessThan() {
    let buffer = Array(" <".utf8)
    var index = 0
    var msgid: String? = nil

    #expect((try? ParseUtils.tryParseMsgId(buffer, index: &index, endIndex: buffer.count, requireAngleAddr: false, throwOnError: false, msgid: &msgid)) == false)

    index = 0
    do {
        _ = try ParseUtils.tryParseMsgId(buffer, index: &index, endIndex: buffer.count, requireAngleAddr: false, throwOnError: true, msgid: &msgid)
        #expect(Bool(false))
    } catch let error as ParseException {
        #expect(error.tokenIndex == 1)
        #expect(error.errorIndex == 2)
    } catch {
        #expect(Bool(false))
    }
}

@Test("ParseUtils try parse msg-id less than local part")
func parseUtilsTryParseMsgIdLessThanLocalPart() {
    let buffer = Array(" <local-part".utf8)
    var index = 0
    var msgid: String? = nil

    #expect((try? ParseUtils.tryParseMsgId(buffer, index: &index, endIndex: buffer.count, requireAngleAddr: false, throwOnError: false, msgid: &msgid)) == false)

    index = 0
    do {
        _ = try ParseUtils.tryParseMsgId(buffer, index: &index, endIndex: buffer.count, requireAngleAddr: false, throwOnError: true, msgid: &msgid)
        #expect(Bool(false))
    } catch let error as ParseException {
        #expect(error.tokenIndex == 1)
        #expect(error.errorIndex == 12)
    } catch {
        #expect(Bool(false))
    }
}

@Test("ParseUtils try parse msg-id less than local part dot")
func parseUtilsTryParseMsgIdLessThanLocalPartDot() {
    let buffer = Array(" <local-part.".utf8)
    var index = 0
    var msgid: String? = nil

    #expect((try? ParseUtils.tryParseMsgId(buffer, index: &index, endIndex: buffer.count, requireAngleAddr: false, throwOnError: false, msgid: &msgid)) == false)

    index = 0
    do {
        _ = try ParseUtils.tryParseMsgId(buffer, index: &index, endIndex: buffer.count, requireAngleAddr: false, throwOnError: true, msgid: &msgid)
        #expect(Bool(false))
    } catch let error as ParseException {
        #expect(error.tokenIndex == 1)
        #expect(error.errorIndex == 13)
    } catch {
        #expect(Bool(false))
    }
}

@Test("ParseUtils try parse msg-id less than local part at")
func parseUtilsTryParseMsgIdLessThanLocalPartAt() {
    let buffer = Array(" <local-part@".utf8)
    var index = 0
    var msgid: String? = nil

    #expect((try? ParseUtils.tryParseMsgId(buffer, index: &index, endIndex: buffer.count, requireAngleAddr: false, throwOnError: false, msgid: &msgid)) == false)

    index = 0
    do {
        _ = try ParseUtils.tryParseMsgId(buffer, index: &index, endIndex: buffer.count, requireAngleAddr: false, throwOnError: true, msgid: &msgid)
        #expect(Bool(false))
    } catch let error as ParseException {
        #expect(error.tokenIndex == 1)
        #expect(error.errorIndex == 13)
    } catch {
        #expect(Bool(false))
    }
}

@Test("ParseUtils try parse msg-id less than local part at greater than")
func parseUtilsTryParseMsgIdLessThanLocalPartAtGreaterThan() {
    let buffer = Array(" <local-part@>".utf8)
    var index = 0
    var msgid: String? = nil

    #expect((try? ParseUtils.tryParseMsgId(buffer, index: &index, endIndex: buffer.count, requireAngleAddr: false, throwOnError: false, msgid: &msgid)) == true)
    #expect(msgid == "local-part@")
}

@Test("ParseUtils try parse msg-id less than local part at domain missing greater than")
func parseUtilsTryParseMsgIdLessThanLocalPartAtDomainMissingGreaterThan() {
    let buffer = Array(" <local-part@domain".utf8)
    var index = 0
    var msgid: String? = nil

    #expect((try? ParseUtils.tryParseMsgId(buffer, index: &index, endIndex: buffer.count, requireAngleAddr: false, throwOnError: false, msgid: &msgid)) == false)

    index = 0
    do {
        _ = try ParseUtils.tryParseMsgId(buffer, index: &index, endIndex: buffer.count, requireAngleAddr: false, throwOnError: true, msgid: &msgid)
        #expect(Bool(false))
    } catch let error as ParseException {
        #expect(error.tokenIndex == 1)
        #expect(error.errorIndex == 19)
    } catch {
        #expect(Bool(false))
    }
}

@Test("ParseUtils try parse msg-id invalid quoted local part")
func parseUtilsTryParseMsgIdInvalidQuotedLocalPart() {
    let buffer = Array(" <\"quoted-string@domain>".utf8)
    var index = 0
    var msgid: String? = nil

    #expect((try? ParseUtils.tryParseMsgId(buffer, index: &index, endIndex: buffer.count, requireAngleAddr: false, throwOnError: false, msgid: &msgid)) == false)

    index = 0
    do {
        _ = try ParseUtils.tryParseMsgId(buffer, index: &index, endIndex: buffer.count, requireAngleAddr: false, throwOnError: true, msgid: &msgid)
        #expect(Bool(false))
    } catch let error as ParseException {
        #expect(error.tokenIndex == 2)
        #expect(error.errorIndex == 24)
    } catch {
        #expect(Bool(false))
    }
}

@Test("ParseUtils try parse msg-id invalid international local part")
func parseUtilsTryParseMsgIdInvalidInternationalLocalPart() {
    let input = " <æøå@domain>"
    guard let data = input.data(using: .isoLatin1) else {
        #expect(Bool(false))
        return
    }
    let buffer = Array(data)
    var index = 0
    var msgid: String? = nil

    #expect((try? ParseUtils.tryParseMsgId(buffer, index: &index, endIndex: buffer.count, requireAngleAddr: false, throwOnError: false, msgid: &msgid)) == false)

    index = 0
    do {
        _ = try ParseUtils.tryParseMsgId(buffer, index: &index, endIndex: buffer.count, requireAngleAddr: false, throwOnError: true, msgid: &msgid)
        #expect(Bool(false))
    } catch let error as ParseException {
        #expect(error.tokenIndex == 2)
        #expect(error.errorIndex == 2)
    } catch {
        #expect(Bool(false))
    }
}

@Test("ParseUtils try parse msg-id with IDN domain")
func parseUtilsTryParseMsgIdWithIdnDomain() {
    let buffer = Array(" <id@xn--v8jxj3d1dzdz08w.com>".utf8)
    let expected = "id@名がドメイン.com"
    var index = 0
    var msgid: String? = nil

    #expect((try? ParseUtils.tryParseMsgId(buffer, index: &index, endIndex: buffer.count, requireAngleAddr: false, throwOnError: false, msgid: &msgid)) == true)
    #expect(msgid == expected)

    index = 0
    #expect((try? ParseUtils.tryParseMsgId(buffer, index: &index, endIndex: buffer.count, requireAngleAddr: false, throwOnError: true, msgid: &msgid)) == true)
    #expect(msgid == expected)
}
