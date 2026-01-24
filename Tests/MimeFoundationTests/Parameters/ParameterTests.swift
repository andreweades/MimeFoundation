//
// ParameterTests.swift
//

import Testing
import MimeFoundation

@Test("Parameter argument exceptions")
func parameterArgumentExceptions() {
    let invalid = "X-测试文本"

    #expect(throws: (any Error).self) {
        _ = try Parameter(encoding: nil, name: "name", value: "value")
    }
    #expect(throws: (any Error).self) {
        _ = try Parameter(encoding: .utf8, name: nil, value: "value")
    }
    #expect(throws: (any Error).self) {
        _ = try Parameter(encoding: .utf8, name: "", value: "value")
    }
    #expect(throws: (any Error).self) {
        _ = try Parameter(encoding: .utf8, name: invalid, value: "value")
    }
    #expect(throws: (any Error).self) {
        _ = try Parameter(encoding: .utf8, name: "name", value: nil)
    }
    #expect(throws: (any Error).self) {
        _ = try Parameter(charset: nil, name: "name", value: "value")
    }
    #expect(throws: (any Error).self) {
        _ = try Parameter(charset: "utf-8", name: nil, value: "value")
    }
    #expect(throws: (any Error).self) {
        _ = try Parameter(charset: "utf-8", name: "", value: "value")
    }
    #expect(throws: (any Error).self) {
        _ = try Parameter(charset: "utf-8", name: invalid, value: "value")
    }
    #expect(throws: (any Error).self) {
        _ = try Parameter(charset: "utf-8", name: "name", value: nil)
    }
    #expect(throws: (any Error).self) {
        _ = try Parameter(nil, "value")
    }
    #expect(throws: (any Error).self) {
        _ = try Parameter("", "value")
    }
    #expect(throws: (any Error).self) {
        _ = try Parameter(invalid, "value")
    }
    #expect(throws: (any Error).self) {
        _ = try Parameter("name", nil)
    }

    let parameter = try? Parameter("name", "value")
    if let parameter {
        #expect(throws: (any Error).self) {
            try parameter.setValue(nil)
        }
        #expect(throws: (any Error).self) {
            try parameter.setEncoding(nil)
        }
        #expect(throws: (any Error).self) {
            try parameter.setEncodingMethod(512)
        }
    } else {
        Issue.record("Failed to create Parameter")
    }
}

@Test("Parameter basic functionality")
func parameterBasicFunctionality() {
    let param = try? Parameter("name", "value")
    guard let param else {
        Issue.record("Failed to create Parameter")
        return
    }

    #expect(param.encoding == .utf8)
    #expect(param.encodingMethod == .default)
    #expect(param.alwaysQuote == false)
    #expect(param.name == "name")
    #expect(param.value == "value")
    #expect(param.description == "name=\"value\"")
}

@Test("Parameter encode")
func parameterEncode() {
    var builder = ValueStringBuilder(initialCapacity: 256)
    builder.append("Content-Disposition: attachment")
    let param = try! Parameter("filename", "tps-report.doc")
    var options = FormatOptions.default
    var lineLength = builder.length

    options.alwaysQuoteParameterValues = false
    options.newLineFormat = .dos

    param.encode(options, builder: &builder, lineLength: &lineLength, charset: .utf8)

    #expect(builder.asString() == "Content-Disposition: attachment; filename=tps-report.doc")
}

@Test("Parameter encode always quote")
func parameterEncodeAlwaysQuote() {
    var builder = ValueStringBuilder(initialCapacity: 256)
    builder.append("Content-Disposition: attachment")
    let param = try! Parameter("filename", "tps-report.doc")
    var options = FormatOptions.default
    var lineLength = builder.length

    param.alwaysQuote = true
    options.newLineFormat = .dos

    param.encode(options, builder: &builder, lineLength: &lineLength, charset: .utf8)

    #expect(builder.asString() == "Content-Disposition: attachment; filename=\"tps-report.doc\"")
}

@Test("Parameter encode format options always quote")
func parameterEncodeFormatOptionsAlwaysQuote() {
    var builder = ValueStringBuilder(initialCapacity: 256)
    builder.append("Content-Disposition: attachment")
    let param = try! Parameter("filename", "tps-report.doc")
    var options = FormatOptions.default
    var lineLength = builder.length

    options.alwaysQuoteParameterValues = true
    options.newLineFormat = .dos

    param.encode(options, builder: &builder, lineLength: &lineLength, charset: .utf8)

    #expect(builder.asString() == "Content-Disposition: attachment; filename=\"tps-report.doc\"")
}

@Test("Parameter encode rfc2047")
func parameterEncodeRfc2047() {
    var builder = ValueStringBuilder(initialCapacity: 256)
    builder.append("Content-Disposition: attachment")
    let param = try! Parameter("filename", "测试文本.doc")
    var options = FormatOptions.default
    var lineLength = builder.length

    param.encodingMethod = .rfc2047
    options.newLineFormat = .dos

    param.encode(options, builder: &builder, lineLength: &lineLength, charset: .utf8)

    #expect(builder.asString() == "Content-Disposition: attachment; filename=\"=?utf-8?b?5rWL6K+V5paH5pysLmRv?=\r\n\t=?utf-8?q?c?=\"")
}

@Test("Parameter encode rfc2047 with surrogate pairs")
func parameterEncodeRfc2047WithSurrogates() {
    var builder = ValueStringBuilder(initialCapacity: 256)
    builder.append("Content-Disposition: attachment")
    let param = try! Parameter("filename", "I ❤️‍🔥 emojis.doc")
    var options = FormatOptions.default
    var lineLength = builder.length

    param.encodingMethod = .rfc2047
    options.newLineFormat = .dos

    param.encode(options, builder: &builder, lineLength: &lineLength, charset: .utf8)
    let encoded = builder.asString()

    #expect(encoded == "Content-Disposition: attachment; filename=\"=?utf-8?b?SSDinaTvuI/igI3wn5Sl?=\r\n\t=?utf-8?q?_emojis=2Edoc?=\"")

    let offset = "Content-Disposition:".count
    let contentDisposition = try! ContentDisposition(parsing:String(encoded.dropFirst(offset)))
    #expect(contentDisposition.parameters.count == 1)
    #expect(contentDisposition.parameters[param.name] == param.value)
}

@Test("Parameter encode rfc2047 with quotes")
func parameterEncodeRfc2047WithQuotes() {
    var builder = ValueStringBuilder(initialCapacity: 256)
    builder.append("Content-Disposition: attachment")
    let param = try! Parameter("filename", "Some \"测试文本\" characters.doc")
    var options = FormatOptions.default
    var lineLength = builder.length

    param.encodingMethod = .rfc2047
    options.newLineFormat = .dos

    param.encode(options, builder: &builder, lineLength: &lineLength, charset: .utf8)
    let encoded = builder.asString()

    #expect(encoded == "Content-Disposition: attachment; filename=\"=?utf-8?b?U29tZSAi5rWL6K+V5paH?=\r\n\t=?utf-8?q?=E6=9C=AC=22_characters=2Edoc?=\"")

    let offset = "Content-Disposition:".count
    let contentDisposition = try! ContentDisposition(parsing:String(encoded.dropFirst(offset)))
    #expect(contentDisposition.parameters.count == 1)
    #expect(contentDisposition.parameters[param.name] == param.value)
}

@Test("Parameter encode rfc2047 with GB18030")
func parameterEncodeRfc2047WithGB18030() {
    var builder = ValueStringBuilder(initialCapacity: 256)
    builder.append("Content-Disposition: attachment")
    let param = try! Parameter(charset: "GB18030", name: "filename", value: "测试文本.doc")
    var options = FormatOptions.default
    var lineLength = builder.length

    param.encodingMethod = .rfc2047
    options.newLineFormat = .dos

    param.encode(options, builder: &builder, lineLength: &lineLength, charset: .utf8)

    #expect(builder.asString() == "Content-Disposition: attachment; filename=\"=?gb18030?b?suLK1M7Esb4uZG9j?=\"")
}

@Test("Parameter encode format options rfc2047")
func parameterEncodeFormatOptionsRfc2047() {
    var builder = ValueStringBuilder(initialCapacity: 256)
    builder.append("Content-Disposition: attachment")
    let param = try! Parameter("filename", "测试文本.doc")
    var options = FormatOptions.default
    var lineLength = builder.length

    options.parameterEncodingMethod = .rfc2047
    options.newLineFormat = .dos

    param.encode(options, builder: &builder, lineLength: &lineLength, charset: .utf8)

    #expect(builder.asString() == "Content-Disposition: attachment; filename=\"=?utf-8?b?5rWL6K+V5paH5pysLmRv?=\r\n\t=?utf-8?q?c?=\"")
}

@Test("Parameter encode format options rfc2047 with GB18030")
func parameterEncodeFormatOptionsRfc2047WithGB18030() {
    var builder = ValueStringBuilder(initialCapacity: 256)
    builder.append("Content-Disposition: attachment")
    let param = try! Parameter(charset: "GB18030", name: "filename", value: "测试文本.doc")
    var options = FormatOptions.default
    var lineLength = builder.length

    options.parameterEncodingMethod = .rfc2047
    options.newLineFormat = .dos

    param.encode(options, builder: &builder, lineLength: &lineLength, charset: .utf8)

    #expect(builder.asString() == "Content-Disposition: attachment; filename=\"=?gb18030?b?suLK1M7Esb4uZG9j?=\"")
}

@Test("Parameter encode rfc2231")
func parameterEncodeRfc2231() {
    var builder = ValueStringBuilder(initialCapacity: 256)
    builder.append("Content-Disposition: attachment")
    let param = try! Parameter("filename", "测试文本.doc")
    var options = FormatOptions.default
    var lineLength = builder.length

    param.encodingMethod = .rfc2231
    options.newLineFormat = .dos

    param.encode(options, builder: &builder, lineLength: &lineLength, charset: .utf8)

    #expect(builder.asString() == "Content-Disposition: attachment;\r\n\tfilename*=utf-8''%E6%B5%8B%E8%AF%95%E6%96%87%E6%9C%AC.doc")
}

@Test("Parameter encode rfc2231 with GB18030")
func parameterEncodeRfc2231WithGB18030() {
    var builder = ValueStringBuilder(initialCapacity: 256)
    builder.append("Content-Disposition: attachment")
    let param = try! Parameter(charset: "GB18030", name: "filename", value: "测试文本.doc")
    var options = FormatOptions.default
    var lineLength = builder.length

    param.encodingMethod = .rfc2231
    options.newLineFormat = .dos

    param.encode(options, builder: &builder, lineLength: &lineLength, charset: .utf8)

    #expect(builder.asString() == "Content-Disposition: attachment;\r\n\tfilename*=gb18030''%B2%E2%CA%D4%CE%C4%B1%BE.doc")
}

@Test("Parameter encode format options rfc2231")
func parameterEncodeFormatOptionsRfc2231() {
    var builder = ValueStringBuilder(initialCapacity: 256)
    builder.append("Content-Disposition: attachment")
    let param = try! Parameter("filename", "测试文本.doc")
    var options = FormatOptions.default
    var lineLength = builder.length

    options.parameterEncodingMethod = .rfc2231
    options.newLineFormat = .dos

    param.encode(options, builder: &builder, lineLength: &lineLength, charset: .utf8)

    #expect(builder.asString() == "Content-Disposition: attachment;\r\n\tfilename*=utf-8''%E6%B5%8B%E8%AF%95%E6%96%87%E6%9C%AC.doc")
}

@Test("Parameter encode format options rfc2231 with GB18030")
func parameterEncodeFormatOptionsRfc2231WithGB18030() {
    var builder = ValueStringBuilder(initialCapacity: 256)
    builder.append("Content-Disposition: attachment")
    let param = try! Parameter(charset: "GB18030", name: "filename", value: "测试文本.doc")
    var options = FormatOptions.default
    var lineLength = builder.length

    options.parameterEncodingMethod = .rfc2231
    options.newLineFormat = .dos

    param.encode(options, builder: &builder, lineLength: &lineLength, charset: .utf8)

    #expect(builder.asString() == "Content-Disposition: attachment;\r\n\tfilename*=gb18030''%B2%E2%CA%D4%CE%C4%B1%BE.doc")
}

@Test("Parameter encode control characters")
func parameterEncodeControlCharacters() {
    var builder = ValueStringBuilder(initialCapacity: 256)
    builder.append("Content-Disposition: attachment")
    let param = try! Parameter("filename", "tps\u{07}-\u{08}report.doc")
    var options = FormatOptions.default
    var lineLength = builder.length

    options.alwaysQuoteParameterValues = false
    options.newLineFormat = .dos

    param.encode(options, builder: &builder, lineLength: &lineLength, charset: .utf8)

    #expect(builder.asString() == "Content-Disposition: attachment; filename*=iso-8859-1''tps%07-%08report.doc")
}

@Test("Parameter encode long parameter name")
func parameterEncodeLongParameterName() {
    var builder = ValueStringBuilder(initialCapacity: 256)
    builder.append("Content-Disposition: attachment")
    let name = String(repeating: "A", count: 72)
    let param = try! Parameter(name, "value")
    var options = FormatOptions.default
    var lineLength = builder.length

    options.alwaysQuoteParameterValues = false
    options.newLineFormat = .dos

    param.encode(options, builder: &builder, lineLength: &lineLength, charset: .utf8)
    let encoded = builder.asString()

    #expect(encoded == "Content-Disposition: attachment;\r\n\t\(name)*0=val;\r\n\t\(name)*1=ue")

    let offset = "Content-Disposition:".count
    let contentDisposition = try! ContentDisposition(parsing:String(encoded.dropFirst(offset)))
    #expect(contentDisposition.parameters.count == 1)
    #expect(contentDisposition.parameters[param.name] == param.value)
}

@Test("Parameter encode long parameter name with rfc2231 value")
func parameterEncodeLongParameterNameWithRfc2231Value() {
    var builder = ValueStringBuilder(initialCapacity: 256)
    builder.append("Content-Disposition: attachment")
    let name = String(repeating: "A", count: 72)
    let param = try! Parameter(charset: "GB18030", name: name, value: "测试文本.doc")
    var options = FormatOptions.default
    var lineLength = builder.length

    options.alwaysQuoteParameterValues = false
    options.newLineFormat = .dos

    param.encode(options, builder: &builder, lineLength: &lineLength, charset: .utf8)
    let encoded = builder.asString()

    #expect(encoded == "Content-Disposition: attachment;\r\n\t\(name)*0*=gb18030'';\r\n\t\(name)*1*=%B2%E2;\r\n\t\(name)*2*=%CA%D4;\r\n\t\(name)*3*=%CE%C4;\r\n\t\(name)*4*=%B1%BE;\r\n\t\(name)*5=.do;\r\n\t\(name)*6=c")

    let offset = "Content-Disposition:".count
    let contentDisposition = try! ContentDisposition(parsing:String(encoded.dropFirst(offset)))
    #expect(contentDisposition.parameters.count == 1)
    #expect(contentDisposition.parameters[param.name] == param.value)
}

@Test("Parameter encode international")
func parameterEncodeInternational() {
    var builder = ValueStringBuilder(initialCapacity: 256)
    builder.append("Content-Disposition: attachment")
    let param = try! Parameter("filename", "测试文本.doc")
    var options = FormatOptions.default
    var lineLength = builder.length

    options.international = true
    options.alwaysQuoteParameterValues = false
    options.newLineFormat = .dos

    param.encode(options, builder: &builder, lineLength: &lineLength, charset: .utf8)

    #expect(builder.asString() == "Content-Disposition: attachment; filename=\"测试文本.doc\"")
}

@Test("Parameter encode long international")
func parameterEncodeLongInternational() {
    var builder = ValueStringBuilder(initialCapacity: 256)
    builder.append("Content-Disposition: attachment")
    let value = "测试文本测试文本测试文本测试文本测试文本测试文本测试文本测试文本测试文本测试文本测试文本测试文本测试文本测试文本测试文本测试文本.doc"
    let param = try! Parameter("filename", value)
    var options = FormatOptions.default
    var lineLength = builder.length

    options.international = true
    options.alwaysQuoteParameterValues = false
    options.newLineFormat = .dos

    param.encode(options, builder: &builder, lineLength: &lineLength, charset: .utf8)
    let encoded = builder.asString()

    #expect(encoded == "Content-Disposition: attachment;\r\n\tfilename*0=\"测试文本测试文本测试文本测试文本测试文本测\";\r\n\tfilename*1=\"试文本测试文本测试文本测试文本测试文本测试\";\r\n\tfilename*2=\"文本测试文本测试文本测试文本测试文本测试文\";\r\n\tfilename*3=\"本.doc\"")

    let offset = "Content-Disposition:".count
    let contentDisposition = try! ContentDisposition(parsing:String(encoded.dropFirst(offset)))
    #expect(contentDisposition.parameters.count == 1)
    #expect(contentDisposition.parameters[param.name] == param.value)
}
