import Testing
@testable import SwiftMimeKit

enum MimeDecoderTestsBase {
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

    static func assertArgumentExceptions(_ decoder: any MimeDecoder, sourceLocation: SourceLocation = #_sourceLocation) {
        var output: [UInt8]? = []
        #expect(throws: (any Error).self, sourceLocation: sourceLocation) {
            try decoder.decode(nil, startIndex: 0, length: 0, output: &output)
        }

        output = []
        #expect(throws: (any Error).self, sourceLocation: sourceLocation) {
            try decoder.decode([], startIndex: -1, length: 0, output: &output)
        }

        output = []
        #expect(throws: (any Error).self, sourceLocation: sourceLocation) {
            try decoder.decode([UInt8](repeating: 0, count: 1), startIndex: 0, length: 10, output: &output)
        }

        var nilOutput: [UInt8]? = nil
        #expect(throws: (any Error).self, sourceLocation: sourceLocation) {
            try decoder.decode([UInt8](repeating: 0, count: 1), startIndex: 0, length: 1, output: &nilOutput)
        }

        output = []
        #expect(throws: (any Error).self, sourceLocation: sourceLocation) {
            try decoder.decode([UInt8](repeating: 0, count: 1), startIndex: 0, length: 1, output: &output)
        }
    }

    static func cloneAndAssert(_ decoder: any MimeDecoder, sample: [UInt8], sourceLocation: SourceLocation = #_sourceLocation) {
        let prefixLength = min(4, sample.count)
        var output: [UInt8]? = [UInt8](repeating: 0, count: decoder.estimateOutputLength(sample.count))
        do {
            _ = try decoder.decode(sample, startIndex: 0, length: prefixLength, output: &output)
        } catch {
            Issue.record("Unexpected error: \(error)", sourceLocation: sourceLocation)
            return
        }

        let clone = decoder.clone()
        let remainingLength = sample.count - prefixLength
        var output1: [UInt8]? = [UInt8](repeating: 0, count: decoder.estimateOutputLength(remainingLength))
        var output2: [UInt8]? = [UInt8](repeating: 0, count: decoder.estimateOutputLength(remainingLength))
        do {
            let n1 = try decoder.decode(sample, startIndex: prefixLength, length: remainingLength, output: &output1)
            let n2 = try clone.decode(sample, startIndex: prefixLength, length: remainingLength, output: &output2)
            #expect(Array(output1?.prefix(n1) ?? []) == Array(output2?.prefix(n2) ?? []), sourceLocation: sourceLocation)
        } catch {
            Issue.record("Unexpected error: \(error)", sourceLocation: sourceLocation)
        }
    }

    static func resetAndAssert(_ decoder: any MimeDecoder, sample: [UInt8], sourceLocation: SourceLocation = #_sourceLocation) {
        let clone = decoder.clone()
        let prefixLength = min(6, sample.count)
        var output: [UInt8]? = [UInt8](repeating: 0, count: decoder.estimateOutputLength(sample.count))
        do {
            _ = try clone.decode(sample, startIndex: 0, length: prefixLength, output: &output)
            clone.reset()

            var freshOutput: [UInt8]? = [UInt8](repeating: 0, count: decoder.estimateOutputLength(sample.count))
            let freshCount = try decoder.decode(sample, startIndex: 0, length: sample.count, output: &freshOutput)

            var resetOutput: [UInt8]? = [UInt8](repeating: 0, count: decoder.estimateOutputLength(sample.count))
            let resetCount = try clone.decode(sample, startIndex: 0, length: sample.count, output: &resetOutput)

            #expect(Array(freshOutput?.prefix(freshCount) ?? []) == Array(resetOutput?.prefix(resetCount) ?? []), sourceLocation: sourceLocation)
        } catch {
            Issue.record("Unexpected error: \(error)", sourceLocation: sourceLocation)
        }
    }

    static func testDecoder(_ decoder: any MimeDecoder, rawData: [UInt8], encodedFile: String, bufferSize: Int, unix: Bool = false, sourceLocation: SourceLocation = #_sourceLocation) {
        let data = try! TestHelper.loadData(relativePath: "\(dataDir)/\(encodedFile)")
        let decodedOutput = MemoryStream([], writable: true)
        let decodedStream = try! FilteredStream(decodedOutput)
        try! decodedStream.add(DecoderFilter(decoder))
        if unix {
            try! decodedStream.add(Dos2UnixFilter())
        }

        var index = 0
        while index < data.count {
            let chunkSize = min(bufferSize, data.count - index)
            try! decodedStream.write(data, offset: index, count: chunkSize)
            index += chunkSize
        }
        try! decodedStream.flush()

        let actual = decodedOutput.toByteArray()
        #expect(actual == rawData, sourceLocation: sourceLocation)
    }
}
