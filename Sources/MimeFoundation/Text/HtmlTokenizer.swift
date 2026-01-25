//
// HtmlTokenizer.swift
//
// Ported from MimeKit (C#) to Swift.
//

final class HtmlTokenizer {
    var decodeCharacterReferences: Bool = true

    private let characters: [Character]
    private var index: Int = 0
    private var rawTextTag: String?

    init(_ reader: TextReadable) {
        let text = reader.readToEnd()
        self.characters = Array(text)
    }

    func readNextToken() -> HtmlToken? {
        if index >= characters.count {
            return nil
        }

        if let rawTextTag {
            if let closeIndex = findClosingTag(rawTextTag, from: index) {
                if closeIndex > index {
                    let data = String(characters[index..<closeIndex])
                    index = closeIndex
                    return HtmlDataToken(data)
                } else {
                    self.rawTextTag = nil
                }
            } else {
                let data = String(characters[index..<characters.count])
                index = characters.count
                return HtmlDataToken(data)
            }
        }

        let current = characters[index]
        if current == "<" {
            if startsWith("<!--", at: index) {
                return parseComment()
            }

            if startsWith("</", at: index) {
                return parseEndTag()
            }

            if startsWith("<!", at: index) {
                return parseDeclaration()
            }

            return parseStartTag()
        }

        return parseData()
    }

    private func parseData() -> HtmlToken? {
        let start = index
        var i = index
        var result = ""
        let entityDecoder = HtmlEntityDecoder()

        while i < characters.count {
            let c = characters[i]
            if c == "<" {
                break
            }

            if decodeCharacterReferences && c == "&" {
                entityDecoder.reset()
                var j = i
                var pushedCount = 0
                var foundSemicolon = false

                while j < characters.count {
                    let ec = characters[j]
                    if entityDecoder.push(ec) {
                        j += 1
                        pushedCount += 1
                        if ec == ";" {
                            foundSemicolon = true
                            break
                        }
                    } else {
                        break
                    }
                }

                if foundSemicolon {
                    result.append(entityDecoder.getValue())
                    i = j
                    continue
                }
            }

            result.append(c)
            i += 1
        }

        index = i
        if result.isEmpty && start == i {
            return nil
        }
        return HtmlDataToken(result)
    }

    private func parseDeclaration() -> HtmlToken {
        let start = index
        var i = index
        while i < characters.count {
            if characters[i] == ">" {
                i += 1
                break
            }
            i += 1
        }
        index = i
        return HtmlDataToken(String(characters[start..<i]))
    }

    private func parseComment() -> HtmlToken {
        let start = index + 4
        var i = start
        while i + 2 < characters.count {
            if characters[i] == "-", characters[i + 1] == "-", characters[i + 2] == ">" {
                let comment = String(characters[start..<i])
                index = i + 3
                return HtmlCommentToken(comment)
            }
            i += 1
        }

        let comment = String(characters[start..<characters.count])
        index = characters.count
        return HtmlCommentToken(comment)
    }

    private func parseEndTag() -> HtmlToken {
        var i = index + 2
        while i < characters.count, characters[i].isWhitespace {
            i += 1
        }
        let nameStart = i
        while i < characters.count, !characters[i].isWhitespace, characters[i] != ">" {
            i += 1
        }
        let name = String(characters[nameStart..<i])

        while i < characters.count, characters[i] != ">" {
            i += 1
        }
        if i < characters.count, characters[i] == ">" {
            i += 1
        }
        index = i
        return HtmlTagToken(name: name, attributes: [], isEndTag: true, isEmptyElement: false)
    }

    private func parseStartTag() -> HtmlToken {
        var i = index + 1
        while i < characters.count, characters[i].isWhitespace {
            i += 1
        }
        let nameStart = i
        while i < characters.count, !characters[i].isWhitespace, characters[i] != ">", characters[i] != "/" {
            i += 1
        }
        let name = String(characters[nameStart..<i])
        var attributes: [HtmlAttribute] = []
        var isEmptyElement = false

        while i < characters.count {
            while i < characters.count, characters[i].isWhitespace {
                i += 1
            }
            if i >= characters.count {
                break
            }
            if characters[i] == ">" {
                i += 1
                break
            }
            if characters[i] == "/" {
                if i + 1 < characters.count, characters[i + 1] == ">" {
                    isEmptyElement = true
                    i += 2
                    break
                }
                i += 1
                continue
            }

            let attrNameStart = i
            while i < characters.count, !characters[i].isWhitespace, characters[i] != "=", characters[i] != ">", characters[i] != "/" {
                i += 1
            }
            let attrName = String(characters[attrNameStart..<i])

            while i < characters.count, characters[i].isWhitespace {
                i += 1
            }

            var attrValue: String? = nil
            if i < characters.count, characters[i] == "=" {
                i += 1
                while i < characters.count, characters[i].isWhitespace {
                    i += 1
                }
                if i < characters.count, characters[i] == "\"" || characters[i] == "'" {
                    let quote = characters[i]
                    i += 1
                    let valueStart = i
                    while i < characters.count, characters[i] != quote {
                        i += 1
                    }
                    attrValue = String(characters[valueStart..<min(i, characters.count)])
                    if i < characters.count, characters[i] == quote {
                        i += 1
                    }
                } else {
                    let valueStart = i
                    while i < characters.count, !characters[i].isWhitespace, characters[i] != ">", characters[i] != "/" {
                        i += 1
                    }
                    if i > valueStart {
                        attrValue = String(characters[valueStart..<i])
                    }
                }
            }

            if !attrName.isEmpty {
                attributes.append(HtmlAttribute(name: attrName, value: attrValue))
            }
        }

        index = i
        let token = HtmlTagToken(name: name, attributes: attributes, isEndTag: false, isEmptyElement: isEmptyElement)

        if !isEmptyElement {
            let lowerName = name.lowercased()
            if lowerName == "script" || lowerName == "style" {
                rawTextTag = lowerName
            }
        }

        return token
    }

    private func startsWith(_ prefix: String, at index: Int) -> Bool {
        let prefixChars = Array(prefix)
        guard index + prefixChars.count <= characters.count else {
            return false
        }
        for i in 0..<prefixChars.count {
            if characters[index + i] != prefixChars[i] {
                return false
            }
        }
        return true
    }

    private func findClosingTag(_ tag: String, from startIndex: Int) -> Int? {
        let lowerTag = tag.lowercased()
        var i = startIndex
        while i + 2 < characters.count {
            if characters[i] == "<" && characters[i + 1] == "/" {
                var j = i + 2
                while j < characters.count, characters[j].isWhitespace {
                    j += 1
                }
                let nameStart = j
                while j < characters.count, !characters[j].isWhitespace, characters[j] != ">" {
                    j += 1
                }
                if nameStart < j {
                    let name = String(characters[nameStart..<j]).lowercased()
                    if name == lowerTag {
                        return i
                    }
                }
            }
            i += 1
        }
        return nil
    }
}
