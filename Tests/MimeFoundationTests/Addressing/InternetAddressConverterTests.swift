//
// Author: Jeffrey Stedfast <jestedfa@microsoft.com>
//
// Copyright (c) 2013-2026 .NET Foundation and Contributors
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.
//

//
// InternetAddressConverterTests.swift
//

import Testing
import MimeFoundation

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
