//
// MimeVisitorTests.swift
//

import Testing
@testable import MimeFoundation

final class CountingVisitor: MimeVisitor {
    var messages = 0
    var entities = 0
    var parts = 0
    var textParts = 0
    var messageParts = 0
    var deliveryStatus = 0
    var dispositionNotification = 0
    var feedbackReport = 0
    var messagePartial = 0
    var multiparts = 0

    func visit(_ message: MimeMessage) { messages += 1 }
    func visit(_ entity: MimeEntity) { entities += 1 }
    func visit(_ part: MimePart) { parts += 1 }
    func visit(_ part: TextPart) { textParts += 1 }
    func visit(_ part: MessagePart) { messageParts += 1 }
    func visit(_ part: MessageDeliveryStatus) { deliveryStatus += 1 }
    func visit(_ part: MessageDispositionNotification) { dispositionNotification += 1 }
    func visit(_ part: MessageFeedbackReport) { feedbackReport += 1 }
    func visit(_ part: MessagePartial) { messagePartial += 1 }
    func visit(_ multipart: Multipart) { multiparts += 1 }
}

@Test("MimeVisitor dispatch")
func mimeVisitorDispatch() throws {
    let visitor = CountingVisitor()

    let message = MimeMessage()
    message.subject = "Hello"
    let multipart = try Multipart("mixed")
    _ = try? multipart.add(TextPart("plain"))
    _ = try? multipart.add(MessageDeliveryStatus())
    _ = try? multipart.add(MessageDispositionNotification())
    _ = try? multipart.add(MessageFeedbackReport())
    _ = try? multipart.add(MessagePartial("id@example.com", 1, 1))
    message.body = multipart

    try message.accept(visitor)
    #expect(visitor.messages == 1)

    let iterator = MimeIterator(message)
    let iter = iterator
    #expect(iter.moveNext())
    repeat {
        try iter.current?.accept(visitor)
    } while iter.moveNext()

    #expect(visitor.multiparts >= 1)
    #expect(visitor.textParts >= 1)
    #expect(visitor.deliveryStatus == 1)
    #expect(visitor.dispositionNotification == 1)
    #expect(visitor.feedbackReport == 1)
    #expect(visitor.messagePartial == 1)
}
