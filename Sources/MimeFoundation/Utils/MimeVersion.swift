//
// MimeVersion.swift
//
// Ported from MimeKit (C#) to Swift.
//

/// Represents a MIME version number.
///
/// `MimeVersion` represents the version number found in the MIME-Version header
/// of MIME messages. The standard MIME version is "1.0", but this type supports
/// version numbers with 2 to 4 components for flexibility.
///
/// ## Parsing MIME Versions
///
/// Use ``MimeUtils/tryParseVersion(_:)-1ygnx`` to parse version strings:
///
/// ```swift
/// if let version = MimeUtils.tryParseVersion("1.0") {
///     print(version)  // "1.0"
/// }
/// ```
///
/// ## Version Components
///
/// The version is stored as an array of integer components. For example:
/// - "1.0" -> `[1, 0]`
/// - "1.0.0" -> `[1, 0, 0]`
/// - "1.0.0.0" -> `[1, 0, 0, 0]`
public struct MimeVersion: Equatable, CustomStringConvertible, Sendable {
    /// The version number components.
    ///
    /// For a version string like "1.0", this array contains `[1, 0]`.
    /// The array always contains between 2 and 4 elements.
    public let components: [Int]

    /// Creates a new MIME version from the specified components.
    ///
    /// - Parameter components: An array of 2 to 4 integer version components.
    /// - Returns: A new `MimeVersion`, or `nil` if the component count is invalid.
    ///
    /// ## Example
    ///
    /// ```swift
    /// let version = MimeVersion(components: [1, 0])
    /// print(version!)  // "1.0"
    /// ```
    public init?(components: [Int]) {
        guard (2...4).contains(components.count) else {
            return nil
        }
        self.components = components
    }

    /// A string representation of the version number.
    ///
    /// Returns the components joined by periods, e.g., "1.0" or "1.0.0".
    public var description: String {
        components.map(String.init).joined(separator: ".")
    }
}
