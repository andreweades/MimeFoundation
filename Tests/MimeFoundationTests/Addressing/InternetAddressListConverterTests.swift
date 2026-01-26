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
// InternetAddressListConverterTests.swift
//

import Testing
import MimeFoundation

@Test("InternetAddressList converter can convert")
func internetAddressListConverterCanConvert() {
    let converter = InternetAddressListConverter()
    #expect(converter.canConvertFrom(String.self))
    #expect(converter.canConvertTo(String.self))
}

@Test("InternetAddressList converter is valid")
func internetAddressListConverterIsValid() {
    let converter = InternetAddressListConverter()
    #expect(converter.isValid("Skye <skye@shield.gov>, Leo Fitz <fitz@shield.gov>, Melinda May <may@shield.gov>"))
}

@Test("InternetAddressList converter convert valid")
func internetAddressListConverterConvertValid() throws {
    let converter = InternetAddressListConverter()
    let result = try converter.convertFrom("Skye <skye@shield.gov>, Leo Fitz <fitz@shield.gov>, Melinda May <may@shield.gov>")
    #expect(result.count == 3)
    #expect(result[0].name == "Skye")
    #expect(result[1].name == "Leo Fitz")
    #expect(result[2].name == "Melinda May")

    let text = try converter.convertTo(result, destinationType: String.self) as? String
    #expect(text == "\"Skye\" <skye@shield.gov>, \"Leo Fitz\" <fitz@shield.gov>, \"Melinda May\" <may@shield.gov>")
}

@Test("InternetAddressList converter convert not valid")
func internetAddressListConverterConvertNotValid() {
    let converter = InternetAddressListConverter()

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
        _ = try converter.convertTo(InternetAddressList(), destinationType: Int.self)
        #expect(Bool(false))
    } catch let error as ConverterError {
        #expect(error == .notSupported)
    } catch {
        #expect(Bool(false))
    }
}

@Test("InternetAddressList converter is not valid")
func internetAddressListConverterIsNotValid() {
    let converter = InternetAddressListConverter()
    #expect(!converter.isValid(""))
    #expect(!converter.isValid(5))
}

@Test("InternetAddressList converter register twice throws")
func internetAddressListConverterRegisterTwiceThrows() async {
    do {
        try await InternetAddressListConverter.register(.default)
    } catch {
        #expect(Bool(false))
        return
    }

    do {
        try await InternetAddressListConverter.register(.default)
        #expect(Bool(false))
    } catch let error as ConverterError {
        #expect(error == .alreadyRegistered)
    } catch {
        #expect(Bool(false))
    }
}
