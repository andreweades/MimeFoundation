//
// MimeEncoder.swift
//
// Ported from MimeKit (C#) to Swift.
//

public enum MimeCodingError: Error, Equatable {
    case inputNil
    case outputNil
    case startIndexOutOfRange
    case lengthOutOfRange
    case outputTooSmall
}

public protocol MimeEncoder {
    var encoding: ContentEncoding { get }
    func clone() -> any MimeEncoder
    func estimateOutputLength(_ inputLength: Int) -> Int
    func encode(_ input: [UInt8]?, startIndex: Int, length: Int, output: inout [UInt8]?) throws -> Int
    func flush(_ input: [UInt8]?, startIndex: Int, length: Int, output: inout [UInt8]?) throws -> Int
    func reset()
}

public protocol MimeDecoder {
    var encoding: ContentEncoding { get }
    func clone() -> any MimeDecoder
    func estimateOutputLength(_ inputLength: Int) -> Int
    func decode(_ input: [UInt8]?, startIndex: Int, length: Int, output: inout [UInt8]?) throws -> Int
    func reset()
}
