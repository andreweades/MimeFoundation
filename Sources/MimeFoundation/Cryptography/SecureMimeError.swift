//
// SecureMimeError.swift
//
// Error types for S/MIME operations.
//

import Foundation

/// Errors that can occur during S/MIME operations.
public enum SecureMimeError: Error, Equatable, Sendable {
    /// The certificate is invalid or could not be parsed.
    case invalidCertificate(String)

    /// The private key is invalid or could not be parsed.
    case invalidPrivateKey(String)

    /// The specified algorithm is not supported.
    case unsupportedAlgorithm(String)

    /// Signature verification failed.
    case signatureVerificationFailed(String)

    /// Failed to load PKCS#12 data.
    case pkcs12LoadFailed(String)

    /// The signature data is malformed or invalid.
    case invalidSignatureData(String)

    /// The signed content does not match the signature.
    case contentMismatch(String)

    /// No signer certificate was found in the signature.
    case noSignerCertificate

    /// Failed to create the signature.
    case signingFailed(String)

    /// The multipart/signed structure is invalid.
    case invalidMultipartSigned(String)

    /// File read operation failed.
    case fileReadFailed(String)

    /// An argument was invalid.
    case invalidArgument(String)
}

extension SecureMimeError: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .invalidCertificate(let message):
            return "Invalid certificate: \(message)"
        case .invalidPrivateKey(let message):
            return "Invalid private key: \(message)"
        case .unsupportedAlgorithm(let algorithm):
            return "Unsupported algorithm: \(algorithm)"
        case .signatureVerificationFailed(let message):
            return "Signature verification failed: \(message)"
        case .pkcs12LoadFailed(let message):
            return "Failed to load PKCS#12: \(message)"
        case .invalidSignatureData(let message):
            return "Invalid signature data: \(message)"
        case .contentMismatch(let message):
            return "Content mismatch: \(message)"
        case .noSignerCertificate:
            return "No signer certificate found in signature"
        case .signingFailed(let message):
            return "Signing failed: \(message)"
        case .invalidMultipartSigned(let message):
            return "Invalid multipart/signed: \(message)"
        case .fileReadFailed(let message):
            return "File read failed: \(message)"
        case .invalidArgument(let message):
            return "Invalid argument: \(message)"
        }
    }
}
