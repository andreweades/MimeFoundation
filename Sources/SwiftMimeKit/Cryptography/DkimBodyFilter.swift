//
// DkimBodyFilter.swift
//
// Ported from MimeKit (C#) to Swift.
//

class DkimBodyFilter: MimeFilterBase {
    var lastWasNewLine: Bool = false
    var isEmptyLine: Bool = false
    var emptyLines: Int = 0
}
