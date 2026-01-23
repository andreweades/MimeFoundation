//
// InternetAddressConverterTests.swift
//

import Testing
import SwiftMimeKit

@Test("InternetAddress converter can convert")
func internetAddressConverterCanConvert() {
    let converter = InternetAddressConverter()
    #expect(converter.canConvertFrom(String.self))
    #expect(converter.canConvertTo(String.self))
}

@Test("InternetAddress converter is valid")
func internetAddressConverterIsValid() {
    let converter = InternetAddressConverter()
    #expect(converter.isValid("Unit Tests <tests@mimekit.net>"))
}

@Test("InternetAddress converter convert valid")
func internetAddressConverterConvertValid() throws {
    let converter = InternetAddressConverter()
    let result = try converter.convertFrom("Unit Tests <tests@mimekit.net>")
    #expect(result is MailboxAddress)
    guard let mailbox = result as? MailboxAddress else {
        #expect(Bool(false))
        return
    }
    #expect(mailbox.name == "Unit Tests")
    #expect(mailbox.address == "tests@mimekit.net")

    let text = try converter.convertTo(mailbox, destinationType: String.self) as? String
    #expect(text == "\"Unit Tests\" <tests@mimekit.net>")
}

@Test("InternetAddress converter convert not valid")
func internetAddressConverterConvertNotValid() {
    let converter = InternetAddressConverter()

    #expect(throws: ParseException.self) {
        _ = try converter.convertFrom("")
    }

    do {
        _ = try converter.convertFrom(5)
        #expect(Bool(false))
    } catch let error as ConverterError {
        #expect(error == .notSupported)
    } catch {
        #expect(Bool(false))
    }

    do {
        _ = try converter.convertTo(MailboxAddress(name: "Unit Tests", address: "tests@mimekit.net"), destinationType: Int.self)
        #expect(Bool(false))
    } catch let error as ConverterError {
        #expect(error == .notSupported)
    } catch {
        #expect(Bool(false))
    }
}

@Test("InternetAddress converter is not valid")
func internetAddressConverterIsNotValid() {
    let converter = InternetAddressConverter()
    #expect(!converter.isValid(""))
    #expect(!converter.isValid(5))
}

@Test("InternetAddress converter register twice throws")
func internetAddressConverterRegisterTwiceThrows() async {
    do {
        try await InternetAddressConverter.register(.default)
    } catch {
        #expect(Bool(false))
        return
    }

    do {
        try await InternetAddressConverter.register(.default)
        #expect(Bool(false))
    } catch let error as ConverterError {
        #expect(error == .alreadyRegistered)
    } catch {
        #expect(Bool(false))
    }
}
