import Testing
@testable import MimeFoundation

enum MimeEncoderTestsBase {
    static let dataDir = "encoders"
    static let wikipediaUnix: [UInt8] = {
        let data = try! TestHelper.loadData(relativePath: "\(dataDir)/wikipedia.txt")
        let output = MemoryStream([], writable: true)
        let filtered = try! FilteredStream(output)
        try! filtered.add(Dos2UnixFilter())
        try! filtered.write(data, offset: 0, count: data.count)
        try! filtered.flush()
        return output.toByteArray()
    }()
    static let wikipediaDos: [UInt8] = {
        let data = try! TestHelper.loadData(relativePath: "\(dataDir)/wikipedia.txt")
        let output = MemoryStream([], writable: true)
        let filtered = try! FilteredStream(output)
        try! filtered.add(Unix2DosFilter())
        try! filtered.write(data, offset: 0, count: data.count)
        try! filtered.flush()
        return output.toByteArray()
    }()
    static let photo: [UInt8] = {
        try! TestHelper.loadData(relativePath: "\(dataDir)/photo.jpg")
    }()

    static func assertArgumentExceptions(_ encoder: any MimeEncoder, sourceLocation: SourceLocation = #_sourceLocation) {
        var output = [UInt8]()

        #expect(throws: (any Error).self, sourceLocation: sourceLocation) {
            try encoder.encode([], startIndex: -1, length: 0, output: &output)
        }

        output = []
        #expect(throws: (any Error).self, sourceLocation: sourceLocation) {
            try encoder.encode([UInt8](repeating: 0, count: 1), startIndex: 0, length: 10, output: &output)
        }

        output = []
        #expect(throws: (any Error).self, sourceLocation: sourceLocation) {
            try encoder.encode([UInt8](repeating: 0, count: 1), startIndex: 0, length: 1, output: &output)
        }

        output = []
        #expect(throws: (any Error).self, sourceLocation: sourceLocation) {
            try encoder.flush([], startIndex: -1, length: 0, output: &output)
        }

        output = []
        #expect(throws: (any Error).self, sourceLocation: sourceLocation) {
            try encoder.flush([UInt8](repeating: 0, count: 1), startIndex: 0, length: 10, output: &output)
        }

        output = []
        #expect(throws: (any Error).self, sourceLocation: sourceLocation) {
            try encoder.flush([UInt8](repeating: 0, count: 1), startIndex: 0, length: 1, output: &output)
        }
    }

    static func cloneAndAssert(_ encoder: any MimeEncoder, sample: [UInt8], sourceLocation: SourceLocation = #_sourceLocation) {
        let prefixLength = min(3, sample.count)
        var output = [UInt8](repeating: 0, count: encoder.estimateOutputLength(sample.count))
        do {
            _ = try encoder.encode(sample, startIndex: 0, length: prefixLength, output: &output)
        } catch {
            Issue.record("Unexpected error: \(error)", sourceLocation: sourceLocation)
            return
        }

        let clone = encoder.copy()
        let remainingLength = sample.count - prefixLength
        var output1 = [UInt8](repeating: 0, count: encoder.estimateOutputLength(remainingLength))
        var output2 = [UInt8](repeating: 0, count: encoder.estimateOutputLength(remainingLength))
        do {
            let n1 = try encoder.flush(sample, startIndex: prefixLength, length: remainingLength, output: &output1)
            let n2 = try clone.flush(sample, startIndex: prefixLength, length: remainingLength, output: &output2)
            #expect(Array(output1.prefix(n1)) == Array(output2.prefix(n2)), sourceLocation: sourceLocation)
        } catch {
            Issue.record("Unexpected error: \(error)", sourceLocation: sourceLocation)
        }
    }

    static func resetAndAssert(_ encoder: any MimeEncoder, sample: [UInt8], sourceLocation: SourceLocation = #_sourceLocation) {
        let clone = encoder.copy()
        let prefixLength = min(5, sample.count)
        var output = [UInt8](repeating: 0, count: encoder.estimateOutputLength(sample.count))
        do {
            _ = try clone.encode(sample, startIndex: 0, length: prefixLength, output: &output)
            clone.reset()

            var freshOutput = [UInt8](repeating: 0, count: encoder.estimateOutputLength(sample.count))
            let freshCount = try encoder.flush(sample, startIndex: 0, length: sample.count, output: &freshOutput)

            var resetOutput = [UInt8](repeating: 0, count: encoder.estimateOutputLength(sample.count))
            let resetCount = try clone.flush(sample, startIndex: 0, length: sample.count, output: &resetOutput)

            #expect(Array(freshOutput.prefix(freshCount)) == Array(resetOutput.prefix(resetCount)), sourceLocation: sourceLocation)
        } catch {
            Issue.record("Unexpected error: \(error)", sourceLocation: sourceLocation)
        }
    }

    static func testEncoder(_ encoder: any MimeEncoder, fileName: String, rawData: [UInt8], encodedFile: String, bufferSize: Int, sourceLocation: SourceLocation = #_sourceLocation) {
        let expectedData = try! TestHelper.loadData(relativePath: "\(dataDir)/\(encodedFile)")
        let expectedOutput = MemoryStream([], writable: true)
        let expectedStream = try! FilteredStream(expectedOutput)
        try! expectedStream.add(Dos2UnixFilter())
        try! expectedStream.write(expectedData, offset: 0, count: expectedData.count)
        try! expectedStream.flush()
        let expected = expectedOutput.toByteArray()

        let encodedOutput = MemoryStream([], writable: true)
        let encodedStream = try! FilteredStream(encodedOutput)
        try! encodedStream.add(EncoderFilter(encoder))

        var index = 0
        while index < rawData.count {
            let chunkSize = min(bufferSize, rawData.count - index)
            try! encodedStream.write(rawData, offset: index, count: chunkSize)
            index += chunkSize
        }
        try! encodedStream.flush()

        var actual = encodedOutput.toByteArray()
        if encoder.encoding == .uuEncode {
            let begin = Array("begin 644 \(fileName)\n".utf8)
            let end = Array("end\n".utf8)
            actual = begin + actual + end
        }

        #expect(actual == expected, sourceLocation: sourceLocation)
    }

    static func testEncoderFlush(_ encoder: any MimeEncoder, fileName: String, rawData: [UInt8], encodedFile: String, sourceLocation: SourceLocation = #_sourceLocation) {
        let expectedData = try! TestHelper.loadData(relativePath: "\(dataDir)/\(encodedFile)")
        let expectedOutput = MemoryStream([], writable: true)
        let expectedStream = try! FilteredStream(expectedOutput)
        try! expectedStream.add(Dos2UnixFilter())
        try! expectedStream.write(expectedData, offset: 0, count: expectedData.count)
        try! expectedStream.flush()
        let expected = expectedOutput.toByteArray()

        let outputLength = encoder.estimateOutputLength(rawData.count)
        var output = [UInt8](repeating: 0, count: outputLength)
        let count: Int
        do {
            count = try encoder.flush(rawData, startIndex: 0, length: rawData.count, output: &output)
        } catch {
            Issue.record("Unexpected error: \(error)", sourceLocation: sourceLocation)
            return
        }
        var actual = Array(output.prefix(count))

        if encoder.encoding == .uuEncode {
            let begin = Array("begin 644 \(fileName)\n".utf8)
            let end = Array("end\n".utf8)
            actual = begin + actual + end
        }

        #expect(actual == expected, sourceLocation: sourceLocation)
    }
}
