import Foundation
import Testing
@testable import MimeFoundation

@Suite
struct AuthenticationResultsTests {
    private static func ascii(_ text: String) -> [UInt8] {
        Array(text.utf8)
    }

    private static func encode(_ authres: AuthenticationResults, header: String) -> String {
        var encoded = header
        var options = FormatOptions.default
        options.newLineFormat = .unix
        authres.encode(options, &encoded, lineLength: header.count)
        return encoded
    }

    private static func encodeWithoutHeader(_ authres: AuthenticationResults, headerLength: Int) -> String {
        var encoded = ""
        var options = FormatOptions.default
        options.newLineFormat = .unix
        authres.encode(options, &encoded, lineLength: headerLength)
        return encoded
    }

    private static func assertParseFailure(_ input: String, tokenIndex: Int, errorIndex: Int) {
        let buffer = ascii(input)
        #expect((try? AuthenticationResults(parsing: buffer)) == nil)

        do {
            _ = try AuthenticationResults(parsing: buffer)
            #expect(Bool(false))
        } catch let error as ParseException {
            #expect(error.tokenIndex == tokenIndex)
            #expect(error.errorIndex == errorIndex)
        } catch {
            #expect(Bool(false))
        }
    }

    @Test("AuthenticationResults argument exceptions")
    func argumentExceptions() {
        let buffer = [UInt8](repeating: 0, count: 16)
        // Empty/invalid buffers should throw ParseException
        #expect(throws: (any Error).self) {
            _ = try AuthenticationResults(parsing: buffer)
        }
    }

    @Test("Encode long authserv-id")
    func encodeLongAuthServId() {
        let authservId = "this-is-a-really-really-really-long-authserv-identifier-that-is-78-octets-long"
        let expected = "Authentication-Results:\n\t" + authservId + ";\n\tdkim=pass; spf=pass\n"
        var encoded = "Authentication-Results:"
        var options = FormatOptions.default
        options.newLineFormat = .unix

        var authres = AuthenticationResults(authservId)
        authres.results.append(AuthenticationMethodResult("dkim", "pass"))
        authres.results.append(AuthenticationMethodResult("spf", "pass"))

        authres.encode(options, &encoded, lineLength: encoded.count)
        #expect(encoded == expected)
    }

    @Test("Encode long authserv-id with version")
    func encodeLongAuthServIdWithVersion() {
        let authservId = "this-is-a-really-really-really-long-authserv-identifier-that-is-78-octets-long"
        let expected = "Authentication-Results:\n\t" + authservId + "\n\t1; dkim=pass; spf=pass\n"
        var encoded = "Authentication-Results:"
        var options = FormatOptions.default
        options.newLineFormat = .unix

        var authres = AuthenticationResults(authservId)
        authres.results.append(AuthenticationMethodResult("dkim", "pass"))
        authres.results.append(AuthenticationMethodResult("spf", "pass"))
        authres.version = 1

        authres.encode(options, &encoded, lineLength: encoded.count)
        #expect(encoded == expected)
    }

    @Test("Encode long result method")
    func encodeLongResultMethod() {
        let expected = "Authentication-Results: lists.example.com 1;\n\treally-long-method-name=really-long-value\n"
        var encoded = "Authentication-Results:"
        var options = FormatOptions.default
        options.newLineFormat = .unix

        var authres = AuthenticationResults("lists.example.com")
        authres.results.append(AuthenticationMethodResult("really-long-method-name", "really-long-value"))
        authres.version = 1

        authres.encode(options, &encoded, lineLength: encoded.count)
        #expect(encoded == expected)
    }

    @Test("Encode long result method with version")
    func encodeLongResultMethodWithVersion() {
        let expected = "Authentication-Results: lists.example.com 1;\n\treally-long-method-name/1=really-long-value\n"
        var encoded = "Authentication-Results:"
        var options = FormatOptions.default
        options.newLineFormat = .unix

        var result = AuthenticationMethodResult("really-long-method-name", "really-long-value")
        result.version = 1

        var authres = AuthenticationResults("lists.example.com")
        authres.results.append(result)
        authres.version = 1

        authres.encode(options, &encoded, lineLength: encoded.count)
        #expect(encoded == expected)
    }

    @Test("Encode quoted property value")
    func encodeQuotedPropertyValue() {
        let expected = "Authentication-Results: lists.example.com 1;\n\tfoo=pass (2 of 3 tests OK) ptype.prop=\"value1;value2\"\n"
        var encoded = "Authentication-Results:"
        var options = FormatOptions.default
        options.newLineFormat = .unix

        var authres = AuthenticationResults("lists.example.com")
        var result = AuthenticationMethodResult("foo", "pass")
        result.resultComment = "2 of 3 tests OK"
        result.properties.append(AuthenticationMethodProperty("ptype", "prop", "value1;value2"))
        authres.results.append(result)
        authres.version = 1

        authres.encode(options, &encoded, lineLength: encoded.count)
        #expect(encoded == expected)
    }

    @Test("Encode long result method with version and comment")
    func encodeLongResultMethodWithVersionAndComment() {
        let expected = "Authentication-Results: lists.example.com 1;\n\treally-long-method-name/1=really-long-value\n\t(this is a really long result comment)\n"
        var encoded = "Authentication-Results:"
        var options = FormatOptions.default
        options.newLineFormat = .unix

        var result = AuthenticationMethodResult("really-long-method-name", "really-long-value")
        result.resultComment = "this is a really long result comment"
        result.version = 1

        var authres = AuthenticationResults("lists.example.com")
        authres.results.append(result)
        authres.version = 1

        authres.encode(options, &encoded, lineLength: encoded.count)
        #expect(encoded == expected)
    }

    @Test("Encode long result method with version and comment and reason")
    func encodeLongResultMethodWithVersionAndCommentAndReason() {
        let expected = "Authentication-Results: lists.example.com 1;\n\treally-really-really-long-method-name/214748367=\n\treally-really-really-long-value (this is a really really long result comment)\n\treason=\"this is a really really really long reason\"\n\tthis-is-a-really-really-long-ptype.this-is-a-really-really-long-property=\n\tthis-is-a-really-really-long-value\n"
        var encoded = "Authentication-Results:"
        var options = FormatOptions.default
        options.newLineFormat = .unix

        var result = AuthenticationMethodResult("really-really-really-long-method-name", "really-really-really-long-value")
        result.resultComment = "this is a really really long result comment"
        result.reason = "this is a really really really long reason"
        result.version = 214748367
        result.properties.append(AuthenticationMethodProperty("this-is-a-really-really-long-ptype", "this-is-a-really-really-long-property", "this-is-a-really-really-long-value"))

        var authres = AuthenticationResults("lists.example.com")
        authres.results.append(result)
        authres.version = 1

        authres.encode(options, &encoded, lineLength: encoded.count)
        #expect(encoded == expected)
    }

    @Test("Encode long Office365 random domain tokens and action")
    func encodeLongOffice365RandomDomainTokensAndAction() {
        let expected = "Authentication-Results: lists.example.com 1;\n\tspf=fail (sender IP is 1.1.1.1) smtp.mailfrom=eu-west-1.amazonses.com;\n\treally-really-long-receivingdomain.com; dkim=pass (signature was verified)\n\theader.d=domain.com; another-really-really-long-receivingdomain.com;\n\tdmarc=bestguesspass action=\"none\" header.from=domain.com\n"
        var encoded = "Authentication-Results:"
        var options = FormatOptions.default
        options.newLineFormat = .unix

        var authres = AuthenticationResults("lists.example.com")
        var spf = AuthenticationMethodResult("spf", "fail")
        spf.resultComment = "sender IP is 1.1.1.1"
        spf.properties.append(AuthenticationMethodProperty("smtp", "mailfrom", "eu-west-1.amazonses.com"))
        authres.results.append(spf)

        var dkim = AuthenticationMethodResult("dkim", "pass")
        dkim.office365AuthenticationServiceIdentifier = "really-really-long-receivingdomain.com"
        dkim.resultComment = "signature was verified"
        dkim.properties.append(AuthenticationMethodProperty("header", "d", "domain.com"))
        authres.results.append(dkim)

        var dmarc = AuthenticationMethodResult("dmarc", "bestguesspass")
        dmarc.office365AuthenticationServiceIdentifier = "another-really-really-long-receivingdomain.com"
        dmarc.action = "none"
        dmarc.properties.append(AuthenticationMethodProperty("header", "from", "domain.com"))
        authres.results.append(dmarc)

        authres.version = 1

        authres.encode(options, &encoded, lineLength: encoded.count)
        #expect(encoded == expected)
    }

    @Test("Parse ARC Authentication-Results")
    func parseArcAuthenticationResults() {
        let input = "i=1; example.com; foo=pass"
        let buffer = Self.ascii(input)
        guard let authres = try? AuthenticationResults(parsing: buffer) else {
            #expect(Bool(false), "Failed to parse AuthenticationResults")
            return
        }
        #expect(authres.authenticationServiceIdentifier == "example.com")
        #expect(authres.instance == 1)
        #expect(authres.results.count == 1)
        #expect(authres.results[0].method == "foo")
        #expect(authres.results[0].result == "pass")
        #expect(authres.toString() == input)

        let expected = " i=1; example.com; foo=pass\n"
        let encoded = Self.encodeWithoutHeader(authres, headerLength: "ARC-Authentication-Results:".count)
        #expect(encoded == expected)
    }

    @Test("Parse authserv-id")
    func parseAuthServId() throws {
        let buffer = Self.ascii("example.org")
        var authres: AuthenticationResults? = nil

        authres = try? AuthenticationResults(parsing: buffer)
        #expect(authres != nil)
        #expect(authres?.authenticationServiceIdentifier == "example.org")
        #expect(authres?.toString() == "example.org; none")

        let parsedRange = try AuthenticationResults(parsing: buffer)
        #expect(parsedRange.authenticationServiceIdentifier == "example.org")
        #expect(parsedRange.toString() == "example.org; none")

        let parsed = try AuthenticationResults(parsing: buffer)
        #expect(parsed.authenticationServiceIdentifier == "example.org")
        #expect(parsed.toString() == "example.org; none")

        let expected = " example.org; none\n"
        let encoded = Self.encodeWithoutHeader(parsed, headerLength: "Authentication-Results:".count)
        #expect(encoded == expected)
    }

    @Test("Parse authserv-id with semicolon")
    func parseAuthServIdSemicolon() {
        let buffer = Self.ascii("example.org;")
        var authres: AuthenticationResults? = nil

        authres = try? AuthenticationResults(parsing: buffer)
        #expect(authres != nil)
        #expect(authres?.authenticationServiceIdentifier == "example.org")
        #expect(authres?.toString() == "example.org; none")

        let expected = " example.org; none\n"
        let encoded = Self.encodeWithoutHeader(authres!, headerLength: "Authentication-Results:".count)
        #expect(encoded == expected)
    }

    @Test("Parse authserv-id with version")
    func parseAuthServIdWithVersion() {
        let input = "example.org 1"
        let buffer = Self.ascii(input)
        var authres: AuthenticationResults? = nil

        authres = try? AuthenticationResults(parsing: buffer)
        #expect(authres != nil)
        #expect(authres?.authenticationServiceIdentifier == "example.org")
        #expect(authres?.version == 1)
        #expect(authres?.toString() == "example.org 1; none")

        let expected = " example.org 1; none\n"
        let encoded = Self.encodeWithoutHeader(authres!, headerLength: "Authentication-Results:".count)
        #expect(encoded == expected)
    }

    @Test("Parse authserv-id with version and semicolon")
    func parseAuthServIdWithVersionAndSemicolon() {
        let buffer = Self.ascii("example.org 1;")
        var authres: AuthenticationResults? = nil

        authres = try? AuthenticationResults(parsing: buffer)
        #expect(authres != nil)
        #expect(authres?.authenticationServiceIdentifier == "example.org")
        #expect(authres?.version == 1)
        #expect(authres?.toString() == "example.org 1; none")

        let expected = " example.org 1; none\n"
        let encoded = Self.encodeWithoutHeader(authres!, headerLength: "Authentication-Results:".count)
        #expect(encoded == expected)
    }

    @Test("Parse no authserv-id")
    func parseNoAuthServId() {
        let input = "spf=fail (sender IP is 1.1.1.1) smtp.mailfrom=eu-west-1.amazonses.com; dkim=pass (signature was verified) header.d=domain.com; dmarc=bestguesspass header.from=domain.com"
        let buffer = Self.ascii(input)
        guard let authres = try? AuthenticationResults(parsing: buffer) else {
            #expect(Bool(false), "Failed to parse AuthenticationResults")
            return
        }

        #expect(authres.authenticationServiceIdentifier == nil)
        #expect(authres.results.count == 3)

        #expect(authres.results[0].method == "spf")
        #expect(authres.results[0].result == "fail")
        #expect(authres.results[0].resultComment == "sender IP is 1.1.1.1")
        #expect(authres.results[0].properties.count == 1)
        #expect(authres.results[0].properties[0].propertyType == "smtp")
        #expect(authres.results[0].properties[0].property == "mailfrom")
        #expect(authres.results[0].properties[0].value == "eu-west-1.amazonses.com")

        #expect(authres.results[1].method == "dkim")
        #expect(authres.results[1].result == "pass")
        #expect(authres.results[1].resultComment == "signature was verified")
        #expect(authres.results[1].properties.count == 1)
        #expect(authres.results[1].properties[0].propertyType == "header")
        #expect(authres.results[1].properties[0].property == "d")
        #expect(authres.results[1].properties[0].value == "domain.com")

        #expect(authres.results[2].method == "dmarc")
        #expect(authres.results[2].result == "bestguesspass")
        #expect(authres.results[2].resultComment == nil)
        #expect(authres.results[2].properties.count == 1)
        #expect(authres.results[2].properties[0].propertyType == "header")
        #expect(authres.results[2].properties[0].property == "from")
        #expect(authres.results[2].properties[0].value == "domain.com")

        #expect(authres.toString() == input)

        let expected = "\n\tspf=fail (sender IP is 1.1.1.1) smtp.mailfrom=eu-west-1.amazonses.com;\n\tdkim=pass (signature was verified) header.d=domain.com;\n\tdmarc=bestguesspass header.from=domain.com\n"
        let encoded = Self.encodeWithoutHeader(authres, headerLength: "Authentication-Results:".count)
        #expect(encoded == expected)
    }

    @Test("Parse no results")
    func parseNoResults() {
        let buffer = Self.ascii("example.org 1; none")
        var authres: AuthenticationResults? = nil

        authres = try? AuthenticationResults(parsing: buffer)
        #expect(authres != nil)
        #expect(authres?.authenticationServiceIdentifier == "example.org")
        #expect(authres?.version == 1)
        #expect(authres?.results.count == 0)
        #expect(authres?.toString() == "example.org 1; none")

        let expected = " example.org 1; none\n"
        let encoded = Self.encodeWithoutHeader(authres!, headerLength: "Authentication-Results:".count)
        #expect(encoded == expected)
    }

    @Test("Parse simple")
    func parseSimple() {
        let input = "example.com; foo=pass"
        let buffer = Self.ascii(input)
        var authres: AuthenticationResults? = nil

        authres = try? AuthenticationResults(parsing: buffer)
        #expect(authres != nil)
        #expect(authres?.authenticationServiceIdentifier == "example.com")
        #expect(authres?.results.count == 1)
        #expect(authres?.results[0].method == "foo")
        #expect(authres?.results[0].result == "pass")
        #expect(authres?.toString() == input)

        let expected = " example.com; foo=pass\n"
        let encoded = Self.encodeWithoutHeader(authres!, headerLength: "Authentication-Results:".count)
        #expect(encoded == expected)
    }

    @Test("Parse simple with comment")
    func parseSimpleWithComment() {
        let input = "example.com; foo=pass (2 of 3 tests OK)"
        let buffer = Self.ascii(input)
        var authres: AuthenticationResults? = nil

        authres = try? AuthenticationResults(parsing: buffer)
        #expect(authres != nil)
        #expect(authres?.authenticationServiceIdentifier == "example.com")
        #expect(authres?.results.count == 1)
        #expect(authres?.results[0].method == "foo")
        #expect(authres?.results[0].result == "pass")
        #expect(authres?.results[0].resultComment == "2 of 3 tests OK")
        #expect(authres?.toString() == input)

        let expected = " example.com; foo=pass (2 of 3 tests OK)\n"
        let encoded = Self.encodeWithoutHeader(authres!, headerLength: "Authentication-Results:".count)
        #expect(encoded == expected)
    }

    @Test("Parse simple with property 1")
    func parseSimpleWithProperty1() {
        let input = "example.com; spf=pass smtp.mailfrom=example.net"
        let buffer = Self.ascii(input)
        var authres: AuthenticationResults? = nil

        authres = try? AuthenticationResults(parsing: buffer)
        #expect(authres != nil)
        #expect(authres?.authenticationServiceIdentifier == "example.com")
        #expect(authres?.results.count == 1)
        #expect(authres?.results[0].method == "spf")
        #expect(authres?.results[0].result == "pass")
        #expect(authres?.results[0].properties.count == 1)
        #expect(authres?.results[0].properties[0].propertyType == "smtp")
        #expect(authres?.results[0].properties[0].property == "mailfrom")
        #expect(authres?.results[0].properties[0].value == "example.net")
        #expect(authres?.toString() == input)

        let expected = " example.com; spf=pass smtp.mailfrom=example.net\n"
        let encoded = Self.encodeWithoutHeader(authres!, headerLength: "Authentication-Results:".count)
        #expect(encoded == expected)
    }

    @Test("Parse simple with property 2")
    func parseSimpleWithProperty2() {
        let input = "example.com; spf=pass smtp.mailfrom=@example.net"
        let buffer = Self.ascii(input)
        var authres: AuthenticationResults? = nil

        authres = try? AuthenticationResults(parsing: buffer)
        #expect(authres != nil)
        #expect(authres?.authenticationServiceIdentifier == "example.com")
        #expect(authres?.results.count == 1)
        #expect(authres?.results[0].method == "spf")
        #expect(authres?.results[0].result == "pass")
        #expect(authres?.results[0].properties.count == 1)
        #expect(authres?.results[0].properties[0].propertyType == "smtp")
        #expect(authres?.results[0].properties[0].property == "mailfrom")
        #expect(authres?.results[0].properties[0].value == "@example.net")
        #expect(authres?.toString() == input)

        let expected = " example.com; spf=pass smtp.mailfrom=@example.net\n"
        let encoded = Self.encodeWithoutHeader(authres!, headerLength: "Authentication-Results:".count)
        #expect(encoded == expected)
    }

    @Test("Parse simple with property 3")
    func parseSimpleWithProperty3() {
        let input = "example.com; spf=pass smtp.mailfrom=local-part@example.net"
        let buffer = Self.ascii(input)
        var authres: AuthenticationResults? = nil

        authres = try? AuthenticationResults(parsing: buffer)
        #expect(authres != nil)
        #expect(authres?.authenticationServiceIdentifier == "example.com")
        #expect(authres?.results.count == 1)
        #expect(authres?.results[0].method == "spf")
        #expect(authres?.results[0].result == "pass")
        #expect(authres?.results[0].properties.count == 1)
        #expect(authres?.results[0].properties[0].propertyType == "smtp")
        #expect(authres?.results[0].properties[0].property == "mailfrom")
        #expect(authres?.results[0].properties[0].value == "local-part@example.net")
        #expect(authres?.toString() == input)

        let expected = " example.com;\n\tspf=pass smtp.mailfrom=local-part@example.net\n"
        let encoded = Self.encodeWithoutHeader(authres!, headerLength: "Authentication-Results:".count)
        #expect(encoded == expected)
    }

    @Test("Parse simple with quoted property value")
    func parseSimpleWithQuotedPropertyValue() {
        let input = "example.com; method=pass ptype.prop=\"value1;value2\""
        let buffer = Self.ascii(input)
        var authres: AuthenticationResults? = nil

        authres = try? AuthenticationResults(parsing: buffer)
        #expect(authres != nil)
        #expect(authres?.authenticationServiceIdentifier == "example.com")
        #expect(authres?.results.count == 1)
        #expect(authres?.results[0].method == "method")
        #expect(authres?.results[0].result == "pass")
        #expect(authres?.results[0].properties.count == 1)
        #expect(authres?.results[0].properties[0].propertyType == "ptype")
        #expect(authres?.results[0].properties[0].property == "prop")
        #expect(authres?.results[0].properties[0].value == "value1;value2")
        #expect(authres?.toString() == input)

        let expected = " example.com; method=pass ptype.prop=\"value1;value2\"\n"
        let encoded = Self.encodeWithoutHeader(authres!, headerLength: "Authentication-Results:".count)
        #expect(encoded == expected)
    }

    @Test("Parse simple with reason")
    func parseSimpleWithReason() {
        let input = "example.com; spf=pass reason=good"
        let buffer = Self.ascii(input)
        var authres: AuthenticationResults? = nil

        authres = try? AuthenticationResults(parsing: buffer)
        #expect(authres != nil)
        #expect(authres?.authenticationServiceIdentifier == "example.com")
        #expect(authres?.results.count == 1)
        #expect(authres?.results[0].method == "spf")
        #expect(authres?.results[0].result == "pass")
        #expect(authres?.results[0].reason == "good")
        #expect(authres?.results[0].properties.count == 0)
        #expect(authres?.toString() == "example.com; spf=pass reason=\"good\"")

        let expected = " example.com; spf=pass reason=\"good\"\n"
        let encoded = Self.encodeWithoutHeader(authres!, headerLength: "Authentication-Results:".count)
        #expect(encoded == expected)
    }

    @Test("Parse simple with reason semicolon")
    func parseSimpleWithReasonSemiColon() {
        let input = "example.com; spf=pass reason=good; "
        let buffer = Self.ascii(input)
        var authres: AuthenticationResults? = nil

        authres = try? AuthenticationResults(parsing: buffer)
        #expect(authres != nil)
        #expect(authres?.authenticationServiceIdentifier == "example.com")
        #expect(authres?.results.count == 1)
        #expect(authres?.results[0].method == "spf")
        #expect(authres?.results[0].result == "pass")
        #expect(authres?.results[0].reason == "good")
        #expect(authres?.results[0].properties.count == 0)
        #expect(authres?.toString() == "example.com; spf=pass reason=\"good\"")

        let expected = " example.com; spf=pass reason=\"good\"\n"
        let encoded = Self.encodeWithoutHeader(authres!, headerLength: "Authentication-Results:".count)
        #expect(encoded == expected)
    }

    @Test("Parse simple with quoted reason")
    func parseSimpleWithQuotedReason() {
        let input = "example.com; spf=pass reason=\"good stuff\""
        let buffer = Self.ascii(input)
        var authres: AuthenticationResults? = nil

        authres = try? AuthenticationResults(parsing: buffer)
        #expect(authres != nil)
        #expect(authres?.authenticationServiceIdentifier == "example.com")
        #expect(authres?.results.count == 1)
        #expect(authres?.results[0].method == "spf")
        #expect(authres?.results[0].result == "pass")
        #expect(authres?.results[0].reason == "good stuff")
        #expect(authres?.results[0].properties.count == 0)
        #expect(authres?.toString() == input)

        let expected = " example.com; spf=pass reason=\"good stuff\"\n"
        let encoded = Self.encodeWithoutHeader(authres!, headerLength: "Authentication-Results:".count)
        #expect(encoded == expected)
    }

    @Test("Parse simple with quoted reason semicolon")
    func parseSimpleWithQuotedReasonSemiColon() {
        let input = "example.com; spf=pass reason=\"good stuff\""
        let buffer = Self.ascii(input + "; ")
        var authres: AuthenticationResults? = nil

        authres = try? AuthenticationResults(parsing: buffer)
        #expect(authres != nil)
        #expect(authres?.authenticationServiceIdentifier == "example.com")
        #expect(authres?.results.count == 1)
        #expect(authres?.results[0].method == "spf")
        #expect(authres?.results[0].result == "pass")
        #expect(authres?.results[0].reason == "good stuff")
        #expect(authres?.results[0].properties.count == 0)
        #expect(authres?.toString() == input)

        let expected = " example.com; spf=pass reason=\"good stuff\"\n"
        let encoded = Self.encodeWithoutHeader(authres!, headerLength: "Authentication-Results:".count)
        #expect(encoded == expected)
    }

    @Test("Parse method with multiple properties")
    func parseMethodWithMultipleProperties() {
        let input = "example.com; spf=pass ptype1.prop1=value1 ptype2.prop2=value2"
        let buffer = Self.ascii(input)
        var authres: AuthenticationResults? = nil

        authres = try? AuthenticationResults(parsing: buffer)
        #expect(authres != nil)
        #expect(authres?.authenticationServiceIdentifier == "example.com")
        #expect(authres?.results.count == 1)
        #expect(authres?.results[0].method == "spf")
        #expect(authres?.results[0].result == "pass")
        #expect(authres?.results[0].properties.count == 2)
        #expect(authres?.results[0].properties[0].propertyType == "ptype1")
        #expect(authres?.results[0].properties[0].property == "prop1")
        #expect(authres?.results[0].properties[0].value == "value1")
        #expect(authres?.results[0].properties[1].propertyType == "ptype2")
        #expect(authres?.results[0].properties[1].property == "prop2")
        #expect(authres?.results[0].properties[1].value == "value2")
        #expect(authres?.toString() == input)

        let expected = " example.com;\n\tspf=pass ptype1.prop1=value1 ptype2.prop2=value2\n"
        let encoded = Self.encodeWithoutHeader(authres!, headerLength: "Authentication-Results:".count)
        #expect(encoded == expected)
    }

    @Test("Parse multiple methods")
    func parseMultipleMethods() {
        let input = "example.com; auth=pass (cram-md5) smtp.auth=sender@example.net; spf=pass smtp.mailfrom=example.net; sender-id=pass header.from=example.net"
        let buffer = Self.ascii(input)
        guard let authres = try? AuthenticationResults(parsing: buffer) else {
            #expect(Bool(false), "Failed to parse AuthenticationResults")
            return
        }

        #expect(authres.authenticationServiceIdentifier == "example.com")
        #expect(authres.results.count == 3)
        #expect(authres.results[0].method == "auth")
        #expect(authres.results[0].result == "pass")
        #expect(authres.results[0].resultComment == "cram-md5")
        #expect(authres.results[0].properties.count == 1)
        #expect(authres.results[0].properties[0].propertyType == "smtp")
        #expect(authres.results[0].properties[0].property == "auth")
        #expect(authres.results[0].properties[0].value == "sender@example.net")
        #expect(authres.results[1].method == "spf")
        #expect(authres.results[1].result == "pass")
        #expect(authres.results[1].properties.count == 1)
        #expect(authres.results[1].properties[0].propertyType == "smtp")
        #expect(authres.results[1].properties[0].property == "mailfrom")
        #expect(authres.results[1].properties[0].value == "example.net")
        #expect(authres.results[2].method == "sender-id")
        #expect(authres.results[2].result == "pass")
        #expect(authres.results[2].properties.count == 1)
        #expect(authres.results[2].properties[0].propertyType == "header")
        #expect(authres.results[2].properties[0].property == "from")
        #expect(authres.results[2].properties[0].value == "example.net")
        #expect(authres.toString() == input)

        let expected = " example.com;\n\tauth=pass (cram-md5) smtp.auth=sender@example.net;\n\tspf=pass smtp.mailfrom=example.net; sender-id=pass header.from=example.net\n"
        let encoded = Self.encodeWithoutHeader(authres, headerLength: "Authentication-Results:".count)
        #expect(encoded == expected)
    }

    @Test("Parse multiple methods with reasons")
    func parseMultipleMethodsWithReasons() {
        let input = "example.com; dkim=pass reason=\"good signature\" header.i=@mail-router.example.net; dkim=fail reason=\"bad signature\" header.i=@newyork.example.com"
        let buffer = Self.ascii(input)
        guard let authres = try? AuthenticationResults(parsing: buffer) else {
            #expect(Bool(false), "Failed to parse AuthenticationResults")
            return
        }

        #expect(authres.authenticationServiceIdentifier == "example.com")
        #expect(authres.results.count == 2)
        #expect(authres.results[0].method == "dkim")
        #expect(authres.results[0].result == "pass")
        #expect(authres.results[0].reason == "good signature")
        #expect(authres.results[0].properties.count == 1)
        #expect(authres.results[0].properties[0].propertyType == "header")
        #expect(authres.results[0].properties[0].property == "i")
        #expect(authres.results[0].properties[0].value == "@mail-router.example.net")
        #expect(authres.results[1].method == "dkim")
        #expect(authres.results[1].result == "fail")
        #expect(authres.results[1].reason == "bad signature")
        #expect(authres.results[1].properties.count == 1)
        #expect(authres.results[1].properties[0].propertyType == "header")
        #expect(authres.results[1].properties[0].property == "i")
        #expect(authres.results[1].properties[0].value == "@newyork.example.com")
        #expect(authres.toString() == input)

        let expected = " example.com;\n\tdkim=pass reason=\"good signature\" header.i=@mail-router.example.net;\n\tdkim=fail reason=\"bad signature\" header.i=@newyork.example.com\n"
        let encoded = Self.encodeWithoutHeader(authres, headerLength: "Authentication-Results:".count)
        #expect(encoded == expected)
    }

    @Test("Parse heavily commented example")
    func parseHeavilyCommentedExample() {
        let input = "foo.example.net (foobar) 1 (baz); dkim (Because I like it) / 1 (One yay) = (wait for it) fail policy (A dot can go here) . (like that) expired (this surprised me) = (as I wasn't expecting it) 1362471462"
        let buffer = Self.ascii(input)
        guard let authres = try? AuthenticationResults(parsing: buffer) else {
            #expect(Bool(false), "Failed to parse AuthenticationResults")
            return
        }

        #expect(authres.authenticationServiceIdentifier == "foo.example.net")
        #expect(authres.version == 1)
        #expect(authres.results.count == 1)
        #expect(authres.results[0].method == "dkim")
        #expect(authres.results[0].version == 1)
        #expect(authres.results[0].result == "fail")
        #expect(authres.results[0].properties.count == 1)
        #expect(authres.results[0].properties[0].propertyType == "policy")
        #expect(authres.results[0].properties[0].property == "expired")
        #expect(authres.results[0].properties[0].value == "1362471462")
        #expect(authres.toString() == "foo.example.net 1; dkim/1=fail policy.expired=1362471462")

        let expected = " foo.example.net 1;\n\tdkim/1=fail policy.expired=1362471462\n"
        let encoded = Self.encodeWithoutHeader(authres, headerLength: "Authentication-Results:".count)
        #expect(encoded == expected)
    }

    @Test("Parse method property value with slash")
    func parseMethodPropertyValueWithSlash() {
        let input = "i=2; test.com; dkim=pass header.d=test.com header.s=selector1 header.b=Iww3/TIUS; dmarc=pass (policy=reject) header.from=test.com; spf=pass (test.com: domain of no-reply@test.com designates 1.1.1.1 as permitted sender) smtp.mailfrom=no-reply@test.com"
        let buffer = Self.ascii(input)
        guard let authres = try? AuthenticationResults(parsing: buffer) else {
            #expect(Bool(false), "Failed to parse AuthenticationResults")
            return
        }

        #expect(authres.authenticationServiceIdentifier == "test.com")
        #expect(authres.results.count == 3)
        #expect(authres.results[0].method == "dkim")
        #expect(authres.results[0].result == "pass")
        #expect(authres.results[0].properties.count == 3)
        #expect(authres.results[0].properties[0].propertyType == "header")
        #expect(authres.results[0].properties[0].property == "d")
        #expect(authres.results[0].properties[0].value == "test.com")
        #expect(authres.results[0].properties[1].propertyType == "header")
        #expect(authres.results[0].properties[1].property == "s")
        #expect(authres.results[0].properties[1].value == "selector1")
        #expect(authres.results[0].properties[2].propertyType == "header")
        #expect(authres.results[0].properties[2].property == "b")
        #expect(authres.results[0].properties[2].value == "Iww3/TIUS")

        #expect(authres.results[1].method == "dmarc")
        #expect(authres.results[1].result == "pass")
        #expect(authres.results[1].resultComment == "policy=reject")
        #expect(authres.results[1].properties.count == 1)
        #expect(authres.results[1].properties[0].propertyType == "header")
        #expect(authres.results[1].properties[0].property == "from")
        #expect(authres.results[1].properties[0].value == "test.com")

        #expect(authres.results[2].method == "spf")
        #expect(authres.results[2].result == "pass")
        #expect(authres.results[2].resultComment == "test.com: domain of no-reply@test.com designates 1.1.1.1 as permitted sender")
        #expect(authres.results[2].properties.count == 1)
        #expect(authres.results[2].properties[0].propertyType == "smtp")
        #expect(authres.results[2].properties[0].property == "mailfrom")
        #expect(authres.results[2].properties[0].value == "no-reply@test.com")

        #expect(authres.toString() == input)

        let expected = " i=2; test.com;\n\tdkim=pass header.d=test.com header.s=selector1 header.b=Iww3/TIUS;\n\tdmarc=pass (policy=reject) header.from=test.com; spf=pass\n\t(test.com: domain of no-reply@test.com designates 1.1.1.1 as permitted sender)\n\tsmtp.mailfrom=no-reply@test.com\n"
        let encoded = Self.encodeWithoutHeader(authres, headerLength: "Authentication-Results:".count)
        #expect(encoded == expected)
    }

    @Test("Parse Office365 random domain tokens and action")
    func parseOffice365RandomDomainTokensAndAction() {
        let input = "spf=fail (sender IP is 1.1.1.1) smtp.mailfrom=eu-west-1.amazonses.com; receivingdomain.com; dkim=pass (signature was verified) header.d=domain.com;domain1.com; dmarc=bestguesspass action=none header.from=domain.com;"
        let buffer = Self.ascii(input)
        guard let authres = try? AuthenticationResults(parsing: buffer) else {
            #expect(Bool(false), "Failed to parse AuthenticationResults")
            return
        }

        #expect(authres.authenticationServiceIdentifier == nil)
        #expect(authres.results.count == 3)
        #expect(authres.results[0].method == "spf")
        #expect(authres.results[0].result == "fail")
        #expect(authres.results[0].resultComment == "sender IP is 1.1.1.1")
        #expect(authres.results[0].properties.count == 1)
        #expect(authres.results[0].properties[0].propertyType == "smtp")
        #expect(authres.results[0].properties[0].property == "mailfrom")
        #expect(authres.results[0].properties[0].value == "eu-west-1.amazonses.com")

        #expect(authres.results[1].office365AuthenticationServiceIdentifier == "receivingdomain.com")
        #expect(authres.results[1].method == "dkim")
        #expect(authres.results[1].result == "pass")
        #expect(authres.results[1].resultComment == "signature was verified")
        #expect(authres.results[1].properties.count == 1)
        #expect(authres.results[1].properties[0].propertyType == "header")
        #expect(authres.results[1].properties[0].property == "d")
        #expect(authres.results[1].properties[0].value == "domain.com")

        #expect(authres.results[2].office365AuthenticationServiceIdentifier == "domain1.com")
        #expect(authres.results[2].method == "dmarc")
        #expect(authres.results[2].result == "bestguesspass")
        #expect(authres.results[2].resultComment == nil)
        #expect(authres.results[2].action == "none")
        #expect(authres.results[2].properties.count == 1)
        #expect(authres.results[2].properties[0].propertyType == "header")
        #expect(authres.results[2].properties[0].property == "from")
        #expect(authres.results[2].properties[0].value == "domain.com")

        #expect(authres.toString() == "spf=fail (sender IP is 1.1.1.1) smtp.mailfrom=eu-west-1.amazonses.com; receivingdomain.com; dkim=pass (signature was verified) header.d=domain.com; domain1.com; dmarc=bestguesspass action=\"none\" header.from=domain.com")

        let expected = "\n\tspf=fail (sender IP is 1.1.1.1) smtp.mailfrom=eu-west-1.amazonses.com;\n\treceivingdomain.com; dkim=pass (signature was verified) header.d=domain.com;\n\tdomain1.com; dmarc=bestguesspass action=\"none\" header.from=domain.com\n"
        let encoded = Self.encodeWithoutHeader(authres, headerLength: "Authentication-Results:".count)
        #expect(encoded == expected)
    }

    @Test("Parse Office365 random domain tokens and empty property value")
    func parseOffice365RandomDomainTokensAndEmptyPropertyValue() {
        let input = "spf=temperror (sender IP is 1.1.1.1) smtp.helo=tes.test.ru; mydomain.com; dkim=none (message not signed) header.d=none;mydomain.com; dmarc=none action=none header.from=;"
        let buffer = Self.ascii(input)
        guard let authres = try? AuthenticationResults(parsing: buffer) else {
            #expect(Bool(false), "Failed to parse AuthenticationResults")
            return
        }

        #expect(authres.authenticationServiceIdentifier == nil)
        #expect(authres.results.count == 3)
        #expect(authres.results[0].method == "spf")
        #expect(authres.results[0].result == "temperror")
        #expect(authres.results[0].resultComment == "sender IP is 1.1.1.1")
        #expect(authres.results[0].properties.count == 1)
        #expect(authres.results[0].properties[0].propertyType == "smtp")
        #expect(authres.results[0].properties[0].property == "helo")
        #expect(authres.results[0].properties[0].value == "tes.test.ru")

        #expect(authres.results[1].office365AuthenticationServiceIdentifier == "mydomain.com")
        #expect(authres.results[1].method == "dkim")
        #expect(authres.results[1].result == "none")
        #expect(authres.results[1].resultComment == "message not signed")
        #expect(authres.results[1].properties.count == 1)
        #expect(authres.results[1].properties[0].propertyType == "header")
        #expect(authres.results[1].properties[0].property == "d")
        #expect(authres.results[1].properties[0].value == "none")

        #expect(authres.results[2].office365AuthenticationServiceIdentifier == "mydomain.com")
        #expect(authres.results[2].method == "dmarc")
        #expect(authres.results[2].result == "none")
        #expect(authres.results[2].resultComment == nil)
        #expect(authres.results[2].action == "none")
        #expect(authres.results[2].properties.count == 1)
        #expect(authres.results[2].properties[0].propertyType == "header")
        #expect(authres.results[2].properties[0].property == "from")
        #expect(authres.results[2].properties[0].value == "")

        #expect(authres.toString() == "spf=temperror (sender IP is 1.1.1.1) smtp.helo=tes.test.ru; mydomain.com; dkim=none (message not signed) header.d=none; mydomain.com; dmarc=none action=\"none\" header.from=")

        let expected = "\n\tspf=temperror (sender IP is 1.1.1.1) smtp.helo=tes.test.ru;\n\tmydomain.com; dkim=none (message not signed) header.d=none;\n\tmydomain.com; dmarc=none action=\"none\" header.from=\n"
        let encoded = Self.encodeWithoutHeader(authres, headerLength: "Authentication-Results:".count)
        #expect(encoded == expected)
    }

    @Test("Parse Gmail Authentication-Results")
    func parseGmailAuthenticationResults() {
        let input = "mx.google.com; dkim=pass header.i=@sender.com header.s=15ca3b75e6386151 header.b=qsGI6Y43; gateway.spf=pass (google.com: domain receiver.com configured 1.2.3.4 as internal address) smtp.mailfrom=mail@from.com smtp.remote-ip=1.2.3.4 policy.d=receiver.com"
        let buffer = Self.ascii(input)
        guard let authres = try? AuthenticationResults(parsing: buffer) else {
            #expect(Bool(false), "Failed to parse AuthenticationResults")
            return
        }

        #expect(authres.authenticationServiceIdentifier == "mx.google.com")
        #expect(authres.results.count == 2)
        #expect(authres.results[0].method == "dkim")
        #expect(authres.results[0].result == "pass")
        #expect(authres.results[0].properties.count == 3)
        #expect(authres.results[0].properties[0].propertyType == "header")
        #expect(authres.results[0].properties[0].property == "i")
        #expect(authres.results[0].properties[0].value == "@sender.com")
        #expect(authres.results[0].properties[1].propertyType == "header")
        #expect(authres.results[0].properties[1].property == "s")
        #expect(authres.results[0].properties[1].value == "15ca3b75e6386151")
        #expect(authres.results[0].properties[2].propertyType == "header")
        #expect(authres.results[0].properties[2].property == "b")
        #expect(authres.results[0].properties[2].value == "qsGI6Y43")

        #expect(authres.results[1].method == "gateway.spf")
        #expect(authres.results[1].result == "pass")
        #expect(authres.results[1].resultComment == "google.com: domain receiver.com configured 1.2.3.4 as internal address")
        #expect(authres.results[1].properties.count == 3)
        #expect(authres.results[1].properties[0].propertyType == "smtp")
        #expect(authres.results[1].properties[0].property == "mailfrom")
        #expect(authres.results[1].properties[0].value == "mail@from.com")
        #expect(authres.results[1].properties[1].propertyType == "smtp")
        #expect(authres.results[1].properties[1].property == "remote-ip")
        #expect(authres.results[1].properties[1].value == "1.2.3.4")
        #expect(authres.results[1].properties[2].propertyType == "policy")
        #expect(authres.results[1].properties[2].property == "d")
        #expect(authres.results[1].properties[2].value == "receiver.com")

        #expect(authres.toString() == input)
    }

    @Test("Parse method result with underscore")
    func parseMethodResultWithUnderscore() {
        let input = " atlas122.free.mail.gq1.yahoo.com; dkim=dkim_pass header.i=@news.aegeanair.com header.s=@aegeanair2; spf=pass smtp.mailfrom=news.aegeanair.com; dmarc=success(p=REJECT) header.from=news.aegeanair.com;"
        let buffer = Self.ascii(input)
        guard let authres = try? AuthenticationResults(parsing: buffer) else {
            #expect(Bool(false), "Failed to parse AuthenticationResults")
            return
        }

        #expect(authres.authenticationServiceIdentifier == "atlas122.free.mail.gq1.yahoo.com")
        #expect(authres.results.count == 3)
        #expect(authres.results[0].method == "dkim")
        #expect(authres.results[0].result == "dkim_pass")
        #expect(authres.results[0].resultComment == nil)
        #expect(authres.results[0].properties.count == 2)
        #expect(authres.results[0].properties[0].propertyType == "header")
        #expect(authres.results[0].properties[0].property == "i")
        #expect(authres.results[0].properties[0].value == "@news.aegeanair.com")
        #expect(authres.results[0].properties[1].propertyType == "header")
        #expect(authres.results[0].properties[1].property == "s")
        #expect(authres.results[0].properties[1].value == "@aegeanair2")

        #expect(authres.results[1].method == "spf")
        #expect(authres.results[1].result == "pass")
        #expect(authres.results[1].resultComment == nil)
        #expect(authres.results[1].properties.count == 1)
        #expect(authres.results[1].properties[0].propertyType == "smtp")
        #expect(authres.results[1].properties[0].property == "mailfrom")
        #expect(authres.results[1].properties[0].value == "news.aegeanair.com")

        #expect(authres.results[2].method == "dmarc")
        #expect(authres.results[2].result == "success")
        #expect(authres.results[2].resultComment == "p=REJECT")
        #expect(authres.results[2].properties.count == 1)
        #expect(authres.results[2].properties[0].propertyType == "header")
        #expect(authres.results[2].properties[0].property == "from")
        #expect(authres.results[2].properties[0].value == "news.aegeanair.com")

        #expect(authres.toString() == "atlas122.free.mail.gq1.yahoo.com; dkim=dkim_pass header.i=@news.aegeanair.com header.s=@aegeanair2; spf=pass smtp.mailfrom=news.aegeanair.com; dmarc=success (p=REJECT) header.from=news.aegeanair.com")

        let expected = " atlas122.free.mail.gq1.yahoo.com;\n\tdkim=dkim_pass header.i=@news.aegeanair.com header.s=@aegeanair2;\n\tspf=pass smtp.mailfrom=news.aegeanair.com;\n\tdmarc=success (p=REJECT) header.from=news.aegeanair.com\n"
        let encoded = Self.encodeWithoutHeader(authres, headerLength: "Authentication-Results:".count)
        #expect(encoded == expected)
    }

    @Test("Parse property with equal sign in value")
    func parsePropertyWithEqualSignInValue() {
        let input = "i=1; relay.mailrelay.com; dkim=pass header.d=domaina.com header.s=sfdc header.b=abcefg; dmarc=pass (policy=quarantine) header.from=domaina.com; spf=pass (relay.mailrelay.com: domain of support=domaina.com__0-1q6woix34obtbu@823lwd90ky2ahf.mail_sender.com designates 1.1.1.1 as permitted sender) smtp.mailfrom=support=domaina.com__0-1q6woix34obtbu@823lwd90ky2ahf.mail_sender.com"
        let buffer = Self.ascii(input)
        guard let authres = try? AuthenticationResults(parsing: buffer) else {
            #expect(Bool(false), "Failed to parse AuthenticationResults")
            return
        }

        #expect(authres.instance == 1)
        #expect(authres.authenticationServiceIdentifier == "relay.mailrelay.com")
        #expect(authres.results.count == 3)
        #expect(authres.results[0].method == "dkim")
        #expect(authres.results[0].result == "pass")
        #expect(authres.results[0].resultComment == nil)
        #expect(authres.results[0].properties.count == 3)
        #expect(authres.results[0].properties[0].propertyType == "header")
        #expect(authres.results[0].properties[0].property == "d")
        #expect(authres.results[0].properties[0].value == "domaina.com")
        #expect(authres.results[0].properties[1].propertyType == "header")
        #expect(authres.results[0].properties[1].property == "s")
        #expect(authres.results[0].properties[1].value == "sfdc")
        #expect(authres.results[0].properties[2].propertyType == "header")
        #expect(authres.results[0].properties[2].property == "b")
        #expect(authres.results[0].properties[2].value == "abcefg")

        #expect(authres.results[1].method == "dmarc")
        #expect(authres.results[1].result == "pass")
        #expect(authres.results[1].resultComment == "policy=quarantine")
        #expect(authres.results[1].properties.count == 1)
        #expect(authres.results[1].properties[0].propertyType == "header")
        #expect(authres.results[1].properties[0].property == "from")
        #expect(authres.results[1].properties[0].value == "domaina.com")

        #expect(authres.results[2].method == "spf")
        #expect(authres.results[2].result == "pass")
        #expect(authres.results[2].resultComment == "relay.mailrelay.com: domain of support=domaina.com__0-1q6woix34obtbu@823lwd90ky2ahf.mail_sender.com designates 1.1.1.1 as permitted sender")
        #expect(authres.results[2].properties.count == 1)
        #expect(authres.results[2].properties[0].propertyType == "smtp")
        #expect(authres.results[2].properties[0].property == "mailfrom")
        #expect(authres.results[2].properties[0].value == "support=domaina.com__0-1q6woix34obtbu@823lwd90ky2ahf.mail_sender.com")

        #expect(authres.toString() == "i=1; relay.mailrelay.com; dkim=pass header.d=domaina.com header.s=sfdc header.b=abcefg; dmarc=pass (policy=quarantine) header.from=domaina.com; spf=pass (relay.mailrelay.com: domain of support=domaina.com__0-1q6woix34obtbu@823lwd90ky2ahf.mail_sender.com designates 1.1.1.1 as permitted sender) smtp.mailfrom=support=domaina.com__0-1q6woix34obtbu@823lwd90ky2ahf.mail_sender.com")

        let expected = " i=1; relay.mailrelay.com;\n\tdkim=pass header.d=domaina.com header.s=sfdc header.b=abcefg;\n\tdmarc=pass (policy=quarantine) header.from=domaina.com; spf=pass\n\t(relay.mailrelay.com: domain of support=domaina.com__0-1q6woix34obtbu@823lwd90ky2ahf.mail_sender.com designates 1.1.1.1 as permitted sender)\n\tsmtp.mailfrom=\n\tsupport=domaina.com__0-1q6woix34obtbu@823lwd90ky2ahf.mail_sender.com\n"
        let encoded = Self.encodeWithoutHeader(authres, headerLength: "Authentication-Results:".count)
        #expect(encoded == expected)
    }

    @Test("Parse failures")
    func parseFailures() {
        let cases: [(String, Int, Int)] = [
            (" \"quoted-authserv-id", 1, 20),
            (" (truncated comment", 1, 19),
            (" authserv-id (truncated comment", 13, 31),
            (" authserv-id 1 (truncated comment", 15, 33),
            (" i= (truncated comment", 4, 22),
            (" i=1 (truncated comment", 5, 23),
            (" i=1; (truncated comment", 6, 24),
            (" authserv-id; (incomplete comment", 14, 33),
            (" authserv-id; method (incomplete comment", 21, 40),
            (" authserv-id; method= (incomplete comment", 22, 41),
            (" authserv-id; method=result (incomplete comment", 28, 47),
            (" authserv-id; method=result (comment) (incomplete comment", 38, 57),
            (" authserv-id; method/ (incomplete comment", 22, 41),
            (" authserv-id; method/1 (incomplete comment", 23, 42),
            (" authserv-id; method/1= (incomplete comment", 24, 43),
            ("authserv-id; method=pass reason (truncated comment", 32, 50),
            ("authserv-id; method=pass reason= (truncated comment", 33, 51),
            ("authserv-id; method=pass reason=value (truncated comment", 38, 56),
            ("authserv-id; method=pass ptype (truncated comment", 31, 49),
            ("authserv-id; method=pass ptype. (truncated comment", 32, 50),
            ("authserv-id; method=pass ptype.prop (truncated comment", 36, 54),
            ("authserv-id; method=pass ptype.prop= (truncated comment", 37, 55),
            ("authserv-id; method=pass ptype.prop=value (truncated comment", 42, 60),
            ("i=", 2, 2),
            ("i=abc; authserv-id", 2, 2),
            ("i=1: authserv-id", 3, 3),
            ("i=5", 2, 3),
            ("i=5;", 4, 4),
            ("i=5; i=1", 5, 6),
            ("authserv-id x", 12, 12),
            ("authserv-id 1 x", 14, 14),
            ("authserv-id; .", 13, 13),
            ("authserv-id; abc", 13, 16),
            ("authserv-id; abc def", 13, 17),
            ("authserv-id; abc/1 ", 13, 19),
            ("authserv-id; abc/1.0=pass", 13, 18),
            ("authserv-id; abc/def=pass", 17, 17),
            ("authserv-id; abc=", 13, 17),
            ("authserv-id; abc=.", 17, 17),
            ("authserv-id; none; method=pass", 13, 17),
            ("authserv-id; method=pass; none", 26, 30),
            ("authserv-id; method=pass (truncated comment", 25, 43),
            ("authserv-id; method=pass .", 25, 25),
            ("authserv-id; method=pass reason", 25, 31),
            ("authserv-id; method=pass reason=", 32, 32),
            ("authserv-id; method=pass reason=\"this is some text", 32, 50),
            ("authserv-id; method=pass reason=;", 32, 32),
            ("authserv-id; method=pass reason .", 25, 32),
            ("authserv-id; method=pass reason=\"because I said so\" .;", 52, 52),
            ("authserv-id; method=pass ptype", 25, 30),
            ("authserv-id; method=pass ptype.", 25, 31),
            ("authserv-id; method=pass ptype.prop", 25, 35),
            ("authserv-id; method=pass ptype.prop=", 25, 36),
            ("authserv-id; method=pass ptype.prop=\"incomplete qstring", 25, 55),
            ("authserv-id; method=pass ptype;", 25, 30),
            ("authserv-id; method=pass ptype.prop;", 25, 35),
            ("authserv-id; method=pass ptype.prop=value .", 42, 42),
            ("authserv-id; method=pass ptype..", 31, 31),
            ("authserv-id; method=pass ptype.prop=pvalue; invalid.office365.domain..; method=pass", 44, 69),
            ("authserv-id; method=pass ptype.prop=pvalue; truncated.office365.domain", 44, 70),
            ("authserv-id; method=pass ptype.prop=pvalue; office365.domain :", 61, 61)
        ]

        for (input, tokenIndex, errorIndex) in cases {
            Self.assertParseFailure(input, tokenIndex: tokenIndex, errorIndex: errorIndex)
        }
    }
}
