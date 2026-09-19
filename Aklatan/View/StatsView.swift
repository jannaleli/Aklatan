import Charts
import SwiftUI

private enum StatsPeriod: String, CaseIterable, Identifiable {
    case week = "Week"
    case month = "Month"
    case year = "Year"
    var id: Self { self }
}

struct StatsView: View {
    @Environment(\.accentTheme) private var theme
    @EnvironmentObject private var activity: ReadingActivityStore
    @EnvironmentObject private var library: LibraryStore
    @State private var period: StatsPeriod = .week

    private let calendar = Calendar.current

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 0) {
                DisplayText("Reading Stats", size: 32)

                Picker("Period", selection: $period) {
                    ForEach(StatsPeriod.allCases) { period in
                        Text(period.rawValue).tag(period)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.top, 18)

                summaryGrid
                    .padding(.top, 20)

                SectionTitle("Reading activity")
                    .padding(.top, 28)
                    .padding(.bottom, 12)
                activityChart

                SectionTitle("Yearly goal")
                    .padding(.top, 28)
                    .padding(.bottom, 12)
                goalCard

                if !favoriteSubjects.isEmpty {
                    SectionTitle("Favorite subjects")
                        .padding(.top, 28)
                        .padding(.bottom, 12)
                    subjectCard
                }
            }
            .padding(.horizontal, 22)
            .padding(.top, 18)
            .padding(.bottom, 120)
        }
        .background(Palette.background)
    }

    private var summaryGrid: some View {
        LazyVGrid(
            columns: [GridItem(.flexible(), spacing: 12), GridItem(.flexible())],
            spacing: 12
        ) {
            statCard(value: "\(finishedCount)", label: "Books finished", icon: "checkmark.circle")
            statCard(value: formattedMinutes(totalMinutes), label: "Reading time", icon: "clock")
            statCard(value: "\(activeDays)", label: "Active days", icon: "calendar")
            statCard(value: "\(activity.currentStreak())", label: "Day streak", icon: "flame.fill")
        }
    }

    private func statCard(value: String, label: String, icon: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Image(systemName: icon)
                .foregroundStyle(icon == "flame.fill" ? Palette.flame : theme.color)
            DisplayText(value, size: 24)
            Text(label)
                .font(.system(size: 12))
                .foregroundStyle(Palette.muted)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .cardStyle(radius: 16)
    }

    private var activityChart: some View {
        VStack(alignment: .leading, spacing: 12) {
            if totalMinutes == 0 {
                Text("Log a reading session to begin tracking your activity.")
                    .font(.system(size: 13))
                    .foregroundStyle(Palette.muted)
                    .frame(maxWidth: .infinity, minHeight: 150)
                    .multilineTextAlignment(.center)
            } else {
                Chart(chartPoints, id: \.date) { point in
                    BarMark(
                        x: .value("Date", point.date, unit: chartUnit),
                        y: .value("Minutes", point.minutes)
                    )
                    .foregroundStyle(theme.color.gradient)
                    .cornerRadius(4)
                }
                .chartYAxis {
                    AxisMarks(position: .leading)
                }
                .chartXAxis {
                    AxisMarks(values: .automatic(desiredCount: period == .week ? 7 : 5)) {
                        AxisGridLine().foregroundStyle(Palette.hairline)
                        AxisValueLabel(format: axisDateFormat)
                    }
                }
                .frame(height: 180)
            }
        }
        .padding(16)
        .cardStyle(radius: 16)
    }

    private var goalCard: some View {
        let year = calendar.component(.year, from: .now)
        let goal = activity.goal(for: year)
        let completed = activity.completions(from: yearInterval.start, to: yearInterval.end).count
        let progress = min(Double(completed) / Double(goal), 1)

        return VStack(alignment: .leading, spacing: 12) {
            HStack {
                DisplayText("\(completed) of \(goal) books", size: 19)
                Spacer()
                HStack(spacing: 14) {
                    Button {
                        activity.setGoal(max(1, goal - 1), for: year)
                    } label: {
                        Image(systemName: "minus.circle")
                    }
                    Button {
                        activity.setGoal(goal + 1, for: year)
                    } label: {
                        Image(systemName: "plus.circle")
                    }
                }
                .font(.system(size: 20))
                .foregroundStyle(theme.ink)
                .buttonStyle(.plain)
            }
            ProgressBar(value: progress, color: theme.color)
            Text("\(Int(progress * 100))% of your \(year) goal")
                .font(.system(size: 12))
                .foregroundStyle(Palette.muted)
        }
        .padding(16)
        .cardStyle(radius: 16)
    }

    private var subjectCard: some View {
        VStack(spacing: 12) {
            ForEach(Array(favoriteSubjects.prefix(5)), id: \.name) { subject in
                HStack {
                    Text(subject.name)
                        .font(.system(size: 13, weight: .medium))
                        .lineLimit(1)
                    Spacer()
                    Text("\(subject.count)")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(theme.ink)
                }
            }
        }
        .padding(16)
        .cardStyle(radius: 16)
    }

    private var interval: DateInterval {
        let now = Date.now
        switch period {
        case .week:
            return calendar.dateInterval(of: .weekOfYear, for: now) ?? DateInterval(start: now, duration: 1)
        case .month:
            return calendar.dateInterval(of: .month, for: now) ?? DateInterval(start: now, duration: 1)
        case .year:
            return yearInterval
        }
    }

    private var yearInterval: DateInterval {
        calendar.dateInterval(of: .year, for: .now) ?? DateInterval(start: .now, duration: 1)
    }

    private var totalMinutes: Int {
        activity.minutes(from: interval.start, to: interval.end)
    }

    private var activeDays: Int {
        activity.activeDays(from: interval.start, to: interval.end)
    }

    private var finishedCount: Int {
        activity.completions(from: interval.start, to: interval.end).count
    }

    private var chartPoints: [(date: Date, minutes: Int)] {
        switch period {
        case .week, .month:
            return dailyPoints(in: interval)
        case .year:
            return monthsInCurrentYear()
        }
    }

    private var chartUnit: Calendar.Component {
        period == .year ? .month : .day
    }

    private var axisDateFormat: Date.FormatStyle {
        period == .year ? .dateTime.month(.abbreviated) : .dateTime.weekday(.narrow)
    }

    private func monthsInCurrentYear() -> [(date: Date, minutes: Int)] {
        let yearStart = yearInterval.start
        return (0..<12).compactMap { offset in
            guard let month = calendar.date(byAdding: .month, value: offset, to: yearStart),
                  let nextMonth = calendar.date(byAdding: .month, value: 1, to: month),
                  month <= Date.now else {
                return nil
            }
            return (month, activity.minutes(from: month, to: nextMonth))
        }
    }

    private func dailyPoints(in interval: DateInterval) -> [(date: Date, minutes: Int)] {
        var points: [(date: Date, minutes: Int)] = []
        var day = calendar.startOfDay(for: interval.start)
        let today = calendar.startOfDay(for: .now)

        while day <= today && day < interval.end {
            guard let nextDay = calendar.date(byAdding: .day, value: 1, to: day) else {
                break
            }
            points.append((day, activity.minutes(from: day, to: nextDay)))
            day = nextDay
        }
        return points
    }

    private var favoriteSubjects: [(name: String, count: Int)] {
        let ids = activity.completions.map(\.bookID)
        let subjects = ids.compactMap { library.book(id: $0)?.subjects.first }
        return Dictionary(grouping: subjects, by: { $0 })
            .map { (name: $0.key, count: $0.value.count) }
            .sorted { $0.count > $1.count }
    }

    private func formattedMinutes(_ minutes: Int) -> String {
        guard minutes >= 60 else { return "\(minutes)m" }
        return "\(minutes / 60)h \(minutes % 60)m"
    }
}
