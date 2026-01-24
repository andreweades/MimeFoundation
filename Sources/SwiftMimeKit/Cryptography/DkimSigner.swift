//
// DkimSigner.swift
//
// Ported from MimeKit (C#) to Swift.
//

import Foundation

public final class DkimSigner: DkimSignerBase {
    private static let shouldNotInclude: Set<String> = [
        "return-path",
        "received",
        "comments",
        "keywords",
        "bcc",
        "resent-bcc",
        "dkim-signature"
    ]

    public var agentOrUserIdentifier: String?
    public var queryMethod: String?

    public func sign(_ options: FormatOptions, _ message: MimeMessage, headers: [String]) throws {
        let fields = try validateHeaderFields(headers)
        try dkimSign(options, message: message, headers: fields)
    }

    public func sign(_ message: MimeMessage, headers: [String]) throws {
        try sign(.default, message, headers: headers)
    }

    public func sign(_ options: FormatOptions, _ message: MimeMessage, headers: [HeaderId]) throws {
        var fields: [String] = []
        fields.reserveCapacity(headers.count)
        var containsFrom = false

        for header in headers {
            if header == .unknown {
                throw DkimSignerError.invalidArgument
            }
            let field = header.headerName.lowercased()
            if DkimSigner.shouldNotInclude.contains(field) {
                throw DkimSignerError.invalidArgument
            }
            if header == .from {
                containsFrom = true
            }
            fields.append(field)
        }

        guard containsFrom else {
            throw DkimSignerError.invalidArgument
        }

        try dkimSign(options, message: message, headers: fields)
    }

    public func sign(_ message: MimeMessage, headers: [HeaderId]) throws {
        try sign(.default, message, headers: headers)
    }

    private func validateHeaderFields(_ headers: [String]) throws -> [String] {
        var fields: [String] = []
        fields.reserveCapacity(headers.count)
        var containsFrom = false

        for header in headers {
            guard !header.isEmpty else {
                throw DkimSignerError.invalidArgument
            }
            let field = header.lowercased()
            if DkimSigner.shouldNotInclude.contains(field) {
                throw DkimSignerError.invalidArgument
            }
            if field == "from" {
                containsFrom = true
            }
            fields.append(field)
        }

        guard containsFrom else {
            throw DkimSignerError.invalidArgument
        }

        return fields
    }

    private func dkimSign(_ options: FormatOptions, message: MimeMessage, headers: [String]) throws {
        var signingOptions = options.clone()
        signingOptions.newLineFormat = .dos
        signingOptions.ensureNewLine = true

        var builder = ValueStringBuilder(initialCapacity: 256)
        let timestamp = getTimestamp()

        builder.append("v=1")

        switch signatureAlgorithm {
        case .ed25519Sha256:
            builder.append("; a=ed25519-sha256")
        case .rsaSha256:
            builder.append("; a=rsa-sha256")
        case .rsaSha1:
            builder.append("; a=rsa-sha1")
        }

        builder.append("; d=")
        builder.append(domain)
        builder.append("; s=")
        builder.append(selector)
        builder.append("; c=")
        builder.append(canonicalizationToken(headerCanonicalizationAlgorithm))
        builder.append("/")
        builder.append(canonicalizationToken(bodyCanonicalizationAlgorithm))

        if let queryMethod, !queryMethod.isEmpty {
            builder.append("; q=")
            builder.append(queryMethod)
        }
        if let agentOrUserIdentifier, !agentOrUserIdentifier.isEmpty {
            builder.append("; i=")
            builder.append(agentOrUserIdentifier)
        }

        builder.append("; t=")
        builder.append(String(timestamp))

        if let expiresAfter = signaturesExpireAfter {
            let expiration = timestamp + Int64(expiresAfter)
            builder.append("; x=")
            builder.append(String(expiration))
        }

        let context = try createSigningContext()
        let stream = try DkimSignatureStream(context)
        let filtered = try FilteredStream(stream)
        try filtered.add(signingOptions.createNewLineFilter(false))

        try DkimVerifierBase.writeHeaders(options: signingOptions, message: message, fields: headers, canonicalization: headerCanonicalizationAlgorithm, stream: filtered)

        builder.append("; h=")
        builder.appendJoin(separator: ":", values: headers)

        let bodyHash = try message.hashBody(signingOptions, signatureAlgorithm: signatureAlgorithm, bodyCanonicalization: bodyCanonicalizationAlgorithm, maxLength: -1)
        builder.append("; bh=")
        builder.append(Data(bodyHash).base64EncodedString())
        builder.append("; b=")

        let dkimHeader = Header(.dkimSignature, value: builder.toString())
        message.headers.insert(dkimHeader, at: 0)

        switch headerCanonicalizationAlgorithm {
        case .relaxed:
            try DkimVerifierBase.writeHeaderRelaxed(options: signingOptions, stream: filtered, header: dkimHeader, isDkimSignature: true)
        case .simple:
            try DkimVerifierBase.writeHeaderSimple(options: signingOptions, stream: filtered, header: dkimHeader, isDkimSignature: true)
        }

        try filtered.flush()

        let signature = try stream.generateSignature()
        dkimHeader.value += Data(signature).base64EncodedString()
    }

    private func canonicalizationToken(_ algorithm: DkimCanonicalizationAlgorithm) -> String {
        switch algorithm {
        case .relaxed:
            return "relaxed"
        case .simple:
            return "simple"
        }
    }

    private func getTimestamp() -> Int64 {
        Int64(Date().timeIntervalSince1970)
    }
}
