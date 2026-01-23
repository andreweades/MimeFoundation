//
// DateTimeOffset.swift
//
// Ported from MimeKit (C#) to Swift.
//

import Foundation

public struct DateTimeOffset: Equatable, Sendable {
    public let date: Date
    public let offsetMinutes: Int

    public init?(year: Int, month: Int, day: Int, hour: Int, minute: Int, second: Int, offsetMinutes: Int) {
        guard let timeZone = TimeZone(secondsFromGMT: offsetMinutes * 60) else {
            return nil
        }
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = timeZone
        let components = DateComponents(
            year: year,
            month: month,
            day: day,
            hour: hour,
            minute: minute,
            second: second
        )
        guard let date = calendar.date(from: components) else {
            return nil
        }
        self.date = date
        self.offsetMinutes = offsetMinutes
    }

    public init(date: Date, offsetMinutes: Int) {
        self.date = date
        self.offsetMinutes = offsetMinutes
    }

    public static func now() -> DateTimeOffset {
        let now = Date()
        let offset = TimeZone.current.secondsFromGMT(for: now) / 60
        return DateTimeOffset(date: now, offsetMinutes: offset)
    }

    private var calendar: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: offsetMinutes * 60) ?? TimeZone(secondsFromGMT: 0)!
        return calendar
    }

    public var year: Int {
        calendar.component(.year, from: date)
    }

    public var month: Int {
        calendar.component(.month, from: date)
    }

    public var day: Int {
        calendar.component(.day, from: date)
    }

    public var hour: Int {
        calendar.component(.hour, from: date)
    }

    public var minute: Int {
        calendar.component(.minute, from: date)
    }

    public var second: Int {
        calendar.component(.second, from: date)
    }

    // 0 = Sunday, 6 = Saturday
    public var dayOfWeek: Int {
        let weekday = calendar.component(.weekday, from: date)
        return max(0, weekday - 1)
    }
}
