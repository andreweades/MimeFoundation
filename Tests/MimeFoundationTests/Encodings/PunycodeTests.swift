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

import Testing
@testable import MimeFoundation

@Suite
struct PunycodeTests {
    @Test func encode() {
        let punycode = Punycode()
        let cases: [(String, String)] = [
            ("abc.org", "abc.org"),
            ("my_company.com", "my_company.com"),
            ("bücher.com", "xn--bcher-kva.com"),
            ("мойдомен.рф", "xn--d1acklchcc.xn--p1ai"),
            ("παράδειγμα.δοκιμή", "xn--hxajbheg2az3al.xn--jxalpdlp"),
            ("mycharity。org", "mycharity.org")
        ]

        for (input, expected) in cases {
            #expect(punycode.encode(input) == expected)
        }
    }

    @Test func encodeIndex() {
        let punycode = Punycode()
        let cases: [(String, Int, String)] = [
            ("user@abc.org", 5, "abc.org"),
            ("user@my_company.com", 5, "my_company.com"),
            ("user@bücher.com", 5, "xn--bcher-kva.com"),
            ("user@мойдомен.рф", 5, "xn--d1acklchcc.xn--p1ai"),
            ("user@παράδειγμα.δοκιμή", 5, "xn--hxajbheg2az3al.xn--jxalpdlp"),
            ("user@mycharity。org", 5, "mycharity.org")
        ]

        for (input, index, expected) in cases {
            #expect(punycode.encode(input, index: index) == expected)
        }
    }

    @Test func encodeIndexCount() {
        let punycode = Punycode()
        let cases: [(String, Int, Int, String)] = [
            ("(user@abc.org)", 6, 7, "abc.org"),
            ("(user@my_company.com)", 6, 14, "my_company.com"),
            ("(user@bücher.com)", 6, 10, "xn--bcher-kva.com"),
            ("(user@мойдомен.рф)", 6, 11, "xn--d1acklchcc.xn--p1ai"),
            ("(user@παράδειγμα.δοκιμή)", 6, 17, "xn--hxajbheg2az3al.xn--jxalpdlp"),
            ("(user@mycharity。org)", 6, 13, "mycharity.org")
        ]

        for (input, index, count, expected) in cases {
            #expect(punycode.encode(input, index: index, count: count) == expected)
        }
    }

    @Test func decode() {
        let punycode = Punycode()
        let cases: [(String, String)] = [
            ("abc.org", "abc.org"),
            ("my_company.com", "my_company.com"),
            ("xn--bcher-kva.com", "bücher.com"),
            ("xn--d1acklchcc.xn--p1ai", "мойдомен.рф"),
            ("xn--hxajbheg2az3al.xn--jxalpdlp", "παράδειγμα.δοκιμή")
        ]

        for (input, expected) in cases {
            #expect(punycode.decode(input) == expected)
        }
    }

    @Test func decodeIndex() {
        let punycode = Punycode()
        let cases: [(String, Int, String)] = [
            ("user@abc.org", 5, "abc.org"),
            ("user@my_company.com", 5, "my_company.com"),
            ("user@xn--bcher-kva.com", 5, "bücher.com"),
            ("user@xn--d1acklchcc.xn--p1ai", 5, "мойдомен.рф"),
            ("user@xn--hxajbheg2az3al.xn--jxalpdlp", 5, "παράδειγμα.δοκιμή")
        ]
        for (input, index, expected) in cases {
            #expect(punycode.decode(input, index: index) == expected)
        }
    }

    @Test func decodeIndexCount() {
        let punycode = Punycode()
        let cases: [(String, Int, Int, String)] = [
            ("(user@abc.org)", 6, 7, "abc.org"),
            ("(user@my_company.com)", 6, 14, "my_company.com"),
            ("(user@xn--bcher-kva.com)", 6, 17, "bücher.com"),
            ("(user@xn--d1acklchcc.xn--p1ai)", 6, 23, "мойдомен.рф"),
            ("(user@xn--hxajbheg2az3al.xn--jxalpdlp)", 6, 31, "παράδειγμα.δοκιμή")
        ]

        for (input, index, count, expected) in cases {
            #expect(punycode.decode(input, index: index, count: count) == expected)
        }
    }
}
