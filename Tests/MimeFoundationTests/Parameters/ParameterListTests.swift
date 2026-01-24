//
// ParameterListTests.swift
//

import Testing
@testable import MimeFoundation

@Test("ParameterList argument exceptions")
func parameterListArgumentExceptions() {
    let invalid = "X-测试文本"
    let list = ParameterList()
    var parameter: Parameter? = nil
    var value: String? = nil

    #expect(throws: (any Error).self) {
        try list.add(nil as String.Encoding?, "name", "value")
    }
    #expect(throws: (any Error).self) {
        try list.add(.utf8, nil, "value")
    }
    #expect(throws: (any Error).self) {
        try list.add(.utf8, "", "value")
    }
    #expect(throws: (any Error).self) {
        try list.add(.utf8, invalid, "value")
    }
    #expect(throws: (any Error).self) {
        try list.add(.utf8, "name", nil)
    }
    #expect(throws: (any Error).self) {
        try list.add(nil as String?, "name", "value")
    }
    #expect(throws: (any Error).self) {
        try list.add("utf-8", nil, "value")
    }
    #expect(throws: (any Error).self) {
        try list.add("utf-8", "", "value")
    }
    #expect(throws: (any Error).self) {
        try list.add("utf-8", invalid, "value")
    }
    #expect(throws: (any Error).self) {
        try list.add("utf-8", "name", nil)
    }
    #expect(throws: (any Error).self) {
        try list.add(nil as String?, "value")
    }
    #expect(throws: (any Error).self) {
        try list.add("", "value")
    }
    #expect(throws: (any Error).self) {
        try list.add(invalid, "value")
    }
    #expect(throws: (any Error).self) {
        try list.add("name", nil)
    }
    #expect(throws: (any Error).self) {
        try list.add(nil as Parameter?)
    }

    try? list.add("name", "x-value")
    #expect(throws: (any Error).self) {
        try list.add("name", "value")
    }
    #expect(throws: (any Error).self) {
        let dup = try Parameter("name", "value")
        try list.add(dup)
    }
    list.clear()

    #expect(throws: (any Error).self) {
        _ = try list.contains(nil as Parameter?)
    }
    #expect(throws: (any Error).self) {
        _ = try list.contains(nil as String?)
    }

    var emptyArray: [Parameter]? = []
    #expect(throws: (any Error).self) {
        try list.copyTo(&emptyArray, -1)
    }
    var nilArray: [Parameter]? = nil
    #expect(throws: (any Error).self) {
        try list.copyTo(&nilArray, 0)
    }

    #expect(throws: (any Error).self) {
        _ = try list.indexOf(nil as Parameter?)
    }
    #expect(throws: (any Error).self) {
        _ = try list.indexOf(nil as String?)
    }

    try? list.add("x-name", "value")
    #expect(throws: (any Error).self) {
        try list.insert(-1, Parameter("name", "value"))
    }
    #expect(throws: (any Error).self) {
        try list.insert(-1, "field", "value")
    }
    #expect(throws: (any Error).self) {
        try list.insert(0, nil, "value")
    }
    #expect(throws: (any Error).self) {
        try list.insert(0, "", "value")
    }
    #expect(throws: (any Error).self) {
        try list.insert(0, invalid, "value")
    }
    #expect(throws: (any Error).self) {
        try list.insert(0, "name", nil)
    }
    #expect(throws: (any Error).self) {
        try list.insert(0, nil as Parameter?)
    }
    #expect(throws: (any Error).self) {
        try list.insert(0, "x-name", "x-value")
    }
    #expect(throws: (any Error).self) {
        let dup = try Parameter("x-name", "x-value")
        try list.insert(0, dup)
    }
    list.clear()

    #expect(throws: (any Error).self) {
        _ = try list.remove(nil as Parameter?)
    }
    #expect(throws: (any Error).self) {
        _ = try list.remove(nil as String?)
    }
    #expect(throws: (any Error).self) {
        try list.removeAt(-1)
    }
    #expect(throws: (any Error).self) {
        _ = try list.tryGetValue(nil, &parameter)
    }
    #expect(throws: (any Error).self) {
        _ = try list.tryGetValue(nil, &value)
    }
}

@Test("ParameterList basic functionality")
func parameterListBasicFunctionality() {
    let list = ParameterList()
    let xyz = try? Parameter("xyz", "3")

    #expect(list.isReadOnly == false)
    #expect(list.count == 0)

    let abc = try! Parameter("abc", "0")
    try? list.add(abc)
    try? list.add(.utf8, "def", "1")
    try? list.add("ghi", "2")

    #expect(list.count == 3)
    #expect(list.contains("xyz") == false)
    #expect(list.contains(list[0]) == true)
    #expect(list.contains("aBc") == true)
    #expect(list.contains("DEf") == true)
    #expect(list.contains("gHI") == true)
    #expect(list.indexOf("xyz") == -1)
    #expect(list.indexOf("aBc") == 0)
    #expect(list.indexOf("dEF") == 1)
    #expect(list.indexOf("Ghi") == 2)

    if let xyz {
        #expect(list.indexOf(xyz) == -1)
    }

    #expect(list[0].name == "abc")
    #expect(list[1].name == "def")
    #expect(list[2].name == "ghi")
    #expect(list["AbC"] == "0")
    #expect(list["dEf"] == "1")
    #expect(list["GHi"] == "2")

    var parameter: Parameter? = nil
    var value: String? = nil
    _ = try? list.tryGetValue("Abc", &parameter)
    #expect(parameter?.name == "abc")
    _ = try? list.tryGetValue("Abc", &value)
    #expect(value == "0")

    if let xyz {
        #expect(list.remove(xyz) == false)
        try? list.insert(0, xyz)
        #expect(list.remove(xyz) == true)

        #expect(list.remove("xyz") == false)
        try? list.insert(0, xyz)
        #expect(list.remove("xyz") == true)
    }

    var array: [Parameter]? = Array(repeating: try! Parameter("tmp", "0"), count: list.count)
    try? list.copyTo(&array, 0)
    #expect(array?[0].name == "abc")
    #expect(array?[1].name == "def")
    #expect(array?[2].name == "ghi")

    var index = 0
    for param in list {
        #expect(param == array?[index])
        index += 1
    }

    list.clear()
    #expect(list.count == 0)

    try? list.add("xyz", "3")
    if let arr = array {
        try? list.insert(0, arr[2])
        try? list.insert(0, arr[1].name, arr[1].value)
        try? list.insert(0, arr[0])
    }

    #expect(list.count == 4)
    #expect(list[0].name == "abc")
    #expect(list[1].name == "def")
    #expect(list[2].name == "ghi")
    #expect(list[3].name == "xyz")
    #expect(list["AbC"] == "0")
    #expect(list["dEf"] == "1")
    #expect(list["GHi"] == "2")
    #expect(list["XYZ"] == "3")

    try? list.removeAt(3)
    #expect(list.count == 3)
    #expect(list.toString() == "; abc=\"0\"; def=\"1\"; ghi=\"2\"")

    list[0] = try! Parameter("abc", "replaced")
    #expect(list.toString() == "; abc=\"replaced\"; def=\"1\"; ghi=\"2\"")

    list[0] = try! Parameter("xxx", "0")
    #expect(list.toString() == "; xxx=\"0\"; def=\"1\"; ghi=\"2\"")
}

@Test("ParameterList parse rfc2231 value without charset declaration")
func parameterListParseRfc2231WithoutCharset() {
    let text = "name*0*=This%20is%20some%20encoded%20ascii%20text"
    let expected = "This is some encoded ascii text"
    let options = ParserOptions.default
    let input = Array(text.utf8)
    var index = 0
    var list: ParameterList? = nil

    let result = (try? ParameterList.tryParse(options, input, index: &index, endIndex: input.count, throwOnError: false, paramList: &list)) ?? false
    #expect(result == true)
    #expect(list?["name"] == expected)
}

@Test("ParameterList parse rfc2231 value with incomplete charset declaration")
func parameterListParseRfc2231WithIncompleteCharset() {
    let text = "name*0*=us-ascii'This%20is%20some%20encoded%20ascii%20text"
    let expected = "us-ascii'This is some encoded ascii text"
    let options = ParserOptions.default
    let input = Array(text.utf8)
    var index = 0
    var list: ParameterList? = nil

    let result = (try? ParameterList.tryParse(options, input, index: &index, endIndex: input.count, throwOnError: false, paramList: &list)) ?? false
    #expect(result == true)
    #expect(list?["name"] == expected)
}

@Test("ParameterList parse rfc2231 value with unsupported charset")
func parameterListParseRfc2231WithUnsupportedCharset() {
    let text = "name*0*=x-unsupported-charset''This%20is%20some%20encoded%20ascii%20text"
    let expected = "This is some encoded ascii text"
    let options = ParserOptions.default
    let input = Array(text.utf8)
    var index = 0
    var list: ParameterList? = nil

    let result = (try? ParameterList.tryParse(options, input, index: &index, endIndex: input.count, throwOnError: false, paramList: &list)) ?? false
    #expect(result == true)
    #expect(list?["name"] == expected)
}
