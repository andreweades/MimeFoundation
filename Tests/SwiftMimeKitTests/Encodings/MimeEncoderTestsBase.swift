import Testing
@testable import SwiftMimeKit

enum MimeEncoderTestsBase {
    static let dataDir = "encoders"
    static let wikipediaUnix: [UInt8] = {
        let data = try! TestHelper.loadData(relativePath: "\(dataDir)/wikipedia.txt")
        let filtered = FilteredStream()
        filtered.add(Dos2UnixFilter())
        filtered.write(data, startIndex: 0, length: data.count)
        filtered.flush()
        return filtered.toByteArray()
    }()
    static let wikipediaDos: [UInt8] = {
        let data = try! TestHelper.loadData(relativePath: "\(dataDir)/wikipedia.txt")
        let filtered = FilteredStream()
        filtered.add(Unix2DosFilter())
        filtered.write(data, startIndex: 0, length: data.count)
        filtered.flush()
        return filtered.toByteArray()
    }()
    static let photo: [UInt8] = {
        try! TestHelper.loadData(relativePath: "\(dataDir)/photo.jpg")
    }()

    static func assertArgumentExceptions(_ encoder: any MimeEncoder, sourceLocation: SourceLocation = #_sourceLocation) {
        var output: [UInt8]? = []
        #expect(throws: (any Error).self, sourceLocation: sourceLocation) {
            try encoder.encode(nil, startIndex: 0, length: 0, output: &output)
        }

        output = []
        #expect(throws: (any Error).self, sourceLocation: sourceLocation) {
            try encoder.encode([], startIndex: -1, length: 0, output: &output)
        }

        output = []
        #expect(throws: (any Error).self, sourceLocation: sourceLocation) {
            try encoder.encode([UInt8](repeating: 0, count: 1), startIndex: 0, length: 10, output: &output)
        }

        var nilOutput: [UInt8]? = nil
        #expect(throws: (any Error).self, sourceLocation: sourceLocation) {
            try encoder.encode([UInt8](repeating: 0, count: 1), startIndex: 0, length: 1, output: &nilOutput)
        }

        output = []
        #expect(throws: (any Error).self, sourceLocation: sourceLocation) {
            try encoder.encode([UInt8](repeating: 0, count: 1), startIndex: 0, length: 1, output: &output)
        }

        output = []
        #expect(throws: (any Error).self, sourceLocation: sourceLocation) {
            try encoder.flush(nil, startIndex: 0, length: 0, output: &output)
        }

        output = []
        #expect(throws: (any Error).self, sourceLocation: sourceLocation) {
            try encoder.flush([], startIndex: -1, length: 0, output: &output)
        }

        output = []
        #expect(throws: (any Error).self, sourceLocation: sourceLocation) {
            try encoder.flush([UInt8](repeating: 0, count: 1), startIndex: 0, length: 10, output: &output)
        }

        nilOutput = nil
        #expect(throws: (any Error).self, sourceLocation: sourceLocation) {
            try encoder.flush([UInt8](repeating: 0, count: 1), startIndex: 0, length: 1, output: &nilOutput)
        }

        output = []
        #expect(throws: (any Error).self, sourceLocation: sourceLocation) {
            try encoder.flush([UInt8](repeating: 0, count: 1), startIndex: 0, length: 1, output: &output)
        }
    }

    static func cloneAndAssert(_ encoder: any MimeEncoder, sample: [UInt8], sourceLocation: SourceLocation = #_sourceLocation) {
        let prefixLength = min(3, sample.count)
        var output: [UInt8]? = [UInt8](repeating: 0, count: encoder.estimateOutputLength(sample.count))
        do {
            _ = try encoder.encode(sample, startIndex: 0, length: prefixLength, output: &output)
        } catch {
            Issue.record("Unexpected error: \(error)", sourceLocation: sourceLocation)
            return
        }

        let clone = encoder.clone()
        let remainingLength = sample.count - prefixLength
        var output1: [UInt8]? = [UInt8](repeating: 0, count: encoder.estimateOutputLength(remainingLength))
        var output2: [UInt8]? = [UInt8](repeating: 0, count: encoder.estimateOutputLength(remainingLength))
        do {
            let n1 = try encoder.flush(sample, startIndex: prefixLength, length: remainingLength, output: &output1)
            let n2 = try clone.flush(sample, startIndex: prefixLength, length: remainingLength, output: &output2)
            #expect(Array(output1?.prefix(n1) ?? []) == Array(output2?.prefix(n2) ?? []), sourceLocation: sourceLocation)
        } catch {
            Issue.record("Unexpected error: \(error)", sourceLocation: sourceLocation)
        }
    }

    static func resetAndAssert(_ encoder: any MimeEncoder, sample: [UInt8], sourceLocation: SourceLocation = #_sourceLocation) {
        let clone = encoder.clone()
        let prefixLength = min(5, sample.count)
        var output: [UInt8]? = [UInt8](repeating: 0, count: encoder.estimateOutputLength(sample.count))
        do {
            _ = try clone.encode(sample, startIndex: 0, length: prefixLength, output: &output)
            clone.reset()

            var freshOutput: [UInt8]? = [UInt8](repeating: 0, count: encoder.estimateOutputLength(sample.count))
            let freshCount = try encoder.flush(sample, startIndex: 0, length: sample.count, output: &freshOutput)

            var resetOutput: [UInt8]? = [UInt8](repeating: 0, count: encoder.estimateOutputLength(sample.count))
            let resetCount = try clone.flush(sample, startIndex: 0, length: sample.count, output: &resetOutput)

            #expect(Array(freshOutput?.prefix(freshCount) ?? []) == Array(resetOutput?.prefix(resetCount) ?? []), sourceLocation: sourceLocation)
        } catch {
            Issue.record("Unexpected error: \(error)", sourceLocation: sourceLocation)
        }
    }

    static func testEncoder(_ encoder: any MimeEncoder, fileName: String, rawData: [UInt8], encodedFile: String, bufferSize: Int, sourceLocation: SourceLocation = #_sourceLocation) {
        let expectedData = try! TestHelper.loadData(relativePath: "\(dataDir)/\(encodedFile)")
        let expectedStream = FilteredStream()
        expectedStream.add(Dos2UnixFilter())
        expectedStream.write(expectedData, startIndex: 0, length: expectedData.count)
        expectedStream.flush()
        let expected = expectedStream.toByteArray()

        let encodedStream = FilteredStream()
        encodedStream.add(EncoderFilter(encoder: encoder))

        var index = 0
        while index < rawData.count {
            let chunkSize = min(bufferSize, rawData.count - index)
            encodedStream.write(rawData, startIndex: index, length: chunkSize)
            index += chunkSize
        }
        encodedStream.flush()

        var actual = encodedStream.toByteArray()
        if encoder.encoding == .uuEncode {
            let begin = Array("begin 644 \(fileName)\n".utf8)
            let end = Array("end\n".utf8)
            actual = begin + actual + end
        }

        #expect(actual == expected, sourceLocation: sourceLocation)
    }

    static func testEncoderFlush(_ encoder: any MimeEncoder, fileName: String, rawData: [UInt8], encodedFile: String, sourceLocation: SourceLocation = #_sourceLocation) {
        let expectedData = try! TestHelper.loadData(relativePath: "\(dataDir)/\(encodedFile)")
        let expectedStream = FilteredStream()
        expectedStream.add(Dos2UnixFilter())
        expectedStream.write(expectedData, startIndex: 0, length: expectedData.count)
        expectedStream.flush()
        let expected = expectedStream.toByteArray()

        let outputLength = encoder.estimateOutputLength(rawData.count)
        var output: [UInt8]? = [UInt8](repeating: 0, count: outputLength)
        let count: Int
        do {
            count = try encoder.flush(rawData, startIndex: 0, length: rawData.count, output: &output)
        } catch {
            Issue.record("Unexpected error: \(error)", sourceLocation: sourceLocation)
            return
        }
        var actual = Array(output?.prefix(count) ?? [])

        if encoder.encoding == .uuEncode {
            let begin = Array("begin 644 \(fileName)\n".utf8)
            let end = Array("end\n".utf8)
            actual = begin + actual + end
        }

        #expect(actual == expected, sourceLocation: sourceLocation)
    }
}
