//
// FormatOptions+Filters.swift
//
// Ported from MimeKit (C#) to Swift.
//

extension FormatOptions {
    internal func createNewLineFilter(_ ensureNewLine: Bool) -> MimeFilter {
        switch newLineFormat {
        case .unix:
            return Dos2UnixFilter(ensureNewLine)
        case .mixed, .dos:
            return Unix2DosFilter(ensureNewLine)
        }
    }
}
