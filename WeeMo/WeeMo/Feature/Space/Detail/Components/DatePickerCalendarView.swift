//
//  DatePickerCalendarView.swift
//  WeeMo
//
//  Created by Reimos on 2025-11-08.
//

import SwiftUI

// MARK: - Calendar Cell Model
struct CalendarCell: Identifiable {
    let id = UUID()
    let day: Int?
    let date: Date?

    var isEmpty: Bool {
        day == nil
    }
}

struct DatePickerCalendarView: View {
    @Binding var selectedDate: Date?
    @Binding var startHour: Int?
    @Binding var endHour: Int?
    let pricePerHour: Int
    var blockedHours: Set<Int> = [] // 예약된(블락된) 시간

    @State private var currentMonth: Date = Date()

    private let calendar = Calendar.current
    private let daysOfWeek = ["일", "월", "화", "수", "목", "금", "토"]

    // 월의 첫 번째 날
    private var monthStartDate: Date {
        calendar.date(from: calendar.dateComponents([.year, .month], from: currentMonth))!
    }

    // 월의 일수
    private var daysInMonth: Int {
        calendar.range(of: .day, in: .month, for: currentMonth)?.count ?? 30
    }

    // 월의 첫 번째 날이 무슨 요일인지 (0: 일요일)
    private var firstWeekday: Int {
        calendar.component(.weekday, from: monthStartDate) - 1
    }

    // 현재 월/년 표시
    private var monthYearString: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ko_KR")
        formatter.dateFormat = "yyyy년 MMMM"
        return formatter.string(from: currentMonth)
    }

    // 캘린더 셀 배열 생성
    private var calendarCells: [CalendarCell] {
        var cells: [CalendarCell] = []

        // 앞쪽 빈 칸
        for _ in 0..<firstWeekday {
            cells.append(CalendarCell(day: nil, date: nil))
        }

        // 실제 날짜들
        for day in 1...daysInMonth {
            let date = calendar.date(byAdding: .day, value: day - 1, to: monthStartDate)!
            cells.append(CalendarCell(day: day, date: date))
        }

        return cells
    }

    var body: some View {
        VStack(spacing: Spacing.base) {
            // 헤더: 날짜 선택
            HStack(spacing: Spacing.small) {
                Image(systemName: "calendar")
                    .font(.system(size: AppFontSize.s18.rawValue))
                    .foregroundColor(Color("textMain"))

                Text("날짜 선택")
                    .font(.app(.content1))
                    .foregroundColor(Color("textMain"))

                Spacer()
            }

            // 월/년 네비게이션
            HStack {
                Button(action: previousMonth) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: AppFontSize.s14.rawValue))
                        .foregroundColor(Color("textMain"))
                }

                Spacer()

                Text(monthYearString)
                    .font(.app(.subHeadline2))
                    .foregroundColor(Color("textMain"))

                Spacer()

                Button(action: nextMonth) {
                    Image(systemName: "chevron.right")
                        .font(.system(size: AppFontSize.s16.rawValue))
                        .foregroundColor(Color("textMain"))
                }
            }
            .padding(.vertical, Spacing.small)

            // 요일 헤더
            HStack(spacing: 0) {
                ForEach(daysOfWeek, id: \.self) { day in
                    Text(day)
                        .font(.app(.subContent2))
                        .foregroundColor(Color("textSub"))
                        .frame(maxWidth: .infinity)
                }
            }

            // 날짜 그리드
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7), spacing: Spacing.small) {
                ForEach(calendarCells) { cell in
                    if cell.isEmpty {
                        Text("")
                            .frame(height: 40)
                    } else if let day = cell.day, let date = cell.date {
                        DateCellView(
                            day: day,
                            isSelected: calendar.isDate(date, inSameDayAs: selectedDate ?? Date.distantPast),
                            isToday: calendar.isDateInToday(date)
                        ) {
                            selectedDate = date
                        }
                    }
                }
            }

            // 시간 선택 타임라인 (날짜가 선택되었을 때만 표시)
            if selectedDate != nil {
                Divider()
                    .padding(.vertical, Spacing.small)

                TimelineBarView(
                    pricePerHour: pricePerHour,
                    startHour: $startHour,
                    endHour: $endHour,
                    blockedHours: blockedHours
                )
            }
        }
        .padding(Spacing.base)
        .background(Color.white)
        .cornerRadius(Spacing.radiusMedium)
        .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
    }

    private func previousMonth() {
        currentMonth = calendar.date(byAdding: .month, value: -1, to: currentMonth)!
    }

    private func nextMonth() {
        currentMonth = calendar.date(byAdding: .month, value: 1, to: currentMonth)!
    }
}

struct DateCellView: View {
    let day: Int
    let isSelected: Bool
    let isToday: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text("\(day)")
                .font(.app(.content2))
                .foregroundColor(isSelected ? .white : Color("textMain"))
                .frame(height: 40)
                .frame(maxWidth: .infinity)
                .background(
                    isSelected ? Color("wmMain") :
                    isToday ? Color("wmGray") :
                    Color.clear
                )
                .cornerRadius(Spacing.radiusSmall)
        }
    }
}

#Preview {
    DatePickerCalendarView(
        selectedDate: .constant(Date()),
        startHour: .constant(nil),
        endHour: .constant(nil),
        pricePerHour: 15000
    )
    .padding()
}
