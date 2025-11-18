//
//  TimeSlotPickerView.swift
//  WeeMo
//
//  Created by Reimos on 11/17/25.
//

import SwiftUI

// MARK: - Time Slot Picker View (단일 시간대 선택)

struct TimeSlotPickerView: View {
    @Binding var selectedTimeSlot: Int? // 선택된 시작 시간 (0~23)
    let pricePerHour: Int

    private let hours = Array(0...23) // 0시부터 23시까지

    var body: some View {
        VStack(spacing: Spacing.base) {
            // 헤더
            HStack(spacing: Spacing.small) {
                Image(systemName: "clock")
                    .font(.system(size: AppFontSize.s18.rawValue))
                    .foregroundColor(Color("textMain"))

                Text("시간 선택")
                    .font(.app(.headline3))
                    .foregroundColor(Color("textMain"))

                Spacer()
            }

            // 시간대 그리드 (3열)
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 3), spacing: Spacing.small) {
                ForEach(hours, id: \.self) { hour in
                    TimeSlotButton(
                        hour: hour,
                        price: pricePerHour,
                        isSelected: selectedTimeSlot == hour
                    ) {
                        if selectedTimeSlot == hour {
                            selectedTimeSlot = nil // 같은 시간 탭하면 선택 해제
                        } else {
                            selectedTimeSlot = hour
                        }
                    }
                }
            }
        }
    }
}

// MARK: - Time Slot Button

struct TimeSlotButton: View {
    let hour: Int
    let price: Int
    let isSelected: Bool
    let action: () -> Void

    private var timeRange: String {
        String(format: "%02d:00-%02d:00", hour, hour + 1)
    }

    private var formattedPrice: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        return formatter.string(from: NSNumber(value: price)) ?? "\(price)"
    }

    var body: some View {
        Button(action: action) {
            VStack(spacing: Spacing.xSmall) {
                Text(timeRange)
                    .font(.app(.subHeadline2))
                    .foregroundColor(isSelected ? .white : Color("textMain"))

                Text("\(formattedPrice)원")
                    .font(.app(.subContent2))
                    .foregroundColor(isSelected ? .white.opacity(0.8) : Color("textSub"))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, Spacing.medium)
            .background(isSelected ? Color("wmMain") : Color.gray.opacity(0.1))
            .cornerRadius(Spacing.radiusSmall)
        }
    }
}

// MARK: - Preview

#Preview {
    VStack {
        TimeSlotPickerView(
            selectedTimeSlot: .constant(14),
            pricePerHour: 15000
        )
        .padding()
    }
    .background(Color("wmBg"))
}
