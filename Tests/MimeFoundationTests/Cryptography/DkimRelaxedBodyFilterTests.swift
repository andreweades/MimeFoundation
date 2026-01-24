import Testing
@testable import MimeFoundation

@Suite
struct DkimRelaxedBodyFilterTests {
    private static func applyFilter(_ filter: MimeFilter, to text: String) throws -> String {
        let input = Array(text.utf8)
        let output = MemoryStream([], writable: true)
        let filtered = try FilteredStream(output)
        try filtered.add(filter)
        try filtered.write(input, offset: 0, count: input.count)
        try filtered.flush()
        return String(decoding: output.toByteArray(), as: UTF8.self)
    }

    @Test("White space before newline")
    func whiteSpaceBeforeNewLine() throws {
        let text = "text\t \r\n\t \r\ntext\t \r\n"
        let expected = "text\r\n\r\ntext\r\n"
        let actual = try Self.applyFilter(DkimRelaxedBodyFilter(), to: text)
        #expect(actual == expected)
    }

    @Test("Trimming empty lines")
    func trimmingEmptyLines() throws {
        let text = "Hello!\r\n  \r\n\r\n"
        let expected = "Hello!\r\n"
        let actual = try Self.applyFilter(DkimRelaxedBodyFilter(), to: text)
        #expect(actual == expected)
    }

    @Test("Multiple whitespaces per line")
    func multipleWhiteSpacesPerLine() throws {
        let text = "This is a test of the relaxed body filter with  \t multiple \t  spaces\n"
        let expected = "This is a test of the relaxed body filter with multiple spaces\n"
        let actual = try Self.applyFilter(DkimRelaxedBodyFilter(), to: text)
        #expect(actual == expected)
    }

    @Test("Non-empty body ending with multiple newlines")
    func nonEmptyBodyEndingWithMultipleNewLines() throws {
        let text = "This is a test of the relaxed body filter with a non-empty body ending with multiple new-lines\n\n\n"
        let expected = "This is a test of the relaxed body filter with a non-empty body ending with multiple new-lines\n"
        let actual = try Self.applyFilter(DkimRelaxedBodyFilter(), to: text)
        #expect(actual == expected)
    }
}
