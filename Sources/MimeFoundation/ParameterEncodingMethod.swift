//
// ParameterEncodingMethod.swift
//
// Ported from MimeKit (C#) to Swift.
//

/// The method to use for encoding Content-Type and Content-Disposition parameter values.
///
/// The MIME specifications specify that the proper method for encoding Content-Type and
/// Content-Disposition parameter values is the method described in
/// [RFC 2231](https://tools.ietf.org/html/rfc2231). However, it is common for
/// some older email clients to improperly encode using the method described in
/// [RFC 2047](https://tools.ietf.org/html/rfc2047) instead.
public enum ParameterEncodingMethod: UInt8, Sendable {
    /// Use the default encoding method set on the ``FormatOptions``.
    case `default` = 0

    /// Use the encoding method described in RFC 2231.
    ///
    /// This is the proper method for encoding Content-Type and Content-Disposition
    /// parameter values according to the MIME specifications.
    case rfc2231 = 1

    /// Use the encoding method described in RFC 2047.
    ///
    /// Use this method for compatibility with older, non-RFC-compliant email clients
    /// that do not properly support RFC 2231 encoding.
    case rfc2047 = 2
}
