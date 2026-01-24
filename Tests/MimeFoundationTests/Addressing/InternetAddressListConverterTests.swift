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
