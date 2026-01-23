//
// MimeIteratorTests.swift
//

import Testing
@testable import SwiftMimeKit

private func createImapExampleMessageRfc822(_ parents: inout [MimeEntity?]) -> MessagePart {
    let message = MimeMessage()
    let mixed = try! Multipart("mixed")
    let rfc822 = MessagePart("rfc822")
    rfc822.message = message

    parents.append(rfc822)
    message.body = mixed

    parents.append(mixed)
    _ = try? mixed.add(TextPart("plain"))

    parents.append(mixed)
    _ = try? mixed.add(MimePart())

    return rfc822
}

private func createImapExampleInnerMessageRfc822(_ parents: inout [MimeEntity?]) -> MessagePart {
    let message = MimeMessage()
    let mixed = try! Multipart("mixed")
    let alternative = MultipartAlternative()
    let rfc822 = MessagePart("rfc822")
    rfc822.message = message

    parents.append(rfc822)
    message.body = mixed

    parents.append(mixed)
    _ = try? mixed.add(TextPart("plain"))

    parents.append(mixed)
    _ = try? mixed.add(alternative)

    parents.append(alternative)
    _ = try? alternative.add(TextPart("plain"))

    parents.append(alternative)
    _ = try? alternative.add(TextPart("richtext"))

    return rfc822
}

private func createImapExampleInnerMultipart(_ parents: inout [MimeEntity?]) -> Multipart {
    let mixed = try! Multipart("mixed")

    parents.append(mixed)
    _ = try? mixed.add(MimePart("image", "gif"))

    parents.append(mixed)
    _ = try? mixed.add(createImapExampleInnerMessageRfc822(&parents))

    return mixed
}

private func createImapExampleMessage(_ parents: inout [MimeEntity?]) -> MimeMessage {
    let message = MimeMessage()
    let mixed = try! Multipart("mixed")
    message.body = mixed

    parents.append(mixed)
    _ = try? mixed.add(TextPart("plain"))

    parents.append(mixed)
    _ = try? mixed.add(MimePart())

    parents.append(mixed)
    _ = try? mixed.add(createImapExampleMessageRfc822(&parents))

    parents.append(mixed)
    _ = try? mixed.add(createImapExampleInnerMultipart(&parents))

    return message
}

@Test("MimeIterator path specifiers")
func mimeIteratorPathSpecifiers() {
    let expectedPathSpecifiers = ["0", "1", "2", "3", "3.0", "3.1", "3.2", "4", "4.1", "4.2", "4.2.0", "4.2.1", "4.2.2", "4.2.2.1", "4.2.2.2"]
    let expectedDepths = [0, 1, 1, 1, 2, 3, 3, 1, 2, 2, 3, 4, 4, 5, 5]
    var expectedParents: [MimeEntity?] = [nil]
    let message = createImapExampleMessage(&expectedParents)
    let iterator = MimeIterator(message)

    var index = 0
    let iter = iterator
    #expect(iter.moveNext())
    repeat {
        #expect(iter.depth == expectedDepths[index])
        #expect(iter.parent === expectedParents[index])
        #expect(iter.pathSpecifier == expectedPathSpecifiers[index])
        index += 1
    } while iter.moveNext()

    #expect(index == expectedPathSpecifiers.count)
}

@Test("MimeIterator move to")
func mimeIteratorMoveTo() throws {
    let expectedPathSpecifiers = ["0", "1", "2", "3", "3.0", "3.1", "3.2", "4", "4.1", "4.2", "4.2.0", "4.2.1", "4.2.2", "4.2.2.1", "4.2.2.2"]
    let paths = ["3.1", "3.2", "4", "4.2.1", "4.2.2.2", "4.2", "3.2"]
    let expectedDepths = [0, 1, 1, 1, 2, 3, 3, 1, 2, 2, 3, 4, 4, 5, 5]
    var expectedParents: [MimeEntity?] = [nil]
    let message = createImapExampleMessage(&expectedParents)
    let iter = MimeIterator(message)

    for path in paths {
        let index = expectedPathSpecifiers.firstIndex(of: path) ?? 0
        #expect(try iter.moveTo(path) == true)
        #expect(iter.pathSpecifier == expectedPathSpecifiers[index])
        #expect(iter.parent === expectedParents[index])
        #expect(iter.depth == expectedDepths[index])
    }
}
