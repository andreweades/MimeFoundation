//
// Author: Jeffrey Stedfast <jestedfa@microsoft.com>
//
// Copyright (c) 2013-2026 .NET Foundation and Contributors
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.
//

//
// MimeIteratorTests.swift
//

import Testing
@testable import MimeFoundation

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
