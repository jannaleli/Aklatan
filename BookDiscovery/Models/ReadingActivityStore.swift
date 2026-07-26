import Combine
import Foundation

struct ReadingSession: Codable, Identifiable, Sendable {
    let id: UUID
    let bookID: String
    let date: Date
    let durationMinutes: Int
    let progressAfter: Double?
}

struct BookCompletion: Codable, Identifiable, Sendable {
    let id: UUID
    let bookID: String
    let completedAt: Date
}

@MainActor
final class ReadingActivityStore: ObservableObject {
    @Published private(set) var sessions: [ReadingSession]
    @Published private(set) var completions: [BookCompletion]
    @Published private(set) var yearlyGoals: [Int: Int]

    private let defaults: UserDefaults
    private let storageKey: String
    private let calendar: Calendar

    init(
        defaults: UserDefaults = .standard,
        storageKey: String = "marginalia.readingActivity.v1",
        calendar: Calendar = .current
    ) {
        self.defaults = defaults
        self.storageKey = storageKey
        self.calendar = calendar

        if let data = defaults.data(forKey: storageKey),
           let archive = try? JSONDecoder().decode(ActivityArchive.self, from: data) {
            sessions = archive.sessions
            completions = archive.completions
            yearlyGoals = archive.yearlyGoals
        } else {
            sessions = []
            completions = []
            yearlyGoals = [:]
        }
    }

    func logSession(
        for book: Book,
        minutes: Int,
        progressAfter: Double?,
        date: Date = .now
    ) {
        guard minutes > 0 else {
            return
        }

        sessions.append(
            ReadingSession(
                id: UUID(),
                bookID: book.id,
                date: date,
                durationMinutes: minutes,
                progressAfter: progressAfter
            )
        )
        persist()
    }

    func markFinished(_ book: Book, at date: Date = .now) {
        let alreadyCompletedThisYear = completions.contains {
            $0.bookID == book.id
                && calendar.isDate(
                    $0.completedAt,
                    equalTo: date,
                    toGranularity: .year
                )
        }

        guard !alreadyCompletedThisYear else {
            return
        }

        completions.append(
            BookCompletion(
                id: UUID(),
                bookID: book.id,
                completedAt: date
            )
        )
        persist()
    }

    func setGoal(_ target: Int, for year: Int) {
        yearlyGoals[year] = max(1, target)
        persist()
    }

    func goal(for year: Int) -> Int {
        yearlyGoals[year] ?? 12
    }

    func minutes(from start: Date, to end: Date) -> Int {
        sessions
            .filter { $0.date >= start && $0.date < end }
            .reduce(0) { $0 + $1.durationMinutes }
    }

    func completions(from start: Date, to end: Date) -> [BookCompletion] {
        completions.filter { $0.completedAt >= start && $0.completedAt < end }
    }

    func activeDays(from start: Date, to end: Date) -> Int {
        Set(
            sessions
                .filter { $0.date >= start && $0.date < end }
                .map { calendar.startOfDay(for: $0.date) }
        ).count
    }

    func minutesByDay(endingAt date: Date, days: Int) -> [(date: Date, minutes: Int)] {
        let endDay = calendar.startOfDay(for: date)
        return (0..<days).reversed().compactMap { offset in
            guard let day = calendar.date(byAdding: .day, value: -offset, to: endDay),
                  let nextDay = calendar.date(byAdding: .day, value: 1, to: day) else {
                return nil
            }
            return (day, minutes(from: day, to: nextDay))
        }
    }

    func currentStreak(asOf date: Date = .now) -> Int {
        let activeDays = Set(sessions.map { calendar.startOfDay(for: $0.date) })
        var cursor = calendar.startOfDay(for: date)

        if !activeDays.contains(cursor) {
            guard let yesterday = calendar.date(byAdding: .day, value: -1, to: cursor),
                  activeDays.contains(yesterday) else {
                return 0
            }
            cursor = yesterday
        }

        var streak = 0
        while activeDays.contains(cursor) {
            streak += 1
            guard let previous = calendar.date(byAdding: .day, value: -1, to: cursor) else {
                break
            }
            cursor = previous
        }
        return streak
    }

    private func persist() {
        let archive = ActivityArchive(
            sessions: sessions,
            completions: completions,
            yearlyGoals: yearlyGoals
        )

        guard let data = try? JSONEncoder().encode(archive) else {
            return
        }

        defaults.set(data, forKey: storageKey)
    }
}

private struct ActivityArchive: Codable {
    let sessions: [ReadingSession]
    let completions: [BookCompletion]
    let yearlyGoals: [Int: Int]
}
