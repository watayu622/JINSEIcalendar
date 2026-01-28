import SwiftUI
import SwiftData

struct CalendarView: View {
    @Query private var goals: [LifeGoal]
    @Query private var places: [PlaceToVisit]

    @State private var selectedDate = Date()
    @State private var displayedMonth = Date()

    private var calendar: Calendar { Calendar.current }

    /// 表示月の全日付を取得
    private var daysInMonth: [Date] {
        guard let range = calendar.range(of: .day, in: .month, for: displayedMonth),
              let firstDay = calendar.date(from: calendar.dateComponents([.year, .month], from: displayedMonth))
        else { return [] }

        return range.compactMap { day in
            calendar.date(byAdding: .day, value: day - 1, to: firstDay)
        }
    }

    /// 月の最初の曜日のオフセット（日曜始まり）
    private var firstWeekdayOffset: Int {
        guard let firstDay = daysInMonth.first else { return 0 }
        return calendar.component(.weekday, from: firstDay) - 1
    }

    /// 選択日のイベント
    private var eventsForSelectedDate: [CalendarEvent] {
        eventsForDate(selectedDate)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    // 月のナビゲーション
                    monthNavigationHeader

                    // 曜日ヘッダー
                    weekdayHeader

                    // カレンダーグリッド
                    calendarGrid

                    Divider()
                        .padding(.horizontal)

                    // 選択日のイベント表示
                    selectedDateEvents
                }
                .padding()
            }
            .navigationTitle("カレンダー")
        }
    }

    // MARK: - Month Navigation
    private var monthNavigationHeader: some View {
        HStack {
            Button {
                moveMonth(by: -1)
            } label: {
                Image(systemName: "chevron.left")
                    .font(.title3)
            }

            Spacer()

            Text(monthYearString(from: displayedMonth))
                .font(.title2.bold())

            Spacer()

            Button {
                moveMonth(by: 1)
            } label: {
                Image(systemName: "chevron.right")
                    .font(.title3)
            }
        }
        .padding(.horizontal)
    }

    // MARK: - Weekday Header
    private var weekdayHeader: some View {
        let weekdays = ["日", "月", "火", "水", "木", "金", "土"]
        return HStack {
            ForEach(weekdays, id: \.self) { day in
                Text(day)
                    .font(.caption.bold())
                    .frame(maxWidth: .infinity)
                    .foregroundStyle(day == "日" ? .red : day == "土" ? .blue : .primary)
            }
        }
    }

    // MARK: - Calendar Grid
    private var calendarGrid: some View {
        let columns = Array(repeating: GridItem(.flexible()), count: 7)
        return LazyVGrid(columns: columns, spacing: 8) {
            // 空白セル（月初のオフセット）
            ForEach(0..<firstWeekdayOffset, id: \.self) { _ in
                Text("")
                    .frame(height: 44)
            }

            // 日付セル
            ForEach(daysInMonth, id: \.self) { date in
                DayCellView(
                    date: date,
                    isSelected: calendar.isDate(date, inSameDayAs: selectedDate),
                    isToday: calendar.isDateInToday(date),
                    events: eventsForDate(date)
                )
                .onTapGesture {
                    selectedDate = date
                }
            }
        }
    }

    // MARK: - Selected Date Events
    private var selectedDateEvents: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(dateString(from: selectedDate))
                .font(.headline)
                .padding(.horizontal)

            if eventsForSelectedDate.isEmpty {
                Text("この日の予定はありません")
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 20)
            } else {
                ForEach(eventsForSelectedDate) { event in
                    EventRow(event: event)
                        .padding(.horizontal)
                }
            }
        }
    }

    // MARK: - Helper Methods
    private func moveMonth(by value: Int) {
        if let newMonth = calendar.date(byAdding: .month, value: value, to: displayedMonth) {
            withAnimation {
                displayedMonth = newMonth
            }
        }
    }

    private func eventsForDate(_ date: Date) -> [CalendarEvent] {
        var events: [CalendarEvent] = []

        // やりたいことの期限
        for goal in goals {
            if let deadline = goal.deadline,
               calendar.isDate(deadline, inSameDayAs: date) {
                events.append(CalendarEvent(
                    title: goal.title,
                    type: .goalDeadline,
                    isCompleted: goal.isCompleted
                ))
            }
        }

        // 行きたい場所の目標日
        for place in places {
            if let targetDate = place.targetDate,
               calendar.isDate(targetDate, inSameDayAs: date) {
                events.append(CalendarEvent(
                    title: place.name,
                    type: .placeTarget,
                    isCompleted: place.isVisited
                ))
            }
        }

        return events
    }

    private func monthYearString(from date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ja_JP")
        formatter.dateFormat = "yyyy年 M月"
        return formatter.string(from: date)
    }

    private func dateString(from date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ja_JP")
        formatter.dateFormat = "M月d日 (E)"
        return formatter.string(from: date)
    }
}

// MARK: - CalendarEvent
struct CalendarEvent: Identifiable {
    let id = UUID()
    let title: String
    let type: EventType
    let isCompleted: Bool

    enum EventType {
        case goalDeadline
        case placeTarget

        var color: Color {
            switch self {
            case .goalDeadline: return .orange
            case .placeTarget: return .blue
            }
        }

        var icon: String {
            switch self {
            case .goalDeadline: return "star.fill"
            case .placeTarget: return "mappin.circle.fill"
            }
        }

        var label: String {
            switch self {
            case .goalDeadline: return "目標期限"
            case .placeTarget: return "訪問予定"
            }
        }
    }
}

// MARK: - DayCellView
struct DayCellView: View {
    let date: Date
    let isSelected: Bool
    let isToday: Bool
    let events: [CalendarEvent]

    private var dayNumber: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "d"
        return formatter.string(from: date)
    }

    var body: some View {
        VStack(spacing: 2) {
            Text(dayNumber)
                .font(.system(.body, design: .rounded))
                .fontWeight(isToday ? .bold : .regular)
                .foregroundStyle(isSelected ? .white : isToday ? .orange : .primary)
                .frame(width: 32, height: 32)
                .background {
                    if isSelected {
                        Circle().fill(.orange)
                    } else if isToday {
                        Circle().stroke(.orange, lineWidth: 1.5)
                    }
                }

            // イベントドット
            HStack(spacing: 2) {
                ForEach(events.prefix(3)) { event in
                    Circle()
                        .fill(event.isCompleted ? .gray : event.type.color)
                        .frame(width: 5, height: 5)
                }
            }
            .frame(height: 6)
        }
        .frame(height: 44)
    }
}

// MARK: - EventRow
struct EventRow: View {
    let event: CalendarEvent

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: event.type.icon)
                .foregroundStyle(event.isCompleted ? .gray : event.type.color)
                .font(.title3)

            VStack(alignment: .leading, spacing: 2) {
                Text(event.title)
                    .font(.body)
                    .strikethrough(event.isCompleted)
                    .foregroundStyle(event.isCompleted ? .secondary : .primary)

                Text(event.type.label)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            if event.isCompleted {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(.green)
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(event.type.color.opacity(0.1))
        )
    }
}
