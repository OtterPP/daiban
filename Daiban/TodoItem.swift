import Foundation

struct TodoItem: Identifiable, Codable, Equatable, Hashable {
    var id: UUID
    var title: String
    var isDone: Bool
    var createdAt: Date
    var doneAt: Date?
    /// Optional due instant, parsed from capture text (e.g. `8月24日 16:00`).
    var dueAt: Date?

    init(
        id: UUID = UUID(),
        title: String,
        isDone: Bool = false,
        createdAt: Date = Date(),
        doneAt: Date? = nil,
        dueAt: Date? = nil
    ) {
        self.id = id
        self.title = title
        self.isDone = isDone
        self.createdAt = createdAt
        self.doneAt = doneAt
        self.dueAt = dueAt
    }

    /// Overdue only applies to open items. Completing a todo must hide 「过期」,
    /// even when `dueAt` is still in the past.
    func isOverdue(at now: Date = Date()) -> Bool {
        guard !isDone, let dueAt else { return false }
        return dueAt < now
    }

    var isOverdue: Bool { isOverdue() }

    /// Split a capture string into title + optional trailing Chinese datetime.
    /// Example: `"给勇哥发进度 8月24日 16:00"` → title without the date, `dueAt` set.
    static func parseCapture(_ raw: String, now: Date = Date(), calendar: Calendar = .current) -> (title: String, dueAt: Date?) {
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return ("", nil) }

        let pattern = #"(\d{1,2})月(\d{1,2})日(?:\s+(\d{1,2}):(\d{2}))?\s*$"#
        guard let regex = try? NSRegularExpression(pattern: pattern),
              let match = regex.firstMatch(in: trimmed, range: NSRange(trimmed.startIndex..., in: trimmed)),
              let fullRange = Range(match.range, in: trimmed),
              let monthRange = Range(match.range(at: 1), in: trimmed),
              let dayRange = Range(match.range(at: 2), in: trimmed),
              let month = Int(trimmed[monthRange]),
              let day = Int(trimmed[dayRange])
        else {
            return (trimmed, nil)
        }

        var hour = 23
        var minute = 59
        if match.range(at: 3).location != NSNotFound,
           let hourRange = Range(match.range(at: 3), in: trimmed),
           let minuteRange = Range(match.range(at: 4), in: trimmed),
           let parsedHour = Int(trimmed[hourRange]),
           let parsedMinute = Int(trimmed[minuteRange]) {
            hour = parsedHour
            minute = parsedMinute
        }

        // Invalid components must keep the original title. Calendar is lenient
        // and would otherwise turn `2月30日` into March 2 and `25:00` into 01:00.
        guard let dueAt = exactDueDate(
            month: month,
            day: day,
            hour: hour,
            minute: minute,
            now: now,
            calendar: calendar
        ) else {
            return (trimmed, nil)
        }

        let prefix = trimmed[..<fullRange.lowerBound]
            .trimmingCharacters(in: .whitespacesAndNewlines)
        return (prefix.isEmpty ? trimmed : String(prefix), dueAt)
    }

    private static func exactDueDate(
        month: Int,
        day: Int,
        hour: Int,
        minute: Int,
        now: Date,
        calendar: Calendar
    ) -> Date? {
        guard (1...12).contains(month),
              (1...31).contains(day),
              (0...23).contains(hour),
              (0...59).contains(minute)
        else {
            return nil
        }

        var components = calendar.dateComponents([.year], from: now)
        components.month = month
        components.day = day
        components.hour = hour
        components.minute = minute
        components.second = 0

        guard let dueAt = calendar.date(from: components) else { return nil }

        let roundTrip = calendar.dateComponents([.month, .day, .hour, .minute], from: dueAt)
        guard roundTrip.month == month,
              roundTrip.day == day,
              roundTrip.hour == hour,
              roundTrip.minute == minute
        else {
            return nil
        }
        return dueAt
    }

    static func displayDate(_ date: Date) -> String {
        displayFormatter.string(from: date)
    }

    private static let displayFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh_CN")
        formatter.dateFormat = "M月d日 HH:mm"
        return formatter
    }()
}

struct TodoFile: Codable {
    var items: [TodoItem]
}
