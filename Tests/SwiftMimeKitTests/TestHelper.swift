import Foundation

enum TestHelper {
    static var testDataURL: URL {
        guard let url = Bundle.module.url(forResource: "TestData", withExtension: nil) else {
            fatalError("Missing TestData resources")
        }
        return url
    }

    static func dataURL(for relativePath: String) -> URL {
        return testDataURL.appendingPathComponent(relativePath)
    }

    static func loadData(relativePath: String) throws -> [UInt8] {
        let url = dataURL(for: relativePath)
        let data = try Data(contentsOf: url)
        return Array(data)
    }

    static var isoLatinHebrew: String.Encoding {
        let cfEncoding = CFStringEncodings.isoLatinHebrew.rawValue
        let nsEncoding = CFStringConvertEncodingToNSStringEncoding(CFStringEncoding(cfEncoding))
        return String.Encoding(rawValue: nsEncoding)
    }
}
