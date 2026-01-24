//
// ExceptionTests.swift
//

import Testing
@testable import MimeFoundation

@Test("ParseException preserves fields")
func parseExceptionPreservesFields() {
    let expected = ParseException("Message", tokenIndex: 17, errorIndex: 22)

    #expect(expected.message == "Message")
    #expect(expected.tokenIndex == 17)
    #expect(expected.errorIndex == 22)
    #expect(expected == ParseException("Message", tokenIndex: 17, errorIndex: 22))
    #expect(expected != ParseException("Other", tokenIndex: 17, errorIndex: 22))
}
