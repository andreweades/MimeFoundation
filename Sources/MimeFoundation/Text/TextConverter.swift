//
// TextConverter.swift
//
// Ported from MimeKit (C#) to Swift.
//

import Foundation

open class TextConverter {
    static let urlPatterns: [UrlPattern] = [
        UrlPattern(type: .addrspec, pattern: "@", prefix: "mailto:"),
        UrlPattern(type: .mailto, pattern: "mailto:", prefix: ""),
        UrlPattern(type: .web, pattern: "www.", prefix: "http://"),
        UrlPattern(type: .web, pattern: "ftp.", prefix: "ftp://"),
        UrlPattern(type: .file, pattern: "file://", prefix: ""),
        UrlPattern(type: .web, pattern: "ftp://", prefix: ""),
        UrlPattern(type: .web, pattern: "sftp://", prefix: ""),
        UrlPattern(type: .web, pattern: "http://", prefix: ""),
        UrlPattern(type: .web, pattern: "https://", prefix: ""),
        UrlPattern(type: .web, pattern: "news://", prefix: ""),
        UrlPattern(type: .web, pattern: "nntp://", prefix: ""),
        UrlPattern(type: .web, pattern: "telnet://", prefix: ""),
        UrlPattern(type: .web, pattern: "webcal://", prefix: ""),
        UrlPattern(type: .web, pattern: "callto:", prefix: ""),
        UrlPattern(type: .web, pattern: "h323:", prefix: ""),
        UrlPattern(type: .web, pattern: "sip:", prefix: "")
    ]

    public var detectEncodingFromByteOrderMark: Bool = false
    public var inputEncoding: String.Encoding = .utf8
    public var outputEncoding: String.Encoding = .utf8

    private var inputStreamBufferSizeStorage: Int = 4096
    private var outputStreamBufferSizeStorage: Int = 4096

    public var inputStreamBufferSize: Int {
        get { inputStreamBufferSizeStorage }
        set {
            guard newValue > 0 else { return }
            inputStreamBufferSizeStorage = newValue
        }
    }

    public var outputStreamBufferSize: Int {
        get { outputStreamBufferSizeStorage }
        set {
            guard newValue > 0 else { return }
            outputStreamBufferSizeStorage = newValue
        }
    }

    public var footer: String?
    public var header: String?

    public init() {
    }

    open var inputFormat: TextFormat {
        fatalError("Override in subclasses")
    }

    open var outputFormat: TextFormat {
        fatalError("Override in subclasses")
    }

    open func convert(_ reader: TextReadable, _ writer: TextWritable) {
        fatalError("Override in subclasses")
    }

    public func convert(_ text: String) -> String {
        let reader = StringReader(text)
        let writer = StringWriter()
        convert(reader, writer)
        return writer.string
    }

    public func convert(_ data: Data) -> Data {
        let (encoding, offset) = resolveInputEncoding(for: data)
        let slice = data.subdata(in: offset..<data.count)
        let text = String(data: slice, encoding: encoding) ?? ""
        let converted = convert(text)
        return converted.data(using: outputEncoding) ?? Data()
    }

    private func resolveInputEncoding(for data: Data) -> (String.Encoding, Int) {
        guard detectEncodingFromByteOrderMark, data.count >= 2 else {
            return (inputEncoding, 0)
        }

        let bytes = [UInt8](data.prefix(4))

        if bytes.count >= 3, bytes[0] == 0xEF, bytes[1] == 0xBB, bytes[2] == 0xBF {
            return (.utf8, 3)
        }

        if bytes.count >= 4 {
            if bytes[0] == 0xFF, bytes[1] == 0xFE, bytes[2] == 0x00, bytes[3] == 0x00 {
                return (.utf32LittleEndian, 4)
            }
            if bytes[0] == 0x00, bytes[1] == 0x00, bytes[2] == 0xFE, bytes[3] == 0xFF {
                return (.utf32BigEndian, 4)
            }
        }

        if bytes[0] == 0xFF, bytes[1] == 0xFE {
            return (.utf16LittleEndian, 2)
        }
        if bytes[0] == 0xFE, bytes[1] == 0xFF {
            return (.utf16BigEndian, 2)
        }

        return (inputEncoding, 0)
    }
}
