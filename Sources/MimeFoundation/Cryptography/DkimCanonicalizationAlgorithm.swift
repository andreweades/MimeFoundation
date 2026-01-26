//
// DkimCanonicalizationAlgorithm.swift
//
// Ported from MimeKit (C#) to Swift.
//

/// A DKIM canonicalization algorithm.
///
/// Empirical evidence demonstrates that some mail servers and relay systems
/// modify email in transit, potentially invalidating a signature. There are two
/// competing perspectives on such modifications.
///
/// For most signers, mild modification of email is immaterial to the authentication
/// status of the email. For such signers, a canonicalization algorithm that survives
/// modest in-transit modification is preferred (``relaxed``).
///
/// Other signers demand that any modification of the email, however minor, result
/// in a signature verification failure. These signers prefer a canonicalization
/// algorithm that does not tolerate in-transit modification of the signed email
/// (``simple``).
///
/// ## Topics
///
/// ### Canonicalization Algorithms
/// - ``simple``
/// - ``relaxed``
public enum DkimCanonicalizationAlgorithm: Sendable {
    /// The simple canonicalization algorithm.
    ///
    /// This algorithm tolerates almost no modification by mail servers while
    /// the message is in-transit. Use this when you require strict integrity
    /// verification and want any modification to invalidate the signature.
    case simple

    /// The relaxed canonicalization algorithm.
    ///
    /// This algorithm tolerates common modifications by mail servers while
    /// the message is in-transit, such as whitespace replacement and header
    /// field line rewrapping. This is the recommended algorithm for most use
    /// cases as it provides better compatibility with various mail systems.
    case relaxed
}
