//
// DkimVerifier.swift
//
// Ported from MimeKit (C#) to Swift.
//

import Foundation

public final class DkimVerifier: DkimVerifierBase {
    public override init(publicKeyLocator: DkimPublicKeyLocator) {
        super.init(publicKeyLocator: publicKeyLocator)
    }

    public func verify(_ options: FormatOptions, _ message: MimeMessage, _ dkimSignature: Header, cancellationToken: CancellationToken? = nil) throws -> Bool {
        try verifyInternal(options: options, message: message, dkimSignature: dkimSignature, cancellationToken: cancellationToken)
    }

    public func verify(_ message: MimeMessage, _ dkimSignature: Header, cancellationToken: CancellationToken? = nil) throws -> Bool {
        try verify(.default, message, dkimSignature, cancellationToken: cancellationToken)
    }

    public func verifyAsync(_ options: FormatOptions, _ message: MimeMessage, _ dkimSignature: Header, cancellationToken: CancellationToken? = nil) async throws -> Bool {
        try await verifyInternalAsync(options: options, message: message, dkimSignature: dkimSignature, cancellationToken: cancellationToken)
    }

    public func verifyAsync(_ message: MimeMessage, _ dkimSignature: Header, cancellationToken: CancellationToken? = nil) async throws -> Bool {
        try await verifyAsync(.default, message, dkimSignature, cancellationToken: cancellationToken)
    }

    private func verifyInternal(options: FormatOptions, message: MimeMessage, dkimSignature: Header, cancellationToken: CancellationToken?) throws -> Bool {
        var options = options.copy()
        options.newLineFormat = .dos

        guard dkimSignature.id == .dkimSignature else {
            throw DkimVerifierError.invalidArgument
        }

        let parameters = try DkimVerifierBase.parseParameterTags(headerId: dkimSignature.id, signature: dkimSignature.value)
        let validated = try validateDkimSignatureParameters(parameters)

        if !isEnabled(validated.algorithm) {
            return false
        }

        let bodyOk = try DkimVerifierBase.verifyBodyHash(options: options, message: message, signatureAlgorithm: validated.algorithm, canonicalizationAlgorithm: validated.bodyAlgorithm, maxLength: validated.maxLength, bodyHash: validated.bh)
        if !bodyOk {
            return false
        }

        let key = try locatePublicKey(methods: validated.q, domain: validated.d, selector: validated.s, cancellationToken: cancellationToken)

        if case .rsa(let rsa) = key {
            if rsa.keySizeInBits < minimumRsaKeyLength {
                return false
            }
        }

        return try verifySignature(options: options, message: message, dkimSignature: dkimSignature, signatureAlgorithm: validated.algorithm, key: key, headers: validated.headers, canonicalizationAlgorithm: validated.headerAlgorithm, signature: validated.b)
    }

    private func verifyInternalAsync(options: FormatOptions, message: MimeMessage, dkimSignature: Header, cancellationToken: CancellationToken?) async throws -> Bool {
        var options = options.copy()
        options.newLineFormat = .dos

        guard dkimSignature.id == .dkimSignature else {
            throw DkimVerifierError.invalidArgument
        }

        let parameters = try DkimVerifierBase.parseParameterTags(headerId: dkimSignature.id, signature: dkimSignature.value)
        let validated = try validateDkimSignatureParameters(parameters)

        if !isEnabled(validated.algorithm) {
            return false
        }

        let bodyOk = try DkimVerifierBase.verifyBodyHash(options: options, message: message, signatureAlgorithm: validated.algorithm, canonicalizationAlgorithm: validated.bodyAlgorithm, maxLength: validated.maxLength, bodyHash: validated.bh)
        if !bodyOk {
            return false
        }

        let key = try await locatePublicKeyAsync(methods: validated.q, domain: validated.d, selector: validated.s, cancellationToken: cancellationToken)
        if case .rsa(let rsa) = key {
            if rsa.keySizeInBits < minimumRsaKeyLength {
                return false
            }
        }

        return try verifySignature(options: options, message: message, dkimSignature: dkimSignature, signatureAlgorithm: validated.algorithm, key: key, headers: validated.headers, canonicalizationAlgorithm: validated.headerAlgorithm, signature: validated.b)
    }

    private func validateDkimSignatureParameters(_ parameters: [String: String]) throws -> (algorithm: DkimSignatureAlgorithm, headerAlgorithm: DkimCanonicalizationAlgorithm, bodyAlgorithm: DkimCanonicalizationAlgorithm, d: String, s: String, q: String, headers: [String], bh: String, b: String, maxLength: Int) {
        guard let v = parameters["v"] else {
            throw DkimVerifierError.malformedHeader("Malformed DKIM-Signature header: no version parameter detected.")
        }
        guard v == "1" else {
            throw DkimVerifierError.malformedHeader("Unrecognized DKIM-Signature version: v=\(v)")
        }

        let common = try DkimVerifierBase.validateCommonSignatureParameters(header: "DKIM-Signature", parameters: parameters)

        let containsFrom = common.headers.contains { $0.caseInsensitiveCompare("from") == .orderedSame }
        if !containsFrom {
            throw DkimVerifierError.malformedHeader("Malformed DKIM-Signature header: From header not signed.")
        }

        if let id = parameters["i"] {
            if let atIndex = id.lastIndex(of: "@") {
                let domain = String(id[id.index(after: atIndex)...])
                let domainLower = domain.lowercased()
                let dLower = common.d.lowercased()
                if domainLower != dLower && !domainLower.hasSuffix("." + dLower) {
                    throw DkimVerifierError.malformedHeader("Invalid DKIM-Signature header: the domain in the AUID does not match the domain parameter.")
                }
            } else {
                throw DkimVerifierError.malformedHeader("Malformed DKIM-Signature header: no @ in the AUID value.")
            }
        }

        return common
    }
}
