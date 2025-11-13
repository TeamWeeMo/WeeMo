//
//  MeetScheduleSection.swift
//  WeeMo
//
//  Created by 차지용 on 11/10/25.
//

import SwiftUI

struct MeetSchedule: View {
    @State private var startDate = Date()
    @State private var endDate = Date().addingTimeInterval(3600) // 1시간 후
    @State private var showingStartDatePicker = false
    @State private var showingEndDatePicker = false

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            SectionHeader(title: "일정")

            VStack(spacing: 12) {
                // 시작일 선택
                Button(action: {
                    showingStartDatePicker = true
                }) {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("시작일")
                                .font(.app(.content2))
                                .foregroundColor(Color("textSub"))

                            Text(DateFormatter.displayFormatter.string(from: startDate))
                                .font(.app(.content1))
                                .foregroundColor(Color("textMain"))
                        }

                        Spacer()

                        Image(systemName: "calendar")
                            .foregroundColor(.blue)
                            .font(.system(size: 20))
                    }
                }
                .cardStyle()
                .buttonStyle(PlainButtonStyle())

                // 종료일 선택
                Button(action: {
                    showingEndDatePicker = true
                }) {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("종료일")
                                .font(.app(.content2))
                                .foregroundColor(Color("textSub"))

                            Text(DateFormatter.displayFormatter.string(from: endDate))
                                .font(.app(.content1))
                                .foregroundColor(Color("textMain"))
                        }

                        Spacer()

                        Image(systemName: "calendar")
                            .foregroundColor(.blue)
                            .font(.system(size: 20))
                    }
                }
                .cardStyle()
                .buttonStyle(PlainButtonStyle())
            }
        }
        .sheet(isPresented: $showingStartDatePicker) {
            DatePickerView(
                title: "시작일 선택",
                selectedDate: $startDate,
                minimumDate: Date()
            )
        }
        .sheet(isPresented: $showingEndDatePicker) {
            DatePickerView(
                title: "종료일 선택",
                selectedDate: $endDate,
                minimumDate: startDate
            )
        }
        .onChange(of: startDate) { newStartDate in
            // 시작일이 종료일보다 늦으면 종료일을 시작일 + 1시간으로 설정
            if newStartDate >= endDate {
                endDate = newStartDate.addingTimeInterval(3600)
            }
        }
    }
}

struct DatePickerView: View {
    let title: String
    @Binding var selectedDate: Date
    let minimumDate: Date?
    @Environment(\.presentationMode) var presentationMode

    var body: some View {
        VStack {
            CustomNavigationBar(
                onCancel: { presentationMode.wrappedValue.dismiss() },
                onComplete: { presentationMode.wrappedValue.dismiss() }
            )

            DatePicker(
                "",
                selection: $selectedDate,
                in: (minimumDate ?? Date.distantPast)...,
                displayedComponents: [.date, .hourAndMinute]
            )
            .datePickerStyle(WheelDatePickerStyle())
            .labelsHidden()
            .environment(\.locale, Locale(identifier: "ko_KR"))
            .padding(.horizontal, 20)
            .frame(maxHeight: 200)

            Spacer()
        }
        .frame(maxHeight: 320)
        .background(Color("wmBg"))
        .cornerRadius(16, corners: [.topLeft, .topRight])
        .presentationDetents([.height(320)])
    }
}
