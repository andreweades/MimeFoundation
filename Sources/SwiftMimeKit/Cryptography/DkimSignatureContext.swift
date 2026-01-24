//
// DkimSignatureContext.swift
//
// Ported from MimeKit (C#) to Swift.
//

protocol DkimSignatureContext {
    func update(_ buffer: [UInt8], offset: Int, count: Int)
    func generateSignature() throws -> [UInt8]
    func verify(signature: [UInt8]) throws -> Bool
}
